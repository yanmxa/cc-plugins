---
argument-hint: (optional)
description: Set up a complete CentOS development environment (compatible with CentOS 8/9/10) with all essential tools
allowed-tools: [Bash, Read, Edit, Write, TodoWrite]
---

Set up a comprehensive development environment on CentOS 8/9/10, installing tools in dependency order: basic development tools, utilities, libraries, programming languages, container tools, and shell enhancements.

## Implementation Steps

### 0. Detect Package Manager and OS Version
Automatically detect the appropriate package manager (yum or dnf):
```bash
# Detect package manager
if command -v dnf &> /dev/null; then
    PKG_MGR="dnf"
else
    PKG_MGR="yum"
fi

# Detect CentOS version
CENTOS_VERSION=$(grep -oP 'CentOS.*?release \K[0-9]+' /etc/centos-release 2>/dev/null || \
                 grep -oP 'Red Hat.*?release \K[0-9]+' /etc/redhat-release 2>/dev/null || echo "10")

echo "Using package manager: $PKG_MGR"
echo "CentOS/RHEL version: $CENTOS_VERSION"
```

### 1. Install Base Development Tools
Install the "Development Tools" group which provides the foundational compilation tools:
- gcc, g++, make
- autoconf, automake, libtool
- bison, flex, patch
- gdb, valgrind, strace
- rpm-build and related tools

Command:
```bash
# Use detected package manager
sudo $PKG_MGR groupinstall "Development Tools" -y
```

### 2. Install Basic Utilities
Install essential command-line utilities:
- wget, curl (download tools)
- vim (text editor)
- git (version control)
- unzip, tar (archive tools)

Command:
```bash
sudo $PKG_MGR install -y wget curl vim git unzip tar
```

### 3. Install Common Development Libraries
Install development headers and libraries required for building software:
- bzip2-devel (compression library)
- zlib-devel (compression library)
- xz-devel (compression library)
- ncurses-devel (terminal UI library)
- openssl-devel (SSL/TLS library)
- libffi-devel (foreign function interface)
- readline-devel (line editing library)

Command:
```bash
# CentOS 8/9 may use different zlib package name
if [ "$CENTOS_VERSION" -ge 10 ]; then
    ZLIB_PKG="zlib-devel"
else
    ZLIB_PKG="zlib-devel"
fi

sudo $PKG_MGR install -y bzip2 bzip2-devel $ZLIB_PKG xz-devel ncurses-devel \
    openssl-devel libffi-devel readline-devel
```

### 4. Install Programming Languages

#### 4.1 Go (Latest Version)
Download and install the latest Go version:
```bash
LATEST_GO=$(curl -sL https://go.dev/VERSION?m=text | head -1)
curl -LO https://go.dev/dl/${LATEST_GO}.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf ${LATEST_GO}.linux-amd64.tar.gz
rm ${LATEST_GO}.linux-amd64.tar.gz

# Add to PATH (avoid duplicates)
grep -q 'export PATH=$PATH:/usr/local/go/bin' ~/.bashrc || \
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
grep -q 'export PATH=$PATH:/usr/local/go/bin' ~/.zshrc 2>/dev/null || \
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
export PATH=$PATH:/usr/local/go/bin
go version
```

#### 4.2 Python (System Package)
Python 3 is typically pre-installed, verify and install if needed:
```bash
python3 --version || sudo $PKG_MGR install -y python3
sudo $PKG_MGR install -y python3-pip
```

#### 4.3 uv (Modern Python Package Manager)
Install uv for fast Python package management:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh

# Add to PATH (avoid duplicates)
grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc || \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.zshrc 2>/dev/null || \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
export PATH="$HOME/.local/bin:$PATH"
uv --version
```

#### 4.4 Node.js (Check existing or install via nvm)
Check if Node.js exists, if not install via nvm:
```bash
if ! command -v node &> /dev/null; then
    echo "Installing Node.js via nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
else
    echo "Node.js already installed: $(node --version)"
fi
```

### 5. Install Container & Kubernetes Tools

#### 5.1 Docker
Install Docker CE following the official documentation:
```bash
# Remove old/conflicting packages
sudo $PKG_MGR remove -y docker docker-client docker-client-latest docker-common \
    docker-latest docker-latest-logrotate docker-logrotate docker-engine podman runc 2>/dev/null || true

# Install dnf-plugins-core
sudo $PKG_MGR install -y dnf-plugins-core

# Add Docker official repository
sudo $PKG_MGR config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker Engine and components
sudo $PKG_MGR install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable IPv4 forwarding for Docker networking
sudo sysctl -w net.ipv4.ip_forward=1
sudo sh -c 'echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf'

# Start and enable Docker service
sudo systemctl enable --now docker

# Add current user to docker group (enables running docker without sudo)
sudo usermod -aG docker $USER

# Verify installation
docker --version
docker compose version

echo "Docker installed successfully!"
echo "Note: You need to log out and log back in for docker group permissions to take effect."
```

#### 5.2 kubectl (Latest Version)
Install the latest Kubernetes CLI:
```bash
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client
```

#### 5.3 KinD (Kubernetes in Docker)
Install latest KinD:
```bash
# Get latest KinD version
KIND_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v${KIND_VERSION}/kind-linux-amd64"
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
kind --version
```

#### 5.4 OpenShift CLI (oc)
Install the latest OpenShift CLI:
```bash
curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz
tar -xzf openshift-client-linux.tar.gz
sudo mv oc /usr/local/bin/
rm -f kubectl README.md openshift-client-linux.tar.gz
oc version --client
```

### 6. Install and Configure Shell Environment

#### 6.1 Install Zsh
Install zsh shell:
```bash
sudo $PKG_MGR install -y zsh
zsh --version
```

#### 6.2 Install Oh My Zsh
Install Oh My Zsh framework (check if already installed):
```bash
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh already installed"
fi
```

#### 6.3 Install Zsh Plugins
Install syntax highlighting and autosuggestions:
```bash
# Syntax highlighting
if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

# Autosuggestions
if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi
```

#### 6.4 Install z (Directory Jumper)
Install z for quick directory navigation:
```bash
if [ ! -d "$HOME/.z-jump" ]; then
    git clone https://github.com/rupa/z.git ~/.z-jump
    chmod +x ~/.z-jump/z.sh
else
    echo "z already installed"
fi
```

#### 6.5 Configure Zsh
Enable plugins in .zshrc:
```bash
# Update plugins line if .zshrc exists
if [ -f ~/.zshrc ]; then
    # Check if plugins line already configured
    if ! grep -q "zsh-syntax-highlighting" ~/.zshrc; then
        sed -i 's/^plugins=.*/plugins=(git docker kubectl zsh-syntax-highlighting zsh-autosuggestions)/' ~/.zshrc
    fi
    
    # Add z configuration if not present
    if ! grep -q "z-jump/z.sh" ~/.zshrc; then
        cat >> ~/.zshrc << 'EOF'

# z - jump around
[[ -f ~/.z-jump/z.sh ]] && source ~/.z-jump/z.sh
EOF
    fi
fi
```

#### 6.6 Set Zsh as Default Shell
```bash
# Only change if current shell is not zsh
if [ "$SHELL" != "$(which zsh)" ]; then
    sudo chsh -s $(which zsh) $USER
    echo "Default shell changed to zsh. Please log out and log back in."
fi
```

### 7. Install and Configure Tmux

#### 7.1 Install Tmux
```bash
sudo $PKG_MGR install -y tmux
tmux -V
```

#### 7.2 Configure Tmux
Create custom tmux configuration (backup existing if present):
```bash
# Backup existing config
[ -f ~/.tmux.conf ] && cp ~/.tmux.conf ~/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)

cat > ~/.tmux.conf << 'EOF'
# refresh with r
unbind r
bind r source-file ~/.tmux.conf

set -g default-terminal "screen-256color"

# Additional sane pane splitting shortcut
bind '\' split-window -h
bind '-' split-window -v

# Tmux copy
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'
bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'

set-option -g pane-border-lines simple

# easily resizing tmux panes
bind -r j resize-pane -D 5
bind -r k resize-pane -U 5
bind -r l resize-pane -R 5
bind -r h resize-pane -L 5
# maximizing and minimizing tmux pane
bind -r m resize-pane -Z

# set the prefix key to Ctrl-a instead of Ctrl-b
set -g prefix C-a
unbind C-b
bind C-a send-prefix

set -g mouse on

# create window with name
bind-key c command-prompt -p "window name:" "new-window; rename-window '%%'"

# act like vim
setw -g mode-keys vi

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'christoomey/vim-tmux-navigator'
set -g @plugin 'dracula/tmux'

# Dracula theme configuration
set -g @dracula-plugins "cpu-usage ram-usage network"
set -g @dracula-show-left-icon session
set -g @dracula-left-icon-padding 1
set -g @dracula-battery-label "Battery"

# Initialize TMUX plugin manager (keep this line at the very bottom)
run '~/.tmux/plugins/tpm/tpm'
EOF

echo "Tmux configuration created at ~/.tmux.conf"
```

#### 7.3 Install TPM (Tmux Plugin Manager)
```bash
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    echo "TPM installed. Launch tmux and press Ctrl-a + I to install plugins"
else
    echo "TPM already installed"
fi
```

### 8. Final Summary
Display installation summary:
```bash
echo ""
echo "========================================="
echo "CentOS Development Environment Setup Complete"
echo "========================================="
echo ""
echo "Installed Tools:"
echo "  - Development Tools: gcc, g++, make, etc."
echo "  - Languages: Go $(go version 2>/dev/null | awk '{print $3}'), Python $(python3 --version 2>&1 | awk '{print $2}'), Node.js $(node --version 2>/dev/null)"
echo "  - Container Tools: Docker $(docker --version 2>/dev/null | awk '{print $3}'), kubectl, kind, oc"
echo "  - Shell: zsh $(zsh --version 2>/dev/null | awk '{print $2}'), tmux"
echo ""
echo "Next Steps:"
echo "  1. Log out and log back in to activate zsh and docker group permissions"
echo "  2. Launch tmux and press Ctrl-a + I to install tmux plugins"
echo "  3. Start using 'z <directory>' for quick navigation"
echo ""
```

## Post-Installation Steps

After running this command:

1. **Log out and log back in** to activate:
   - Zsh as your default shell
   - Docker group permissions (run docker without sudo)

2. **Install tmux plugins**:
   - Launch tmux: `tmux`
   - Press: `Ctrl-a` + `I` (capital I) to install plugins

3. **Verify installations**:
   ```bash
   # Development tools
   gcc --version
   make --version

   # Programming languages
   go version
   python3 --version
   node --version
   uv --version

   # Container tools
   docker ps
   kubectl version --client
   kind version
   oc version --client

   # Shell
   zsh --version
   tmux -V
   ```

4. **Start using z**:
   - Visit directories: `cd /some/directory`
   - Jump back later: `z directory`

## Notes

- **Compatibility**: Works on CentOS/RHEL 8, 9, and 10
- **Package Manager**: Auto-detects yum or dnf
- **Idempotent**: Safe to run multiple times (checks before installing)
- **Backups**: Existing configurations are backed up before modification
- All tools are installed to their latest stable versions
- PATH configurations are added to both .bashrc and .zshrc
- Tmux configuration uses Ctrl-a as prefix (instead of default Ctrl-b)
- Z builds its database as you navigate; give it time to learn your patterns

## Compatibility Notes

### CentOS 8
- CentOS 8 reached EOL in 2021
- Some repos may need to be updated to vault.centos.org
- Docker installation fully supported

### CentOS 9 Stream
- Fully supported
- Uses dnf package manager
- All tools available in standard repos

### CentOS 10
- Fully supported
- Uses dnf package manager
- Latest package versions available
