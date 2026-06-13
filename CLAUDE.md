# Préférences globales

## Ouverture de fichiers
- Toujours utiliser VSCode (`code <fichier>`) plutôt que `open` quand c'est possible pour ouvrir les fichiers générés ou consultés.
- Pour les fichiers Markdown (`.md`) : utiliser le mode **Preview** de VSCode (Cmd+Shift+V après ouverture, ou installer l'extension "Auto-Open Markdown Preview").
- Pour les fichiers Excel (`.xls`, `.xlsx`) : ouvrir avec VSCode également (extension Excel Viewer recommandée).
- Si VSCode n'est pas disponible (`command -v code` échoue), retomber sur `open`.

## Lancement des repos
- Toujours lancer les repos en local (démarrer le serveur de dev).
- Partager l'URL locale (ex. `http://localhost:3000`) dans le premier message de rappel.

## Tests
- Toujours utiliser Playwright dès que Claude peut exécuter un test lui-même (UI/web, vérification de comportement dans un navigateur).
- Si Playwright n'est pas connecté/installé, suggérer son installation plutôt que de renoncer au test.

## TODO
- Quand je parle de « TODO » (ma liste de tâches), il s'agit de la liste Notion **ATL TAB STUDIO** : https://app.notion.com/p/ATL-TAB-STUDIO-376e001a7211806da98ded9ac3fb78c4
- Utiliser le MCP Notion pour lire/mettre à jour cette liste quand je demande d'ajouter, consulter ou cocher des tâches.

## Emails (Gmail)
- Ne jamais coller une URL brute dans un email envoyé via Gmail.
- Toujours embarquer le lien dans un texte d'ancrage (lien hypertexte HTML), ex. `<a href="https://…">votre maquette</a>` pour « votre maquette ».
- Envoyer ces emails en HTML (et non en texte brut) pour que le lien cliquable soit rendu correctement.

## gstack
- Pour toute navigation web, utiliser le skill `/browse` de gstack. Ne jamais utiliser les outils `mcp__claude-in-chrome__*`.
- Skills gstack disponibles : `/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/plan-design-review`, `/design-consultation`, `/design-shotgun`, `/design-html`, `/review`, `/ship`, `/land-and-deploy`, `/canary`, `/benchmark`, `/browse`, `/connect-chrome`, `/qa`, `/qa-only`, `/design-review`, `/setup-browser-cookies`, `/setup-deploy`, `/setup-gbrain`, `/retro`, `/investigate`, `/document-release`, `/document-generate`, `/codex`, `/cso`, `/autoplan`, `/plan-devex-review`, `/devex-review`, `/careful`, `/freeze`, `/guard`, `/unfreeze`, `/gstack-upgrade`, `/learn`.

## Bibles & principes (docs de référence à la racine de ~/.claude/)
- **Landing pages / produit viral** : dès qu'on conçoit ou révise une landing page (sites vitrines, démos, ComplaintScout, etc.), appliquer la bible `~/.claude/landing-page-bible.md` (32 Principles of a Viral Product, Marc Lou). En cas de conflit, la règle gagne sauf arbitrage explicite.
- **Business / SaaS / monétisation** : dès qu'on entame un sujet business, SaaS ou monétisation, raisonner avec `~/.claude/startup-principles.md` (15 règles fondateur, Y Combinator).

## Repo my-claudecode-terminal-setup (config Claude Code)
- Le repo GitHub `lgdlcs/my-claudecode-terminal-setup` est **multi-plateforme** (macOS + Windows).
- Toute nouvelle config, commande ou script poussé dans ce repo doit être **adapté aux deux environnements** : version macOS (bash/AppleScript) **et** version Windows (PowerShell), chacune installée par son installeur (`install.sh` et `install.ps1`).
- Si une fonctionnalité est impossible sur un des deux OS, le documenter explicitement dans le tableau « OS support » du README.
