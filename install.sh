#!/usr/bin/env bash
# Install the fun config into ~/.claude/
# - Backs up any existing settings.json / statusline.sh with a timestamp
# - Merges new settings into your existing settings.json (top-level keys win)
# - Drops the cross-platform statusline.sh and makes it executable

set -e

CLAUDE_DIR="$HOME/.claude"
REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TS=$(date +%Y%m%d-%H%M%S)

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: 'jq' is required but not installed."
  echo "  macOS:       brew install jq"
  echo "  Git Bash:    scoop install jq    (or: choco install jq)"
  echo "  Debian/WSL:  sudo apt install jq"
  exit 1
fi

mkdir -p "$CLAUDE_DIR"

# --- statusline.sh ---
if [[ -f "$CLAUDE_DIR/statusline.sh" ]]; then
  cp "$CLAUDE_DIR/statusline.sh" "$CLAUDE_DIR/statusline.sh.bak.$TS"
  echo "Backed up: statusline.sh → statusline.sh.bak.$TS"
fi
cp "$REPO_DIR/statusline.sh" "$CLAUDE_DIR/statusline.sh"
chmod +x "$CLAUDE_DIR/statusline.sh"
echo "Installed: $CLAUDE_DIR/statusline.sh"

# --- settings.json ---
if [[ -f "$CLAUDE_DIR/settings.json" ]]; then
  cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak.$TS"
  echo "Backed up: settings.json → settings.json.bak.$TS"
  # Recursive merge: new file wins on conflicts (incl. hooks)
  jq -s '.[0] * .[1]' "$CLAUDE_DIR/settings.json.bak.$TS" "$REPO_DIR/settings.json" > "$CLAUDE_DIR/settings.json.tmp"
  mv "$CLAUDE_DIR/settings.json.tmp" "$CLAUDE_DIR/settings.json"
  echo "Merged:    $CLAUDE_DIR/settings.json"
else
  cp "$REPO_DIR/settings.json" "$CLAUDE_DIR/settings.json"
  echo "Installed: $CLAUDE_DIR/settings.json"
fi

# --- validate ---
if jq -e . "$CLAUDE_DIR/settings.json" >/dev/null 2>&1; then
  echo "OK: settings.json parses cleanly."
else
  echo "ERROR: resulting settings.json is invalid! Restore with:"
  echo "  cp $CLAUDE_DIR/settings.json.bak.$TS $CLAUDE_DIR/settings.json"
  exit 1
fi

echo ""
echo "Done. Open a new Claude Code session to see the changes."
