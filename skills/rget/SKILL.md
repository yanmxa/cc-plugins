---
name: rget
description: Download files and directories from remote machines via SSH/SCP or HTTP/HTTPS. Use when user mentions downloading from remote server, scp, rsync, fetch files from remote host, or getting files from remote machine. Supports progress display, resume, and auto-extraction.
allowed-tools: [Bash, Read, Write, Glob, AskUserQuestion]
---

# rget - Remote File Download Skill

Intelligent remote file and directory download tool supporting SSH/SCP, rsync, and HTTP/HTTPS with automatic protocol detection.

## When to Use This Skill

- User wants to download file(s) from a remote server
- User mentions: "scp from server", "download from remote", "fetch file from host"
- User provides a remote path like `user@host:/path/to/file`
- User wants to sync files from remote machine
- User needs to download and extract archives from remote servers

## Core Capabilities

1. **Auto-detect Protocol**
   - `user@host:/path` → Use SCP/rsync
   - `http://...` or `https://...` → Use wget/curl
   - Intelligent fallback between methods

2. **File & Directory Support**
   - Single files
   - Entire directories (recursive)
   - Multiple files with wildcards
   - Preserve permissions and timestamps

3. **Smart Features**
   - Progress display with transfer speed
   - Resume interrupted downloads
   - Auto-extract archives (.tar.gz, .zip, etc.)
   - Verify file integrity after download

4. **SSH Authentication**
   - Use SSH keys from ~/.ssh/ (preferred)
   - Support custom SSH key paths
   - Use SSH config hosts
   - Handle SSH agent

## Instructions

### 1. Parse Remote Source

When user requests to download from remote:

1. **Detect source format**:
   - SSH format: `user@host:/path/to/file` or `host:/path` (uses SSH config)
   - HTTP format: `http://example.com/file` or `https://...`
   - Auto-detect based on pattern

2. **Extract components**:
   - For SSH: username, hostname, remote path
   - For HTTP: full URL
   - Destination path (optional, defaults to current directory)

3. **Check if directory or file**:
   - Ask user if ambiguous
   - Assume directory if path ends with `/`
   - Use `ssh user@host "test -d /path"` to verify

### 2. Determine Download Method

**Decision tree:**

1. **If HTTP/HTTPS URL**:
   - Use `wget --continue --progress=bar` (if available)
   - Fall back to `curl -L -C - -#` (if wget not available)
   - Show download progress

2. **If SSH source (user@host:path)**:
   - For small files (<100MB): Use `scp -v`
   - For large files/directories: Use `rsync -avz --progress`
   - For resume capability: Prefer `rsync` with `--partial`

3. **Check SSH connectivity first**:
   ```bash
   ssh -o ConnectTimeout=5 user@host "echo connected" 2>/dev/null
   ```

### 3. Execute Download

#### For SSH/SCP Downloads:

**Single file (small):**
```bash
scp -v user@host:/remote/path/file.txt ./local/path/
```

**Single file (large, with resume):**
```bash
rsync -avz --progress --partial user@host:/remote/path/file.txt ./local/path/
```

**Directory (recursive):**
```bash
rsync -avz --progress user@host:/remote/path/directory/ ./local/path/directory/
```

**With custom SSH key:**
```bash
scp -i ~/.ssh/custom_key user@host:/path/file ./
rsync -avz -e "ssh -i ~/.ssh/custom_key" user@host:/path/ ./local/
```

**With SSH config host:**
```bash
# If ~/.ssh/config has entry for "prod-server"
scp prod-server:/path/file ./
rsync -avz --progress prod-server:/path/ ./local/
```

#### For HTTP/HTTPS Downloads:

**Using wget (preferred):**
```bash
wget --continue --progress=bar:force --show-progress \
  -O local_filename https://example.com/file.tar.gz
```

**Using curl (fallback):**
```bash
curl -L -C - -# -o local_filename https://example.com/file.tar.gz
```

### 4. Handle Download Progress

**Show real-time progress:**

1. For `rsync`: Progress is built-in with `--progress`
2. For `scp`: Use `-v` for verbose output
3. For `wget`: Use `--progress=bar:force --show-progress`
4. For `curl`: Use `-#` for progress bar

**Parse and display:**
- File size
- Transfer speed
- ETA (estimated time)
- Percentage complete

### 5. Post-Download Actions

**After successful download:**

1. **Verify download**:
   - Check file exists locally
   - Compare file size (if known)
   - Verify checksum if available

2. **Auto-extract if archive**:
   - Detect: `.tar.gz`, `.tgz`, `.tar.bz2`, `.zip`, `.tar.xz`
   - Ask user: "Extract archive? (yes/no)"
   - If yes:
     ```bash
     # .tar.gz, .tgz
     tar -xzvf file.tar.gz

     # .tar.bz2
     tar -xjvf file.tar.bz2

     # .zip
     unzip file.zip

     # .tar.xz
     tar -xJvf file.tar.xz
     ```

3. **Preserve permissions** (for rsync):
   - `-a` flag preserves permissions, ownership, timestamps
   - Report if permissions changed

4. **Report summary**:
   - Files downloaded
   - Total size
   - Download time
   - Average speed
   - Local path

### 6. Handle Interruptions & Resume

**For interrupted downloads:**

1. **Detect partial file**:
   - Check if `.part` file exists (wget)
   - Check if destination file exists (rsync partial)

2. **Offer to resume**:
   - "Found partial download. Resume? (yes/no)"
   - If yes: Add `--continue` (wget) or `--partial` (rsync)

3. **Resume commands**:
   ```bash
   # wget resume
   wget --continue URL

   # rsync resume
   rsync -avz --progress --partial user@host:/path ./

   # curl resume
   curl -C - -o file URL
   ```

## SSH Authentication Handling

### Priority Order:

1. **SSH agent** (if running)
   - Check: `ssh-add -l`
   - Use automatically if keys loaded

2. **Default SSH keys**
   - `~/.ssh/id_rsa`
   - `~/.ssh/id_ed25519`
   - `~/.ssh/id_ecdsa`

3. **SSH config file** (`~/.ssh/config`)
   - Check for host alias
   - Use configured IdentityFile

4. **Custom key path**
   - If user specifies: `-i /path/to/key`

### SSH Config Detection:

**Check if host is in SSH config:**
```bash
ssh -G hostname | grep "^hostname" | grep -v "^hostname hostname$"
```

**If found, extract:**
- Actual hostname
- Username
- Port
- IdentityFile

### Handle SSH Key Permissions:

**If key permission error:**
```bash
chmod 600 ~/.ssh/id_rsa
chmod 700 ~/.ssh
```

**Suggest to user:**
```
SSH key permissions issue detected.
Run: chmod 600 ~/.ssh/your_key
```

## Smart Defaults

- **Download location**: Current directory
- **Preserve structure**: Yes (with rsync)
- **Show progress**: Always
- **Resume on failure**: Offer to user
- **Extract archives**: Ask user
- **SSH timeout**: 30 seconds
- **Retry on failure**: 3 times with exponential backoff

## Common Scenarios

### Scenario 1: Download Single File via SSH

**User**: "Download /var/log/app.log from prod-server"

**Actions**:
1. Check if "prod-server" is in SSH config
2. Use: `scp prod-server:/var/log/app.log ./`
3. Show progress
4. Report: "Downloaded app.log (2.3 MB) to ./"

### Scenario 2: Download Directory with Resume

**User**: "Download /data/backups from user@192.168.1.100"

**Actions**:
1. Verify it's a directory: `ssh user@192.168.1.100 "test -d /data/backups"`
2. Use: `rsync -avz --progress --partial user@192.168.1.100:/data/backups/ ./backups/`
3. If interrupted, offer resume
4. Report total files and size

### Scenario 3: Download from HTTP

**User**: "Download https://example.com/dataset.tar.gz"

**Actions**:
1. Check if wget available: `which wget`
2. Use: `wget --continue --progress=bar:force https://example.com/dataset.tar.gz`
3. After download, ask: "Extract dataset.tar.gz?"
4. If yes: `tar -xzvf dataset.tar.gz`

### Scenario 4: Batch Download

**User**: "Download all .log files from server:/var/logs/"

**Actions**:
1. Use rsync with include pattern:
   ```bash
   rsync -avz --progress --include='*.log' --exclude='*' \
     user@server:/var/logs/ ./logs/
   ```
2. Report number of files downloaded

### Scenario 5: Download with Custom SSH Key

**User**: "Download file.txt from backup-server using key at ~/.ssh/backup_key"

**Actions**:
1. Verify key exists and has correct permissions
2. Use: `scp -i ~/.ssh/backup_key backup-server:/path/file.txt ./`
3. If permission error on key, suggest: `chmod 600 ~/.ssh/backup_key`

## Error Handling

### Connection Failed

**Error**: `ssh: connect to host X port 22: Connection refused`

**Actions**:
1. Check if host is reachable: `ping -c 3 hostname`
2. Check if SSH port is open: `nc -zv hostname 22`
3. Suggest:
   - Verify hostname/IP
   - Check if SSH service is running
   - Try different port: `ssh -p 2222 user@host`

### Authentication Failed

**Error**: `Permission denied (publickey)`

**Actions**:
1. Check SSH keys: `ssh-add -l`
2. Suggest adding key: `ssh-add ~/.ssh/id_rsa`
3. Or try password auth: `scp -o PreferredAuthentications=password user@host:file ./`

### File Not Found

**Error**: `No such file or directory`

**Actions**:
1. Verify path exists: `ssh user@host "ls -la /path/to/file"`
2. Suggest:
   - Check file path spelling
   - Verify you have read permissions
   - List directory: `ssh user@host "ls /path/to/"`

### Disk Space Full

**Error**: `No space left on device`

**Actions**:
1. Check local disk space: `df -h .`
2. Suggest:
   - Free up space
   - Download to different location
   - Use compression

### Network Interrupted

**Error**: `Connection reset by peer` or timeout

**Actions**:
1. Offer to resume: "Download was interrupted. Resume?"
2. If yes, use rsync with `--partial`
3. If repeated failures, suggest:
   - Check network stability
   - Try during off-peak hours
   - Use screen/tmux for long transfers

## Advanced Features

### 1. Parallel Downloads

**For multiple files:**
```bash
# Download 4 files in parallel
parallel -j 4 scp user@host:/path/file{} ./ ::: 1 2 3 4
```

### 2. Bandwidth Limiting

**To avoid saturating network:**
```bash
# Limit to 1MB/s
rsync -avz --progress --bwlimit=1024 user@host:/path ./

# scp with limit
scp -l 8192 user@host:/path ./  # 8192 Kbit/s = 1 MB/s
```

### 3. Compression for Faster Transfer

**Enable compression:**
```bash
# rsync with compression
rsync -avz --compress user@host:/path ./

# scp with compression
scp -C user@host:/path ./
```

### 4. Exclude Patterns

**Skip certain files:**
```bash
# Exclude .git and node_modules
rsync -avz --progress \
  --exclude='.git' --exclude='node_modules' \
  user@host:/project/ ./project/
```

### 5. Dry Run (Preview)

**See what would be downloaded:**
```bash
rsync -avz --progress --dry-run user@host:/path ./
```

**Ask user**: "Preview shows 245 files (1.2 GB). Proceed with download?"

## Safety Features

1. **Confirm before large downloads**:
   - If size > 1GB, ask user to confirm
   - Show estimated time based on network speed

2. **Verify SSH fingerprint** (first connection):
   - Show fingerprint
   - Ask user to confirm

3. **Check destination exists**:
   - Create directory if needed
   - Warn if files will be overwritten

4. **Atomic downloads** (when possible):
   - Download to temp file first
   - Move to final location on success

## Output Format

**Success output:**
```
✓ Downloading from: user@prod-server:/data/backup.tar.gz
✓ Destination: ./backup.tar.gz
✓ Method: rsync (with resume support)

Progress: [████████████████████] 100% | 245 MB | 12.3 MB/s | ETA: 0s

✓ Download complete!
  File: backup.tar.gz
  Size: 245 MB
  Time: 20s
  Speed: 12.3 MB/s
  Location: /Users/myan/Downloads/backup.tar.gz

Archive detected. Extract now? (yes/no):
```

**Error output:**
```
✗ Failed to connect to remote host
✗ Error: ssh: connect to host prod-server port 22: Connection refused

Troubleshooting:
  1. Check if host is reachable: ping prod-server
  2. Verify SSH service: nc -zv prod-server 22
  3. Check SSH config: cat ~/.ssh/config
  4. Try different port: ssh -p 2222 user@host

Retry? (yes/no):
```

## Configuration

**Optional config file** (`~/.rget.conf`):
```bash
# Default SSH key
DEFAULT_SSH_KEY=~/.ssh/id_rsa

# Default download directory
DOWNLOAD_DIR=~/Downloads

# Auto-extract archives
AUTO_EXTRACT=ask  # Options: yes, no, ask

# Preferred method
PREFER_RSYNC=yes  # Use rsync over scp when possible

# Bandwidth limit (KB/s, 0 = unlimited)
BANDWIDTH_LIMIT=0

# Connection timeout (seconds)
TIMEOUT=30

# Number of retries
RETRY_COUNT=3
```

## Integration with SSH Config

**Example ~/.ssh/config:**
```
Host prod
    HostName prod.example.com
    User deploy
    Port 22
    IdentityFile ~/.ssh/prod_key

Host backup-server
    HostName 192.168.1.100
    User backup
    IdentityFile ~/.ssh/backup_key
```

**Usage with config:**
```bash
# Just use the host alias
rget prod:/data/app.log
rget backup-server:/backups/db.sql.gz
```

## Best Practices

1. **Use rsync for large transfers** - Better resume support
2. **Keep SSH keys secure** - Use ssh-agent, proper permissions
3. **Use SSH config** - Define hosts once, use everywhere
4. **Enable compression** - For slow networks
5. **Verify downloads** - Check file sizes/checksums
6. **Clean up partial downloads** - Remove .part files on failure
7. **Use bandwidth limits** - On shared networks

## Requirements

**Required tools:**
- `ssh` - SSH client
- `scp` - Secure copy (usually bundled with ssh)

**Optional but recommended:**
- `rsync` - For better performance and resume capability
- `wget` or `curl` - For HTTP/HTTPS downloads
- `ssh-agent` - For key management

**Check availability:**
```bash
which ssh scp rsync wget curl
```

## Usage with Claude Code

**Natural commands that trigger this skill:**

- "Download file.txt from server:/path/"
- "Get /var/log/app.log from prod-server"
- "Fetch backup from user@192.168.1.100:/backups/"
- "Download https://example.com/dataset.tar.gz"
- "Sync directory from remote server"
- "Download and extract archive from host"

Claude will automatically use this skill and handle all the complexity!
