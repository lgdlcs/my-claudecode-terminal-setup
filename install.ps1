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

# --- Hooks (~\.claude\hooks\) ---
if (Test-Path (Join-Path $RepoDir "hooks")) {
    $HooksDir = Join-Path $ClaudeDir "hooks"
    New-Item -ItemType Directory -Force -Path $HooksDir | Out-Null
    Get-ChildItem (Join-Path $RepoDir "hooks") -File | ForEach-Object {
        Copy-Item $_.FullName $HooksDir -Force
        Write-Host "Installed: $(Join-Path $HooksDir $_.Name)"
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

# --- pstack plugin (local marketplace; upstream only ships a Cursor manifest) ---
$LocalPlugins = Join-Path $ClaudeDir "local-plugins"
New-Item -ItemType Directory -Force -Path $LocalPlugins | Out-Null
if (-not (Test-Path (Join-Path $LocalPlugins "pstack\skills"))) {
    $tmp = Join-Path ([IO.Path]::GetTempPath()) "cursor-plugins-$Ts"
    git clone -q --depth 1 https://github.com/cursor/plugins.git $tmp
    if ($LASTEXITCODE -eq 0) {
        Copy-Item (Join-Path $tmp "pstack") $LocalPlugins -Recurse -Force
        Write-Host "Installed: $(Join-Path $LocalPlugins 'pstack')"
    }
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Copy-Item (Join-Path $RepoDir "plugins\local\*") $LocalPlugins -Recurse -Force

# --- settings.json (recursive merge + Windows statusline command) ---
& $Py (Join-Path $RepoDir "apply-settings.py") $Py

# --- User-scope MCP servers ---
if (Get-Command claude -ErrorAction SilentlyContinue) {
    $mcp = Get-Content (Join-Path $RepoDir "mcp-servers.json") -Raw | ConvertFrom-Json
    foreach ($s in $mcp.mcpServers.PSObject.Properties) {
        try { claude mcp add --scope user --transport $s.Value.type $s.Name $s.Value.url 2>&1 | Out-Null } catch {}
        if ($LASTEXITCODE -eq 0) { Write-Host "MCP added: $($s.Name)" } else { Write-Host "MCP present: $($s.Name)" }
    }
}

# --- herdr: binary, shared config, Claude Code integration, PowerShell helpers ---
if (-not (Get-Command herdr -ErrorAction SilentlyContinue)) {
    try { Invoke-RestMethod https://herdr.dev/install.ps1 | Invoke-Expression }
    catch { Write-Host "herdr install failed - see https://herdr.dev" }
    $env:PATH = "$env:LOCALAPPDATA\Programs\Herdr\bin;$env:PATH"
}
$HerdrCfg = if ($env:HERDR_CONFIG_PATH) { $env:HERDR_CONFIG_PATH } else { Join-Path $env:APPDATA "herdr\config.toml" }
New-Item -ItemType Directory -Force -Path (Split-Path $HerdrCfg) | Out-Null
if (Test-Path $HerdrCfg) {
    Copy-Item $HerdrCfg "$HerdrCfg.bak.$Ts"
    Write-Host "Backed up: $HerdrCfg -> $HerdrCfg.bak.$Ts"
}
Copy-Item (Join-Path $RepoDir "herdr\config.toml") $HerdrCfg -Force
Write-Host "Installed: $HerdrCfg"
if (Get-Command herdr -ErrorAction SilentlyContinue) {
    try { herdr integration install claude 2>&1 | Out-Null } catch {}
    if ($LASTEXITCODE -eq 0) { Write-Host "herdr: Claude Code integration installed" }
}
Copy-Item (Join-Path $RepoDir "herdr\herdr.ps1") (Join-Path $ClaudeDir "herdr.ps1") -Force
if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Force -Path $PROFILE | Out-Null }
if (-not (Select-String -Path $PROFILE -Pattern '\.claude\\herdr\.ps1' -Quiet)) {
    Add-Content $PROFILE "`n# herdr : alias claude (bypass) dans herdr + commande hr`n. `"`$env:USERPROFILE\.claude\herdr.ps1`""
    Write-Host "Installed: herdr helpers -> $PROFILE"
}

Write-Host ""
Write-Host "Done. Open a new Claude Code session to see the changes."
Write-Host "Note: ANSI colors need a VT-capable terminal (Windows Terminal works)."
