#!/bin/bash
# ssh-fzf - Interactive SSH/SCP with fzf
SSH_FZF_VERSION="1.0.0"

_ssh_hosts() {
  grep -E "^Host\s+" "${SSH_CONFIG:-$HOME/.ssh/config}" 2>/dev/null | \
    awk '{for(i=2;i<=NF;i++) print $i}' | grep -v '[*?]' | sort -u
}

# ss - SSH with fzf server selection
ss() {
  local host
  host=$(_ssh_hosts | fzf --height=40% --layout=reverse --border --prompt="SSH > " \
    --header="Select server" \
    --preview="grep -A 8 'Host {1}$' ${SSH_CONFIG:-$HOME/.ssh/config} | head -8" \
    --preview-window=right:40%:wrap)
  [ -n "$host" ] && ssh "$host"
}

# sc - SCP with fzf (server + path selection, supports files/folders + compression)
sc() {
  # Select server
  local host
  host=$(_ssh_hosts | fzf --height=40% --layout=reverse --border --prompt="SCP > " --header="Select server")
  [ -z "$host" ] && return 0

  # Select direction
  local direction
  direction=$(printf "upload\ndownload" | fzf --height=20% --layout=reverse --border --prompt="Direction > ")
  [ -z "$direction" ] && return 0

  if [ "$direction" = "upload" ]; then
    # Input local base path (default: home)
    local basepath
    read -p "Local base path [~]: " basepath
    basepath="${basepath:-$HOME}"
    basepath="${basepath/#\~/$HOME}"

    # Dynamic search local files/folders
    local localpath
    localpath=$(find "$basepath" -maxdepth 5 \( -type f -o -type d \) 2>/dev/null | \
      fzf --height=60% --layout=reverse --border \
      --prompt="Local path > " \
      --header="Select file/folder to upload (type to filter)" \
      --preview="if [ -d {} ]; then ls -la {}; else head -30 {} 2>/dev/null || file {}; fi" \
      --preview-window=right:50%:wrap)
    [ -z "$localpath" ] && return 0

    # Input remote base path for search
    local remotebase
    read -p "Remote base path [~]: " remotebase
    remotebase="${remotebase:-~}"

    # Dynamic search remote directories
    echo "Loading remote paths..."
    local remotedir
    remotedir=$(ssh "$host" "find $remotebase -maxdepth 4 -type d 2>/dev/null" | \
      fzf --height=50% --layout=reverse --border \
      --prompt="Remote dir > " \
      --header="Select destination on $host" \
      --preview="ssh $host 'ls -la {}' 2>/dev/null" \
      --preview-window=right:50%:wrap)
    [ -z "$remotedir" ] && remotedir="~"

    # Check if it's a directory - offer compression
    if [ -d "$localpath" ]; then
      local compress
      compress=$(printf "no\nyes (tar.gz)" | fzf --height=15% --layout=reverse --border --prompt="Compress? > ")

      if [[ "$compress" == "yes"* ]]; then
        local tarfile="/tmp/$(basename "$localpath").tar.gz"
        echo "Compressing $localpath -> $tarfile"
        tar -czf "$tarfile" -C "$(dirname "$localpath")" "$(basename "$localpath")"
        echo "scp $tarfile $host:$remotedir/"
        scp "$tarfile" "$host:$remotedir/"
        rm "$tarfile"
        echo "Extracting on remote..."
        ssh "$host" "cd $remotedir && tar -xzf $(basename "$tarfile") && rm $(basename "$tarfile")"
      else
        echo "scp -r $localpath $host:$remotedir/"
        scp -r "$localpath" "$host:$remotedir/"
      fi
    else
      echo "scp $localpath $host:$remotedir/"
      scp "$localpath" "$host:$remotedir/"
    fi
  else
    # Input remote base path for search
    local remotebase
    read -p "Remote base path [~]: " remotebase
    remotebase="${remotebase:-~}"

    # Dynamic search remote files/folders
    echo "Loading remote paths..."
    local remotepath
    remotepath=$(ssh "$host" "find $remotebase -maxdepth 5 \( -type f -o -type d \) 2>/dev/null" | \
      fzf --height=60% --layout=reverse --border \
      --prompt="Remote path > " \
      --header="Select file/folder from $host (type to filter)" \
      --preview="ssh $host 'if [ -d {} ]; then ls -la {}; else head -30 {} 2>/dev/null || file {}; fi'" \
      --preview-window=right:50%:wrap)
    [ -z "$remotepath" ] && return 0

    # Input local destination
    local localdir
    read -p "Local destination [.]: " localdir
    localdir="${localdir:-.}"
    localdir="${localdir/#\~/$HOME}"

    # Check if remote is directory
    local isdir
    isdir=$(ssh "$host" "[ -d '$remotepath' ] && echo 'yes' || echo 'no'")

    if [ "$isdir" = "yes" ]; then
      local compress
      compress=$(printf "no\nyes (tar.gz)" | fzf --height=15% --layout=reverse --border --prompt="Compress? > ")

      if [[ "$compress" == "yes"* ]]; then
        local tarfile="$(basename "$remotepath").tar.gz"
        echo "Compressing on remote..."
        ssh "$host" "cd $(dirname "$remotepath") && tar -czf /tmp/$tarfile $(basename "$remotepath")"
        echo "scp $host:/tmp/$tarfile $localdir/"
        scp "$host:/tmp/$tarfile" "$localdir/"
        ssh "$host" "rm /tmp/$tarfile"
        echo "Extracting locally..."
        (cd "$localdir" && tar -xzf "$tarfile" && rm "$tarfile")
      else
        echo "scp -r $host:$remotepath $localdir/"
        scp -r "$host:$remotepath" "$localdir/"
      fi
    else
      echo "scp $host:$remotepath $localdir/"
      scp "$host:$remotepath" "$localdir/"
    fi
  fi
}

# sk - Setup passwordless SSH (ssh-copy-id with fzf)
sk() {
  local keyfile="${1:-$HOME/.ssh/id_rsa.pub}"

  # Check if key exists
  if [ ! -f "$keyfile" ]; then
    echo "No SSH key found at $keyfile"
    read -p "Generate new key? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      ssh-keygen -t rsa -b 4096
      keyfile="$HOME/.ssh/id_rsa.pub"
    else
      return 1
    fi
  fi

  # Select server
  local host
  host=$(_ssh_hosts | fzf --height=40% --layout=reverse --border \
    --prompt="Copy key to > " --header="Select server for passwordless login" \
    --preview="grep -A 8 'Host {1}$' ${SSH_CONFIG:-$HOME/.ssh/config} | head -8" \
    --preview-window=right:40%:wrap)
  [ -z "$host" ] && return 0

  echo "Copying public key to $host..."
  ssh-copy-id -i "$keyfile" "$host"
}

# s - Show available commands
s() {
  echo "ssh-fzf v$SSH_FZF_VERSION - Interactive SSH/SCP with fzf"
  echo ""
  echo "  ss     SSH connect with server selection"
  echo "  sc     SCP transfer (files/folders, compression)"
  echo "  sk     Setup passwordless login (ssh-copy-id)"
  echo "  s      Show this help"
}
