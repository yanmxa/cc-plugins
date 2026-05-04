#!/bin/bash
# Install OrbStack — fast, lightweight Docker runtime for macOS (replaces Docker Desktop)
# OrbStack ships with: docker daemon, docker CLI, compose, buildx, kubernetes, Linux VMs
set -euo pipefail

echo "=== Docker (OrbStack) Setup ==="

if ! command -v brew &>/dev/null; then
  echo "ERROR: Homebrew not found. Install from https://brew.sh first."
  exit 1
fi

# --- Install OrbStack (cask) ---
if brew list --cask orbstack &>/dev/null; then
  echo "  OrbStack already installed."
elif [ -d "/Applications/OrbStack.app" ]; then
  echo "  OrbStack already in /Applications (installed outside brew)."
else
  echo "  Installing OrbStack..."
  brew install --cask orbstack
fi

# --- First launch: triggers the setup wizard (one-time) ---
if ! pgrep -x "OrbStack" >/dev/null 2>&1; then
  echo ""
  echo "  Launching OrbStack for first-time setup (will open the app)..."
  echo "  Accept the permissions prompts, then close the welcome window."
  open -a OrbStack
  sleep 3
fi

echo ""
echo "=== Docker (OrbStack) Setup Complete ==="
echo ""
echo "OrbStack auto-starts when you run docker commands. No 'colima start' needed."
echo ""
echo "Verify:"
echo "  docker run hello-world"
echo "  docker compose version"
echo "  docker buildx version"
echo ""
echo "Daily use:"
echo "  • Just run docker / docker compose — it works"
echo "  • Click menu bar icon to pause / resume / quit"
echo "  • orb status     — CLI status"
echo "  • orb stop       — stop the VM (frees RAM)"
echo ""
echo "Bonus features OrbStack includes for free:"
echo "  • Kubernetes:  enable in settings, then 'kubectl' just works"
echo "  • Linux VMs:   orb create ubuntu my-vm    (full Linux desktop env)"
echo "  • Multi-arch:  docker run --platform linux/amd64 ..."
