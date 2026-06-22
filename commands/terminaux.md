---
description: Ouvre, range et lance claude dans N fenêtres Terminal (N de 1 à 6, défaut 3), pavées en grille pour occuper tout l'écran, puis les passe en /effort max
argument-hint: "[1-6]"
allowed-tools: Bash
---

## Résultat de l'exécution

!`N="$ARGUMENTS"; case "$N" in 1|2|3|4|5|6) ;; *) N=3 ;; esac; if [ "$(uname)" = "Darwin" ]; then osascript ~/Library/Scripts/arrange-terminals.applescript "$N"; else powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/scripts/arrange-terminals.ps1" "$N"; fi && echo "OK : $N terminaux rangés, claude lancé en /effort max"`

Le script adapté à l'OS vient d'être exécuté avec le nombre de terminaux demandé (1 à 6 ; défaut 3 si l'argument est absent ou invalide). Les fenêtres pavent l'écran en grille pour que chacune occupe la place maximale, et toutes les N sont visibles.

Grille selon N : **1**→plein écran · **2**→2 colonnes · **3**→3 colonnes · **4**→2×2 · **5**→3 + 2 en tiers (6e case réservée) · **6**→3×3 (2 rangées de 3).

**Réserver la place** : les fenêtres déjà ouvertes ne sont jamais déplacées tant que la structure de grille ne change pas. Comme N=5 réserve la 6e case (même grille {3,3} que N=6), passer de 5 à 6 ajoute la nouvelle fenêtre dans la case libre sans bouger les 5 premières ; relancer le même N ne déplace rien. Seul un changement de structure (ex. 4→5) ré-agence tout l'écran.

- **macOS** : `~/Library/Scripts/arrange-terminals.applescript` — ouvre les fenêtres Terminal manquantes pour atteindre N et ne place QUE les nouvelles (les fenêtres existantes gardent leur position ; un changement de structure de grille ré-agence tout l'écran), lance `claude` dans chaque fenêtre libre, puis (après ~5 s de démarrage) envoie `/effort max` dans chaque session ainsi lancée (les fenêtres déjà occupées par un process sont laissées telles quelles).
- **Windows** : `~/.claude/scripts/arrange-terminals.ps1` — ouvre seulement les fenêtres manquantes pour atteindre N (Windows Terminal si disponible, sinon PowerShell) et ne place QUE les nouvelles (mêmes règles : l'existant ne bouge pas, sauf changement de structure de grille), lance `claude` uniquement dans les fenêtres nouvellement ouvertes, puis y envoie `/effort max` via SendKeys.

Confirme brièvement à l'utilisateur que les N terminaux sont rangés et claude lancé en `/effort max`, ou signale l'erreur ci-dessus le cas échéant. Ne relance pas le script sauf en cas d'échec.
