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
fi

printf "\033[38;5;208m✳ %s\033[0m  ·  %s  ·  %s%s" "$MODEL" "$DIR_SHORT" "$TIME" "$CTX"
