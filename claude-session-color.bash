# Distinct Terminal color per concurrent Claude session — Windows (Git Bash).
#
# Why a wrapper and not a hook? Claude Code runs hooks detached from the
# terminal (no controlling tty), so a hook cannot emit the OSC color escape.
# macOS works around this with AppleScript driving Terminal.app; mintty /
# Windows Terminal have no such external control. A `claude` shell function,
# however, runs in the live shell and CAN write OSC 11 to the terminal.
#
# Enable it by adding this line to ~/.bashrc (Git Bash):
#   source ~/.claude/claude-session-color.bash
#
# macOS is handled by the SessionStart hook instead, so this only tints on
# Git Bash / Cygwin (mintty and Windows Terminal both support OSC 11).

claude() {
  case "${OSTYPE:-}" in
    msys*|cygwin*) ;;
    *) command claude "$@"; return $? ;;
  esac

  local state_dir="$HOME/.claude/session-colors"
  mkdir -p "$state_dir"

  # 8-bit hex palette (same hues as the macOS hook): blue teal green purple red amber
  local palette=(1F3656 173E46 1F462B 3E2756 56232F 563A1B)
  local ncolors=${#palette[@]}
  local f base used=" " idx="" i=0

  # Drop state files whose owning shell is no longer alive.
  for f in "$state_dir"/win-*; do
    [ -e "$f" ] || continue
    base=$(basename "$f"); base=${base#win-}
    kill -0 "$base" 2>/dev/null || rm -f "$f"
  done

  # First color not in use by another live session.
  for f in "$state_dir"/win-*; do
    [ -e "$f" ] || continue
    [ "$(basename "$f")" = "win-$$" ] && continue
    used="$used$(cat "$f" 2>/dev/null) "
  done
  while [ "$i" -lt "$ncolors" ]; do
    case "$used" in
      *" $i "*) : ;;
      *) idx="$i"; break ;;
    esac
    i=$((i + 1))
  done
  [ -z "$idx" ] && idx=$(( $$ % ncolors ))   # all taken -> round-robin

  echo "$idx" > "$state_dir/win-$$"
  printf '\033]11;#%s\a' "${palette[$idx]}" > /dev/tty 2>/dev/null

  command claude "$@"
  local rc=$?
  rm -f "$state_dir/win-$$"   # free the color (the tint stays until the window closes)
  return $rc
}
