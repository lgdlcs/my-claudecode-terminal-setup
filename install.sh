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

# --- Scripts (Python statuslines + session-color helpers) ---
for f in statusline.py usage-refresh.py terminal-session-color.sh claude-session-color.bash; do
  if [[ -f "$CLAUDE_DIR/$f" ]]; then
    cp "$CLAUDE_DIR/$f" "$CLAUDE_DIR/$f.bak.$TS"
    echo "Backed up: $f -> $f.bak.$TS"
  fi
  cp "$REPO_DIR/$f" "$CLAUDE_DIR/$f"
  chmod +x "$CLAUDE_DIR/$f"
  echo "Installed: $CLAUDE_DIR/$f"
done

# --- Slash commands (~/.claude/commands/) ---
mkdir -p "$CLAUDE_DIR/commands"
for f in "$REPO_DIR"/commands/*.md; do
  cp "$f" "$CLAUDE_DIR/commands/"
  echo "Installed: $CLAUDE_DIR/commands/$(basename "$f")"
done

# --- AppleScripts (macOS only; used by /terminaux) ---
if [[ "$(uname)" == "Darwin" && -d "$REPO_DIR/scripts" ]]; then
  mkdir -p "$HOME/Library/Scripts"
  for f in "$REPO_DIR"/scripts/*.applescript; do
    cp "$f" "$HOME/Library/Scripts/"
    echo "Installed: $HOME/Library/Scripts/$(basename "$f")"
  done
fi

# --- CLAUDE.md (global instructions; backed up, not chmod'd) ---
if [[ -f "$CLAUDE_DIR/CLAUDE.md" ]]; then
  cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.bak.$TS"
  echo "Backed up: CLAUDE.md -> CLAUDE.md.bak.$TS"
fi
cp "$REPO_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "Installed: $CLAUDE_DIR/CLAUDE.md"

# --- Reference docs (bibles & principes; backed up, not chmod'd) ---
for f in landing-page-bible.md startup-principles.md; do
  if [[ -f "$CLAUDE_DIR/$f" ]]; then
    cp "$CLAUDE_DIR/$f" "$CLAUDE_DIR/$f.bak.$TS"
    echo "Backed up: $f -> $f.bak.$TS"
  fi
  cp "$REPO_DIR/$f" "$CLAUDE_DIR/$f"
  echo "Installed: $CLAUDE_DIR/$f"
done

# --- settings.json (recursive merge + OS-specific statusline command) ---
"$PY" "$REPO_DIR/apply-settings.py" "$PY"

# --- shell alias: launch Claude Code in bypass-permissions mode by default ---
# Idempotent: only added if not already present. Use `\claude` to bypass the alias.
RC="$HOME/.zshrc"
if [[ -f "$RC" ]] && ! grep -q "alias claude=" "$RC" 2>/dev/null; then
  {
    echo ""
    echo "# Lance Claude Code en mode bypass permissions par défaut."
    echo "# Pour lancer sans le flag ponctuellement : \\claude  (ou: command claude)"
    echo "alias claude='claude --dangerously-skip-permissions'"
  } >> "$RC"
  echo "Installed: alias claude -> $RC"
fi

echo ""
echo "Done. Open a new Claude Code session to see the changes."
