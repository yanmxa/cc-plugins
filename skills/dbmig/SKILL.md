---
name: dbmig
description: Database backup, restore, and migration tool for MySQL and PostgreSQL. Use when user mentions database backup, restore, migration, mysqldump, pg_dump, database transfer, or cross-database migration. Supports compression, auto-naming, and intelligent connection detection.
allowed-tools: [Bash, Read, Write, Glob, Grep, AskUserQuestion]
---

# dbmig - Database Migration Skill

Intelligent database backup, restore, and migration assistant for MySQL and PostgreSQL. Handles common database operations with smart defaults while allowing full customization.

## When to Use This Skill

- User mentions backing up or restoring a database
- User wants to migrate data between MySQL and PostgreSQL
- User asks about database dump, export, or import
- User mentions mysqldump, pg_dump, or database migration tools
- User needs to manage database backups (list, clean, compress)
- User wants to transfer data between database servers

## Core Capabilities

1. **Backup Operations**
   - Auto-generate timestamped backup filenames
   - Support compression (gzip) to save ~70% space
   - Show database size and table information
   - Support both MySQL and PostgreSQL

2. **Restore Operations**
   - Auto-detect compressed files (.gz)
   - Confirm before overwriting data
   - Create database if not exists
   - Handle both SQL and compressed SQL files

3. **Connection Management**
   - Auto-detect from project `.env` files
   - Support standard DATABASE_URL/URI formats
   - Support individual env vars (HOST, PORT, USER, PASSWORD)
   - Allow manual specification

4. **Backup Management**
   - List all backups with size and date
   - Clean old backups (keep N most recent)
   - Remove specific backup files
   - Show disk space usage

## Database Connection Detection

**Priority Order:**

1. **Explicit DATABASE_URI** environment variable
2. **Project .env file** (look for DATABASE_URL, MYSQL_URL, POSTGRES_URL, etc.)
3. **db_config.env** in current directory
4. **Individual env vars** (DB_HOST, DB_USER, DB_PASSWORD, etc.)
5. **Ask user** if none found

**URI Formats:**
- MySQL: `mysql://user:password@host:port/database`
- PostgreSQL: `postgresql://user:password@host:port/database` or `postgres://...`

**Individual Env Vars:**
- MySQL: `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, `MYSQL_PASSWORD`
- PostgreSQL: `PG_HOST`, `PG_PORT`, `PG_USER`, `PG_PASSWORD`, `PG_DATABASE`

## Instructions

### 1. Detect Database Configuration

When user requests a database operation:

1. **Search for configuration files**:
   - Check for `.env` files in current directory
   - Look for `db_config.env`
   - Search for common patterns: `DATABASE_URL`, `MYSQL_URL`, `POSTGRES_URL`

2. **Parse connection info**:
   - Extract from URI format if found
   - Fall back to individual env vars
   - If none found, ask user for connection details

3. **Validate connection**:
   - For MySQL: test with `mysql -h HOST -u USER -pPASSWORD -e "SELECT 1"`
   - For PostgreSQL: test with `psql -h HOST -U USER -d postgres -c "SELECT 1"`

### 2. Backup Database

**Steps:**

1. **Determine backup filename**:
   - If user specifies: use that filename
   - If not: generate `backup_{dbname}_{timestamp}.sql[.gz]`
   - Default directory: `./backups/` (create if not exists)

2. **Check compression**:
   - If user says "compress" or filename ends with `.gz`: enable compression
   - Default: no compression (for faster operations)

3. **Show database info before backup**:
   - List tables with sizes
   - Show total database size
   - Confirm with user if database is large (>1GB)

4. **Execute backup**:
   ```bash
   # MySQL (uncompressed)
   mysqldump -h HOST -P PORT -u USER -pPASSWORD \
     --single-transaction --routines --triggers --events \
     DATABASE > backup.sql

   # MySQL (compressed)
   mysqldump -h HOST -P PORT -u USER -pPASSWORD \
     --single-transaction --routines --triggers --events \
     DATABASE | gzip > backup.sql.gz

   # PostgreSQL (uncompressed)
   pg_dump -h HOST -p PORT -U USER -d DATABASE \
     --clean --if-exists > backup.sql

   # PostgreSQL (compressed)
   pg_dump -h HOST -p PORT -U USER -d DATABASE \
     --clean --if-exists | gzip > backup.sql.gz
   ```

5. **Report results**:
   - Show backup file size
   - Show compression ratio if applicable
   - Provide full path to backup file
   - Suggest next steps (e.g., "restore with: dbmig restore ...")

### 3. Restore Database

**Steps:**

1. **Verify backup file exists**:
   - Check file path is valid
   - Auto-detect if compressed (.gz extension)
   - Show file size and modification date

2. **Warn user**:
   - Display: "This will OVERWRITE all data in database 'dbname'"
   - Require explicit confirmation (yes/no)
   - If user says no, cancel operation

3. **Create database if needed**:
   - MySQL: `CREATE DATABASE IF NOT EXISTS dbname`
   - PostgreSQL: `createdb dbname` (ignore error if exists)

4. **Execute restore**:
   ```bash
   # MySQL (uncompressed)
   mysql -h HOST -P PORT -u USER -pPASSWORD DATABASE < backup.sql

   # MySQL (compressed)
   gunzip < backup.sql.gz | mysql -h HOST -P PORT -u USER -pPASSWORD DATABASE

   # PostgreSQL (uncompressed)
   psql -h HOST -p PORT -U USER -d DATABASE < backup.sql

   # PostgreSQL (compressed)
   gunzip < backup.sql.gz | psql -h HOST -p PORT -U USER -d DATABASE
   ```

5. **Verify restore**:
   - Count tables after restore
   - Show database size
   - Report success or failure

### 4. List Backups

**Steps:**

1. **Find backup directory**:
   - Check `./backups/` first
   - Look for `BACKUP_DIR` env var
   - Ask user if not found

2. **List all `.sql` and `.sql.gz` files**:
   - Sort by modification time (newest first)
   - Show: filename, size, date
   - Group by database name if possible

3. **Show summary**:
   - Total number of backups
   - Total disk space used
   - Compressed vs uncompressed count

### 5. Clean Old Backups

**Steps:**

1. **Ask user how to clean**:
   - "Keep N most recent backups"
   - "Delete all backups"
   - "Interactive selection"

2. **For "keep N" mode**:
   - Sort backups by date
   - Keep N newest, delete rest
   - Show what will be deleted before confirming

3. **For "delete all" mode**:
   - List all backups
   - Require explicit "yes" confirmation
   - Delete all files

4. **For "interactive" mode**:
   - Show numbered list of backups
   - Ask user to select which to delete
   - Confirm before deletion

## Smart Defaults

- **Backup directory**: `./backups/` (create automatically)
- **Filename format**: `backup_{dbname}_{YYYYMMDD_HHMMSS}.sql[.gz]`
- **Compression**: Off by default (faster), enable with `--compress` or `.gz` filename
- **Connection timeout**: 30 seconds
- **MySQL options**: `--single-transaction --routines --triggers --events`
- **PostgreSQL options**: `--clean --if-exists`

## Environment Variable Examples

**Minimal MySQL setup (db_config.env):**
```bash
MYSQL_HOST=127.0.0.1
MYSQL_USER=root
MYSQL_PASSWORD=your_password
```

**Minimal PostgreSQL setup:**
```bash
PG_HOST=127.0.0.1
PG_USER=postgres
PG_PASSWORD=your_password
```

**URI format (.env):**
```bash
# MySQL
DATABASE_URL=mysql://root:password@localhost:3306/mydb

# PostgreSQL
DATABASE_URL=postgresql://postgres:password@localhost:5432/mydb
```

## Safety Features

1. **Confirmation for destructive operations**:
   - Always confirm before restore
   - Confirm before deleting backups
   - Warn if overwriting existing backup

2. **Validation checks**:
   - Test database connection before operations
   - Verify backup file exists before restore
   - Check disk space before large backups

3. **Error handling**:
   - Clear error messages for connection failures
   - Suggest fixes for common issues
   - Never expose passwords in output

## Common Scenarios

### Scenario 1: Quick Backup

**User**: "Backup my production database"

**Actions**:
1. Detect database connection from .env
2. Generate filename: `backup_production_20251129_143022.sql`
3. Show database size
4. Execute backup
5. Report: "Backup completed: 245 MB saved to backups/backup_production_20251129_143022.sql"

### Scenario 2: Compressed Backup

**User**: "Backup mydb with compression"

**Actions**:
1. Enable compression
2. Generate filename with `.gz` extension
3. Execute: `mysqldump ... | gzip > backup.sql.gz`
4. Report compression ratio: "Original 700 MB → Compressed 210 MB (70% saved)"

### Scenario 3: Restore from Backup

**User**: "Restore database from backups/backup_mydb_20251129.sql.gz"

**Actions**:
1. Verify file exists
2. Detect it's compressed
3. Warn: "This will OVERWRITE all data in 'mydb'. Continue? (yes/no)"
4. Wait for user confirmation
5. Execute: `gunzip < backup.sql.gz | mysql ...`
6. Report success

### Scenario 4: Clean Old Backups

**User**: "Clean old backups, keep only the 5 most recent"

**Actions**:
1. Find all backups in ./backups/
2. Sort by date
3. Show: "Found 12 backups, will delete 7 oldest"
4. List files to delete
5. Confirm with user
6. Delete and report: "Deleted 7 backups, freed 1.2 GB"

## Best Practices

1. **Always test connection first**: Before any operation, verify database is accessible
2. **Use compression for large databases**: Saves ~70% disk space and transfer time
3. **Keep multiple backup versions**: Recommend keeping 3-7 recent backups
4. **Verify restores on non-production first**: Test backup integrity before production restore
5. **Never log passwords**: Mask credentials in all output
6. **Auto-create backup directory**: Don't fail if directory doesn't exist
7. **Use consistent naming**: Timestamp format ensures chronological sorting

## Error Handling

**Connection failed**:
- Check if database server is running
- Verify credentials in configuration
- Test with: `mysql -h HOST -u USER -pPASSWORD -e "SELECT 1"`

**Permission denied**:
- Check user has necessary privileges
- MySQL: needs `SELECT, LOCK TABLES` for backup
- PostgreSQL: needs `SELECT` on all tables

**Disk space full**:
- Check available space: `df -h`
- Suggest compression: "Try --compress to reduce size by ~70%"
- Suggest cleaning old backups

**Invalid backup file**:
- Verify file is not corrupted: `gunzip -t backup.sql.gz`
- Check file size is reasonable
- Suggest re-creating backup from source

## Cross-Database Migration Notes

**MySQL → PostgreSQL**:
- Auto-increment: `AUTO_INCREMENT` → `SERIAL`
- Quotes: Backticks `` `table` `` → Double quotes `"table"`
- Data types: `TINYINT` → `SMALLINT`, `DATETIME` → `TIMESTAMP`
- Engine: Remove `ENGINE=InnoDB`

**PostgreSQL → MySQL**:
- Sequences: Need to create auto-increment columns
- Case sensitivity: PostgreSQL is case-sensitive, MySQL often isn't
- Data types: `SERIAL` → `AUTO_INCREMENT`

**Note**: For complex migrations, suggest using specialized tools or manual SQL conversion.

## Output Format

**Success output**:
```
✓ Backing up database: production_db
✓ Host: 127.0.0.1:3306
✓ Output: backups/backup_production_db_20251129_143022.sql.gz
✓ Compression: enabled (gzip)

✓ Database table sizes:
  users          45.2 MB    120,450 rows
  transactions   189.3 MB   450,230 rows
  logs           12.8 MB    89,120 rows

✓ Starting backup...

✓ Backup completed successfully!
✓ Snapshot size: 73 MB (compressed from ~247 MB)
✓ Space saved: 174 MB (~70% compression)
✓ Full path: /path/to/backups/backup_production_db_20251129_143022.sql.gz

Next steps:
  • Test restore: dbmig restore test_db backups/backup_production_db_20251129_143022.sql.gz
  • List backups: dbmig list
  • Clean old backups: dbmig clean --keep 5
```

**Error output**:
```
✗ Failed to connect to database
✗ Error: Access denied for user 'root'@'localhost'

Troubleshooting:
  1. Verify credentials in db_config.env
  2. Test connection: mysql -h 127.0.0.1 -u root -p
  3. Check user permissions: GRANT SELECT, LOCK TABLES ON *.* TO 'user'@'host';
```

## Usage with Claude Code

**Natural language commands that trigger this skill:**

- "Backup my database"
- "Create a database dump"
- "Restore from backup file X"
- "List all database backups"
- "Clean old database backups"
- "Migrate MySQL to PostgreSQL"
- "Export production database"
- "Import database from dump"

Claude will automatically invoke this skill and handle all the details!
