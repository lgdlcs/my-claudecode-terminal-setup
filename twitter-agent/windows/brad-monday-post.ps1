# Brad — auto-post du récap hebdo le lundi (Windows). Equivalent de brad-monday-post.command.
# Test A/B 2 créneaux : semaine ISO paire -> 11h (slot A) ; impaire -> 17h (slot B). 1 post/semaine.
# Best-effort, non testé sur Windows (dépend de l'auto-post navigateur via Playwright MCP).
$ErrorActionPreference = "SilentlyContinue"
$dir = Join-Path $env:USERPROFILE ".claude\twitter-agent"
$err = Join-Path $dir "brad-monday.err"
if (Test-Path (Join-Path $dir "PAUSED")) { Add-Content $err "$(Get-Date) PAUSED"; exit 0 }

$cal = [System.Globalization.CultureInfo]::InvariantCulture.Calendar
$week = $cal.GetWeekOfYear((Get-Date), [System.Globalization.CalendarWeekRule]::FirstFourDayWeek, [System.DayOfWeek]::Monday)
$hour = [int](Get-Date -Format "HH")
$target = if ($week % 2 -eq 0) { 11 } else { 17 }
if ($hour -ne $target) { Add-Content $err "$(Get-Date) pas le créneau (h=$hour cible=$target semaine=$week)"; exit 0 }
Add-Content $err "$(Get-Date) créneau OK (h=$hour semaine=$week slot $target h)"

# Sérialisation
$busy = Join-Path $dir ".browser-busy"
if (Test-Path $busy) {
    $lines = Get-Content $busy
    $bpid = [int]$lines[0]; $bts = [int]$lines[1]; $now = [int][double]::Parse((Get-Date -UFormat %s))
    if ((Get-Process -Id $bpid -ErrorAction SilentlyContinue) -and (($now - $bts) -lt 900)) {
        Add-Content $err "$(Get-Date) run navigateur Brad déjà en cours (pid $bpid), abandon"; exit 0
    }
}
Set-Content $busy @($PID, [int][double]::Parse((Get-Date -UFormat %s)))

# Pré-vol navigateur
& powershell -ExecutionPolicy Bypass -File (Join-Path $dir "brad-browser-prep.ps1") 2>> $err

$prompt = @"
Tu es Brad (MODE 2). Poste le TWEET HEBDO de régularité sur @lgrdlcs, en ANGLAIS (langue par défaut = EN dans context.md).
Créneau de test de cette semaine : ${target}h (note-le dans le journal pour comparer le reach des 2 créneaux).
1. Lis le fichier le plus récent de ~/.claude/twitter-agent/weekly-stats/ (3 derniers jours). Prends le texte du tweet (avant 'Visuel :'). S'il est en français, traduis-le en anglais naturel. S'il manque, calcule les stats toi-même.
2. Capture le graphe de contributions de https://github.com/lgdlcs (.js-yearly-contributions) en image.
3. Poste le tweet + image via Playwright. Récupère l'URL, journalise dans log.md (avec le créneau).
Si la session X n'est pas connectée OU si Playwright échoue (pré-vol + 1 relance) : n'insiste pas, écris le tweet prêt dans ~/.claude/twitter-agent/weekly-stats/TO_POST.md et signale l'échec.
"@
claude -p $prompt --permission-mode bypassPermissions 2>> $err | Out-File -Append (Join-Path $dir "brad-monday.out")

Remove-Item $busy -Force -ErrorAction SilentlyContinue
if (Test-Path (Join-Path $dir "weekly-stats\TO_POST.md")) {
    if (Get-Command code -ErrorAction SilentlyContinue) { code (Join-Path $dir "weekly-stats\TO_POST.md") }
}
