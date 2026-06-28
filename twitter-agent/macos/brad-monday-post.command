#!/bin/zsh
# Brad — auto-post du récap hebdo le lundi, avec test A/B de 2 créneaux.
# Lancé par launchd com.alttab.brad-monday-post à 11h ET 17h ; ne poste qu'au créneau désigné de la semaine.
# Semaine ISO paire -> 11h (slot A) ; impaire -> 17h (slot B). 1 seul post/semaine, alternance => données comparables.
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
DIR="$HOME/.claude/twitter-agent"
ERR="$DIR/brad-monday.err"
[ -f "$DIR/PAUSED" ] && { echo "$(date) PAUSED" >> "$ERR"; exit 0; }

WEEK=$(TZ=Europe/Paris date '+%V'); HOUR=$(TZ=Europe/Paris date '+%H')
if [ $((10#$WEEK % 2)) -eq 0 ]; then TARGET=11; else TARGET=17; fi
if [ "$((10#$HOUR))" -ne "$TARGET" ]; then
  echo "$(date) pas le créneau (h=$HOUR, cible=$TARGET, semaine=$WEEK)" >> "$ERR"; exit 0
fi
echo "$(date) créneau OK (h=$HOUR, semaine=$WEEK, slot $([ $TARGET -eq 11 ] && echo A/11h || echo B/17h))" >> "$ERR"

# Sérialisation : ne pas lancer si un autre run navigateur Brad est déjà en cours (frais < 15 min)
BUSY="$DIR/.browser-busy"
if [ -f "$BUSY" ]; then
  bpid=$(sed -n '1p' "$BUSY"); bts=$(sed -n '2p' "$BUSY"); now=$(date +%s)
  if [ -n "$bpid" ] && kill -0 "$bpid" 2>/dev/null && [ -n "$bts" ] && [ $((now - bts)) -lt 900 ]; then
    echo "$(date) run navigateur Brad déjà en cours (pid $bpid), abandon" >> "$ERR"; exit 0
  fi
fi
echo "$$" > "$BUSY"; date +%s >> "$BUSY"
trap 'rm -f "$BUSY"' EXIT

# Pré-vol navigateur : libérer le profil Playwright (verrous périmés, orphelins)
/bin/zsh "$DIR/brad-browser-prep.sh" >> "$ERR" 2>&1

PROMPT="Tu es Brad (MODE 2 de ~/.claude/agents/brad.md). Poste le TWEET HEBDO de régularité sur @lgrdlcs, en ANGLAIS (langue par défaut = EN dans context.md).
Créneau de test de cette semaine : ${TARGET}h (note-le dans le journal pour comparer le reach des 2 créneaux plus tard).
Étapes :
1. Lis le fichier le plus récent de ~/.claude/twitter-agent/weekly-stats/ (3 derniers jours). Prends le texte du tweet (avant la ligne 'Visuel :'). S'il est en français, traduis-le en anglais naturel dans la voix Brad. S'il manque, calcule toi-même les stats de la semaine (commits, streak de jours, LOC en t'en moquant) et rédige-le.
2. Capture le graphe de contributions de https://github.com/lgdlcs (élément .js-yearly-contributions) en image.
3. Poste le tweet + image via Playwright (compose/post ; [role=dialog] tweetTextarea_0 ; attache l'image pendant que le tweet est actif ; [role=dialog] tweetButton). Vérifie connecté avant.
4. Récupère l'URL sur /lgrdlcs, journalise dans log.md (avec le créneau ${TARGET}h).
Si la session X n'est pas connectée OU si Playwright échoue (nettoie le verrou mcp-chrome + 1 relance, pas plus) : N'INSISTE PAS. Écris le tweet final prêt-à-poster (EN) dans ~/.claude/twitter-agent/weekly-stats/TO_POST.md et termine en signalant l'échec.
Respecte les garde-fous. Sors un court compte-rendu (posté / fallback)."

claude -p "$PROMPT" --permission-mode bypassPermissions >> "$DIR/brad-monday.out" 2>>"$ERR"

if [ -f "$DIR/weekly-stats/TO_POST.md" ]; then
  command -v code >/dev/null 2>&1 && code "$DIR/weekly-stats/TO_POST.md"
  osascript -e 'display notification "Auto-post échoué — tweet prêt dans TO_POST.md, à poster à la main" with title "Brad — post lundi"' 2>/dev/null
else
  osascript -e 'display notification "Récap hebdo posté (vérifie le journal/profil)" with title "Brad — post lundi"' 2>/dev/null
fi
