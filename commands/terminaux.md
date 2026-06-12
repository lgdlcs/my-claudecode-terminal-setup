---
description: Ouvre et range 3 fenêtres Terminal côte à côte (tiers gauche/centre/droit) et lance claude dans chacune
allowed-tools: Bash
---

## Résultat de l'exécution

!`if [ "$(uname)" = "Darwin" ]; then osascript ~/Library/Scripts/arrange-3-terminals.applescript; else powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/scripts/arrange-3-terminals.ps1"; fi && echo "OK : 3 terminaux rangés, claude lancé"`

Le script adapté à l'OS vient d'être exécuté :

- **macOS** : `~/Library/Scripts/arrange-3-terminals.applescript` — ouvre les fenêtres Terminal manquantes (jusqu'à 3), les place en trois colonnes (tiers gauche, centre, droit), puis lance `claude` dans chaque fenêtre libre (les fenêtres déjà occupées par un process sont laissées telles quelles).
- **Windows** : `~/.claude/scripts/arrange-3-terminals.ps1` — ouvre seulement les fenêtres manquantes (jusqu'à 3, Windows Terminal si disponible, sinon PowerShell), range les 3 premières fenêtres en trois colonnes (les terminaux déjà ouverts sont réutilisés et réalignés au lieu d'en empiler de nouveaux), et lance `claude` uniquement dans les fenêtres nouvellement ouvertes.

Confirme brièvement à l'utilisateur que les 3 terminaux sont rangés et claude lancé, ou signale l'erreur ci-dessus le cas échéant. Ne relance pas le script sauf en cas d'échec.
