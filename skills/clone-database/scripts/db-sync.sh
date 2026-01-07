#!/bin/bash

# Database Sync Script
# Sync database from remote server to local using DATABASE_URL format
#
# Usage:
#   ./db-sync.sh --remote-ssh user@host --remote-url "mysql://user:pass@host:port/db" [options]
#   ./db-sync.sh --profile ec2_prod
#
# Examples:
#   # Full command
#   ./db-sync.sh \
#     --remote-ssh user@aws-start-ec2 \
#     --remote-url "mysql+pymysql://root:testpass123@127.0.0.1:3306/<databasename>" \
#     --local-url "mysql://root:localpass@localhost:3306/<databasename>"
#
#   # Using profile
#   ./db-sync.sh --profile ec2_prod
#
#   # Auto-create local if not exists
#   ./db-sync.sh --remote-ssh user@ec2 --remote-url "mysql://..." --auto-create-local

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }
step() { echo -e "${BLUE}[$1/$2]${NC} $3"; }

# Default values
BACKUP_DIR="./backups"
COMPRESSION=true
CLEANUP_REMOTE=true
BACKUP_LOCAL=false
AUTO_CREATE_LOCAL=false
NO_CONFIRM=false

# Parse DATABASE_URL to extract components
# Format: mysql://user:pass@host:port/dbname
parse_db_url() {
    local url="$1"
    local prefix="$2"  # For variable naming: REMOTE_ or LOCAL_

    # Detect database type from original URL
    if [[ "$1" =~ ^postgres ]]; then
        eval "${prefix}DB_TYPE=postgresql"
    else
        eval "${prefix}DB_TYPE=mysql"
    fi

    # Remove protocol (mysql://, mysql+pymysql://, postgresql://, etc.)
    url=$(echo "$url" | sed -E 's#^[a-z+]+://##')

    # Use regex to parse URL components (handles special characters in password)
    # Format: user:pass@host:port/dbname
    # Match from the end to handle @ in password: find last @, then work backwards
    if [[ "$url" =~ ^(.+)@([^@/]+)/([^?]+) ]]; then
        local userpass="${BASH_REMATCH[1]}"
        local hostport="${BASH_REMATCH[2]}"
        local dbname="${BASH_REMATCH[3]}"

        # Extract user (before first :)
        eval "${prefix}USER=\"${userpass%%:*}\""
        # Extract password (after first :)
        eval "${prefix}PASSWORD=\"${userpass#*:}\""

        # Extract host and port
        eval "${prefix}HOST=\"${hostport%:*}\""
        if [[ "$hostport" == *:* ]]; then
            eval "${prefix}PORT=\"${hostport##*:}\""
        else
            eval "${prefix}PORT=\"3306\""  # Default port
        fi

        eval "${prefix}DB_NAME=\"$dbname\""
    else
        error "Failed to parse database URL: $1"
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --remote-ssh)
            REMOTE_SSH_HOST="$2"
            shift 2
            ;;
        --remote-url)
            REMOTE_URL="$2"
            shift 2
            ;;
        --local-url)
            LOCAL_URL="$2"
            shift 2
            ;;
        --profile)
            PROFILE="$2"
            shift 2
            ;;
        --auto-create-local)
            AUTO_CREATE_LOCAL=true
            shift
            ;;
        --backup-local)
            BACKUP_LOCAL=true
            shift
            ;;
        --no-compression)
            COMPRESSION=false
            shift
            ;;
        --keep-remote)
            CLEANUP_REMOTE=false
            shift
            ;;
        --yes|-y|--no-confirm)
            NO_CONFIRM=true
            shift
            ;;
        -h|--help)
            cat << EOF
Database Sync Script

Usage:
  $0 --remote-ssh HOST --remote-url URL [--local-url URL] [options]
  $0 --profile PROFILE_NAME

Required Arguments (if not using --profile):
  --remote-ssh HOST          SSH host (user@host or alias)
  --remote-url URL           Remote database URL

Optional Arguments:
  --local-url URL            Local database URL (if not provided, will prompt)
  --auto-create-local        Auto-create local database if not exists
  --backup-local             Backup local database before overwrite
  --no-compression           Disable gzip compression
  --keep-remote              Keep remote backup file after sync

Profile:
  --profile NAME             Use saved profile from sync_profiles.env

Examples:
  # Sync from EC2 to local
  $0 \\
    --remote-ssh user@aws-start-ec2 \\
    --remote-url "mysql://root:testpass123@127.0.0.1:3306/<databasename>" \\
    --local-url "mysql://root:localpass@localhost:3306/<databasename>"

  # Auto-create local if not exists
  $0 \\
    --remote-ssh user@ec2 \\
    --remote-url "mysql://root:pass@127.0.0.1:3306/mydb" \\
    --auto-create-local

  # Use saved profile
  $0 --profile ec2_prod

EOF
            exit 0
            ;;
        *)
            error "Unknown option: $1. Use --help for usage."
            ;;
    esac
done

# Load profile if specified
if [ -n "$PROFILE" ]; then
    PROFILE_FILE="./sync_profiles.env"
    if [ ! -f "$PROFILE_FILE" ]; then
        PROFILE_FILE="$(dirname "$0")/../sync_profiles.env"
    fi

    if [ -f "$PROFILE_FILE" ]; then
        info "Loading profile: $PROFILE"
        source "$PROFILE_FILE"
        # Build URLs from profile
        REMOTE_URL="${REMOTE_DB_TYPE}://${REMOTE_DB_USER}:${REMOTE_DB_PASSWORD}@${REMOTE_DB_HOST}:${REMOTE_DB_PORT}/${REMOTE_DB_NAME}"
        LOCAL_URL="${LOCAL_DB_TYPE}://${LOCAL_DB_USER}:${LOCAL_DB_PASSWORD}@${LOCAL_DB_HOST}:${LOCAL_DB_PORT}/${LOCAL_DB_NAME}"
    else
        error "Profile file not found: $PROFILE_FILE"
    fi
fi

# Validate required arguments
if [ -z "$REMOTE_SSH_HOST" ]; then
    error "Missing --remote-ssh argument. Use --help for usage."
fi

if [ -z "$REMOTE_URL" ]; then
    error "Missing --remote-url argument. Use --help for usage."
fi

# Parse DATABASE URLs
parse_db_url "$REMOTE_URL" "REMOTE_"

# If local URL not provided, prompt or use remote as template
if [ -z "$LOCAL_URL" ]; then
    echo ""
    echo "Local database URL not provided."
    echo "Remote database: ${REMOTE_DB_NAME} (${REMOTE_DB_TYPE})"
    echo ""
    read -p "Local database name (default: ${REMOTE_DB_NAME}): " LOCAL_DB_NAME_INPUT
    LOCAL_DB_NAME_INPUT=${LOCAL_DB_NAME_INPUT:-$REMOTE_DB_NAME}

    read -p "Local database user (default: root): " LOCAL_USER_INPUT
    LOCAL_USER_INPUT=${LOCAL_USER_INPUT:-root}

    read -sp "Local database password: " LOCAL_PASSWORD_INPUT
    echo ""

    LOCAL_PORT_INPUT=3306
    if [ "$REMOTE_DB_TYPE" = "postgresql" ]; then
        LOCAL_PORT_INPUT=5432
    fi

    LOCAL_URL="${REMOTE_DB_TYPE}://${LOCAL_USER_INPUT}:${LOCAL_PASSWORD_INPUT}@localhost:${LOCAL_PORT_INPUT}/${LOCAL_DB_NAME_INPUT}"
fi

parse_db_url "$LOCAL_URL" "LOCAL_"

# Display sync plan
echo ""
echo "=========================================="
echo "Database Sync Plan"
echo "=========================================="
echo ""
echo "Source (Remote):"
echo "  SSH Host: ${REMOTE_SSH_HOST}"
echo "  Database: ${REMOTE_DB_NAME} (${REMOTE_DB_TYPE})"
echo "  Host: ${REMOTE_HOST}:${REMOTE_PORT}"
echo "  User: ${REMOTE_USER}"
echo ""
echo "Destination (Local):"
echo "  Database: ${LOCAL_DB_NAME} (${LOCAL_DB_TYPE})"
echo "  Host: ${LOCAL_HOST}:${LOCAL_PORT}"
echo "  User: ${LOCAL_USER}"
echo ""
echo "Options:"
echo "  Compression: ${COMPRESSION}"
echo "  Backup local: ${BACKUP_LOCAL}"
echo "  Auto-create local: ${AUTO_CREATE_LOCAL}"
echo "  Cleanup remote: ${CLEANUP_REMOTE}"
echo ""

if [ "$NO_CONFIRM" = false ]; then
    read -p "Continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        warn "Sync cancelled"
        exit 0
    fi
else
    info "Auto-confirming sync (--yes flag)"
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

TOTAL_STEPS=6
CURRENT_STEP=0

# Step 1: Get remote database statistics
((CURRENT_STEP++))
step $CURRENT_STEP $TOTAL_STEPS "Collecting remote database statistics..."

# Get remote table row counts
if [ "$REMOTE_DB_TYPE" = "mysql" ]; then
    REMOTE_STATS=$(ssh "$REMOTE_SSH_HOST" "mysql -h ${REMOTE_HOST} -P ${REMOTE_PORT} -u ${REMOTE_USER} -p'${REMOTE_PASSWORD}' ${REMOTE_DB_NAME} -e \"SELECT table_name, table_rows FROM information_schema.tables WHERE table_schema='${REMOTE_DB_NAME}' ORDER BY table_name\" 2>/dev/null")
    REMOTE_TOTAL_ROWS=$(ssh "$REMOTE_SSH_HOST" "mysql -h ${REMOTE_HOST} -P ${REMOTE_PORT} -u ${REMOTE_USER} -p'${REMOTE_PASSWORD}' ${REMOTE_DB_NAME} -e \"SELECT SUM(table_rows) FROM information_schema.tables WHERE table_schema='${REMOTE_DB_NAME}'\" 2>/dev/null | tail -1")
elif [ "$REMOTE_DB_TYPE" = "postgresql" ]; then
    REMOTE_STATS=$(ssh "$REMOTE_SSH_HOST" "PGPASSWORD='${REMOTE_PASSWORD}' psql -h ${REMOTE_HOST} -p ${REMOTE_PORT} -U ${REMOTE_USER} -d ${REMOTE_DB_NAME} -t -c \"SELECT schemaname||'.'||tablename, n_live_tup FROM pg_stat_user_tables ORDER BY tablename\" 2>/dev/null")
    REMOTE_TOTAL_ROWS=$(ssh "$REMOTE_SSH_HOST" "PGPASSWORD='${REMOTE_PASSWORD}' psql -h ${REMOTE_HOST} -p ${REMOTE_PORT} -U ${REMOTE_USER} -d ${REMOTE_DB_NAME} -t -c \"SELECT SUM(n_live_tup) FROM pg_stat_user_tables\" 2>/dev/null | xargs")
fi

info "Remote database: ${REMOTE_TOTAL_ROWS} total rows"

# Step 2: Backup remote database
((CURRENT_STEP++))
step $CURRENT_STEP $TOTAL_STEPS "Backing up remote database..."

BACKUP_FILENAME="backup_${REMOTE_DB_NAME}_$(date +%Y%m%d_%H%M%S).sql"
if [ "$COMPRESSION" = true ]; then
    BACKUP_FILENAME="${BACKUP_FILENAME}.gz"
fi

if [ "$REMOTE_DB_TYPE" = "mysql" ]; then
    if [ "$COMPRESSION" = true ]; then
        ssh "$REMOTE_SSH_HOST" "mysqldump -h ${REMOTE_HOST} -P ${REMOTE_PORT} -u ${REMOTE_USER} -p'${REMOTE_PASSWORD}' \
            --single-transaction --routines --triggers --events \
            ${REMOTE_DB_NAME} | gzip > /tmp/${BACKUP_FILENAME}" 2>/dev/null
    else
        ssh "$REMOTE_SSH_HOST" "mysqldump -h ${REMOTE_HOST} -P ${REMOTE_PORT} -u ${REMOTE_USER} -p'${REMOTE_PASSWORD}' \
            --single-transaction --routines --triggers --events \
            ${REMOTE_DB_NAME} > /tmp/${BACKUP_FILENAME}" 2>/dev/null
    fi
elif [ "$REMOTE_DB_TYPE" = "postgresql" ]; then
    if [ "$COMPRESSION" = true ]; then
        ssh "$REMOTE_SSH_HOST" "PGPASSWORD='${REMOTE_PASSWORD}' pg_dump -h ${REMOTE_HOST} -p ${REMOTE_PORT} -U ${REMOTE_USER} -d ${REMOTE_DB_NAME} \
            --clean --if-exists | gzip > /tmp/${BACKUP_FILENAME}" 2>/dev/null
    else
        ssh "$REMOTE_SSH_HOST" "PGPASSWORD='${REMOTE_PASSWORD}' pg_dump -h ${REMOTE_HOST} -p ${REMOTE_PORT} -U ${REMOTE_USER} -d ${REMOTE_DB_NAME} \
            --clean --if-exists > /tmp/${BACKUP_FILENAME}" 2>/dev/null
    fi
fi

if [ $? -eq 0 ]; then
    REMOTE_SIZE=$(ssh "$REMOTE_SSH_HOST" "ls -lh /tmp/${BACKUP_FILENAME} | awk '{print \$5}'")
    info "Remote backup created: ${BACKUP_FILENAME} (${REMOTE_SIZE})"
else
    error "Failed to create remote backup"
fi

# Step 2: Download backup
((CURRENT_STEP++))
step $CURRENT_STEP $TOTAL_STEPS "Downloading backup..."

rsync -avz --progress "$REMOTE_SSH_HOST:/tmp/${BACKUP_FILENAME}" "${BACKUP_DIR}/${BACKUP_FILENAME}"

if [ $? -eq 0 ]; then
    LOCAL_SIZE=$(ls -lh "${BACKUP_DIR}/${BACKUP_FILENAME}" | awk '{print $5}')
    info "Downloaded to: ${BACKUP_DIR}/${BACKUP_FILENAME} (${LOCAL_SIZE})"
else
    error "Failed to download backup"
fi

# Step 3: Prepare local database
((CURRENT_STEP++))
step $CURRENT_STEP $TOTAL_STEPS "Preparing local database..."

# Check if local database exists
if [ "$LOCAL_DB_TYPE" = "mysql" ]; then
    DB_EXISTS=$(mysql -h ${LOCAL_HOST} -P ${LOCAL_PORT} -u ${LOCAL_USER} -p"${LOCAL_PASSWORD}" \
        -e "SHOW DATABASES LIKE '${LOCAL_DB_NAME}'" 2>/dev/null | grep -c "${LOCAL_DB_NAME}")
elif [ "$LOCAL_DB_TYPE" = "postgresql" ]; then
    DB_EXISTS=$(PGPASSWORD="${LOCAL_PASSWORD}" psql -h ${LOCAL_HOST} -p ${LOCAL_PORT} -U ${LOCAL_USER} -lqt 2>/dev/null | \
        cut -d \| -f 1 | grep -w "${LOCAL_DB_NAME}" | wc -l)
fi

if [ "$DB_EXISTS" -gt 0 ]; then
    warn "Local database '${LOCAL_DB_NAME}' already exists"

    if [ "$BACKUP_LOCAL" = true ]; then
        LOCAL_BACKUP_FILE="${BACKUP_DIR}/local_backup_${LOCAL_DB_NAME}_$(date +%Y%m%d_%H%M%S).sql.gz"
        info "Backing up local database to: ${LOCAL_BACKUP_FILE}"

        if [ "$LOCAL_DB_TYPE" = "mysql" ]; then
            mysqldump -h ${LOCAL_HOST} -P ${LOCAL_PORT} -u ${LOCAL_USER} -p"${LOCAL_PASSWORD}" \
                ${LOCAL_DB_NAME} | gzip > "${LOCAL_BACKUP_FILE}"
        elif [ "$LOCAL_DB_TYPE" = "postgresql" ]; then
            PGPASSWORD="${LOCAL_PASSWORD}" pg_dump -h ${LOCAL_HOST} -p ${LOCAL_PORT} -U ${LOCAL_USER} -d ${LOCAL_DB_NAME} | \
                gzip > "${LOCAL_BACKUP_FILE}"
        fi
        info "Local backup saved"
    fi

    # Drop and recreate
    if [ "$LOCAL_DB_TYPE" = "mysql" ]; then
        mysql -h ${LOCAL_HOST} -P ${LOCAL_PORT} -u ${LOCAL_USER} -p"${LOCAL_PASSWORD}" \
            -e "DROP DATABASE IF EXISTS ${LOCAL_DB_NAME}; CREATE DATABASE ${LOCAL_DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
    elif [ "$LOCAL_DB_TYPE" = "postgresql" ]; then
        PGPASSWORD="${LOCAL_PASSWORD}" dropdb -h ${LOCAL_HOST} -p ${LOCAL_PORT} -U ${LOCAL_USER} ${LOCAL_DB_NAME} 2>/dev/null || true
        PGPASSWORD="${LOCAL_PASSWORD}" createdb -h ${LOCAL_HOST} -p ${LOCAL_PORT} -U ${LOCAL_USER} ${LOCAL_DB_NAME} 2>/dev/null
    fi
    info "Recreated database: ${LOCAL_DB_NAME}"
else
    if [ "$AUTO_CREATE_LOCAL" = true ]; then
        info "Creating local database: ${LOCAL_DB_NAME}"
        if [ "$LOCAL_DB_TYPE" = "mysql" ]; then
            mysql -h ${LOCAL_HOST} -P ${LOCAL_PORT} -u ${LOCAL_USER} -p"${LOCAL_PASSWORD}" \
                -e "CREATE DATABASE ${LOCAL_DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
        elif [ "$LOCAL_DB_TYPE" = "postgresql" ]; then
            PGPASSWORD="${LOCAL_PASSWORD}" createdb -h ${LOCAL_HOST} -p ${LOCAL_PORT} -U ${LOCAL_USER} ${LOCAL_DB_NAME} 2>/dev/null
        fi
        info "Created database: ${LOCAL_DB_NAME}"
    else
        error "Local database '${LOCAL_DB_NAME}' does not exist. Use --auto-create-local to create it."
    fi
fi

# Step 4: Restore to local
((CURRENT_STEP++))
step $CURRENT_STEP $TOTAL_STEPS "Restoring to local database..."

if [ "$LOCAL_DB_TYPE" = "mysql" ]; then
    if [ "$COMPRESSION" = true ]; then
        gunzip < "${BACKUP_DIR}/${BACKUP_FILENAME}" | \
            mysql -h ${LOCAL_HOST} -P ${LOCAL_PORT} -u ${LOCAL_USER} -p"${LOCAL_PASSWORD}" ${LOCAL_DB_NAME} 2>/dev/null
    else
        mysql -h ${LOCAL_HOST} -P ${LOCAL_PORT} -u ${LOCAL_USER} -p"${LOCAL_PASSWORD}" ${LOCAL_DB_NAME} \
            < "${BACKUP_DIR}/${BACKUP_FILENAME}" 2>/dev/null
    fi
elif [ "$LOCAL_DB_TYPE" = "postgresql" ]; then
    if [ "$COMPRESSION" = true ]; then
        gunzip < "${BACKUP_DIR}/${BACKUP_FILENAME}" | \
            PGPASSWORD="${LOCAL_PASSWORD}" psql -h ${LOCAL_HOST} -p ${LOCAL_PORT} -U ${LOCAL_USER} -d ${LOCAL_DB_NAME} 2>/dev/null
    else
        PGPASSWORD="${LOCAL_PASSWORD}" psql -h ${LOCAL_HOST} -p ${LOCAL_PORT} -U ${LOCAL_USER} -d ${LOCAL_DB_NAME} \
            < "${BACKUP_DIR}/${BACKUP_FILENAME}" 2>/dev/null
    fi
fi

if [ $? -eq 0 ]; then
    info "Restore completed successfully"
else
    error "Restore failed"
fi

# Step 5: Verify local database and compare
((CURRENT_STEP++))
step $CURRENT_STEP $TOTAL_STEPS "Verifying local database..."

# Get local table row counts
if [ "$LOCAL_DB_TYPE" = "mysql" ]; then
    LOCAL_STATS=$(mysql -h ${LOCAL_HOST} -P ${LOCAL_PORT} -u ${LOCAL_USER} -p"${LOCAL_PASSWORD}" ${LOCAL_DB_NAME} \
        -e "SELECT table_name, table_rows FROM information_schema.tables WHERE table_schema='${LOCAL_DB_NAME}' ORDER BY table_name" 2>/dev/null)
    LOCAL_TOTAL_ROWS=$(mysql -h ${LOCAL_HOST} -P ${LOCAL_PORT} -u ${LOCAL_USER} -p"${LOCAL_PASSWORD}" ${LOCAL_DB_NAME} \
        -e "SELECT SUM(table_rows) FROM information_schema.tables WHERE table_schema='${LOCAL_DB_NAME}'" 2>/dev/null | tail -1)
    TABLE_COUNT=$(mysql -h ${LOCAL_HOST} -P ${LOCAL_PORT} -u ${LOCAL_USER} -p"${LOCAL_PASSWORD}" ${LOCAL_DB_NAME} \
        -e "SHOW TABLES" 2>/dev/null | wc -l)
    TABLE_COUNT=$((TABLE_COUNT - 1))  # Subtract header row
elif [ "$LOCAL_DB_TYPE" = "postgresql" ]; then
    LOCAL_STATS=$(PGPASSWORD="${LOCAL_PASSWORD}" psql -h ${LOCAL_HOST} -p ${LOCAL_PORT} -U ${LOCAL_USER} -d ${LOCAL_DB_NAME} -t \
        -c "SELECT schemaname||'.'||tablename, n_live_tup FROM pg_stat_user_tables ORDER BY tablename" 2>/dev/null)
    LOCAL_TOTAL_ROWS=$(PGPASSWORD="${LOCAL_PASSWORD}" psql -h ${LOCAL_HOST} -p ${LOCAL_PORT} -U ${LOCAL_USER} -d ${LOCAL_DB_NAME} -t \
        -c "SELECT SUM(n_live_tup) FROM pg_stat_user_tables" 2>/dev/null | xargs)
    TABLE_COUNT=$(PGPASSWORD="${LOCAL_PASSWORD}" psql -h ${LOCAL_HOST} -p ${LOCAL_PORT} -U ${LOCAL_USER} -d ${LOCAL_DB_NAME} -t \
        -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'" 2>/dev/null | xargs)
fi

info "Local database: ${LOCAL_TOTAL_ROWS} total rows"
info "Synced ${TABLE_COUNT} tables"

# Step 6: Cleanup
((CURRENT_STEP++))
step $CURRENT_STEP $TOTAL_STEPS "Cleanup..."

# Cleanup remote backup
if [ "$CLEANUP_REMOTE" = true ]; then
    ssh "$REMOTE_SSH_HOST" "rm -f /tmp/${BACKUP_FILENAME}"
    info "Removed remote backup file"
fi

# Generate DATABASE_URL and display summary
echo ""
echo "=========================================="
echo "Sync Complete! ✓"
echo "=========================================="
echo ""
echo "Database: ${LOCAL_DB_NAME}"
echo "Tables: ${TABLE_COUNT}"
echo "Total Rows: ${LOCAL_TOTAL_ROWS}"
echo "Backup: ${BACKUP_DIR}/${BACKUP_FILENAME}"
echo ""
echo "==========================================  "
echo "Data Comparison (Remote → Local)"
echo "=========================================="
echo ""
printf "%-40s %15s %15s\n" "Table Name" "Remote Rows" "Local Rows"
echo "--------------------------------------------------------------------------------"

# Parse and compare stats
if [ "$LOCAL_DB_TYPE" = "mysql" ]; then
    # Create temp files for parsing
    echo "$REMOTE_STATS" | tail -n +2 > /tmp/remote_stats.txt
    echo "$LOCAL_STATS" | tail -n +2 > /tmp/local_stats.txt

    # Read and display each table
    while IFS=$'\t' read -r table remote_rows; do
        # Find matching local row count
        local_rows=$(grep "^${table}" /tmp/local_stats.txt | awk '{print $2}')
        local_rows=${local_rows:-0}

        # Color code based on match
        if [ "$remote_rows" = "$local_rows" ]; then
            printf "${GREEN}%-40s %15s %15s ✓${NC}\n" "$table" "$remote_rows" "$local_rows"
        else
            printf "${YELLOW}%-40s %15s %15s ⚠${NC}\n" "$table" "$remote_rows" "$local_rows"
        fi
    done < /tmp/remote_stats.txt

    # Cleanup temp files
    rm -f /tmp/remote_stats.txt /tmp/local_stats.txt
elif [ "$LOCAL_DB_TYPE" = "postgresql" ]; then
    # Similar logic for PostgreSQL
    echo "$REMOTE_STATS" > /tmp/remote_stats.txt
    echo "$LOCAL_STATS" > /tmp/local_stats.txt

    while read -r line; do
        table=$(echo "$line" | awk '{print $1}')
        remote_rows=$(echo "$line" | awk '{print $2}')
        local_rows=$(grep "$table" /tmp/local_stats.txt | awk '{print $2}')
        local_rows=${local_rows:-0}

        if [ "$remote_rows" = "$local_rows" ]; then
            printf "${GREEN}%-40s %15s %15s ✓${NC}\n" "$table" "$remote_rows" "$local_rows"
        else
            printf "${YELLOW}%-40s %15s %15s ⚠${NC}\n" "$table" "$remote_rows" "$local_rows"
        fi
    done < /tmp/remote_stats.txt

    rm -f /tmp/remote_stats.txt /tmp/local_stats.txt
fi

echo "--------------------------------------------------------------------------------"
printf "%-40s %15s %15s\n" "TOTAL" "$REMOTE_TOTAL_ROWS" "$LOCAL_TOTAL_ROWS"

# Summary status
echo ""
if [ "$REMOTE_TOTAL_ROWS" = "$LOCAL_TOTAL_ROWS" ]; then
    info "Data verification: All rows synced successfully ✓"
else
    warn "Data verification: Row counts differ (Remote: ${REMOTE_TOTAL_ROWS}, Local: ${LOCAL_TOTAL_ROWS})"
    warn "Note: MySQL information_schema.tables.table_rows is approximate. Run ANALYZE TABLE for exact counts."
fi

echo ""
echo "=========================================="
echo "Connection Information"
echo "=========================================="
echo ""
echo "DATABASE_URL:"
if [ "$LOCAL_DB_TYPE" = "mysql" ]; then
    echo "mysql+pymysql://${LOCAL_USER}:${LOCAL_PASSWORD}@${LOCAL_HOST}:${LOCAL_PORT}/${LOCAL_DB_NAME}"
elif [ "$LOCAL_DB_TYPE" = "postgresql" ]; then
    echo "postgresql://${LOCAL_USER}:${LOCAL_PASSWORD}@${LOCAL_HOST}:${LOCAL_PORT}/${LOCAL_DB_NAME}"
fi
echo ""
echo "Connect:"
if [ "$LOCAL_DB_TYPE" = "mysql" ]; then
    echo "mysql -h ${LOCAL_HOST} -P ${LOCAL_PORT} -u ${LOCAL_USER} -p ${LOCAL_DB_NAME}"
elif [ "$LOCAL_DB_TYPE" = "postgresql" ]; then
    echo "psql -h ${LOCAL_HOST} -p ${LOCAL_PORT} -U ${LOCAL_USER} -d ${LOCAL_DB_NAME}"
fi
echo ""
