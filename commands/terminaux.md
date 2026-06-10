---
description: Ouvre et range 3 fenêtres Terminal côte à côte (tiers gauche/centre/droit) et lance claude dans chacune
allowed-tools: Bash
---

## Résultat de l'exécution

!`if [ "$(uname)" = "Darwin" ]; then osascript ~/Library/Scripts/arrange-3-terminals.applescript; else powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/scripts/arrange-3-terminals.ps1"; fi && echo "OK : 3 terminaux rangés, claude lancé"`

Le script adapté à l'OS vient d'être exécuté :

- **macOS** : `~/Library/Scripts/arrange-3-terminals.applescript` — ouvre les fenêtres Terminal manquantes (jusqu'à 3), les place en trois colonnes (tiers gauche, centre, droit), puis lance `claude` dans chaque fenêtre libre (les fenêtres déjà occupées par un process sont laissées telles quelles).
- **Windows** : `~/.claude/scripts/arrange-3-terminals.ps1` — ouvre 3 nouvelles fenêtres (Windows Terminal si disponible, sinon PowerShell), les range en trois colonnes et lance `claude` dans chacune.

Confirme brièvement à l'utilisateur que les 3 terminaux sont rangés et claude lancé, ou signale l'erreur ci-dessus le cas échéant. Ne relance pas le script sauf en cas d'échec.
