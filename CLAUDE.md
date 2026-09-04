# Consignes globales (tous les projets)

## Serveur de dev local

- Toujours lancer le projet en local sur le port 3000 (`localhost:3000`) de préférence.
- Si le port est déjà pris, incrémenter de un (3001, puis 3002, etc.) jusqu'à trouver un port libre.
- Cette règle vaut pour tous les projets.

## Worktree obligatoire si sessions concurrentes

- Si une autre session Claude travaille déjà dans le même checkout git, ne jamais
  écrire dedans : créer d'abord un worktree git dédié et y basculer.
  - Outil `EnterWorktree` de préférence, sinon
    `git worktree add ../<projet>-wt-<sujet> -b wt/<sujet>`.
  - Port de dev distinct (3000 pris → 3001, 3002, …).
  - Annoncer en une ligne : worktree, branche, port.
- Le hook `hooks/worktree-guard.py` (SessionStart) détecte le cas et injecte la
  consigne ; cette règle vaut aussi quand le hook ne s'est pas déclenché (session
  démarrée avant l'autre, sous-agent, doute).
- Exceptions sans worktree : travail en lecture seule (lecture, recherche,
  explication, `git log`/`diff`). Si l'utilisateur demande explicitement de rester
  sur le checkout partagé, signaler le conflit puis obéir.
