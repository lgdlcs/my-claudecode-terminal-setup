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
- Ne pas utiliser de tirets cadratins (—) dans les emails (corps ni signature) : ça fait artificiel/signature IA. Remplacer par une virgule, un point ou un retour à la ligne. Signature « — Lucas » → « Lucas » sur une nouvelle ligne.

## Navigation web
- gstack a été désinstallé (juillet 2026). Pour toute navigation/automatisation web, utiliser les outils **Playwright MCP** (`mcp__playwright__*`). Ne jamais utiliser les outils `mcp__claude-in-chrome__*`.

## Bibles & principes (docs de référence à la racine de ~/.claude/)
- **Landing pages / produit viral** : dès qu'on conçoit ou révise une landing page (sites vitrines, démos, etc.), appliquer la bible `~/.claude/landing-page-bible.md` (32 Principles of a Viral Product, Marc Lou). En cas de conflit, la règle gagne sauf arbitrage explicite.
- **Business / SaaS / monétisation** : dès qu'on entame un sujet business, SaaS ou monétisation, raisonner avec `~/.claude/startup-principles.md` (15 règles fondateur, Y Combinator).

## Reminders / rappels
- Tous les reminders (relances prospects, suivis, tâches datées différées, etc.) se créent via **Google Calendar** (MCP `mcp__claude_ai_Google_Calendar__create_event`), pas en local ni en launchd.
- Mettre l'événement au fuseau `Europe/Paris`, avec un rappel popup le jour J + un rappel email la veille.
- Inclure dans la description : le contexte, la liste concernée (ex. prospects à relancer avec email/tél/site/maquette) et **la commande Claude Code à copier-coller** pour exécuter l'action le jour venu.
