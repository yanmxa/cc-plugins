---
name: init-postgres-mac
description: Install, configure, and manage PostgreSQL server with pgvector extension on macOS using Homebrew. Supports init, start, stop, restart, status, and remove operations.
allowed-tools: [Bash, Read, Write, AskUserQuestion]
---

# init-postgres-mac - PostgreSQL + pgvector for macOS

Complete PostgreSQL + pgvector lifecycle management for macOS using Homebrew.

## Operations

Detect operation from user request:
- **init**: Install and configure (keywords: install, setup, init, create)
- **start**: Start service (keywords: start)
- **stop**: Stop service (keywords: stop)
- **restart**: Restart service (keywords: restart, reload)
- **status**: Check status (keywords: status, check, running)
- **remove**: Uninstall (keywords: remove, uninstall, delete)

If unclear, ask user which operation.

## 1. INIT - Installation and Setup

### Step 1: Pre-check

```bash
# Check Homebrew
command -v brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Check existing installation
brew list postgresql@16 2>/dev/null && echo "PostgreSQL already installed"
brew list pgvector 2>/dev/null && echo "pgvector already installed"
```

If already installed, ask user: reinstall or skip to configuration?

### Step 2: Install PostgreSQL + pgvector

```bash
# Install PostgreSQL
brew install postgresql@16

# Install pgvector (works with postgresql@17 and @18 as well)
brew install pgvector

# Start service
brew services start postgresql@16

# Wait for initialization
sleep 5

# Verify running
brew services list | grep postgresql@16
```

### Step 3: Configure Database

**Ask user for configuration or use auto mode:**

**Interactive mode** - Ask for:
- Database name (default: textsql_db)
- Database user (default: textsql_user)
- User password

**Auto mode** - Generate password:
```bash
DB_PASSWORD=$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
DB_NAME="textsql_db"
DB_USER="textsql_user"
```

**Create database and user:**
```bash
# Create database
createdb ${DB_NAME}

# Create user
psql -d postgres -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';"

# Grant privileges
psql -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"

# Enable pgvector extension
psql -d ${DB_NAME} -c "CREATE EXTENSION vector;"

# Grant schema privileges (PostgreSQL 15+)
psql -d ${DB_NAME} -c "GRANT ALL ON SCHEMA public TO ${DB_USER};"
```

**Verify:**
```bash
# Test connection
psql -U ${DB_USER} -d ${DB_NAME} -c "SELECT 1;"

# Test pgvector
psql -U ${DB_USER} -d ${DB_NAME} -c "SELECT '[1,2,3]'::vector;"
```

### Step 4: Generate Configuration Files

**Create config/database.yaml:**
```yaml
database:
  type: postgresql
  version: "16.0"
  host: localhost
  port: 5432
  user: ${DB_USER}
  password: ${DB_PASSWORD}
  database: ${DB_NAME}
  sslmode: prefer
```

**Create/Update .env:**
```bash
# Backup existing .env
[ -f .env ] && cp .env .env.backup.$(date +%Y%m%d_%H%M%S)

# Create new .env
cat > .env <<EOF
# PostgreSQL Configuration
DATABASE_URI=postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}

DB_HOST=localhost
DB_PORT=5432
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=${DB_NAME}

# PostgreSQL environment variables
PGHOST=localhost
PGPORT=5432
PGUSER=${DB_USER}
PGPASSWORD=${DB_PASSWORD}
PGDATABASE=${DB_NAME}
EOF
```

**Optional: Create ~/.pgpass for password-less login:**
```bash
cat >> ~/.pgpass <<EOF
localhost:5432:${DB_NAME}:${DB_USER}:${DB_PASSWORD}
localhost:5432:*:${DB_USER}:${DB_PASSWORD}
EOF

chmod 600 ~/.pgpass
```

### Step 5: Display Summary

```
✅ PostgreSQL Installation Complete

PostgreSQL Version: 16.0
pgvector Version: 0.8.1
Database: ${DB_NAME}
User: ${DB_USER}
Host: localhost
Port: 5432

Auto-generated Password: ${DB_PASSWORD}
⚠️  Save this password securely!

Configuration Files:
  - config/database.yaml
  - .env
  - ~/.pgpass (optional)

Quick Test:
  psql -U ${DB_USER} -d ${DB_NAME} -c "SELECT '[1,2,3]'::vector;"

Service Management:
  brew services start postgresql@16
  brew services stop postgresql@16
  brew services restart postgresql@16
```

## 2. START - Start Service

```bash
# Start PostgreSQL
brew services start postgresql@16

# Wait for service to be ready
sleep 3

# Verify running
brew services list | grep postgresql@16 | grep started

# Check port
lsof -i :5432
```

**Display:**
```
✅ PostgreSQL Started

Service: postgresql@16 (running)
Port: 5432

Connect:
  psql -d postgres
```

## 3. STOP - Stop Service

```bash
# Stop PostgreSQL
brew services stop postgresql@16

# Verify stopped
brew services list | grep postgresql@16 | grep stopped
```

**Display:**
```
✅ PostgreSQL Stopped

Service: postgresql@16 (stopped)

To start again:
  brew services start postgresql@16
```

## 4. RESTART - Restart Service

```bash
# Restart PostgreSQL
brew services restart postgresql@16

# Wait for service to be ready
sleep 3

# Verify running
brew services list | grep postgresql@16 | grep started
```

**Display:**
```
✅ PostgreSQL Restarted

Service: postgresql@16 (running)
Port: 5432
```

## 5. STATUS - Check Status

```bash
# Service status
brew services list | grep postgresql

# Process check
ps aux | grep postgres | grep -v grep

# Port check
lsof -i :5432

# List databases
psql -d postgres -c "\l"

# Check pgvector
psql -d postgres -c "SELECT * FROM pg_available_extensions WHERE name = 'vector';"
```

**Display comprehensive status output.**

## 6. REMOVE - Uninstall

**⚠️ Warning: This will delete all data!**

Ask user:
- Confirm removal?
- Backup data first?
- Keep data directory?

**If confirmed:**

```bash
# Stop service
brew services stop postgresql@16

# Uninstall packages
brew uninstall postgresql@16
brew uninstall pgvector

# Remove data directory (if user confirms)
rm -rf $(brew --prefix)/var/postgresql@16

# Optional: Remove config files
rm -f ~/.pgpass
rm -f $(brew --prefix)/etc/postgresql@16/postgresql.conf
```

**Backup data first (if requested):**
```bash
# Backup all databases
pg_dumpall > postgresql_backup_$(date +%Y%m%d).sql
```

**Display:**
```
✅ PostgreSQL Removed

Uninstalled:
  - postgresql@16
  - pgvector
  - Data directory

Backup created (if requested):
  - postgresql_backup_YYYYMMDD.sql

Project config files kept:
  - config/database.yaml.backup
  - .env.backup

To reinstall:
  Use this skill with "init" operation
```

## pgvector Quick Reference

### Create Table with Vector Column
```sql
CREATE TABLE items (
  id BIGSERIAL PRIMARY KEY,
  embedding vector(1536)  -- dimension size
);
```

### Insert Vectors
```sql
INSERT INTO items (embedding) VALUES ('[1,2,3]'), ('[4,5,6]');
```

### Similarity Search
```sql
-- L2 distance
SELECT * FROM items ORDER BY embedding <-> '[3,1,2]' LIMIT 5;

-- Cosine distance
SELECT * FROM items ORDER BY embedding <=> '[3,1,2]' LIMIT 5;

-- Inner product (negative)
SELECT * FROM items ORDER BY embedding <#> '[3,1,2]' LIMIT 5;
```

### Create Index
```sql
-- HNSW index (recommended)
CREATE INDEX ON items USING hnsw (embedding vector_cosine_ops);

-- IVFFlat index (faster build)
CREATE INDEX ON items USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
```

## Troubleshooting

### PostgreSQL won't start
```bash
# Check logs
tail -f $(brew --prefix)/var/log/postgresql@16.log

# Remove lock file
rm -f $(brew --prefix)/var/postgresql@16/postmaster.pid

# Restart
brew services restart postgresql@16
```

### Can't connect
```bash
# Check service running
brew services list | grep postgresql

# Check socket
ls -la /tmp/.s.PGSQL.5432

# Start if not running
brew services start postgresql@16
```

### pgvector extension not found
```bash
# Reinstall pgvector
brew reinstall pgvector

# Restart PostgreSQL
brew services restart postgresql@16

# Enable extension
psql -d ${DB_NAME} -c "CREATE EXTENSION vector;"
```

### Port already in use
```bash
# Check what's using port 5432
lsof -i :5432

# Change port in postgresql.conf or kill the process
```

## Security Best Practices

1. **Strong passwords**: Use 16+ character random passwords
2. **Limit access**: Users from localhost only (unless remote needed)
3. **Protect files**: `chmod 600 .env ~/.pgpass`
4. **Don't commit secrets**: Add `.env` to `.gitignore`
5. **Regular backups**: `pg_dump -U user dbname > backup.sql`
6. **Update regularly**: `brew upgrade postgresql@16 pgvector`

## References

- [pgvector GitHub](https://github.com/pgvector/pgvector)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Homebrew PostgreSQL](https://formulae.brew.sh/formula/postgresql@16)
