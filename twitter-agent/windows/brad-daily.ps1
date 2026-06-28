# Brad — proposition Twitter quotidienne (Windows). Equivalent de brad-daily.command.
# Génère 3 propositions de tweets pour aujourd'hui (pas de navigateur, pas de post auto).
$ErrorActionPreference = "SilentlyContinue"
$dir  = Join-Path $env:USERPROFILE ".claude\twitter-agent"
$date = Get-Date -Format "yyyy-MM-dd"
$out  = Join-Path $dir "daily-proposals\$date.md"
$err  = Join-Path $dir "brad-daily.err"
New-Item -ItemType Directory -Force -Path (Join-Path $dir "daily-proposals") | Out-Null
if (Test-Path (Join-Path $dir "PAUSED")) { Add-Content $err "$(Get-Date) PAUSED"; exit 0 }

# Activité récente : commits des 2 derniers jours dans ~\code (borné).
$code = Join-Path $env:USERPROFILE "code"
$digest = ""
if (Test-Path $code) {
    Get-ChildItem $code -Directory | ForEach-Object {
        $repo = $_.FullName
        if (Test-Path (Join-Path $repo ".git")) {
            $log = (git -C $repo log --since="2 days ago" --pretty="- %s" 2>$null | Select-Object -First 6) -join "`n"
            if ($log) { $digest += "### $($_.Name)`n$log`n" }
        }
    }
}
if (-not $digest) { $digest = "(aucun commit récent détecté dans ~\code)" }

$prompt = @"
Tu es Brad, le CM Twitter de Lucas (build in public, @lgrdlcs). Exécute ton MODE 1 (proposition quotidienne).
Lis ~/.claude/agents/brad.md, ~/.claude/twitter-agent/strategy.md et ~/.claude/twitter-agent/context.md.
Activité récente de Lucas (git, 2 derniers jours) :
$digest

Produis EXACTEMENT 3 propositions de tweets pour aujourd'hui ($date), au format markdown de ton MODE 1 (titre + pilier, texte du tweet, visuel suggéré, **Pourquoi**, **Succès =**), puis la reco du jour.
Chaque tweet : direct, sans bullshit, honnête (victoires ET défaites), <=280 caractères, hook en 1ère ligne, aucun chiffre inventé, pas de tiret cadratin.
N'utilise PAS le navigateur, ne poste rien. Sors UNIQUEMENT le markdown des 3 propositions, sans préambule.
"@

claude -p $prompt --permission-mode bypassPermissions > $out 2>> $err

if ((Test-Path $out) -and (Get-Item $out).Length -gt 0) {
    if (Get-Command code -ErrorAction SilentlyContinue) { code $out } else { Invoke-Item $out }
} else {
    Add-Content $err "$(Get-Date) sortie vide"
}
