# Install the fun config into %USERPROFILE%\.claude\  (Windows, PowerShell)
# - Drops the cross-platform Python scripts
# - Installs the slash commands, the PowerShell scripts (used by /terminaux) and CLAUDE.md
# - Merges settings.json (repo wins on conflicts, your machine-specific keys kept)
# Requires: Python 3 on PATH (python or py).
#
# Run from the repo folder:   powershell -ExecutionPolicy Bypass -File .\install.ps1

$ErrorActionPreference = "Stop"

$RepoDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$Ts        = Get-Date -Format "yyyyMMdd-HHmmss"

# Pick a python launcher available on PATH.
$Py = $null
foreach ($cand in @("python", "py")) {
    if (Get-Command $cand -ErrorAction SilentlyContinue) { $Py = $cand; break }
}
if (-not $Py) {
    Write-Error "Python 3 is required but not found on PATH. Install from python.org (check 'Add to PATH')."
    exit 1
}

New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null

# --- Python scripts ---
foreach ($f in @("statusline.py", "usage-refresh.py")) {
    $dest = Join-Path $ClaudeDir $f
    if (Test-Path $dest) {
        Copy-Item $dest "$dest.bak.$Ts"
        Write-Host "Backed up: $f -> $f.bak.$Ts"
    }
    Copy-Item (Join-Path $RepoDir $f) $dest -Force
    Write-Host "Installed: $dest"
}

# --- Slash commands (~\.claude\commands\) ---
$CmdDir = Join-Path $ClaudeDir "commands"
New-Item -ItemType Directory -Force -Path $CmdDir | Out-Null
Get-ChildItem (Join-Path $RepoDir "commands") -Filter *.md | ForEach-Object {
    Copy-Item $_.FullName $CmdDir -Force
    Write-Host "Installed: $(Join-Path $CmdDir $_.Name)"
}

# --- Subagents (~\.claude\agents\) ---
if (Test-Path (Join-Path $RepoDir "agents")) {
    $AgentsDir = Join-Path $ClaudeDir "agents"
    New-Item -ItemType Directory -Force -Path $AgentsDir | Out-Null
    Get-ChildItem (Join-Path $RepoDir "agents") -Filter *.md | ForEach-Object {
        Copy-Item $_.FullName $AgentsDir -Force
        Write-Host "Installed: $(Join-Path $AgentsDir $_.Name)"
    }
}

# --- PowerShell scripts (~\.claude\scripts\ ; used by /terminaux) ---
$ScriptsDir = Join-Path $ClaudeDir "scripts"
New-Item -ItemType Directory -Force -Path $ScriptsDir | Out-Null
Get-ChildItem (Join-Path $RepoDir "scripts") -Filter *.ps1 | ForEach-Object {
    Copy-Item $_.FullName $ScriptsDir -Force
    Write-Host "Installed: $(Join-Path $ScriptsDir $_.Name)"
}

# --- CLAUDE.md (global instructions; backed up) ---
$ClaudeMd = Join-Path $ClaudeDir "CLAUDE.md"
if (Test-Path $ClaudeMd) {
    Copy-Item $ClaudeMd "$ClaudeMd.bak.$Ts"
    Write-Host "Backed up: CLAUDE.md -> CLAUDE.md.bak.$Ts"
}
Copy-Item (Join-Path $RepoDir "CLAUDE.md") $ClaudeMd -Force
Write-Host "Installed: $ClaudeMd"

# --- Reference docs (bibles & principes; backed up) ---
foreach ($f in @("landing-page-bible.md", "startup-principles.md")) {
    $dest = Join-Path $ClaudeDir $f
    if (Test-Path $dest) {
        Copy-Item $dest "$dest.bak.$Ts"
        Write-Host "Backed up: $f -> $f.bak.$Ts"
    }
    Copy-Item (Join-Path $RepoDir $f) $dest -Force
    Write-Host "Installed: $dest"
}

# --- settings.json (recursive merge + Windows statusline command) ---
& $Py (Join-Path $RepoDir "apply-settings.py") $Py

Write-Host ""
Write-Host "Done. Open a new Claude Code session to see the changes."
Write-Host "Note: ANSI colors need a VT-capable terminal (Windows Terminal works)."
