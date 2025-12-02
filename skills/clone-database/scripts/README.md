# db-sync Scripts

Helper scripts for efficient database synchronization.

## Quick Start

### Using DATABASE_URL Format

```bash
# Sync from EC2 to local
./db-sync.sh \
  --remote-ssh user@aws-start-ec2 \
  --remote-url "mysql+pymysql://root:testpass123@127.0.0.1:3306/<databasename>" \
  --local-url "mysql://root:localpass@localhost:3306/<databasename>"

# Auto-create local database if not exists
./db-sync.sh \
  --remote-ssh user@aws-start-ec2 \
  --remote-url "mysql://root:testpass123@127.0.0.1:3306/<databasename>" \
  --auto-create-local
```

### Using Saved Profiles

**1. Create profile** (`sync_profiles.env`):
```bash
REMOTE_SSH_HOST=user@aws-start-ec2
REMOTE_DB_HOST=127.0.0.1
REMOTE_DB_PORT=3306
REMOTE_DB_USER=root
REMOTE_DB_PASSWORD=testpass123
REMOTE_DB_NAME=<databasename>
REMOTE_DB_TYPE=mysql

LOCAL_DB_HOST=localhost
LOCAL_DB_PORT=3306
LOCAL_DB_USER=root
LOCAL_DB_PASSWORD=localpass
LOCAL_DB_NAME=<databasename>
LOCAL_DB_TYPE=mysql
```

**2. Use profile**:
```bash
./db-sync.sh --profile ec2_prod
```

## Script Options

### Required Arguments
- `--remote-ssh HOST` - SSH host (user@host or alias from ~/.ssh/config)
- `--remote-url URL` - Remote database URL

### Optional Arguments
- `--local-url URL` - Local database URL (prompts if not provided)
- `--auto-create-local` - Auto-create local database if not exists
- `--backup-local` - Backup local database before overwriting
- `--no-compression` - Disable gzip compression
- `--keep-remote` - Keep remote backup file after sync
- `--profile NAME` - Use saved profile

## Supported DATABASE_URL Formats

### MySQL
```bash
mysql://user:password@host:port/database
mysql+pymysql://user:password@host:port/database
```

### PostgreSQL
```bash
postgresql://user:password@host:port/database
postgres://user:password@host:port/database
```

## Examples

### Example 1: Simple Sync

```bash
./db-sync.sh \
  --remote-ssh user@ec2 \
  --remote-url "mysql://root:pass@127.0.0.1:3306/mydb" \
  --local-url "mysql://root:localpass@localhost:3306/mydb"
```

### Example 2: Create Local Database

```bash
./db-sync.sh \
  --remote-ssh prod-server \
  --remote-url "mysql://root:pass@127.0.0.1:3306/<databasename>" \
  --auto-create-local
```

**Will prompt for:**
- Local database name (default: same as remote)
- Local user (default: root)
- Local password

### Example 3: Backup Local Before Overwrite

```bash
./db-sync.sh \
  --remote-ssh staging \
  --remote-url "mysql://deploy:pass@localhost:3306/app_db" \
  --local-url "mysql://root:localpass@localhost:3306/app_db" \
  --backup-local
```

**Creates:**
- `backups/local_backup_app_db_YYYYMMDD_HHMMSS.sql.gz`

### Example 4: PostgreSQL Sync

```bash
./db-sync.sh \
  --remote-ssh pg-server \
  --remote-url "postgresql://postgres:pass@localhost:5432/analytics" \
  --local-url "postgresql://postgres:localpass@localhost:5432/analytics" \
  --auto-create-local
```

### Example 5: Using SSH Config Alias

**~/.ssh/config:**
```
Host prod
    HostName ec2-xxx.amazonaws.com
    User deploy
    IdentityFile ~/.ssh/prod_key
```

**Command:**
```bash
./db-sync.sh \
  --remote-ssh prod \
  --remote-url "mysql://root:pass@127.0.0.1:3306/mydb" \
  --auto-create-local
```

## Workflow

The script executes these steps:

1. **Parse URLs** - Extract DB credentials from DATABASE_URLs
2. **Verify** - Check SSH connection and databases
3. **Backup Remote** - Create compressed backup on remote server
4. **Download** - Transfer backup to local machine (with progress)
5. **Prepare Local** - Create or drop/recreate local database
6. **Restore** - Import backup to local database
7. **Verify** - Count tables to confirm sync
8. **Cleanup** - Remove temporary files
9. **Output** - Display DATABASE_URL for local database

## Output

```
==========================================
Database Sync Plan
==========================================

Source (Remote):
  SSH Host: user@aws-start-ec2
  Database: <databasename> (mysql)
  Host: 127.0.0.1:3306
  User: root

Destination (Local):
  Database: <databasename> (mysql)
  Host: localhost:3306
  User: root

Options:
  Compression: true
  Backup local: false
  Auto-create local: true
  Cleanup remote: true

Continue? (yes/no): yes

[1/5] Backing up remote database...
✓ Remote backup created: backup_<databasename>_20251129_143022.sql.gz (345M)

[2/5] Downloading backup...
✓ Downloaded to: backups/backup_<databasename>_20251129_143022.sql.gz (345M)

[3/5] Preparing local database...
✓ Created database: <databasename>

[4/5] Restoring to local database...
✓ Restore completed successfully

[5/5] Verifying sync and cleanup...
✓ Synced 45 tables
✓ Removed remote backup file

==========================================
Sync Complete! ✓
==========================================

Database: <databasename>
Tables: 45
Backup: backups/backup_<databasename>_20251129_143022.sql.gz

DATABASE_URL:
mysql+pymysql://root:localpass@localhost:3306/<databasename>

Connect:
mysql -h localhost -P 3306 -u root -p <databasename>
```

## Troubleshooting

### SSH Connection Failed
```bash
# Test SSH connection
ssh user@host "echo test"

# Check SSH config
cat ~/.ssh/config
```

### Remote MySQL Not Accessible
```bash
# Test from remote
ssh user@host "mysql -u root -p'pass' -e 'SELECT 1'"

# Check MySQL is running
ssh user@host "systemctl status mysql"
```

### Local MySQL Not Running
```bash
# Start MySQL
brew services start mysql

# Check status
brew services list | grep mysql
```

### Permission Denied
```bash
# Verify local MySQL credentials
mysql -u root -p -e "SELECT 1"

# Reset password if needed
mysql -u root
ALTER USER 'root'@'localhost' IDENTIFIED BY 'newpassword';
```

## Tips

1. **Use SSH Config** - Define hosts in `~/.ssh/config` for easier access
2. **Save Profiles** - Create `sync_profiles.env` for frequently synced databases
3. **Compression** - Always enabled by default, saves ~70% bandwidth
4. **Backup Local** - Use `--backup-local` when syncing to existing production databases
5. **Test First** - Try with `--auto-create-local` to create a new local database first

## Integration with Claude Code

When using with Claude Code, just say:

**"Sync mysql+pymysql://root:testpass123@127.0.0.1:3306/<databasename> from aws-start-ec2 to local"**

Claude will automatically use this script with the db-sync skill!
