#!/bin/bash

# MySQL Server Setup Script for macOS (for db-sync)
# Simplified version for db-sync skill
#
# Usage:
#   Auto mode:  ./setup-mysql-mac.sh --auto
#   Interactive: ./setup-mysql-mac.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }

# Check for --auto flag
AUTO_MODE=false
if [[ "$1" == "--auto" ]]; then
    AUTO_MODE=true
    warn "Running in AUTO mode (non-interactive)"
fi

# Generate random password
generate_password() {
    LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 16
}

echo "=========================================="
echo "MySQL Server Setup for macOS"
echo "=========================================="
echo ""

# Check Homebrew
if ! command -v brew &> /dev/null; then
    error "Homebrew not installed. Install with: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
fi

info "Homebrew is installed"

# Check if MySQL already installed
if brew list mysql &> /dev/null; then
    warn "MySQL is already installed"
    if [ "$AUTO_MODE" = true ]; then
        info "AUTO mode: Skipping installation"
        SKIP_INSTALL=true
    else
        read -p "Reinstall? (y/N): " reinstall
        if [[ $reinstall =~ ^[Yy]$ ]]; then
            brew services stop mysql || true
            brew uninstall mysql
        else
            SKIP_INSTALL=true
        fi
    fi
fi

# Install MySQL
if [ -z "$SKIP_INSTALL" ]; then
    echo ""
    info "Installing MySQL via Homebrew..."
    brew install mysql
    info "MySQL installed successfully"
fi

# Start MySQL
echo ""
info "Starting MySQL service..."
brew services start mysql
sleep 5

# Verify MySQL running
if brew services list | grep mysql | grep started &> /dev/null; then
    info "MySQL service is running"
else
    error "MySQL service failed to start. Check: brew services list"
fi

# Secure MySQL
echo ""
echo "=========================================="
echo "Securing MySQL"
echo "=========================================="

if [ "$AUTO_MODE" = true ]; then
    # Auto mode: generate password
    ROOT_PASSWORD=$(generate_password)

    # Set root password (fresh install has no password)
    mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';" 2>/dev/null || {
        warn "Root password already set or unable to set"
        ROOT_PASSWORD=""
    }

    info "MySQL secured in AUTO mode"
else
    # Interactive mode
    warn "Running mysql_secure_installation..."
    echo "Recommended answers:"
    echo "  - Set root password: YES"
    echo "  - Remove anonymous users: YES"
    echo "  - Disallow root login remotely: YES"
    echo "  - Remove test database: YES"
    echo "  - Reload privilege tables: YES"
    echo ""
    read -p "Press Enter to continue..."

    mysql_secure_installation

    read -sp "Enter MySQL root password: " ROOT_PASSWORD
    echo ""
fi

# Output credentials
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
info "MySQL Server is ready"
echo "  Host: localhost"
echo "  Port: 3306"
echo "  User: root"

if [ "$AUTO_MODE" = true ] && [ -n "$ROOT_PASSWORD" ]; then
    echo ""
    warn "Auto-generated Root Password (SAVE THIS!):"
    echo "  ${ROOT_PASSWORD}"
    echo ""
    error "⚠ IMPORTANT: Save this password securely!"
fi

echo ""
info "Useful commands:"
echo "  Start:   brew services start mysql"
echo "  Stop:    brew services stop mysql"
echo "  Restart: brew services restart mysql"
echo "  Connect: mysql -u root -p"
echo ""
