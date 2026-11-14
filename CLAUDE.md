# CLAUDE.md — Livre Blanc Citoyen

Application web qui recueille les contributions des populations de Côte d'Ivoire, les regroupe en livres blancs régionaux (31 régions et 2 districts autonomes, soit 33 UTR) puis les consolide en un livre blanc national sur lequel les candidats s'engagent. Projet UP-PRO d'élèves ingénieurs ING2 STIC (ESI, INP-HB), soutenance le 15 janvier 2027. Démonstration en local.

## Avant toute tâche

1. Repérer la tâche dans `docs/IMPLEMENTATION_PLAN.md` (numéro de lot et de tâche).
2. Lire les sections citées par la tâche, et seulement elles. Les documents :

| Besoin | Document |
|---|---|
| Ce que l'application doit faire : glossaire, règles RG-xx, fonctionnalités F-xx, exigences NF-xx | `docs/PRD.md` |
| Comment : architecture, choix techniques T-xx, moteur d'analyse, documents, sécurité, tests | `docs/TRD.md` |
| Données : MCD, passage au MLD, où chaque règle est garantie, similarité | `docs/DATABASE_SCHEMA.md`, `database/generated/` |
| Points d'API, format des erreurs, échanges détaillés | `docs/API_SPECIFICATIONS.md`, `api/openapi.yaml` |
| Écrans, navigation, parcours par rôle | `docs/APP_FLOW.md` |
| Ce que chaque écran doit permettre : contenus, textes, états | `docs/UX_SPECIFICATIONS.md` |
| Charte graphique de départ (révisable à la tâche 0.8) | `docs/UI_DESIGN_SYSTEM.md`, `design/design-system/project/README.md` |
| Traitements MERISE (MCC, MCT, MOT) | `docs/MERISE_TRAITEMENTS.md` |

3. Proposer un plan court (fichiers, tests) avant d'écrire du code.

## Sources de vérité (ne jamais contourner)

- **Schéma de la base** : `database/migrations/*.sql`. Toute évolution = une NOUVELLE migration numérotée ; jamais modifier une migration appliquée. Le schéma Drizzle (`server/db/schema.ts`) est généré par `drizzle-kit pull`, jamais écrit à la main. Procédure : skill `lbc-migration`.
- **Règles de gestion** : celles qui protègent les données publiées sont garanties par la base (contraintes, déclencheurs ; tableau DATABASE_SCHEMA §5). Le code les vérifie aussi pour afficher un message clair, mais ne les désactive jamais. Procédure : skill `lbc-regle-de-gestion`.
- **Points d'API** : `api/endpoints.py`, puis `python3 api/generer.py`. Procédure : skill `lbc-endpoint`.
- **Valeurs visuelles** : `design/design-system/project/tokens.json`, une fois la direction d'interface validée (tâche 0.8). Aucune couleur, taille ou espacement en dur.
- **Fichiers générés, jamais édités à la main** : `database/generated/*`, `api/openapi.yaml`, les tableaux de `docs/API_SPECIFICATIONS.md` et `docs/DATABASE_SCHEMA.md`, `server/db/schema.ts`, `diagrams/merise/*`.

## Pile technique

Nuxt 4 (Vue 3, Nitro, TypeScript strict) en monolithe modulaire, version mobile en application web progressive (lot 6, après la version web ; `@vite-pwa/nuxt` à valider, IndexedDB via `idb-keyval`) · Node 24 LTS · pnpm · PostgreSQL 18 (`pg_trgm`, `unaccent`) · Drizzle ORM · pg-boss (tâches de fond, processus `worker`) · nuxt-auth-utils (sessions en base, scrypt) · nuxt-security · Nuxt UI 4 et Tailwind CSS 4 · Zod (schémas partagés dans `shared/`) · Tiptap · D3 et TopoJSON · GSAP (accueil uniquement) · Playwright (PDF et tests) · docx · Vitest · Docker Compose (`app`, `worker`, `postgres`, `mailpit`).

## Commandes (créées au lot 0)

```bash
docker compose up -d            # app http://localhost:3000, Mailpit http://localhost:8025
pnpm dev                        # développement sans conteneur pour l'application
pnpm migrer                     # applique les migrations non appliquées
pnpm charger-demo [--base]      # référentiels et comptes ; sans --base : jeu complet de démonstration
pnpm test                       # Vitest : unitaires et intégration (base jetable)
pnpm test:e2e                   # Playwright (scénario PRD §14.3, parcours, axe)
pnpm lint && pnpm typecheck
psql -d lbc_test -f database/tests/test_regles_gestion.sql     # 60 contrôles des règles en base
python3 database/mcd/generer_mld.py                            # régénère MLD et dictionnaire
python3 api/generer.py                                         # régénère la doc API et openapi.yaml
python3 scripts/docs/controle_coherence.py                     # cohérence documents ↔ base
```

## Architecture et conventions

- Couches serveur : `server/middleware` (session) → `server/api/v1` (route mince : Zod puis service) → `server/modules/<module>/service.ts` (règles, transaction, audit) → `requetes.ts` (Drizzle). Les calculs du moteur sont des fonctions pures dans `server/engine/`. Une route n'accède jamais à la base ; un module n'importe pas les requêtes d'un autre.
- Autorisations côté serveur à chaque requête : rôle ET périmètre territorial (`politique.ts` de chaque module, `exiger()`). Les listes sont filtrées dans la requête SQL.
- Toute action d'administration appelle `auditer()` dans la même transaction.
- Erreurs : RFC 9457 avec `code` et, pour une règle, `regle: "RG-xx"` ; messages en français simple qui disent quoi faire.
- Noms du domaine en français, sans accents, comme le glossaire (`contribution`, `preoccupation`, `convergence`, `livreBlanc`) ; vocabulaire technique en anglais quand c'est l'usage (`service`, `handler`, `props`). Champs JSON de l'API en `camelCase` français.
- Interface, messages, commentaires et commits en français.
- Paramètres du moteur (seuils, pondérations) lus dans `edition.parametres`, jamais en dur.
- Versions publiées de livres blancs : rendues uniquement depuis `contenu_fige`.

## Interfaces : c'est à toi de concevoir la présentation

Les maquettes produites pendant la conception **n'ont pas été retenues** par l'équipe : elles ne sont pas dans ce dépôt et ne doivent pas servir de modèle. Tu es responsable de la manière dont les choses se présentent, sur le portail public comme dans les espaces des contributeurs, des administrateurs et des candidats. Exigence de l'équipe : **rien ne doit avoir l'air d'avoir été produit par une IA**.

- Avant tout écran, la tâche 0.8 du plan fixe une direction d'interface validée par l'équipe. Procédure complète, avec la liste des tics à éviter : skill `lbc-interface`.
- `docs/UX_SPECIFICATIONS.md` décrit **ce que les écrans doivent permettre** (contenus, règles de saisie, états, textes) ; il ne fixe pas leur mise en forme. `docs/APP_FLOW.md` fixe les écrans, les accès et les parcours.
- `design/design-system/` est une **proposition de départ** (palette inspirée du territoire, polices libres et lisibles, accessibilité vérifiée) : tu peux la remettre en cause à la tâche 0.8 ; une fois la direction validée, les jetons deviennent la référence et plus aucune valeur n'est écrite en dur.
- Contraintes qui ne bougent pas : neutralité (ni drapeau, ni couleur de parti, aucun candidat mis en avant), WCAG 2.1 AA (focus visible, cibles de 44 px, libellés visibles, contrastes), pages publiques légères (JavaScript initial < 250 Ko compressé).

## Version web et version mobile (D-16)

**Ordre de réalisation : la version web d'abord (lots 0 à 5), la version mobile ensuite (lot 6).** N'ajouter ni module PWA, ni service worker, ni file d'attente hors connexion avant le lot 6. Le formulaire de contribution est simplement écrit de façon à pouvoir, plus tard, mettre un envoi en attente.

- **Version web** : s'utilise **en ligne**, pensée d'abord pour l'ordinateur (portail, administration) et lisible sur un téléphone. Aucune exigence hors connexion.
- **Version mobile** : la même application, **installable** sur le téléphone (application web progressive, TRD T-13), conçue pour le téléphone et **utilisable hors connexion** pour préparer des contributions (file d'attente envoyée au retour du réseau, `idClient` pour éviter les doublons, RG-30), voir ses envois et relire ce qui a déjà été ouvert (F-38). Soutiens, signalements, suggestions et administration exigent le réseau.
- Au lot 6, le portail reçoit une page « Télécharger l'application mobile » (`/application-mobile`, lien dans l'en-tête et le pied de page) qui explique l'installation et propose le bouton d'installation.
- Les ressources (polices, contours de cartes) sont servies par l'application elle-même : la démonstration locale ne dépend d'aucun service tiers.

## Définition de « fini »

Comportement conforme aux F-xx et RG-xx cités, tests ajoutés et passants, autorisations testées, audit écrit, écran conforme à la direction d'interface et relu contre la liste des tics à éviter, validé au clavier, sur 390 px et 1 440 px, axe sans violation, documents de référence à jour si un comportement, une API ou le schéma a changé.

## Interdits

- Modifier une migration appliquée, désactiver un déclencheur ou une contrainte pour « faire passer » un test.
- Supprimer physiquement une contribution, une préoccupation, une version publiée ou une ligne du journal d'audit.
- Exposer une donnée personnelle hors des sérialiseurs publics (RG-29, NF-21, NF-25).
- Faire dépendre l'application d'un service tiers en ligne (polices, cartes, modèle de langage, analyse d'audience) : la version web a seulement besoin de notre serveur.
- Présenter un résultat du moteur comme une décision : il propose, l'administration décide.
