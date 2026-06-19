---
description: Met à jour le suivi de la campagne parapente d'après les réponses reçues dans Gmail (détection + statut, sans envoi)
argument-hint: (aucun) — scanne tous les prospects en attente de réponse
allowed-tools: Read, Edit, Bash(python3:*), mcp__gmail__search_emails, mcp__gmail__read_email
---

Tu mets à jour le **suivi de la campagne parapente** d'alt-tab studio en te basant **uniquement sur les réponses reçues dans Gmail**. Tu **ne crées aucun brouillon et n'envoies aucun email** : cette commande est en **lecture seule sur Gmail** et n'écrit que dans le fichier de suivi.

## Fichiers
- Source de vérité : `/Users/pouetpouets/code/email-automation/campaign_parapente.json`
  (roster sous la clé `prospects`, chaque entrée a : `slug`, `name`, `email`, `tel`, `site`, `maquette_url`, `thread_id`, `status`, `first_send`, `last_send`, `notes`).
- Régénération du dashboard : `python3 /Users/pouetpouets/code/email-automation/sync_and_plan.py --no-sync` (ne touche pas à la master, régénère juste `campaign_data.js`).

## Statuts (workflow)
`todo_maquette` → `todo` → `sent` → `r1` → `r2` → puis terminal : `replied` / `meeting` / `client` / `recontact` / `dead` / `excluded`.

## Procédure

1. **Lis** `campaign_parapente.json`. Construis la liste des prospects **en attente de réponse** : ceux dont le `status` est `sent`, `r1` ou `r2`. Note aussi (pour info) ceux en `replied` / `meeting` afin de repérer un éventuel **nouveau** message entrant dans leur thread.

2. **Pour chaque prospect à scanner**, cherche une réponse **entrante** dans Gmail avec `mcp__gmail__search_emails` :
   - Requête : `from:<email> newer_than:25d` (utilise le champ `email` du prospect).
   - Si le prospect a un `thread_id` non vide, c'est un indice fort : une réponse dans ce thread = réponse du prospect.
   - Ouvre les messages pertinents avec `mcp__gmail__read_email` pour lire le contenu réel avant de classer (ne te fie jamais au seul objet).
   - ⚠️ Ignore les accusés de réception automatiques, les réponses « absent du bureau / vacances », et tes propres messages sortants.

3. **Classe chaque réponse trouvée** et mets à jour le statut :
   - Intérêt / question / demande d'infos / neutre positif → `replied`.
   - Demande de RDV, d'appel, de devis → `meeting`.
   - Signature de prestation / accord → `client`.
   - Refus cordial, « déjà un prestataire », « pas le moment » sec, « pas intéressé » → `dead`.
   - « Pas maintenant mais recontactez plus tard » → `recontact`.
   Ajoute **toujours une note datée** au champ `notes` (format `JJ/MM — résumé court de la réponse`, en conservant les notes existantes, séparateur ` · `).

4. **Règles de sécurité** (ne jamais enfreindre) :
   - Ne modifie un statut **que** si une réponse réelle le justifie. Pas de réponse = pas de changement.
   - **Ne jamais écraser un statut terminal** existant (`replied` / `meeting` / `client` / `dead` / `excluded`). Pour ces prospects, si tu repères un **nouveau** message entrant, ne change pas le statut : signale-le dans le rapport pour arbitrage humain (ex. relance du prospect après un `replied`).
   - Ne touche pas aux champs autres que `status` et `notes` (sauf `last_send`/dates : ne pas y toucher ici, c'est l'affaire du script d'envoi).
   - Mets à jour le champ `updated` (en tête du JSON) à la date du jour.

5. **Sauvegarde** : réécris `campaign_parapente.json` (JSON valide, indentation 2 espaces, UTF-8, garde l'ordre des prospects), puis lance `python3 /Users/pouetpouets/code/email-automation/sync_and_plan.py --no-sync` pour régénérer le dashboard.

6. **Rapport** (5–8 lignes max) :
   - Nombre de prospects scannés.
   - Réponses détectées, avec pour chacune : nom + nouveau statut + une phrase de contexte.
   - Changements de statut appliqués.
   - Prospects en statut terminal ayant reçu un **nouveau** message (à arbitrer).
   - Si 0 réponse et 0 changement : le dire simplement (« RAS, aucune nouvelle réponse »).

   Termine par la **prochaine action conseillée** (ex. « 2 nouvelles réponses `replied` → préparer une réponse personnalisée », ou « lancer le plan de relances via le RUNBOOK »). N'exécute pas cette action : cette commande s'arrête au suivi.
