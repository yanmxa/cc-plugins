#!/bin/bash
set -e

echo "🔧 Fixing Claude Code auto-update issues..."
echo ""

# Step 1: Clean npm cache forcefully
echo "📦 Cleaning npm cache..."
rm -rf ~/.npm/_cacache 2>/dev/null || true
echo "   Cache cleaned"

# Step 2: Remove existing global installation and temp directories
echo "🗑️  Removing existing global Claude Code installation..."
NPM_PREFIX=$(npm config get prefix)
CLAUDE_DIR="${NPM_PREFIX}/lib/node_modules/@anthropic-ai/claude-code"
ANTHROPIC_DIR="${NPM_PREFIX}/lib/node_modules/@anthropic-ai"

if [ -d "$ANTHROPIC_DIR" ]; then
    echo "   Removing: $ANTHROPIC_DIR"
    rm -rf "$ANTHROPIC_DIR"
else
    echo "   No existing installation found at: $ANTHROPIC_DIR"
fi

# Step 3: Reinstall Claude Code globally (this may take several minutes)
echo "⬇️  Reinstalling @anthropic-ai/claude-code globally (this may take 5+ minutes)..."
npm install -g @anthropic-ai/claude-code

echo ""
echo "✅ Claude Code auto-update fix complete!"
echo "   Auto-updates should now work normally."