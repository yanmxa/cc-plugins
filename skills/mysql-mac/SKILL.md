---
name: mysql-mac
description: Install, configure, and manage MySQL server on macOS using Homebrew. Use when user mentions installing MySQL on Mac, setting up MySQL database, creating MySQL user/database, securing MySQL, or managing MySQL service on macOS. Handles both interactive and automated setup.
allowed-tools: [Bash, Read, Write, Glob, AskUserQuestion]
---

# mysql-mac - MySQL Setup for macOS

Complete MySQL server installation, configuration, and management tool for macOS using Homebrew. Handles everything from fresh install to database/user creation with intelligent defaults.

## When to Use This Skill

- User wants to install MySQL on macOS
- User mentions "setup MySQL on Mac" or "install MySQL Homebrew"
- User needs to create a MySQL database and user
- User wants to secure MySQL installation
- User asks about MySQL configuration on macOS
- User needs to manage MySQL service (start/stop/restart)

## Core Capabilities

1. **Installation**
   - Install MySQL via Homebrew
   - Check existing installation
   - Handle reinstallation scenarios
   - Verify Homebrew availability

2. **Security Configuration**
   - Secure MySQL installation
   - Set root password
   - Remove anonymous users
   - Configure access restrictions
   - Generate secure passwords

3. **Database & User Setup**
   - Create database with proper charset
   - Create user with privileges
   - Configure connection settings
   - Generate configuration files

4. **Service Management**
   - Start/stop/restart MySQL service
   - Check service status
   - Auto-start on boot
   - Troubleshoot service issues

5. **Configuration Generation**
   - Create .env files
   - Generate database.yaml
   - Save connection strings
   - Document credentials securely

## Installation Modes

### Interactive Mode (Default)
- Prompts for all configuration
- User sets passwords manually
- Runs mysql_secure_installation
- Full control over settings

### Auto Mode (--auto)
- No user prompts
- Auto-generates secure passwords
- Uses sensible defaults
- Ideal for quick setup or scripting

## Instructions

### 1. Pre-Installation Checks

**Before starting:**

1. **Check Homebrew**:
   ```bash
   command -v brew || echo "Homebrew not installed"
   ```

   If not installed, guide user:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Check existing MySQL**:
   ```bash
   brew list mysql 2>/dev/null
   mysql --version 2>/dev/null
   ```

3. **Ask user about mode**:
   - Interactive: Full control, set passwords manually
   - Auto: Quick setup, auto-generated passwords

### 2. Install MySQL

**For fresh installation:**

1. **Install via Homebrew**:
   ```bash
   brew install mysql
   ```

2. **Start MySQL service**:
   ```bash
   brew services start mysql
   ```

3. **Wait for initialization** (5 seconds):
   ```bash
   sleep 5
   ```

4. **Verify service is running**:
   ```bash
   brew services list | grep mysql | grep started
   ```

**For existing installation:**

1. **Ask user**:
   - Reinstall? (Stop service, uninstall, reinstall)
   - Skip to configuration?
   - Update existing installation?

2. **If reinstalling**:
   ```bash
   brew services stop mysql
   brew uninstall mysql
   brew install mysql
   ```

### 3. Secure MySQL Installation

#### Interactive Mode:

1. **Run mysql_secure_installation**:
   ```bash
   mysql_secure_installation
   ```

2. **Guide user** with recommended answers:
   - Set root password: **YES** (strong password)
   - Remove anonymous users: **YES**
   - Disallow root login remotely: **YES**
   - Remove test database: **YES**
   - Reload privilege tables: **YES**

3. **Collect information**:
   - Root password (user-provided)
   - Database name (default: textsql_db)
   - Database user (default: textsql_user)
   - User password (user-provided)
   - Host (default: localhost)
   - Port (default: 3306)

#### Auto Mode:

1. **Generate secure passwords**:
   ```bash
   # 16-character random password
   ROOT_PASSWORD=$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 16)
   DB_PASSWORD=$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 16)
   ```

2. **Set root password** (fresh install):
   ```bash
   mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';" 2>/dev/null
   ```

3. **Use defaults**:
   - Database: `textsql_db`
   - User: `textsql_user`
   - Host: `localhost`
   - Port: `3306`

### 4. Create Database and User

**Execute SQL commands:**

```sql
-- Create database with UTF8MB4 charset
CREATE DATABASE IF NOT EXISTS ${DB_NAME}
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- Create user (only from localhost for security)
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost'
  IDENTIFIED BY '${DB_PASSWORD}';

-- Grant all privileges on the specific database
GRANT ALL PRIVILEGES ON ${DB_NAME}.*
  TO '${DB_USER}'@'localhost';

-- Apply changes
FLUSH PRIVILEGES;

-- Verify database exists
SHOW DATABASES;
```

**Run via bash:**
```bash
mysql -u root -p"${ROOT_PASSWORD}" <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SHOW DATABASES;
EOF
```

**Verify success:**
- Check exit code: `$? -eq 0`
- Test connection: `mysql -u ${DB_USER} -p"${DB_PASSWORD}" ${DB_NAME} -e "SELECT 1"`

### 5. Generate Configuration Files

#### Create database.yaml:

**Location**: `./config/database.yaml`

**Content**:
```yaml
# MySQL Database Configuration
# Auto-generated by Claude Code mysql-mac skill

database:
  type: mysql
  version: "8.0"
  host: ${DB_HOST}
  port: ${DB_PORT}
  user: ${DB_USER}
  password: ${DB_PASSWORD}
  database: ${DB_NAME}
  charset: utf8mb4

  # Connection pool settings (optional)
  pool_size: 5
  max_overflow: 10
  pool_timeout: 30
  pool_recycle: 3600
```

#### Create/Update .env:

**Location**: `./.env`

**Before creating:**
1. Check if .env exists
2. If exists, backup: `.env.backup.YYYYMMDD_HHMMSS`
3. Create new .env

**Content**:
```bash
# =============================================================================
# Database Configuration
# =============================================================================
# Auto-generated by Claude Code mysql-mac skill on $(date)

DATABASE_URI=mysql+pymysql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}
DATABASE_VERSION=MySQL 8.0

# Individual connection parameters
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=${DB_NAME}

# =============================================================================
# Add your application-specific settings below
# =============================================================================
```

#### Create my.cnf (optional):

**Location**: `~/.my.cnf` (for client convenience)

**Content**:
```ini
[client]
user=${DB_USER}
password=${DB_PASSWORD}
host=${DB_HOST}
port=${DB_PORT}
database=${DB_NAME}
```

**Set permissions**:
```bash
chmod 600 ~/.my.cnf
```

### 6. Post-Installation Summary

**Display to user:**

1. **Installation summary**:
   - Database Name
   - Database User
   - Host & Port
   - Service status

2. **Auto mode: Show credentials**:
   - ⚠️ Display generated passwords
   - Warn to save securely
   - Indicate where passwords are saved

3. **Configuration files created**:
   - config/database.yaml
   - .env
   - ~/.my.cnf (optional)

4. **Useful commands**:
   ```bash
   # Service management
   brew services start mysql
   brew services stop mysql
   brew services restart mysql
   brew services list | grep mysql

   # Connect to MySQL
   mysql -u ${DB_USER} -p ${DB_NAME}
   mysql -u root -p

   # Check MySQL status
   mysqladmin -u root -p status
   mysqladmin -u root -p variables
   ```

5. **Next steps**:
   - Test connection
   - Import schema/data
   - Configure application
   - Set up backups

## Common Scenarios

### Scenario 1: Fresh MySQL Installation

**User**: "Install MySQL on my Mac"

**Actions**:
1. Check Homebrew installed
2. Install MySQL: `brew install mysql`
3. Start service: `brew services start mysql`
4. Ask: Interactive or auto mode?
5. If interactive: Run mysql_secure_installation
6. If auto: Generate passwords, secure automatically
7. Create database and user
8. Generate config files
9. Display summary with credentials

### Scenario 2: Create New Database on Existing MySQL

**User**: "Create a new MySQL database called myapp"

**Actions**:
1. Check MySQL is running
2. Ask for root password (or detect from config)
3. Ask for new user details
4. Create database and user
5. Update .env with new database info
6. Test connection
7. Display connection string

### Scenario 3: Reset MySQL Installation

**User**: "Reinstall MySQL, I forgot the root password"

**Actions**:
1. Stop MySQL: `brew services stop mysql`
2. Uninstall: `brew uninstall mysql`
3. Remove data directory (ask user):
   ```bash
   rm -rf /usr/local/var/mysql
   # or for Apple Silicon
   rm -rf /opt/homebrew/var/mysql
   ```
4. Fresh install
5. Secure installation
6. Create database and user
7. Generate new configs

### Scenario 4: Automated Setup for CI/CD

**User**: "Set up MySQL automatically for testing"

**Actions**:
1. Run in auto mode
2. Use test database name
3. Generate secure passwords
4. Save credentials to CI environment
5. Create minimal config
6. Verify connection
7. Return connection string

### Scenario 5: Multiple Databases

**User**: "Create databases for dev, staging, and production"

**Actions**:
1. Check MySQL running
2. For each environment:
   - Create database: `${app}_dev`, `${app}_staging`, `${app}_prod`
   - Create user with privileges
   - Generate separate .env files
3. Create .env.dev, .env.staging, .env.prod
4. Document which to use when

## Service Management

### Start MySQL:
```bash
brew services start mysql

# Verify started
brew services list | grep mysql
# Should show: started
```

### Stop MySQL:
```bash
brew services stop mysql
```

### Restart MySQL:
```bash
brew services restart mysql
```

### Check Status:
```bash
# Service status
brew services list | grep mysql

# MySQL process
ps aux | grep mysql

# MySQL port
lsof -i :3306
```

### Auto-start on boot:
```bash
# Enable (default with brew services start)
brew services start mysql

# Disable auto-start but keep running
brew services run mysql
```

## Troubleshooting

### MySQL Won't Start

**Check logs**:
```bash
# Homebrew logs
tail -f /usr/local/var/mysql/$(hostname).err
# or for Apple Silicon
tail -f /opt/homebrew/var/mysql/$(hostname).err
```

**Common fixes**:
1. Remove lock files:
   ```bash
   rm -f /usr/local/var/mysql/*.pid
   rm -f /tmp/mysql.sock*
   ```

2. Check permissions:
   ```bash
   sudo chown -R $(whoami) /usr/local/var/mysql
   # or for Apple Silicon
   sudo chown -R $(whoami) /opt/homebrew/var/mysql
   ```

3. Reinstall:
   ```bash
   brew services stop mysql
   brew uninstall mysql
   brew install mysql
   brew services start mysql
   ```

### Can't Connect to MySQL

**Error**: `ERROR 2002 (HY000): Can't connect to local MySQL server through socket`

**Fix**:
1. Check MySQL is running:
   ```bash
   brew services list | grep mysql
   ```

2. If not running, start:
   ```bash
   brew services start mysql
   sleep 5
   ```

3. Check socket file exists:
   ```bash
   ls -la /tmp/mysql.sock
   ```

### Access Denied

**Error**: `ERROR 1045 (28000): Access denied for user 'user'@'localhost'`

**Fix**:
1. Verify username/password
2. Reset user password:
   ```bash
   mysql -u root -p
   ALTER USER 'username'@'localhost' IDENTIFIED BY 'new_password';
   FLUSH PRIVILEGES;
   ```

3. If root password forgotten:
   - Stop MySQL
   - Start in safe mode
   - Reset password
   - Restart normally

### Port Already in Use

**Error**: Port 3306 already in use

**Fix**:
1. Check what's using port:
   ```bash
   lsof -i :3306
   ```

2. Kill process or change MySQL port:
   ```bash
   # Edit config
   nano /usr/local/etc/my.cnf
   # Add: port = 3307

   # Restart
   brew services restart mysql
   ```

### Homebrew Not Found

**Error**: `brew: command not found`

**Fix**:
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# For Apple Silicon, add to PATH
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

## Security Best Practices

1. **Strong Passwords**:
   - Minimum 16 characters
   - Mix of letters, numbers, symbols
   - Use password generator

2. **Limit Access**:
   - Users only from localhost (unless remote needed)
   - Specific database privileges only
   - No GRANT ALL unless necessary

3. **Remove Defaults**:
   - Delete test database
   - Remove anonymous users
   - Disable remote root login

4. **Secure Files**:
   - Protect .env: `chmod 600 .env`
   - Protect my.cnf: `chmod 600 ~/.my.cnf`
   - Don't commit passwords to git

5. **Regular Updates**:
   ```bash
   brew update
   brew upgrade mysql
   ```

6. **Backup Regularly**:
   ```bash
   mysqldump -u root -p ${DB_NAME} > backup_$(date +%Y%m%d).sql
   ```

## Advanced Configuration

### Custom my.cnf

**Location**: `/usr/local/etc/my.cnf` (Intel) or `/opt/homebrew/etc/my.cnf` (Apple Silicon)

**Example**:
```ini
[mysqld]
port = 3306
bind-address = 127.0.0.1
max_connections = 200
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# Performance
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M

# Logging
log_error = /usr/local/var/mysql/error.log
slow_query_log = 1
slow_query_log_file = /usr/local/var/mysql/slow.log
long_query_time = 2

[client]
port = 3306
default-character-set = utf8mb4
```

**Apply changes**:
```bash
brew services restart mysql
```

### Enable Remote Access

**Warning**: Only enable if needed, security risk!

1. **Edit my.cnf**:
   ```ini
   [mysqld]
   bind-address = 0.0.0.0
   ```

2. **Create remote user**:
   ```sql
   CREATE USER 'user'@'%' IDENTIFIED BY 'password';
   GRANT ALL PRIVILEGES ON database.* TO 'user'@'%';
   FLUSH PRIVILEGES;
   ```

3. **Firewall** (if needed):
   ```bash
   # macOS firewall allows by default
   # Check: System Settings > Network > Firewall
   ```

### SSL/TLS Configuration

**Generate certificates**:
```bash
mysql_ssl_rsa_setup --datadir=/usr/local/var/mysql
```

**Configure my.cnf**:
```ini
[mysqld]
require_secure_transport = ON
ssl-ca = /path/to/ca.pem
ssl-cert = /path/to/server-cert.pem
ssl-key = /path/to/server-key.pem
```

## Integration Examples

### Python (pymysql/SQLAlchemy):
```python
from sqlalchemy import create_engine

# From .env
DATABASE_URI = "mysql+pymysql://user:pass@localhost:3306/dbname"
engine = create_engine(DATABASE_URI)
```

### Node.js (mysql2):
```javascript
const mysql = require('mysql2');
const connection = mysql.createConnection({
  host: 'localhost',
  user: 'user',
  password: 'password',
  database: 'dbname'
});
```

### Go (go-sql-driver):
```go
import "database/sql"
import _ "github.com/go-sql-driver/mysql"

db, err := sql.Open("mysql", "user:password@tcp(localhost:3306)/dbname")
```

## Output Format

**Success output**:
```
==========================================
MySQL Server Setup for macOS
==========================================

✓ Homebrew is installed
✓ MySQL installed successfully
✓ MySQL service is running
✓ MySQL secured in AUTO mode
✓ Database and user created successfully
✓ Created config/database.yaml
✓ Created .env with database configuration

==========================================
Installation Complete!
==========================================

MySQL Server Setup Summary:
  Database Name: myapp_db
  Database User: myapp_user
  Host: localhost
  Port: 3306

Auto-generated Credentials (SAVE THESE!):
  MySQL Root Password: Xy9#mK2$pL4@nQ8v
  Database User Password: Bw7!tR5&hN3%jM9c

⚠ IMPORTANT: Save these credentials in a secure location!

Configuration Files:
  Database config: config/database.yaml
  Environment: .env

Useful Commands:
  Start MySQL:   brew services start mysql
  Stop MySQL:    brew services stop mysql
  Restart MySQL: brew services restart mysql
  MySQL CLI:     mysql -u myapp_user -p myapp_db
  Check status:  brew services list | grep mysql

Next Steps:
  1. Test the connection
  2. Import your database schema/data
  3. Configure your application to use the database

Setup complete! Happy developing! 🚀
```

## Usage with Claude Code

**Natural commands that trigger this skill:**

- "Install MySQL on my Mac"
- "Set up MySQL database on macOS"
- "Create a new MySQL database called myapp"
- "Help me configure MySQL on Mac"
- "Reset my MySQL installation"
- "Generate MySQL config files"
- "Secure my MySQL installation"

Claude will handle all the details automatically!
