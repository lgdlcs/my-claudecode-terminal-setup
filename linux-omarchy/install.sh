#!/usr/bin/env bash
# Install the Linux / Omarchy machine config: Claude Code settings + theme + MCP,
# pstack plugin, herdr config, Super+F2 binding and the herdr-only bypass alias.
# Every overwritten file is backed up with a timestamp suffix.

set -e

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TS=$(date +%Y%m%d-%H%M%S)

backup() { [[ -f "$1" ]] && cp "$1" "$1.bak.$TS" && echo "Backed up: $1 -> $1.bak.$TS"; return 0; }

# --- Claude Code: settings (merged, repo wins) + theme ---
mkdir -p "$HOME/.claude/themes"
backup "$HOME/.claude/settings.json"
python3 - "$DIR/claude/settings.json" "$HOME/.claude/settings.json" "$HOME" <<'PY'
import json, os, sys
src, dst, home = sys.argv[1:]
repo = json.loads(open(src).read().replace("__HOME__", home))
cur = json.load(open(dst)) if os.path.exists(dst) else {}
def merge(a, b):
    for k, v in b.items():
        a[k] = merge(a.get(k, {}), v) if isinstance(v, dict) and isinstance(a.get(k), dict) else v
    return a
json.dump(merge(cur, repo), open(dst, "w"), indent=2)
PY
echo "Merged: ~/.claude/settings.json"
cp "$DIR/claude/themes/omarchy.json" "$HOME/.claude/themes/"
echo "Installed: ~/.claude/themes/omarchy.json"

# --- Claude Code: user-scope MCP servers ---
if command -v claude >/dev/null 2>&1; then
  python3 -c "import json,sys;[print(n,s['type'],s['url']) for n,s in json.load(open(sys.argv[1]))['mcpServers'].items()]" "$DIR/claude/mcp-servers.json" |
  while read -r name type url; do
    claude mcp add --scope user --transport "$type" "$name" "$url" 2>/dev/null && echo "MCP added: $name" || echo "MCP present: $name"
  done
fi

# --- pstack (local plugin marketplace, from cursor/plugins) ---
if [[ ! -d "$HOME/.claude/local-plugins/pstack" ]]; then
  tmp=$(mktemp -d)
  git clone -q --depth 1 https://github.com/cursor/plugins.git "$tmp"
  mkdir -p "$HOME/.claude/local-plugins"
  cp -r "$tmp/pstack" "$HOME/.claude/local-plugins/"
  rm -rf "$tmp"
  # Upstream only ships a Cursor manifest; add the Claude Code marketplace + plugin manifests
  cp -r "$DIR/claude/local-plugins/." "$HOME/.claude/local-plugins/"
  echo "Installed: ~/.claude/local-plugins/pstack"
fi

# --- herdr ---
mkdir -p "$HOME/.config/herdr"
backup "$HOME/.config/herdr/config.toml"
cp "$DIR/herdr/config.toml" "$HOME/.config/herdr/config.toml"
echo "Installed: ~/.config/herdr/config.toml"

# --- Hyprland: Super+F2 -> herdr ---
B="$HOME/.config/hypr/bindings.lua"
if [[ -f "$B" ]]; then
  backup "$B"
  sed -i '/"SUPER + F2"/d' "$B"
  tail -n 1 "$DIR/hypr/bindings-herdr.lua" >> "$B"
  echo "Bound: Super+F2 -> herdr"
  hyprctl reload >/dev/null 2>&1 || true
fi

# --- bash: bypass-permissions alias inside herdr only ---
if ! grep -q 'HERDR_ENV' "$HOME/.bashrc" 2>/dev/null; then
  { echo; cat "$DIR/shell/herdr-claude.bash"; } >> "$HOME/.bashrc"
  echo "Added: herdr-only claude alias to ~/.bashrc"
fi

echo "Done. Open a new terminal (or Super+F2) to pick up the changes."
