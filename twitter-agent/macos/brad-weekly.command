#!/bin/zsh
# Brad — récap hebdo GitHub (régularité + commitment). Lancé le dimanche par launchd com.alttab.brad-weekly.
# Calcule les stats EN LOCAL (pas de navigateur) puis fait rédiger le tweet du lundi par Brad.
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
DIR="$HOME/.claude/twitter-agent"
DATE=$(TZ=Europe/Paris date '+%Y-%m-%d')
OUT="$DIR/weekly-stats/$DATE.md"
ERR="$DIR/brad-weekly.err"
mkdir -p "$DIR/weekly-stats"
[ -f "$DIR/PAUSED" ] && { echo "$(date) PAUSED" >> "$ERR"; exit 0; }

# --- Calcul des stats sur ~/code (commits semaine, streak, LOC) ---
STATS=$(python3 <<'PY'
import os, subprocess, datetime, glob
home=os.path.expanduser('~'); code=os.path.join(home,'code')
repos=set()
for pat in ('*/.git','*/*/.git'):
    for p in glob.glob(os.path.join(code,pat)):
        repos.add(os.path.dirname(p))
today=datetime.date.today()
commit_days=set(); commits_week=0; ins=0; dele=0
def run(args,r):
    try: return subprocess.run(['git','-C',r]+args,capture_output=True,text=True,timeout=25).stdout
    except Exception: return ''
for r in sorted(repos):
    for line in run(['log','--since','160 days ago','--pretty=%cd','--date=short'],r).splitlines():
        try: commit_days.add(datetime.date.fromisoformat(line.strip()))
        except Exception: pass
    commits_week+=len([l for l in run(['log','--since','7 days ago','--oneline'],r).splitlines() if l.strip()])
    for line in run(['log','--since','7 days ago','--numstat','--pretty=tformat:'],r).splitlines():
        parts=line.split('\t')
        if len(parts)==3:
            a,d_=parts[0],parts[1]
            if a.isdigit(): ins+=int(a)
            if d_.isdigit(): dele+=int(d_)
streak=0
cur=today if today in commit_days else today-datetime.timedelta(days=1)
while cur in commit_days:
    streak+=1; cur-=datetime.timedelta(days=1)
print(f"COMMITS_WEEK={commits_week}")
print(f"STREAK_DAYS={streak}")
print(f"LOC_ADDED={ins}")
print(f"LOC_REMOVED={dele}")
print(f"ACTIVE_REPOS={len(repos)}")
PY
)
echo "$(date) $STATS" >> "$ERR"

PROMPT="Tu es Brad, le CM Twitter de Lucas (build in public, @lgrdlcs). Rédige le TWEET HEBDO de régularité, destiné à être posté LUNDI matin.
Stats GitHub de la semaine (calculées en local) :
$STATS

Brief :
- Le message central = RÉGULARITÉ et COMMITMENT (montrer qu'on shippe tous les jours), PAS la performance brute.
- Mets en avant la streak (jours enchaînés) et le nombre de commits de la semaine.
- Mentionne les LOC mais MOQUE-TOI-EN explicitement : à l'ère de l'IA, le nombre de lignes ne veut plus rien dire. C'est un clin d'oeil, pas une fierté.
- Voix Brad : direct, sans bullshit, honnête, hook en 1ère ligne, ≤280 caractères, pas de tiret cadratin, ≤1 hashtag.
- Visuel = le graphe de contributions GitHub (à attacher au moment de poster).
Lis ~/.claude/twitter-agent/strategy.md et context.md pour la voix.
Sors UNIQUEMENT, en markdown : le texte exact du tweet, puis 'Visuel :', '**Pourquoi :**', '**Succès =**'. Aucun préambule."

claude -p "$PROMPT" --permission-mode bypassPermissions > "$OUT" 2>>"$ERR"

if [ -s "$OUT" ]; then
  command -v code >/dev/null 2>&1 && code "$OUT" || open "$OUT"
  osascript -e 'display notification "Récap hebdo prêt (à poster lundi ~11h)" with title "Brad — stats GitHub"' 2>/dev/null
else
  echo "$(date) sortie vide" >> "$ERR"
  osascript -e 'display notification "Echec récap hebdo (voir brad-weekly.err)" with title "Brad — stats GitHub"' 2>/dev/null
fi
