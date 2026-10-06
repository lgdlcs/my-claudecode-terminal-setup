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
for f in statusline.py usage-refresh.py terminal-session-color.sh terminal-color.sh claude-session-color.bash; do
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

# --- Subagents (~/.claude/agents/) ---
if [[ -d "$REPO_DIR/agents" ]]; then
  mkdir -p "$CLAUDE_DIR/agents"
  for f in "$REPO_DIR"/agents/*.md; do
    cp "$f" "$CLAUDE_DIR/agents/"
    echo "Installed: $CLAUDE_DIR/agents/$(basename "$f")"
  done
fi

# --- Hooks (~/.claude/hooks/) ---
if [[ -d "$REPO_DIR/hooks" ]]; then
  mkdir -p "$CLAUDE_DIR/hooks"
  for f in "$REPO_DIR"/hooks/*; do
    cp "$f" "$CLAUDE_DIR/hooks/"
    chmod +x "$CLAUDE_DIR/hooks/$(basename "$f")"
    echo "Installed: $CLAUDE_DIR/hooks/$(basename "$f")"
  done
fi

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

# --- pstack plugin (local marketplace; upstream only ships a Cursor manifest) ---
if [[ ! -d "$CLAUDE_DIR/local-plugins/pstack/skills" ]]; then
  tmp=$(mktemp -d)
  if git clone -q --depth 1 https://github.com/cursor/plugins.git "$tmp"; then
    mkdir -p "$CLAUDE_DIR/local-plugins"
    cp -r "$tmp/pstack" "$CLAUDE_DIR/local-plugins/"
    echo "Installed: $CLAUDE_DIR/local-plugins/pstack"
  fi
  rm -rf "$tmp"
fi
mkdir -p "$CLAUDE_DIR/local-plugins"
cp -r "$REPO_DIR/plugins/local/." "$CLAUDE_DIR/local-plugins/"

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

# --- User-scope MCP servers ---
if command -v claude >/dev/null 2>&1; then
  "$PY" -c "import json,sys;[print(n,s['type'],s['url']) for n,s in json.load(open(sys.argv[1]))['mcpServers'].items()]" "$REPO_DIR/mcp-servers.json" |
  while read -r name type url; do
    claude mcp add --scope user --transport "$type" "$name" "$url" >/dev/null 2>&1 && echo "MCP added: $name" || echo "MCP present: $name"
  done
fi

# --- herdr: binary, shared config, Claude Code integration, shell helpers ---
if ! command -v herdr >/dev/null 2>&1; then
  curl -fsSL https://herdr.dev/install.sh | sh || echo "herdr install failed — see https://herdr.dev"
  export PATH="$HOME/.local/bin:$PATH"
fi
HERDR_CFG="${HERDR_CONFIG_PATH:-$HOME/.config/herdr/config.toml}"
mkdir -p "$(dirname "$HERDR_CFG")"
if [[ -f "$HERDR_CFG" ]]; then
  cp "$HERDR_CFG" "$HERDR_CFG.bak.$TS"
  echo "Backed up: $HERDR_CFG -> $HERDR_CFG.bak.$TS"
fi
cp "$REPO_DIR/herdr/config.toml" "$HERDR_CFG"
echo "Installed: $HERDR_CFG"
command -v herdr >/dev/null 2>&1 && herdr integration install claude >/dev/null 2>&1 && echo "herdr: Claude Code integration installed"
cp "$REPO_DIR/herdr/herdr.sh" "$CLAUDE_DIR/herdr.sh"
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [[ -f "$rc" ]] && ! grep -q '.claude/herdr.sh' "$rc"; then
    printf '\n# herdr : alias claude (bypass) dans herdr + commande hr\n[ -f "$HOME/.claude/herdr.sh" ] && . "$HOME/.claude/herdr.sh"\n' >> "$rc"
    echo "Installed: herdr helpers -> $rc"
  fi
done

echo ""
echo "Done. Open a new Claude Code session to see the changes."
