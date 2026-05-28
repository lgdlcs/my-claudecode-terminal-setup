#!/usr/bin/env bash
# Rafraîchit le cache d'utilisation du forfait (fenêtres 5h / 7j).
# Appelé en arrière-plan par statusline.sh. Écrit ~/.claude/usage-cache.json.
# Lit les en-têtes anthropic-ratelimit-unified-* via un appel /v1/messages minimal.

CLAUDE_DIR="$HOME/.claude"
CACHE="$CLAUDE_DIR/usage-cache.json"
LOCK="$CLAUDE_DIR/.usage-refresh.lock"

# Lock anti-stampede : un seul refresh à la fois. Lock périmé (>60s) => on le casse.
if [ -d "$LOCK" ]; then
  if [ -n "$(find "$LOCK" -prune -mmin +1 2>/dev/null)" ]; then
    rmdir "$LOCK" 2>/dev/null
  else
    exit 0
  fi
fi
mkdir "$LOCK" 2>/dev/null || exit 0
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

# Token OAuth : .credentials.json puis keychain en repli.
TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' "$CLAUDE_DIR/.credentials.json" 2>/dev/null)
if [ -z "$TOKEN" ]; then
  TOKEN=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
            | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
fi
[ -z "$TOKEN" ] && exit 0

HEADERS=$(curl -s --max-time 10 -D - -o /dev/null https://api.anthropic.com/v1/messages \
  -H "authorization: Bearer $TOKEN" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: oauth-2025-04-20" \
  -H "content-type: application/json" \
  -d '{"model":"claude-haiku-4-5-20251001","max_tokens":1,"messages":[{"role":"user","content":"."}]}' \
  2>/dev/null)

[ -z "$HEADERS" ] && exit 0

get() { echo "$HEADERS" | grep -i "^$1:" | tail -1 | sed -E 's/^[^:]+:[[:space:]]*//; s/[[:space:]]*$//' | tr -d '\r'; }

H5U=$(get 'anthropic-ratelimit-unified-5h-utilization')
H5R=$(get 'anthropic-ratelimit-unified-5h-reset')
D7U=$(get 'anthropic-ratelimit-unified-7d-utilization')
D7R=$(get 'anthropic-ratelimit-unified-7d-reset')
STATUS=$(get 'anthropic-ratelimit-unified-status')

# Si l'appel n'a pas renvoyé l'utilisation (401, quota épuisé, etc.), on garde l'ancien cache.
[ -z "$H5U" ] && exit 0

NOW=$(date +%s)
TMP="$CACHE.tmp.$$"
cat > "$TMP" <<EOF
{"fetched_at":$NOW,"h5_util":${H5U:-0},"h5_reset":${H5R:-0},"d7_util":${D7U:-0},"d7_reset":${D7R:-0},"status":"${STATUS:-unknown}"}
EOF
mv "$TMP" "$CACHE" 2>/dev/null
