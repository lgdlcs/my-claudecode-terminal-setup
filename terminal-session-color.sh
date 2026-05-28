#!/usr/bin/env bash
# Give each concurrent Claude session a distinct Terminal.app background color.
# Picks a palette color not already used by another live session, then applies
# it to the tab whose TTY matches this session (not just the front window).
# macOS / Terminal.app only; no-ops everywhere else.

set -u

[ "$(uname)" = "Darwin" ] || exit 0
command -v osascript >/dev/null 2>&1 || exit 0
[ "${TERM_PROGRAM:-}" = "Apple_Terminal" ] || exit 0

STATE_DIR="$HOME/.claude/session-colors"
mkdir -p "$STATE_DIR"

# Palette: 16-bit RGB triplets for AppleScript (dark tints, light text).
PALETTE=(
  "8000, 14000, 22000"   # 0 blue
  "6000, 16000, 18000"   # 1 teal
  "8000, 18000, 11000"   # 2 green
  "16000, 10000, 22000"  # 3 purple
  "22000, 9000, 12000"   # 4 red
  "22000, 15000, 7000"   # 5 amber
)
NCOLORS=${#PALETTE[@]}

# --- Find this session's controlling TTY by walking up the process tree ---
# The hook shell itself has no controlling tty; the Claude process does.
mytty=""
pid=$$
for _ in 1 2 3 4 5 6; do
  t=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
  case "$t" in
    ttys*) mytty="$t"; break ;;
  esac
  pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  { [ -z "$pid" ] || [ "$pid" = "0" ]; } && break
done
[ -n "$mytty" ] || exit 0

# --- Prune state files for tabs that are no longer open ---
open_ttys=$(osascript -e 'tell application "Terminal" to get tty of every tab of every window' 2>/dev/null \
  | tr ',' '\n' | sed 's#.*/##; s/ //g')
if [ -n "$open_ttys" ]; then
  for f in "$STATE_DIR"/ttys*; do
    [ -e "$f" ] || continue
    base=$(basename "$f")
    printf '%s\n' "$open_ttys" | grep -qx "$base" || rm -f "$f"
  done
fi

# --- Pick a color index: reuse this tty's if known, else first one not in use ---
idx=""
[ -f "$STATE_DIR/$mytty" ] && idx=$(cat "$STATE_DIR/$mytty" 2>/dev/null)
case "$idx" in ''|*[!0-9]*) idx="" ;; esac
if [ -z "$idx" ] || [ "$idx" -ge "$NCOLORS" ]; then
  used=" "
  for f in "$STATE_DIR"/ttys*; do
    [ -e "$f" ] || continue
    [ "$(basename "$f")" = "$mytty" ] && continue
    used="$used$(cat "$f" 2>/dev/null) "
  done
  idx=""
  i=0
  while [ "$i" -lt "$NCOLORS" ]; do
    case "$used" in
      *" $i "*) : ;;
      *) idx="$i"; break ;;
    esac
    i=$((i + 1))
  done
  # All colors taken by live sessions -> distribute round-robin.
  if [ -z "$idx" ]; then
    n=$(find "$STATE_DIR" -name 'ttys*' 2>/dev/null | wc -l | tr -d ' ')
    idx=$(( n % NCOLORS ))
  fi
fi
echo "$idx" > "$STATE_DIR/$mytty"
color="${PALETTE[$idx]}"

# --- Apply the color to the tab matching this session's TTY ---
osascript >/dev/null 2>&1 <<EOF || true
tell application "Terminal"
  repeat with w in windows
    repeat with t in tabs of w
      if (tty of t) is "/dev/$mytty" then
        set background color of t to {$color}
      end if
    end repeat
  end repeat
end tell
EOF
