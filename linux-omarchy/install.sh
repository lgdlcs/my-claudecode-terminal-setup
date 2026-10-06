#!/usr/bin/env bash
# Omarchy-only extras, on top of the shared ../install.sh (Claude Code + herdr):
# Claude Code color theme and the Super+F2 binding that opens herdr.

set -e

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TS=$(date +%Y%m%d-%H%M%S)

# --- Claude Code: Omarchy color theme ---
mkdir -p "$HOME/.claude/themes"
cp "$DIR/themes/omarchy.json" "$HOME/.claude/themes/"
echo "Installed: ~/.claude/themes/omarchy.json"

# --- Hyprland: Super+F2 -> herdr ---
B="$HOME/.config/hypr/bindings.lua"
if [[ -f "$B" ]]; then
  cp "$B" "$B.bak.$TS"
  sed -i '/"SUPER + F2"/d' "$B"
  tail -n 1 "$DIR/hypr/bindings-herdr.lua" >> "$B"
  echo "Bound: Super+F2 -> herdr"
  hyprctl reload >/dev/null 2>&1 || true
fi
