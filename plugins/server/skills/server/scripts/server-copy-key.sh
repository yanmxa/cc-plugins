#!/bin/bash
# Copy SSH public key to remote server's authorized_keys
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOST_FILE="$SCRIPT_DIR/host"

if [ ! -f "$HOST_FILE" ]; then
  echo "ERROR: Host file not found at $HOST_FILE"
  exit 1
fi

# Check SSH key exists
if [ ! -f "$HOME/.ssh/id_rsa.pub" ] && [ ! -f "$HOME/.ssh/id_ed25519.pub" ]; then
  echo "ERROR: No SSH public key found."
  echo "Generate one with: ssh-keygen -t ed25519"
  exit 1
fi

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

echo "Select a server to copy SSH key to:"
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

echo ">> Copying SSH key to ${names[index]}: ${servers[index]}"
if [ "${passwords[index]}" = "-1" ]; then
  ssh-copy-id -p "${ports[index]}" "${servers[index]}"
else
  expect -c "spawn ssh-copy-id -p ${ports[index]} ${servers[index]}; expect *assword*; send ${passwords[index]}\r; interact"
fi

echo ""
echo "SSH key deployed. You can now update the host file to use -1 as password."
