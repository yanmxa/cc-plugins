---
name: db-sync
description: Sync MySQL/PostgreSQL databases from remote servers to local machine. Use when user mentions syncing database from EC2/server to local, copying remote database, or pulling database from remote. Handles backup, download, and restore in one workflow. Supports creating new or overwriting existing local database.
allowed-tools: [Bash, Read, Write, Glob, AskUserQuestion]
---

# db-sync - Cross-Machine Database Synchronization

One-command database synchronization from remote servers to local machine. Automates: remote backup → download → local restore → output DATABASE_URL.

## When to Use This Skill

- User wants to sync remote database to local
- User mentions "copy database from EC2/server to local"
- User asks to "pull database from remote"
- User needs local copy of remote database

## Core Workflow

```
1. Backup remote database (via SSH)
2. Download backup file (SCP/rsync)
3. Restore to local (new or existing database)
4. Output DATABASE_URL
5. Cleanup temp files
```

## Helper Script

**Location**: `~/.claude/skills/db-sync/scripts/db-sync.sh`

**Quick usage with DATABASE_URL:**
```bash
# Sync with full URLs
./db-sync.sh \
  --remote-ssh user@aws-start-ec2 \
  --remote-url "mysql+pymysql://root:testpass123@127.0.0.1:3306/shopline_demo_test_2" \
  --local-url "mysql://root:localpass@localhost:3306/shopline_demo_test_2"

# Auto-create local if not exists
./db-sync.sh \
  --remote-ssh user@aws-start-ec2 \
  --remote-url "mysql://root:testpass123@127.0.0.1:3306/shopline_demo_test_2" \
  --auto-create-local
```

**Natural language with Claude:**
> "Sync mysql+pymysql://root:testpass123@127.0.0.1:3306/shopline_demo_test_2 from aws-start-ec2 to local"

Claude will parse the request and use the script automatically.

## Instructions

### 1. Collect Information

**Ask user or detect from config:**

1. **Remote source**:
   - SSH host: `user@host` or SSH config alias
   - DB credentials: host, port, user, password, database name
   - DB type: MySQL or PostgreSQL

2. **Local destination**:
   - DB type: MySQL or PostgreSQL
   - DB name: Same as remote or new name?
   - Action: Create new or overwrite existing?

3. **Options**:
   - Use compression? (default: yes for >100MB)
   - Backup local DB first? (if overwriting)

### 2. Execute Sync

#### Step 1: Remote Backup

**MySQL:**
```bash
ssh user@host << 'ENDSSH'
mkdir -p ~/db_backups
mysqldump -h ${REMOTE_HOST} -P ${REMOTE_PORT} -u ${REMOTE_USER} -p'${REMOTE_PASSWORD}' \
  --single-transaction --routines --triggers --events \
  ${REMOTE_DB_NAME} | gzip > ~/db_backups/backup_$(date +%Y%m%d_%H%M%S).sql.gz
ls -lh ~/db_backups/backup_*.sql.gz | tail -1
ENDSSH
```

**PostgreSQL:**
```bash
ssh user@host << 'ENDSSH'
mkdir -p ~/db_backups
pg_dump -h ${REMOTE_HOST} -p ${REMOTE_PORT} -U ${REMOTE_USER} -d ${REMOTE_DB_NAME} \
  --clean --if-exists | gzip > ~/db_backups/backup_$(date +%Y%m%d_%H%M%S).sql.gz
ENDSSH
```

#### Step 2: Download Backup

```bash
# Create local backup directory
mkdir -p ./backups

# Download with progress
rsync -avz --progress user@host:~/db_backups/backup_TIMESTAMP.sql.gz ./backups/

# Or streaming (no intermediate file on remote)
ssh user@host "mysqldump ... | gzip" > ./backups/backup_$(date +%Y%m%d_%H%M%S).sql.gz
```

#### Step 3: Restore to Local

**Ask user:**
- Create new database or overwrite existing?
- If overwrite: Backup local first?

**MySQL restore:**
```bash
# Backup local if needed
if [ "$BACKUP_LOCAL" = "yes" ]; then
  mysqldump -u ${LOCAL_USER} -p'${LOCAL_PASSWORD}' ${LOCAL_DB_NAME} | \
    gzip > ./backups/local_backup_$(date +%Y%m%d_%H%M%S).sql.gz
fi

# Create or recreate database
mysql -u ${LOCAL_USER} -p'${LOCAL_PASSWORD}' << EOF
DROP DATABASE IF EXISTS ${LOCAL_DB_NAME};
CREATE DATABASE ${LOCAL_DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EOF

# Restore
gunzip < ./backups/backup_*.sql.gz | \
  mysql -u ${LOCAL_USER} -p'${LOCAL_PASSWORD}' ${LOCAL_DB_NAME}
```

**PostgreSQL restore:**
```bash
# Backup local if needed
if [ "$BACKUP_LOCAL" = "yes" ]; then
  pg_dump -U ${LOCAL_USER} -d ${LOCAL_DB_NAME} | \
    gzip > ./backups/local_backup_$(date +%Y%m%d_%H%M%S).sql.gz
fi

# Drop and recreate (or just restore with --clean flag)
dropdb ${LOCAL_DB_NAME} 2>/dev/null || true
createdb ${LOCAL_DB_NAME}

# Restore
gunzip < ./backups/backup_*.sql.gz | \
  psql -U ${LOCAL_USER} -d ${LOCAL_DB_NAME}
```

#### Step 4: Verify Sync

```bash
# MySQL: Count tables
LOCAL_TABLES=$(mysql -u ${LOCAL_USER} -p'${LOCAL_PASSWORD}' ${LOCAL_DB_NAME} -e "SHOW TABLES" | wc -l)

# PostgreSQL: Count tables
LOCAL_TABLES=$(psql -U ${LOCAL_USER} -d ${LOCAL_DB_NAME} -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'")

# Compare with remote (optional)
REMOTE_TABLES=$(ssh user@host "mysql ... -e 'SHOW TABLES' | wc -l")
```

#### Step 5: Generate DATABASE_URL

**MySQL:**
```bash
DATABASE_URL="mysql://${LOCAL_USER}:${LOCAL_PASSWORD}@localhost:${LOCAL_PORT}/${LOCAL_DB_NAME}"

# For Python/SQLAlchemy
DATABASE_URL="mysql+pymysql://${LOCAL_USER}:${LOCAL_PASSWORD}@localhost:${LOCAL_PORT}/${LOCAL_DB_NAME}"
```

**PostgreSQL:**
```bash
DATABASE_URL="postgresql://${LOCAL_USER}:${LOCAL_PASSWORD}@localhost:${LOCAL_PORT}/${LOCAL_DB_NAME}"
```

**Output to user:**
```
✓ Sync complete!

Database: ${LOCAL_DB_NAME}
Tables: ${LOCAL_TABLES}
Size: ${SIZE_MB} MB

DATABASE_URL:
mysql+pymysql://root:password@localhost:3306/shopline_demo_test_2

Connect:
mysql -u root -p shopline_demo_test_2
```

#### Step 6: Cleanup

```bash
# Ask user
read -p "Remove backup files? (yes/no): " cleanup

if [ "$cleanup" = "yes" ]; then
  # Remove remote backup
  ssh user@host "rm -f ~/db_backups/backup_*.sql.gz"

  # Remove local backup (optional, keep by default)
  # rm -f ./backups/backup_*.sql.gz
fi
```

### 3. Handle Existing Local Database

**Ask user:**
```
Local database 'shopline_demo_test_2' already exists.

What would you like to do?
[1] Overwrite (drop and recreate)
[2] Create with new name (e.g., shopline_demo_test_2_new)
[3] Cancel
```

**If overwrite:**
- Ask: Backup local database first?
- Warn: All local data will be lost
- Confirm: Type 'yes' to continue

**If new name:**
- Suggest name: `${DB_NAME}_${TIMESTAMP}` or `${DB_NAME}_remote`
- Create new database
- No local backup needed

## Common Scenarios

### Scenario 1: EC2 MySQL → Local MySQL (Create New)

**User**: "Sync shopline_demo_test_2 from EC2 to local"

**Actions**:
1. SSH to EC2, backup MySQL
2. Download backup (345 MB compressed)
3. Create local database `shopline_demo_test_2`
4. Restore 45 tables
5. Output: `mysql+pymysql://root:pass@localhost:3306/shopline_demo_test_2`

### Scenario 2: EC2 MySQL → Local MySQL (Overwrite)

**User**: "Sync shopline_demo_test_2 from EC2, overwrite local"

**Actions**:
1. Detect local DB exists
2. Ask: Backup local first? (yes)
3. Backup local → `local_backup_20251129.sql.gz`
4. SSH to EC2, backup remote
5. Download and restore (overwrites local)
6. Output DATABASE_URL

### Scenario 3: Remote PostgreSQL → Local PostgreSQL

**User**: "Pull postgres database app_db from staging server"

**Actions**:
1. SSH to staging, pg_dump
2. Download backup
3. Create/overwrite local `app_db`
4. Restore
5. Output: `postgresql://postgres:pass@localhost:5432/app_db`

### Scenario 4: Quick Streaming Sync (No Intermediate Files)

**User**: "Quick sync from remote, don't save backup file"

**Actions**:
```bash
# Stream: remote backup → download → local restore (all in one pipeline)
ssh user@host "mysqldump ... | gzip" | gunzip | mysql local_db

# Output DATABASE_URL
```

## Error Handling

### SSH Failed
```
✗ Cannot connect to user@host
→ Check: ssh user@host "echo test"
→ Verify SSH key or password
```

### Remote DB Unreachable
```
✗ Remote MySQL connection failed
→ Check: ssh user@host "mysql -u root -p'pass' -e 'SELECT 1'"
→ Verify credentials in remote config
```

### Local MySQL Not Running
```
✗ Local MySQL is not running
→ Start: brew services start mysql
→ Check: brew services list | grep mysql
```

### Disk Space Full
```
✗ Insufficient disk space (need 1.2 GB, have 500 MB)
→ Free space: df -h
→ Clean backups: rm ./backups/old_*.sql.gz
```

## Configuration

**Optional: Save sync profiles in `sync_profiles.env`:**

```bash
# EC2 Production to Local
EC2_PROD_SSH_HOST=user@ec2-xxx.amazonaws.com
EC2_PROD_DB_HOST=127.0.0.1
EC2_PROD_DB_PORT=3306
EC2_PROD_DB_USER=root
EC2_PROD_DB_PASSWORD=testpass123
EC2_PROD_DB_NAME=shopline_demo_test_2

LOCAL_DB_HOST=localhost
LOCAL_DB_PORT=3306
LOCAL_DB_USER=root
LOCAL_DB_PASSWORD=localpass
LOCAL_DB_NAME=shopline_demo_test_2
```

## Output Format

**Success:**
```
==========================================
Database Sync Complete ✓
==========================================

Source: user@ec2-host → shopline_demo_test_2
Destination: localhost → shopline_demo_test_2

Synced: 45 tables | 1.2 GB → 345 MB (compressed)
Time: 3m 24s | Speed: 8.2 MB/s

DATABASE_URL:
mysql+pymysql://root:password@localhost:3306/shopline_demo_test_2

Connect:
mysql -u root -p shopline_demo_test_2

Backup saved:
./backups/backup_20251129_143022.sql.gz
```

## Usage with Claude Code

**Trigger phrases:**
- "Sync shopline_demo_test_2 from EC2 to local"
- "Pull database from remote server"
- "Copy EC2 MySQL to local Mac"
- "Download remote database to local"
