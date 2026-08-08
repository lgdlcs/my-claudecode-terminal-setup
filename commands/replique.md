---
description: Réplique une référence (template Framer, site, app, jeu…) au niveau agence prestigieuse / studio AAA, via fan-out de sous-agents + boucle de critique adverse jusqu'à la perfection
argument-hint: "<ce qu'on construit> + <URL(s) de référence> + <règles par élément>"
---

# /replique — clone conforme d'une référence, jusqu'à la perfection

Brief de Lucas :

$ARGUMENTS

Si le brief est vide ou ne contient aucune référence exploitable (URL, capture, repo, nom de produit), demande **une seule** question : quelle est la référence à répliquer et quel est le livrable attendu. Sinon, exécute sans poser de question.

## Contrat

Tu es **orchestrateur**, pas exécutant. Tu spécifies, tu délègues, tu arbitres, tu vérifies. Tu n'écris toi-même que la colle (scaffold, config, intégration) et le rapport final.

La référence est **la vérité**. Le livrable doit soutenir une comparaison côte à côte en aveugle avec elle et gagner — pas « s'en approcher ».

Le domaine n'est pas limité au web : ça peut être un site, un template, une app, un jeu (Three.js / canvas), une interaction. Adapte les axes de vérification au domaine, jamais l'exigence.

## 1. Cadrage

1. Extrais du brief : le **livrable**, les **références** (une par élément si Lucas a découpé), les **règles explicites par élément** (« reprends le hero de X », « tout le reste comme Y sauf le hero », « utilise la vidéo de Z »), les **contraintes fonctionnelles** (ex. « tous les jeux jouables, sans bug, chaque joueur gagne de l'argent »).
2. Les règles par élément de Lucas **priment sur tout**, y compris sur ce qu'un sous-agent juge « plus joli ». Recopie-les mot pour mot dans chaque brief d'agent concerné.
3. Choix par défaut sans demander : stack la plus proche de la référence (statique HTML/CSS/JS + GSAP/Lenis pour un template Framer ; Three.js + Vite pour de la 3D/jeu), projet dans `~/code/<slug>`, `npm run dev` qui marche, git init + premier commit.

## 2. Dossier de référence (obligatoire avant toute ligne de code)

Lance des sous-agents de **capture** (un par référence) qui produisent, dans `<scratchpad>/replique/ref/<nom>/` :

- Captures plein écran à **1440px et 390px**, à chaque palier de scroll (0 %, 25 %, 50 %, 75 %, 100 %) — Playwright.
- Un **relevé de design tokens** : palette exacte (hex prélevés), familles/graisses/tailles/interlettrage typo, échelle d'espacement, rayons, ombres, grille et largeurs max.
- Un **inventaire des animations** : déclencheur (scroll / hover / entrée), propriété animée, durée, easing, décalage (stagger), comportement au scrub. Captures en rafale sur les séquences clés.
- Les **assets** récupérables (vidéo hero, images, icônes, polices) avec leur URL, plus la structure DOM/CSS quand elle est lisible.
- Un `SPEC.md` par référence : la description est faite pour qu'un agent qui n'a **jamais vu** la page puisse la reconstruire.

Rien ne démarre tant que ces `SPEC.md` n'existent pas.

## 3. Découpage et fan-out

Découpe le livrable en **aspects indépendants** (typiquement 5 à 10) : hero, navigation, chaque grande section, système de composants (cartes produit, boutons, formulaires), moteur d'animation transverse, responsive, perf/accessibilité, et pour un jeu : chaque mécanique / mini-jeu, économie, HUD, rendu, audio.

Pour chaque aspect, un **agent d'implémentation** (modèle Opus, `/effort max`) reçoit : le `SPEC.md` concerné, les règles textuelles de Lucas, les tokens partagés, et l'ordre explicite de ne pas inventer hors spec. Lance les agents indépendants **en parallèle dans un même message**. Si plusieurs agents touchent les mêmes fichiers, isole-les (`isolation: "worktree"`) ou sérialise-les ; tout partagé (tokens, layout global) est écrit par toi en amont.

## 4. Boucle de vérification adverse (le cœur de la commande)

Pour **chaque aspect**, à chaque round, un **sous-agent critique distinct** — jamais celui qui a codé — évalue le rendu réel, pas le code :

1. Il lance l'app (Playwright), reproduit les captures de la référence aux mêmes paliers de scroll et viewports, rejoue les interactions et les animations.
2. Il vérifie les axes durs : zéro erreur console, **60 fps mesurés** (`requestAnimationFrame` sur 3 s pendant scroll/animation/jeu), pas de layout shift, responsive 390/768/1440, assets chargés, et pour un jeu : chaque mécanique **jouable de bout en bout**, sans blocage, avec les règles fonctionnelles du brief effectivement respectées pour **tous** les joueurs/cas.
3. **Comparaison côte à côte en aveugle** : il reçoit les paires de captures sans savoir laquelle est la référence (mélange l'ordre, nomme-les `A` / `B`) et doit désigner la meilleure et justifier en 3 points. Si la référence gagne, l'aspect est **recalé**.
4. Il rend un verdict typé : `WOW` (digne d'une agence prestigieuse / d'un studio AAA, gagne ou égale la référence en aveugle) ou `RECALÉ` + liste ordonnée d'écarts précis et actionnables (« l'easing du hero est `ease-out` alors que la ref scrub linéairement sur 120 % de viewport »).

Consigne au critique : **exigence extrême, aucune complaisance**. « Correct », « propre », « ça ressemble » = `RECALÉ`. Il ne valide que ce qui l'époustoufle.

Tout `RECALÉ` repart en implémentation avec la liste d'écarts, puis re-passe la boucle. **Tu ne t'arrêtes pas tant que tous les aspects ne sont pas `WOW`.**

Garde-fou : si un aspect fait 4 rounds sans progrès mesurable (mêmes écarts qui reviennent), arrête cet aspect, dis-le explicitement à Lucas avec les écarts restants et ce qui bloque — et continue les autres aspects jusqu'au bout.

## 5. Passe finale d'ensemble

Quand tous les aspects sont `WOW`, un dernier critique évalue le **produit entier** contre la référence entière : cohérence entre sections, rythme du scroll, transitions, charge perçue, et une dernière comparaison en aveugle page complète. S'il recale, tu repars en boucle.

Puis : tests Playwright de non-régression sur les parcours clés, build de prod qui passe, commit.

## 6. Rapport

Rends à Lucas, court et factuel :

- Le chemin du projet et la commande pour le lancer.
- Un tableau aspect → verdict final → nombre de rounds.
- Le résultat des comparaisons en aveugle (qui a gagné, sur quels critères).
- Les fps mesurés et ce qui reste non résolu, s'il y a lieu. Ne déclare « parfait » que ce qui a réellement été vérifié.
