#!/bin/bash
# Interactive SSH login with server selection
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOST_FILE="$SCRIPT_DIR/host"

if [ ! -f "$HOST_FILE" ]; then
  echo "ERROR: Host file not found at $HOST_FILE"
  echo "Create it with format: name user@server password [port]"
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

if [ ${#names[@]} -eq 0 ]; then
  echo "ERROR: No servers configured in $HOST_FILE"
  exit 1
fi

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

echo ">> Logging in to ${names[index]}: ${servers[index]}"
if [ "${passwords[index]}" = "-1" ]; then
  ssh -C "${servers[index]}" -p "${ports[index]}"
else
  expect -c "spawn ssh ${servers[index]} -p ${ports[index]}; expect *assword*; send ${passwords[index]}\r; interact"
fi
