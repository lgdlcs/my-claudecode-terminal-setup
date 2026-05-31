---
description: Commit et push le repo de travail en cours (message auto si non fourni)
argument-hint: [message de commit optionnel]
allowed-tools: Bash(git status:*), Bash(git add:*), Bash(git diff:*), Bash(git commit:*), Bash(git push:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git log:*), Bash(git remote:*)
---

Tu dois committer puis pusher le dépôt git du **répertoire de travail courant**.

Argument fourni (message de commit, peut être vide) : `$ARGUMENTS`

Procédure :

1. Vérifie qu'on est bien dans un repo git (`git rev-parse --is-inside-work-tree`). Sinon, arrête-toi et signale-le.
2. Affiche `git status -s` et `git diff --stat` pour voir ce qui va être inclus.
3. Si rien n'est à committer ni à pusher, dis-le simplement et arrête-toi.
4. Stage tout : `git add -A`.
5. Message de commit :
   - Si `$ARGUMENTS` est non vide → utilise-le tel quel.
   - Sinon → génère un message concis et descriptif à partir du diff (style impératif, ex. `Fix header alignment on mobile`).
   - Termine toujours le message par :
     ```
     Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
     ```
6. Commit.
7. Push :
   - Récupère la branche courante (`git branch --show-current`).
   - Si elle a déjà un upstream → `git push`.
   - Sinon → `git push -u origin <branche>`.
8. Confirme en une ligne : branche poussée + résumé du commit.

Notes :
- Ne crée pas de nouvelle branche automatiquement : push la branche courante telle quelle (c'est une commande de push volontaire de l'utilisateur).
- Si le push échoue (ex. besoin d'un `pull --rebase`, conflit, pas de remote), explique le problème et propose la correction au lieu de forcer.
