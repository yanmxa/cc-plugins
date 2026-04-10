---
name: server
description: Server management operations - SSH login, SCP file upload/download, and SSH key deployment. Use this skill when the user mentions server login, SSH, upload file to server, download from server, copy SSH key, server management, remote access, or SCP operations.
allowed-tools: [Bash, Read, Write, Edit]
---

# Server Management

Interactive server management with SSH login, SCP file transfer, and SSH key setup. Reads server configuration from a `host` file.

## Host file format

The host file at `${CLAUDE_SKILL_DIR}/scripts/host` defines available servers:

```
name user@server_ip password [port]
```

- **name**: Display name for server selection (e.g., `cloud-user@meng(10.0.11.238)`)
- **user@server_ip**: SSH connection string
- **password**: Server password, or `-1` for SSH key authentication
- **port**: SSH port (default: 22)

Example:
```
my-server admin@192.168.1.100 mypass123 22
prod-box deploy@10.0.0.5 -1
```

## Operations

### Login to server

Interactive server selection and SSH login:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/server-login.sh
```

Supports both password (via expect) and key-based authentication.

### Upload file to server

Upload a local file or directory to a remote server:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/server-upload.sh <local_path> <remote_path>
```

### Download file from server

Download a file or directory from a remote server:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/server-download.sh <remote_path> <local_path>
```

### Copy SSH key to server

Deploy your SSH public key to a server's authorized_keys:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/server-copy-key.sh
```

This uses `ssh-copy-id` to add `~/.ssh/id_rsa.pub` to the remote server.

## Adding servers

Edit the host file to add new servers:

```bash
echo "new-server user@ip password port" >> ${CLAUDE_SKILL_DIR}/scripts/host
```

Or use `-1` as password for key-based auth:

```bash
echo "new-server user@ip -1" >> ${CLAUDE_SKILL_DIR}/scripts/host
```

## Notes

- The `host` file is gitignored to prevent credential leakage
- Use `-1` as password after copying your SSH key via `server-copy-key.sh`
- All SCP operations support recursive transfer (directories)
- Expects `expect` command to be available for password-based auth
