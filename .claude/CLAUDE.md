# Règles spécifiques à ce repo

## Multi-plateforme (macOS + Windows)
- Le repo GitHub `lgdlcs/my-claudecode-terminal-setup` est **multi-plateforme** (macOS + Windows).
- Toute nouvelle config, commande ou script poussé dans ce repo doit être **adapté aux deux environnements** : version macOS (bash/AppleScript) **et** version Windows (PowerShell), chacune installée par son installeur (`install.sh` et `install.ps1`).
- Si une fonctionnalité est impossible sur un des deux OS, le documenter explicitement dans le tableau « OS support » du README.

## Sync avec ~/.claude/CLAUDE.md
- Le `CLAUDE.md` à la racine de ce repo est la **source** installée en global par `install.sh`/`install.ps1` (copie vers `~/.claude/CLAUDE.md`). Toute modification des préférences globales se fait ici puis se réinstalle — garder les deux fichiers identiques.
