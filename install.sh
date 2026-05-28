#!/usr/bin/env bash
# Install the fun config into ~/.claude/  (macOS / Linux / Git Bash / WSL)
# - Drops the cross-platform Python scripts and makes them executable
# - Merges settings.json (repo wins on conflicts, your machine-specific keys kept)
# Requires: python3 (no jq needed anymore).

set -e

CLAUDE_DIR="$HOME/.claude"
REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TS=$(date +%Y%m%d-%H%M%S)

# Pick a python launcher.
if command -v python3 >/dev/null 2>&1; then PY=python3
elif command -v python >/dev/null 2>&1; then PY=python
else
  echo "ERROR: Python 3 is required but not found (install python3)."
  exit 1
fi

mkdir -p "$CLAUDE_DIR"

# --- Scripts (Python statuslines + macOS session-color hook) ---
for f in statusline.py usage-refresh.py terminal-session-color.sh; do
  if [[ -f "$CLAUDE_DIR/$f" ]]; then
    cp "$CLAUDE_DIR/$f" "$CLAUDE_DIR/$f.bak.$TS"
    echo "Backed up: $f -> $f.bak.$TS"
  fi
  cp "$REPO_DIR/$f" "$CLAUDE_DIR/$f"
  chmod +x "$CLAUDE_DIR/$f"
  echo "Installed: $CLAUDE_DIR/$f"
done

# --- settings.json (recursive merge + OS-specific statusline command) ---
"$PY" "$REPO_DIR/apply-settings.py" "$PY"

echo ""
echo "Done. Open a new Claude Code session to see the changes."
