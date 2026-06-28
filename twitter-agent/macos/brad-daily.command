#!/bin/zsh
# Brad — proposition Twitter quotidienne (background, lancé par launchd com.alttab.brad-daily).
# Génère 3 propositions de tweets pour aujourd'hui, sans toucher au navigateur (pas de post auto).
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
DIR="$HOME/.claude/twitter-agent"
DATE=$(TZ=Europe/Paris date '+%Y-%m-%d')
OUT="$DIR/daily-proposals/$DATE.md"
ERR="$DIR/brad-daily.err"
mkdir -p "$DIR/daily-proposals"

# Kill switch global
if [ -f "$DIR/PAUSED" ]; then
  echo "$(date) PAUSED, run annulé" >> "$ERR"
  exit 0
fi

# Activité récente : commits des 2 derniers jours dans ~/code (borné)
DIGEST=$(find "$HOME/code" -maxdepth 2 -name .git -type d 2>/dev/null | while read -r g; do
  repo=$(dirname "$g"); name=$(basename "$repo")
  log=$(git -C "$repo" log --since="2 days ago" --pretty=format:"- %s" 2>/dev/null | head -6)
  [ -n "$log" ] && printf '### %s\n%s\n' "$name" "$log"
done | head -120)
[ -z "$DIGEST" ] && DIGEST="(aucun commit récent détecté dans ~/code)"

PROMPT="Tu es Brad, le CM Twitter de Lucas (build in public, @lgrdlcs). Exécute ton MODE 1 (proposition quotidienne).
Lis ~/.claude/agents/brad.md, ~/.claude/twitter-agent/strategy.md et ~/.claude/twitter-agent/context.md.
Activité récente de Lucas (git, 2 derniers jours) :
$DIGEST

Produis EXACTEMENT 3 propositions de tweets pour aujourd'hui ($DATE), au format markdown de ton MODE 1 (titre + pilier, texte du tweet, visuel suggéré, **Pourquoi**, **Succès =**), puis la reco du jour.
Chaque tweet : direct, sans bullshit, honnête (victoires ET défaites), ≤280 caractères, hook en 1ère ligne, aucun chiffre inventé, pas de tiret cadratin.
N'utilise PAS le navigateur, ne poste rien. Sors UNIQUEMENT le markdown des 3 propositions, sans préambule ni conclusion hors format."

# Génération headless (lecture seule des fichiers de contexte)
claude -p "$PROMPT" --permission-mode bypassPermissions > "$OUT" 2>>"$ERR"

if [ -s "$OUT" ]; then
  command -v code >/dev/null 2>&1 && code "$OUT" || open "$OUT"
  osascript -e 'display notification "3 propositions de tweets prêtes" with title "Brad — com Twitter"' 2>/dev/null
else
  echo "$(date) sortie vide, voir $ERR" >> "$ERR"
  osascript -e 'display notification "Echec génération (voir brad-daily.err)" with title "Brad — com Twitter"' 2>/dev/null
fi
