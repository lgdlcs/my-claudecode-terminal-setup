# Pré-vol navigateur de Brad (Windows) : libère le profil Playwright MCP avant tout usage du navigateur.
# Equivalent de brad-browser-prep.sh : tue les Chrome ORPHELINS du profil MCP + retire les verrous Singleton.
# Best-effort, non testé sur Windows. Ne touche pas au Chrome personnel.
$ErrorActionPreference = "SilentlyContinue"
$cache = Join-Path $env:LOCALAPPDATA "ms-playwright-mcp"

# Tuer uniquement les Chrome dont la ligne de commande référence le profil MCP.
Get-CimInstance Win32_Process -Filter "Name='chrome.exe'" | Where-Object {
    $_.CommandLine -match "ms-playwright-mcp[\\/]mcp-chrome"
} | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

Start-Sleep -Milliseconds 600

# Retirer les verrous Singleton périmés du/des profils MCP.
if (Test-Path $cache) {
    Get-ChildItem $cache -Directory -Filter "mcp-chrome-*" | ForEach-Object {
        foreach ($lock in @("SingletonLock","SingletonCookie","SingletonSocket")) {
            Remove-Item (Join-Path $_.FullName $lock) -Force -ErrorAction SilentlyContinue
        }
    }
}
Write-Host "brad-browser-prep: profil Playwright MCP libéré"
