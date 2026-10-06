# Dans herdr, Claude Code démarre sans demandes de permission
if [ "${HERDR_ENV:-}" = 1 ]; then
  alias claude='claude --dangerously-skip-permissions'
fi
