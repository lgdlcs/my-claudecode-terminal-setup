---
description: Ouvre, range et lance claude dans N fenêtres Terminal (N de 1 à 6, défaut 3), pavées en grille pour occuper tout l'écran, puis les passe en /effort max
argument-hint: "[1-6]"
allowed-tools: Bash
---

## Résultat de l'exécution

!`N="$ARGUMENTS"; case "$N" in 1|2|3|4|5|6) ;; *) N=3 ;; esac; if [ "$(uname)" = "Darwin" ]; then osascript ~/Library/Scripts/arrange-terminals.applescript "$N"; else powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/scripts/arrange-terminals.ps1" "$N"; fi && echo "OK : $N terminaux rangés, claude lancé en /effort max"`

Le script adapté à l'OS vient d'être exécuté avec le nombre de terminaux demandé (1 à 6 ; défaut 3 si l'argument est absent ou invalide). Les fenêtres pavent l'écran en grille pour que chacune occupe la place maximale, et toutes les N sont visibles.

Grille selon N : **1**→plein écran · **2**→2 colonnes · **3**→3 colonnes · **4**→2×2 · **5**→3+2 · **6**→3×3 (2 rangées de 3).

- **macOS** : `~/Library/Scripts/arrange-terminals.applescript` — ouvre les fenêtres Terminal manquantes pour atteindre N, les pave en grille, lance `claude` dans chaque fenêtre libre, puis (après ~5 s de démarrage) envoie `/effort max` dans chaque session ainsi lancée (les fenêtres déjà occupées par un process sont laissées telles quelles).
- **Windows** : `~/.claude/scripts/arrange-terminals.ps1` — ouvre seulement les fenêtres manquantes pour atteindre N (Windows Terminal si disponible, sinon PowerShell), les pave dans la même grille, lance `claude` uniquement dans les fenêtres nouvellement ouvertes, puis y envoie `/effort max` via SendKeys.

Confirme brièvement à l'utilisateur que les N terminaux sont rangés et claude lancé en `/effort max`, ou signale l'erreur ci-dessus le cas échéant. Ne relance pas le script sauf en cas d'échec.
