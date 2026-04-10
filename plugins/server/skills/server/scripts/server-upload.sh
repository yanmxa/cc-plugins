#!/bin/bash
# Upload file/directory to remote server via SCP
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOST_FILE="$SCRIPT_DIR/host"

if [ $# -lt 2 ]; then
  echo "Usage: $0 <local_path> <remote_path>"
  exit 1
fi

if [ ! -f "$HOST_FILE" ]; then
  echo "ERROR: Host file not found at $HOST_FILE"
  exit 1
fi

LOCAL_PATH="$1"
REMOTE_PATH="$2"

names=()
servers=()
passwords=()
ports=()

while read -r line; do
  [ -z "$line" ] && continue
  name=$(echo "$line" | awk '{print $1}')
  serv=$(echo "$line" | awk '{print $2}')
  pass=$(echo "$line" | awk '{print $3}')
  port=$(echo "$line" | awk '{print $4}')
  port="${port:-22}"
  names+=("$name")
  servers+=("$serv")
  passwords+=("$pass")
  ports+=("$port")
done < "$HOST_FILE"

echo "Select a server:"
select option in "${names[@]}"; do
  select_name="$option"
  break
done

if [ -z "${select_name:-}" ]; then
  echo ">> No server selected!"
  exit 0
fi

for index in "${!names[@]}"; do
  if [ "$select_name" = "${names[index]}" ]; then
    break
  fi
done

echo ">> Uploading to ${servers[index]}:$REMOTE_PATH"
if [ "${passwords[index]}" = "-1" ]; then
  scp -P "${ports[index]}" -r "$LOCAL_PATH" "${servers[index]}:$REMOTE_PATH"
else
  expect -c "spawn scp -P ${ports[index]} -r $LOCAL_PATH ${servers[index]}:$REMOTE_PATH; expect *assword*; send ${passwords[index]}\r; interact"
fi
