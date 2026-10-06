# herdr helpers for bash / zsh — sourced from ~/.bashrc or ~/.zshrc by install.sh

# Inside herdr, Claude Code starts without permission prompts
if [ "${HERDR_ENV:-}" = 1 ]; then
  alias claude='claude --dangerously-skip-permissions'
fi

# hr                   -> local herdr session (or $HERDR_HOST's when set)
# hr <host> [session]  -> attach over SSH to the herdr session running on <host>
hr() {
  local host="${1:-${HERDR_HOST:-}}"
  if [ -z "$host" ]; then
    herdr
  elif [ -n "${2:-}" ]; then
    herdr --remote "$host" --session "$2"
  else
    herdr --remote "$host"
  fi
}
