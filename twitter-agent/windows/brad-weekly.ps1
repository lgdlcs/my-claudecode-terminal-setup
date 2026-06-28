# Brad — récap hebdo GitHub (Windows). Equivalent de brad-weekly.command.
# Calcule les stats en local (pas de navigateur) puis fait rédiger le tweet du lundi par Brad.
$ErrorActionPreference = "SilentlyContinue"
$dir  = Join-Path $env:USERPROFILE ".claude\twitter-agent"
$date = Get-Date -Format "yyyy-MM-dd"
$out  = Join-Path $dir "weekly-stats\$date.md"
$err  = Join-Path $dir "brad-weekly.err"
New-Item -ItemType Directory -Force -Path (Join-Path $dir "weekly-stats") | Out-Null
if (Test-Path (Join-Path $dir "PAUSED")) { Add-Content $err "$(Get-Date) PAUSED"; exit 0 }

# --- Stats sur ~\code (commits semaine, streak, LOC) ---
$code = Join-Path $env:USERPROFILE "code"
$commitDays = @{}; $commitsWeek = 0; $ins = 0; $del = 0
if (Test-Path $code) {
    Get-ChildItem $code -Directory | ForEach-Object {
        $repo = $_.FullName
        if (-not (Test-Path (Join-Path $repo ".git"))) { return }
        git -C $repo log --since="160 days ago" --pretty="%cd" --date=short 2>$null | ForEach-Object { if ($_) { $commitDays[$_] = $true } }
        $commitsWeek += (git -C $repo log --since="7 days ago" --oneline 2>$null | Measure-Object -Line).Lines
        git -C $repo log --since="7 days ago" --numstat --pretty="tformat:" 2>$null | ForEach-Object {
            $p = $_ -split "`t"
            if ($p.Count -eq 3) {
                if ($p[0] -match '^\d+$') { $ins += [int]$p[0] }
                if ($p[1] -match '^\d+$') { $del += [int]$p[1] }
            }
        }
    }
}
$streak = 0; $cur = (Get-Date).Date
if (-not $commitDays.ContainsKey($cur.ToString("yyyy-MM-dd"))) { $cur = $cur.AddDays(-1) }
while ($commitDays.ContainsKey($cur.ToString("yyyy-MM-dd"))) { $streak++; $cur = $cur.AddDays(-1) }
$stats = "COMMITS_WEEK=$commitsWeek`nSTREAK_DAYS=$streak`nLOC_ADDED=$ins`nLOC_REMOVED=$del"
Add-Content $err "$(Get-Date) $stats"

$prompt = @"
Tu es Brad, le CM Twitter de Lucas (build in public, @lgrdlcs). Rédige le TWEET HEBDO de régularité, destiné à être posté LUNDI matin.
Stats GitHub de la semaine (calculées en local) :
$stats

Brief :
- Le message central = REGULARITE et COMMITMENT (montrer qu'on shippe tous les jours), PAS la performance brute.
- Mets en avant la streak (jours enchaînés) et le nombre de commits de la semaine.
- Mentionne les LOC mais MOQUE-TOI-EN explicitement : à l'ère de l'IA le nombre de lignes ne veut plus rien dire. Clin d'oeil, pas une fierté.
- Voix Brad : direct, sans bullshit, honnête, hook en 1ère ligne, <=280 caractères, pas de tiret cadratin, <=1 hashtag.
- Visuel = le graphe de contributions GitHub (à attacher au moment de poster).
Lis ~/.claude/twitter-agent/strategy.md et context.md pour la voix et la langue par défaut.
Sors UNIQUEMENT, en markdown : le texte exact du tweet, puis 'Visuel :', '**Pourquoi :**', '**Succès =**'. Aucun préambule.
"@

claude -p $prompt --permission-mode bypassPermissions > $out 2>> $err

if ((Test-Path $out) -and (Get-Item $out).Length -gt 0) {
    if (Get-Command code -ErrorAction SilentlyContinue) { code $out } else { Invoke-Item $out }
} else {
    Add-Content $err "$(Get-Date) sortie vide"
}
