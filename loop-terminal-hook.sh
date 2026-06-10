#!/bin/bash
# Hook UserPromptSubmit : redirige les prompts /loop vers le terminal « Claude Loops ».
# La session qui tourne DANS ce terminal a CLAUDE_LOOP_TERMINAL=1 : on la laisse
# traiter ses /loop normalement (sinon boucle infinie de redirection).
[ -n "${CLAUDE_LOOP_TERMINAL:-}" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
prompt=$(printf '%s' "$input" | jq -r '.prompt // empty')
case "$prompt" in
  "/loop" | "/loop "*) ;;
  *) exit 0 ;;
esac

cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[ -n "$cwd" ] || cwd="$HOME"

if bash "$HOME/.claude/loop-terminal.sh" "$prompt" "$cwd" >/dev/null 2>&1; then
  jq -n --arg r "↪ Loop envoyé dans le terminal « Claude Loops » : $prompt" \
    '{decision: "block", reason: $r}'
else
  jq -n '{systemMessage: "⚠️ Échec d’ouverture du terminal « Claude Loops » — le loop tourne dans cette session."}'
fi
