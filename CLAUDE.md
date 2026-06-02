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

## Emails (Gmail)
- Ne jamais coller une URL brute dans un email envoyé via Gmail.
- Toujours embarquer le lien dans un texte d'ancrage (lien hypertexte HTML), ex. `<a href="https://…">votre maquette</a>` pour « votre maquette ».
- Envoyer ces emails en HTML (et non en texte brut) pour que le lien cliquable soit rendu correctement.