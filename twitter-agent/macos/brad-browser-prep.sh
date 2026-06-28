#!/bin/zsh
# Pré-vol navigateur de Brad : libère le profil Playwright MCP avant tout usage du navigateur.
# - tue les process Chrome ORPHELINS du profil MCP (pas le Chrome perso, dossier différent)
# - retire les verrous Singleton périmés qui font échouer la relance ("Browser is already in use")
# Idempotent et sûr. À sourcer/appeler avant toute session Playwright pilotée par Brad.
CACHE="$HOME/Library/Caches/ms-playwright-mcp"

# Cible UNIQUEMENT les Chrome du profil MCP (cmdline contient ms-playwright-mcp/mcp-chrome).
# Ne touche jamais au Chrome personnel (~/Library/Application Support/Google/Chrome).
if pgrep -f "ms-playwright-mcp/mcp-chrome" >/dev/null 2>&1; then
  pkill -9 -f "ms-playwright-mcp/mcp-chrome" 2>/dev/null
  # petite attente active sans `sleep` bloquant prolongé
  for i in 1 2 3 4 5; do pgrep -f "ms-playwright-mcp/mcp-chrome" >/dev/null 2>&1 || break; sleep 0.3; done
fi

# Retire les verrous de singleton (le process qui les tenait est mort).
if [ -d "$CACHE" ]; then
  rm -f "$CACHE"/mcp-chrome-*/SingletonLock "$CACHE"/mcp-chrome-*/SingletonCookie "$CACHE"/mcp-chrome-*/SingletonSocket 2>/dev/null
fi

echo "brad-browser-prep: profil Playwright MCP libéré"
