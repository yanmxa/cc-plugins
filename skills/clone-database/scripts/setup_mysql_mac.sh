#!/bin/bash

# MySQL Server Setup Script for macOS
# This script helps you install and configure MySQL on your Mac
#
# Usage:
#   Interactive mode:  ./setup_mysql_mac.sh
#   Non-interactive:   ./setup_mysql_mac.sh --auto
#
# Non-interactive mode uses defaults:
#   - Database: textsql_db
#   - User: textsql_user
#   - Password: auto-generated (16 chars)
#   - Root password: auto-generated (16 chars)

set -e  # Exit on error

echo "=========================================="
echo "MySQL Server Setup for macOS"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check for --auto flag
AUTO_MODE=false
if [[ "$1" == "--auto" ]]; then
    AUTO_MODE=true
    echo -e "${YELLOW}Running in AUTO mode (non-interactive)${NC}"
    echo ""
fi

# Function to generate random password
generate_password() {
    LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 16
}

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${RED}Error: Homebrew is not installed.${NC}"
    echo "Please install Homebrew first by running:"
    echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
fi

echo -e "${GREEN}✓ Homebrew is installed${NC}"
echo ""

# Check if MySQL is already installed
if brew list mysql &> /dev/null; then
    echo -e "${YELLOW}MySQL is already installed via Homebrew${NC}"
    if [ "$AUTO_MODE" = true ]; then
        echo "AUTO mode: Skipping installation, proceeding to configuration..."
        SKIP_INSTALL=true
    else
        read -p "Do you want to reinstall? (y/N): " reinstall
        if [[ $reinstall =~ ^[Yy]$ ]]; then
            echo "Stopping MySQL service..."
            brew services stop mysql || true
            echo "Uninstalling MySQL..."
            brew uninstall mysql
        else
            echo "Skipping installation. Proceeding to configuration..."
            SKIP_INSTALL=true
        fi
    fi
fi

# Install MySQL
if [ -z "$SKIP_INSTALL" ]; then
    echo ""
    echo "Installing MySQL via Homebrew..."
    brew install mysql
    echo -e "${GREEN}✓ MySQL installed successfully${NC}"
fi

echo ""
echo "=========================================="
echo "Starting MySQL Server"
echo "=========================================="

# Start MySQL service
echo "Starting MySQL service..."
brew services start mysql

# Wait for MySQL to start
echo "Waiting for MySQL to initialize..."
sleep 5

# Check if MySQL is running
if brew services list | grep mysql | grep started &> /dev/null; then
    echo -e "${GREEN}✓ MySQL service is running${NC}"
else
    echo -e "${RED}Error: MySQL service failed to start${NC}"
    echo "Please check the logs with: brew services list"
    exit 1
fi

echo ""
echo "=========================================="
echo "Securing MySQL Installation"
echo "=========================================="
echo ""

# Set default values
DB_NAME="textsql_db"
DB_USER="textsql_user"
DB_HOST="localhost"
DB_PORT="3306"

if [ "$AUTO_MODE" = true ]; then
    # Auto mode: generate passwords and skip mysql_secure_installation
    echo -e "${YELLOW}AUTO mode: Generating secure passwords...${NC}"
    ROOT_PASSWORD=$(generate_password)
    DB_PASSWORD=$(generate_password)

    # Try to set root password if it's not set (fresh install)
    echo "Attempting to secure MySQL automatically..."

    # For fresh MySQL install, root has no password
    mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';" 2>/dev/null || {
        echo -e "${YELLOW}Root password already set or unable to set. Will try to use existing connection.${NC}"
        echo -e "${YELLOW}If this fails, please run the script in interactive mode without --auto flag.${NC}"
        # Try to use the connection that's already working
        ROOT_PASSWORD=""
    }

    echo -e "${GREEN}✓ MySQL secured in AUTO mode${NC}"
else
    # Interactive mode
    echo -e "${YELLOW}IMPORTANT: You will be prompted to set a root password and configure security options.${NC}"
    echo "Recommended answers:"
    echo "  - Set root password: YES (choose a strong password)"
    echo "  - Remove anonymous users: YES"
    echo "  - Disallow root login remotely: YES (for security)"
    echo "  - Remove test database: YES"
    echo "  - Reload privilege tables: YES"
    echo ""
    read -p "Press Enter to continue with mysql_secure_installation..."

    mysql_secure_installation

    # Prompt for root password
    read -sp "Enter MySQL root password: " ROOT_PASSWORD
    echo ""

    # Prompt for database details
    read -p "Enter database name (default: textsql_db): " DB_NAME
    DB_NAME=${DB_NAME:-textsql_db}

    read -p "Enter database user (default: textsql_user): " DB_USER
    DB_USER=${DB_USER:-textsql_user}

    read -sp "Enter password for $DB_USER: " DB_PASSWORD
    echo ""

    read -p "Enter database host (default: localhost): " DB_HOST
    DB_HOST=${DB_HOST:-localhost}

    read -p "Enter database port (default: 3306): " DB_PORT
    DB_PORT=${DB_PORT:-3306}
fi

echo ""
echo "=========================================="
echo "Creating Database and User"
echo "=========================================="
echo ""

# Create database and user
echo ""
echo "Creating database and user..."

# Prepare MySQL command based on whether ROOT_PASSWORD is set
if [ -z "$ROOT_PASSWORD" ]; then
    MYSQL_CMD="mysql -u root"
else
    MYSQL_CMD="mysql -u root -p${ROOT_PASSWORD}"
fi

$MYSQL_CMD <<EOF
-- Create database
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create user
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';

-- Grant privileges
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';

-- Flush privileges
FLUSH PRIVILEGES;

-- Show databases
SHOW DATABASES;
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database and user created successfully${NC}"
else
    echo -e "${RED}Error: Failed to create database and user${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo -e "${GREEN}MySQL Server Setup Summary:${NC}"
echo "  Database Name: ${DB_NAME}"
echo "  Database User: ${DB_USER}"
echo "  Host: ${DB_HOST}"
echo "  Port: ${DB_PORT}"

# Show passwords only in AUTO mode
if [ "$AUTO_MODE" = true ]; then
    echo ""
    echo -e "${YELLOW}Auto-generated Credentials (SAVE THESE!):${NC}"
    if [ -n "$ROOT_PASSWORD" ]; then
        echo "  MySQL Root Password: ${ROOT_PASSWORD}"
    fi
    echo "  Database User Password: ${DB_PASSWORD}"
    echo ""
    echo -e "${RED}⚠ IMPORTANT: Save these credentials in a secure location!${NC}"
fi

echo ""
echo -e "${GREEN}Useful Commands:${NC}"
echo "  Start MySQL:   brew services start mysql"
echo "  Stop MySQL:    brew services stop mysql"
echo "  Restart MySQL: brew services restart mysql"
echo "  MySQL CLI:     mysql -u ${DB_USER} -p ${DB_NAME}"
echo "  Check status:  brew services list | grep mysql"
echo ""
echo -e "${GREEN}Setup complete! 🚀${NC}"
echo ""

# Export credentials for use by calling script
export MYSQL_ROOT_PASSWORD="$ROOT_PASSWORD"
export MYSQL_DB_NAME="$DB_NAME"
export MYSQL_DB_USER="$DB_USER"
export MYSQL_DB_PASSWORD="$DB_PASSWORD"
export MYSQL_DB_HOST="$DB_HOST"
export MYSQL_DB_PORT="$DB_PORT"
