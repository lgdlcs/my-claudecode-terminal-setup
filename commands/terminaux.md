---
description: Ouvre et range 3 fenêtres Terminal côte à côte (tiers gauche/centre/droit)
allowed-tools: Bash(osascript:*)
---

## Résultat de l'exécution

!`osascript ~/Library/Scripts/arrange-3-terminals.applescript && echo "OK : 3 terminaux rangés"`

Le script `~/Library/Scripts/arrange-3-terminals.applescript` vient d'être exécuté : il ouvre des fenêtres Terminal manquantes (jusqu'à 3) puis les place en trois colonnes (tiers gauche, centre, droit).

Confirme brièvement à l'utilisateur que les 3 terminaux sont rangés, ou signale l'erreur ci-dessus le cas échéant. Ne relance pas le script sauf en cas d'échec.
