---
description: Change la couleur de fond du terminal de la session en cours (nom, hex ou random)
argument-hint: "[bleu|teal|vert|violet|rouge|ambre|rose|gris|noir|blanc|#rrggbb|random]"
allowed-tools: Bash
---

## Résultat de l'exécution

!`bash ~/.claude/terminal-color.sh "$ARGUMENTS"`

Le script vient d'être exécuté avec la couleur demandée. Il colore **l'onglet de cette session** (repéré par son TTY, pas simplement la fenêtre au premier plan) et ajuste la couleur du texte et du curseur selon la luminosité du fond.

- **Couleurs nommées** : `bleu` `teal` `vert` `violet` `rouge` `ambre` `rose` `gris` `noir` `blanc` (alias anglais acceptés : `blue`, `green`, `purple`…). `noir` / `defaut` remet un fond noir.
- **Hex libre** : `#1F3656` ou `1f3656`.
- **`random`** : une couleur au hasard de la palette.
- **Sans argument** (ou `liste`) : affiche simplement les couleurs disponibles, sans rien changer.

macOS + Terminal.app uniquement (le script s'arrête proprement avec un message ailleurs). La couleur automatique par session (`terminal-session-color.sh`, appliquée au démarrage) est écrasée pour cet onglet ; le choix manuel tient jusqu'à la prochaine session dans le même onglet.

Confirme brièvement à l'utilisateur la couleur appliquée, ou relaie l'erreur ci-dessus. Ne relance pas le script sauf en cas d'échec.
