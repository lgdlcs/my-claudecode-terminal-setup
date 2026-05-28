#!/usr/bin/env bash
# Cross-platform statusline for Claude Code.
# Reads session JSON on stdin, prints: ✳ Model · dir · HH:MM · NN% ctx

INPUT=$(cat)
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // .model.id // "claude"')
DIR=$(echo "$INPUT" | jq -r '.workspace.current_dir // .cwd // empty' | sed "s|^$HOME|~|")
DIR_SHORT=$(basename "$DIR")
TIME=$(date "+%H:%M")

TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
CTX=""
if [[ -n "$TRANSCRIPT" && -f "$TRANSCRIPT" ]]; then
  if command -v tac >/dev/null 2>&1; then
    REV="tac"
  else
    REV="tail -r"
  fi
  TOKENS=$($REV "$TRANSCRIPT" 2>/dev/null | jq -rs '[.[] | select(.message.usage)] | first | .message.usage | (.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)' 2>/dev/null)
  if [[ -n "$TOKENS" && "$TOKENS" != "null" && "$TOKENS" -gt 0 ]]; then
    PCT=$((TOKENS * 100 / 200000))
    CTX="  ·  ${PCT}% ctx"
  fi
  if [[ -n "$TOKENS" && "$TOKENS" != "null" && "$TOKENS" -gt 0 ]]; then
    PCT=$((TOKENS * 100 / 200000))
    if   (( PCT < 40 )); then EMOJI="🧠"; LABEL="chill";    COLOR="\033[32m"          # vert
    elif (( PCT < 70 )); then EMOJI="🤔"; LABEL="thinking"; COLOR="\033[33m"          # jaune
    elif (( PCT < 90 )); then EMOJI="🥵"; LABEL="hot";      COLOR="\033[38;5;208m"    # orange
    else                      EMOJI="🤯"; LABEL="melting";  COLOR="\033[31m"          # rouge
    fi
    CTX=$(printf "  ·  %s ${COLOR}%d%% %s\033[0m" "$EMOJI" "$PCT" "$LABEL")
  fi
fi

# ── Utilisation du forfait (fenêtres 5h / 7j), depuis le cache ──────────────
USAGE=""
CACHEF="$HOME/.claude/usage-cache.json"
TTL=180
NOWU=$(date +%s)
FETCHED=0
if [[ -f "$CACHEF" ]]; then
  read -r H5U H5R FETCHED < <(jq -r '"\(.h5_util) \(.h5_reset) \(.fetched_at)"' "$CACHEF" 2>/dev/null)
  if [[ -n "$H5U" && "$H5U" != "null" ]]; then
    PCT5=$(awk -v u="$H5U" 'BEGIN{printf "%d", u*100+0.5}')
    REM=$(( H5R - NOWU ))
    if (( REM > 0 )); then CD=$(printf "%dh%02d" $((REM/3600)) $(((REM%3600)/60))); else CD="reset!"; fi
    # mini-jauge 8 segments + emoji/label qui montent en température
    FILLED=$(awk -v u="$H5U" 'BEGIN{f=int(u*8+0.5); if(f>8)f=8; if(f<0)f=0; print f}')
    BAR=""; for ((i=0;i<8;i++)); do (( i<FILLED )) && BAR+="▰" || BAR+="▱"; done
    if   (( PCT5 < 50 )); then UCOL="\033[32m";       UEMO="🚀"; ULAB="cruise"
    elif (( PCT5 < 75 )); then UCOL="\033[33m";       UEMO="🔥"; ULAB="warm"
    elif (( PCT5 < 90 )); then UCOL="\033[38;5;208m"; UEMO="🥵"; ULAB="danger"
    else                       UCOL="\033[31m";       UEMO="🚨"; ULAB="MAX!"
    fi
    USAGE=$(printf "  ·  %s ${UCOL}%s %d%% %s\033[0m \033[2m⏳%s\033[0m" "$UEMO" "$BAR" "$PCT5" "$ULAB" "$CD")
  fi
fi
# Rafraîchissement en arrière-plan si cache absent ou périmé (non bloquant).
if [[ ! -f "$CACHEF" ]] || (( NOWU - FETCHED > TTL )); then
  nohup "$HOME/.claude/usage-refresh.sh" >/dev/null 2>&1 &
fi

printf "\033[38;5;208m✳ %s\033[0m  ·  %s  ·  %s%s%s" "$MODEL" "$DIR_SHORT" "$TIME" "$CTX" "$USAGE"



