# TRD — Livre Blanc Citoyen

> Document des exigences techniques (Technical Requirements Document). Il traduit le PRD en choix d'architecture, de technologies et d'algorithmes, et sert de référence à l'implémentation.

| Champ | Valeur |
|---|---|
| Version | 1.0 — phase 3 (conception), soumise à validation |
| Date | 12 novembre 2026 |
| Documents de référence | `PRD.md` v1.1 · `DATABASE_SCHEMA.md` · `API_SPECIFICATIONS.md` · `APP_FLOW.md` · `MERISE_TRAITEMENTS.md` |
| Équipe | SORO K. S. Samuel (responsable) · AZOUASSI Ô. Sara Océane · GLEDE D. Henri Joël · WOGNIN Noé Phinées — ING2 STIC, ESI / INP-HB |

**Convention.** Les décisions techniques sont numérotées `T-xx` et suivent le format « contexte, options, choix, conséquences » (§3). Les exigences du PRD (`RG-xx`, `F-xx`, `NF-xx`, `D-xx`) sont citées par leur identifiant.

---

## 1. Objet et périmètre

Le TRD couvre :

- l'architecture d'ensemble et le découpage du code ;
- les technologies retenues, avec leurs versions et leurs justifications ;
- le moteur d'analyse (similarité, regroupement, scores, consolidation) au niveau algorithmique ;
- la production des documents (web, PDF, Word) ;
- les tâches de fond, la sécurité, la protection des données, la journalisation ;
- la stratégie de tests, le déploiement local et la configuration.

Le modèle de données est décrit dans `DATABASE_SCHEMA.md`, les points d'accès de l'API dans `API_SPECIFICATIONS.md` et les parcours dans `APP_FLOW.md`.

---

## 2. Contraintes et facteurs d'architecture

| Facteur | Source | Conséquence technique |
|---|---|---|
| Nuxt, Vue et TypeScript imposés | C-01 | Interface et serveur dans le même cadre applicatif |
| Déploiement local pour la démonstration | C-02, NF-41 | Les ressources (polices, contours de cartes) et le moteur d'analyse sont servis par l'application elle-même, sans service tiers ; les e-mails passent par un serveur de test |
| Version web en ligne, version mobile hors connexion | D-16, F-38, NF-32, C-08 | La version web suppose une connexion au serveur ; la version mobile, installable, garde sur le téléphone ce qu'il faut pour préparer des contributions et relire ce qui a déjà été ouvert (T-13) |
| Équipe de quatre étudiants, trois mois | C-07 | Une seule base de code, une seule base de données, un minimum de composants à exploiter |
| Traçabilité et figement des versions publiées | P3, RG-54 | Intégrité garantie par la base (contraintes et déclencheurs), pas seulement par le code |
| Explicabilité du moteur | D-05, P5 | Algorithmes déterministes, paramètres stockés avec chaque calcul et chaque version publiée |
| Connexions mobiles lentes | NF-02, NF-32 | Rendu serveur des pages publiques, budget JavaScript, images compressées |
| Accessibilité | NF-30 | Composants accessibles par défaut, tests automatiques |
| Données personnelles | NF-20 à NF-24 | Minimisation, anonymisation, journaux sans données personnelles |

---

## 3. Décisions techniques

### T-01 — Monolithe modulaire Nuxt full-stack

- **Contexte.** Le PRD décrit 13 modules métier qui partagent fortement leurs données (une contribution est lue par la modération, l'analyse régionale, le livre blanc, le portail).
- **Options.** (a) Nuxt pour l'interface et une API séparée (NestJS ou Express) ; (b) Nuxt full-stack, avec les routes serveur Nitro ; (c) microservices.
- **Choix : (b)**, validé par l'équipe (D-13). Le code serveur est découpé en modules (`server/modules/*`) qui reproduisent les modules M1 à M13 du PRD, avec des frontières explicites (§5).
- **Conséquences.** Un seul langage, un seul déploiement, des types partagés entre l'interface et le serveur (`shared/`). Les traitements longs ne doivent pas bloquer les requêtes : ils passent par une file de tâches exécutée dans un second processus (T-05).

### T-02 — PostgreSQL comme socle unique

- **Options.** PostgreSQL, MySQL/MariaDB, MongoDB.
- **Choix : PostgreSQL 18.** Il apporte, sans composant supplémentaire, ce dont le projet a besoin : la recherche plein texte en français (`to_tsvector('french', …)`), la similarité par trigrammes (`pg_trgm`), les colonnes générées, les index partiels, les déclencheurs pour garantir les règles de gestion, le type `jsonb` pour les contenus figés. Il héberge aussi la file de tâches (T-05). L'extension `pgvector` permettra la similarité sémantique en évolution (§6.6).
- **Conséquences.** Le moteur d'analyse s'appuie sur des fonctions SQL. Le schéma a été testé sur PostgreSQL 16 ; il n'utilise aucune fonctionnalité propre à la version 18. Sous PostgreSQL 18, la fonction native `uuidv7()` peut remplacer `gen_uuid_v7()`.

### T-03 — Accès aux données : SQL versionné et Drizzle ORM

- **Options.** Prisma, Drizzle, Kysely, SQL brut.
- **Choix.** Les **migrations SQL** écrites à la main sont la source de vérité (elles portent les contraintes, déclencheurs et vues que les outils d'ORM ne génèrent pas). **Drizzle ORM** sert de constructeur de requêtes typé : son schéma TypeScript est obtenu par introspection de la base migrée (`drizzle-kit pull`), et n'est jamais modifié à la main.
- **Pourquoi pas Prisma.** Son langage de schéma ne décrit ni les déclencheurs ni les index partiels ; il faudrait maintenir deux sources. Drizzle reste proche du SQL et permet d'appeler les fonctions SQL du moteur (`similarite_textes`, `chevauchement`) sans détour.
- **Conséquences.** Une petite commande `scripts/migrer.ts` applique, dans l'ordre et dans une transaction, les fichiers `database/migrations/NNNN_*.sql` non encore appliqués (table technique `migration_appliquee` : nom, empreinte, date). Une migration déjà appliquée dont l'empreinte change fait échouer la commande.

### T-04 — Authentification : nuxt-auth-utils et sessions révocables

- **Options.** Auth.js (`@sidebase/nuxt-auth`), Lucia (déprécié comme bibliothèque), nuxt-auth-utils.
- **Choix : nuxt-auth-utils.** Le module fournit un cookie de session scellé (chiffré et signé), des fonctions de hachage de mot de passe (scrypt) et s'intègre aux routes serveur. Le projet n'a besoin ni de fournisseurs OAuth ni de JWT.
- **Complément.** Un cookie scellé ne peut pas être révoqué côté serveur. Le cookie ne contient donc que l'identifiant d'une ligne de la table `session` ; chaque requête authentifiée vérifie que cette session existe, n'est ni expirée ni révoquée (§9.2).
- **Conséquences.** NF-11 est mise à jour dans le PRD v1.1 : hachage **scrypt** (accepté par les recommandations OWASP au même titre qu'Argon2id et bcrypt).

### T-05 — Tâches de fond : pg-boss

- **Options.** BullMQ (exige Redis), pg-boss (file dans PostgreSQL), tâches planifiées de Nitro.
- **Choix : pg-boss.** La file est stockée dans PostgreSQL : aucun service supplémentaire, publication d'une tâche possible dans la même transaction que la donnée qui la motive, reprise automatique après une panne. Les tâches planifiées de Nitro, encore expérimentales, ne gèrent ni les reprises ni la concurrence.
- **Conséquences.** Deux processus partagent la même image : `app` (requêtes HTTP) et `worker` (`RUN_WORKERS=true`, exécution des tâches). Liste des tâches au §8.

### T-06 — Interface : Nuxt UI, Tailwind CSS 4 et une direction artistique propre

- **Options.** Vuetify, PrimeVue, Nuxt UI, composants écrits à la main.
- **Choix : Nuxt UI v4** (sous licence MIT, gratuit, bâti sur Reka UI et Tailwind CSS 4). Les composants Reka UI gèrent l'accessibilité (focus, ARIA, clavier), ce qui sert NF-30.
- **Conséquences.** Le thème par défaut est entièrement remplacé par les jetons du système de design (`UI_DESIGN_SYSTEM.md`, phase 4) afin d'éviter l'apparence générique d'une bibliothèque. Les composants propres au produit (fil de traçabilité, carte, jauges de score, mise en page des livres blancs) sont écrits spécifiquement.

### T-07 — Cartographie : D3 et TopoJSON, sans fond de carte en ligne

- **Options.** Leaflet ou MapLibre avec tuiles, D3 avec des contours vectoriels.
- **Choix : D3 (`d3-geo`) et TopoJSON.** Le besoin est une carte thématique (choroplèthe par UTR, zoom sur les départements), pas une carte routière. Les contours viennent du jeu COD-AB de la Côte d'Ivoire (niveau 1 : 33 unités ; niveau 2 : départements), simplifiés avec mapshaper et servis depuis `public/geo/`. Aucune tuile, aucun appel réseau.
- **Conséquences.** Le même code SVG produit la carte de l'interface et celle des livres blancs (§7). Licence des contours (CC BY-IGO) : attribution affichée sous chaque carte.

### T-08 — Animations : GSAP, avec parcimonie

- **Choix : GSAP** (gratuit, extensions comprises, dont ScrollTrigger), disponible pour les rares séquences que la direction d'interface jugera utiles (par exemple montrer le chemin d'une contribution jusqu'à un engagement), et chargé uniquement sur les pages concernées. Les transitions simples (survol, ouverture d'un panneau) restent en CSS. Pas d'animation décorative au défilement ni de décompte de chiffres (skill `lbc-interface`).
- **Règles.** Animer uniquement `transform` et `opacity` ; durée de 150 à 400 ms pour l'interface, au plus 1,2 s pour une séquence narrative ; aucune animation ne retarde une action ; `gsap.matchMedia()` désactive les séquences si `prefers-reduced-motion: reduce` (NF-33).

### T-09 — Texte enrichi : Tiptap

- **Choix : Tiptap** (sur ProseMirror) pour l'introduction des livres blancs et les synthèses (F-61). Le contenu est stocké en JSON ProseMirror, avec un jeu de nœuds restreint (paragraphe, titres 2 et 3, gras, italique, listes, lien). Ce format se convertit sans perte vers le web, le PDF et le Word (§7), contrairement à du HTML libre.

### T-10 — Documents : un modèle, trois rendus

- **Choix.** Un **modèle de document** JSON unique (`DocumentModel`) est construit à partir des données ; il est rendu en web (composants Vue), en **PDF** (impression d'une route dédiée par Chromium via Playwright) et en **Word** (bibliothèque `docx`). Détails au §7.
- **Pourquoi pas une conversion HTML vers Word.** Les convertisseurs produisent des styles approximatifs ; la bibliothèque `docx` produit de vrais styles Word (titres, table des matières), que l'administration pourra retravailler.

### T-11 — Validation : Zod partagé

- Les schémas Zod de `shared/schemas/` valident les formulaires côté client **et** les corps de requêtes côté serveur. Les messages d'erreur sont rédigés en français simple (NF-31).

### T-12 — Modèle de langage : interface prévue, désactivée

- Conformément à D-05, le MVP n'appelle aucun modèle de langage. Une interface `FournisseurRedaction` est définie (une méthode : proposer une synthèse à partir de propositions sources). Son implémentation de démonstration, si le temps le permet (F-75, évolution), appellera un modèle exécuté localement (par exemple via Ollama), jamais un service en ligne. Tout texte généré est marqué `texte_assiste = true` jusqu'à sa validation humaine.

### T-13 — Version mobile : application web progressive installable

- **Contexte.** L'équipe a décidé (D-16) que la version web s'utilise en ligne, et qu'une version mobile doit fonctionner hors connexion pour les zones où le réseau est irrégulier : préparer des contributions et les envoyer plus tard, relire ses contributions et les livres blancs déjà ouverts (F-38).
- **Options.** (a) Application native (Android) : deuxième base de code, publication sur un magasin, hors de portée en trois mois ; (b) application hybride (Capacitor) : même code, mais une chaîne de construction mobile en plus ; (c) **application web progressive** (PWA) : la même application Nuxt, installable depuis le navigateur du téléphone, avec un *service worker* qui garde en cache l'interface et les données nécessaires.
- **Choix : (c).** Une seule base de code, installation sans magasin, et le parcours de contribution existe déjà dans l'application. Module envisagé : `@vite-pwa/nuxt` (Workbox) ; sa compatibilité avec Nuxt 4 n'est pas confirmée officiellement : elle est vérifiée par un essai au début du lot 6 (la version mobile est réalisée après la version web), avec repli sur `vite-plugin-pwa` configuré directement ou sur un *service worker* écrit avec Workbox.
- **Ce qui fonctionne hors connexion** :
  - l'interface de la version mobile (pages mises en cache à l'installation) ;
  - le formulaire de contribution, avec les référentiels nécessaires gardés sur le téléphone (territoires sélectionnables, secteurs, édition active et sa date de fin de collecte) ;
  - la **file d'attente** : une contribution terminée sans réseau est enregistrée dans IndexedDB (bibliothèque `idb-keyval`) avec un identifiant `idClient` (UUID v7) et sa date de rédaction ;
  - la relecture de « Mes contributions » (dernier état reçu) et des livres blancs déjà ouverts.
- **Synchronisation.** Au retour du réseau (évènement `online`, et nouvelle tentative à chaque ouverture et toutes les 5 minutes, l'API Background Sync n'étant pas disponible partout), chaque contribution en attente est envoyée à `POST /contributions` avec son `idClient`. Le serveur applique toutes les règles à la réception (RG-30) ; un renvoi avec le même `idClient` renvoie la contribution déjà enregistrée au lieu d'en créer une autre. Refus (collecte close, limite du jour) : la contribution reste sur le téléphone avec le motif. Session expirée : l'envoi attend une nouvelle connexion.
- **Ce qui ne fonctionne pas hors connexion** : la suggestion de contributions proches (elle exige le serveur ; le regroupement automatique en préoccupation s'applique à la réception), les soutiens, les signalements et toute l'administration.
- **Conséquences.** Migration `0002_version_mobile.sql` (`id_client`, `saisie_le`) ; écran « En attente d'envoi » ; tests Playwright avec le réseau coupé (§13).

---

## 4. Architecture d'ensemble

### 4.1 Vue des conteneurs

![Architecture](../diagrams/technique/architecture.png)

| Conteneur | Rôle | Image |
|---|---|---|
| `app` | Rendu des pages et API `/api/v1` | Image du projet (Node 24, Chromium non nécessaire) |
| `worker` | Exécution des tâches pg-boss ; impression PDF | Même image, avec Chromium (Playwright) ; `RUN_WORKERS=true` |
| `postgres` | Données, file de tâches | `postgres:18` |
| `mailpit` | Serveur SMTP de test et boîte de lecture web | `axllent/mailpit` |

Un volume nommé `fichiers` est monté dans `app` et `worker` (photos, procès-verbaux, exports). Les fichiers ne sont jamais servis directement : ils passent par une route qui contrôle les droits (§9.5).

### 4.2 Couches du code serveur

```
requête HTTP
  └─ server/middleware      session, identifiant de requête, journal technique
      └─ server/api/v1      fichier mince : lit les paramètres, valide (Zod), appelle un service
          └─ server/modules/<module>/service.ts    règles applicatives, transactions, audit
              ├─ politique.ts     qui a le droit ? (rôle + périmètre territorial)
              ├─ requetes.ts      accès aux données (Drizzle)
              └─ server/engine    calculs purs du moteur d'analyse
```

Règles de dépendance :

- une route n'accède jamais directement à la base ;
- un module n'importe pas les `requetes.ts` d'un autre module : il passe par son service ;
- `server/engine` ne dépend ni de Nuxt ni de la base pour ses calculs (fonctions pures testables), sauf ses adaptateurs SQL regroupés dans `server/engine/sql/`.

### 4.3 Modes de rendu des pages

| Zone | Routes | Rendu | Raison |
|---|---|---|---|
| Portail public | `/`, `/carte`, `/regions/**`, `/livres-blancs/**`, `/priorites/**`, `/engagements/**`, `/recherche`, pages d'information | Rendu serveur, cache de 60 s (`swr`) pour les pages de livres blancs publiés | Premier affichage rapide sur mobile (NF-02), contenu indexable |
| Espace contributeur | `/espace/**`, `/contribuer` | Rendu serveur, sans cache | Données personnelles |
| Version mobile installée | `/contribuer`, `/espace/contributions`, `/livres-blancs/**` déjà ouverts, `/hors-connexion` | Coquille mise en cache par le *service worker* ; formulaire rendu côté client ; données lues dans IndexedDB sans réseau | Utilisation hors connexion (T-13) |
| Administration | `/admin/**` | Rendu côté client (`ssr: false`) | Écrans riches et interactifs, aucun besoin d'indexation |
| Impression | `/impression/**` | Rendu serveur, mise en page d'impression | Source des PDF (§7) ; accès réservé (§9.6) |

### 4.4 Chemin d'une contribution

![Séquence de dépôt](../diagrams/technique/sequence_depot.png)

---

## 5. Organisation du projet

```
livre-blanc-citoyen/
├─ app/                          interface (Nuxt 4)
│  ├─ assets/css/main.css        jetons du système de design (@theme Tailwind 4)
│  ├─ components/                ui/ · carte/ · contribution/ · preoccupation/ · livre-blanc/ · graphiques/ · tracabilite/
│  ├─ composables/               useSession, usePhase, usePerimetre, useBrouillonLocal, useFileAttente (version mobile)…
│  ├─ layouts/                   public · espace · admin · impression
│  ├─ middleware/                authentification.ts, role.ts (confort d'affichage ; le contrôle réel est serveur)
│  └─ pages/                     voir APP_FLOW.md (plan des écrans)
├─ server/
│  ├─ api/v1/                    une arborescence par ressource (voir API_SPECIFICATIONS.md)
│  ├─ modules/
│  │  ├─ comptes/                M1 — inscription, connexion, profil, organisations
│  │  ├─ referentiels/           M2 — territoires, secteurs, termes interdits
│  │  ├─ editions/               M2 — éditions, paramètres, transitions de phase
│  │  ├─ contributions/          M3 — dépôt, modification, soutiens, signalements, imports de terrain
│  │  ├─ moderation/             M4
│  │  ├─ analyse-regionale/      M5 — préoccupations, fusions, validation
│  │  ├─ livres-blancs/          M6, M8 — composition, publication, versions, exports
│  │  ├─ consolidation/          M7 — calculs, convergences, états généraux
│  │  ├─ engagements/            M9 — candidats, engagements, suivi
│  │  ├─ portail/                M10 — lectures publiques, traçabilité, recherche
│  │  ├─ statistiques/           M11
│  │  ├─ notifications/          M12
│  │  └─ audit/                  M13
│  ├─ engine/                    similarite.ts · regroupement.ts · scores.ts · consolidation.ts · union-find.ts · sql/
│  ├─ documents/                 modele.ts · construire-lbr.ts · construire-lbn.ts · rendu-docx.ts · rendu-pdf.ts · graphiques.ts
│  ├─ jobs/                      enregistrement des tâches et gestionnaires (§8)
│  ├─ db/                        client.ts · schema.ts (généré) · transaction.ts
│  ├─ middleware/                01.session.ts · 02.requete.ts
│  ├─ plugins/                   pg-boss.ts (démarre les gestionnaires si RUN_WORKERS=true)
│  └─ utils/                     erreurs.ts (RFC 9457) · autorisation.ts · audit.ts · pagination.ts · fichiers.ts
├─ shared/                       code commun client et serveur
│  ├─ schemas/                   schémas Zod (contribution, inscription, préoccupation…)
│  ├─ types/                     types du domaine, DocumentModel
│  └─ utils/                     phases.ts (machine à états), libelles.ts (textes de l'interface), formats.ts
├─ database/                     migrations SQL, tests SQL, MCD, données initiales (seeds/)
├─ public/geo/                   civ_utr.topo.json · civ_departements.topo.json
├─ tests/                        unit/ · integration/ · e2e/ · a11y/ · charge/
├─ docker/                       Dockerfile · compose.yaml
├─ scripts/                      migrer.ts · charger-demo.ts · sauvegarder.sh · restaurer.sh · calibrer-similarite.ts
└─ docs/                         PRD, TRD, APP_FLOW, schémas…
```

**Langue du code.** Les noms du domaine sont en français et suivent le glossaire du PRD (`contribution`, `preoccupation`, `convergence`, `livreBlanc`) ; le vocabulaire technique reste en anglais lorsqu'il est l'usage (`service`, `handler`, `store`, `props`). Les identifiants n'ont pas d'accents. Cette règle évite les traductions approximatives entre le métier, la base et le code.

---

## 6. Moteur d'analyse

Le moteur met en œuvre le §10 du PRD. Il est **déterministe** : avec les mêmes données et les mêmes paramètres, il produit le même résultat. Les paramètres utilisés sont stockés avec chaque calcul (`calcul_consolidation.parametres`) et chaque version publiée (`version_livre_blanc.parametres_figes`).

### 6.1 Paramètres d'une édition

Les paramètres sont stockés dans `edition.parametres` (JSON validé par un schéma Zod, figé hors préparation par RG-02) :

```json
{
  "seuils": { "suggestion": 0.20, "rattachement": 0.30, "doublon": 0.60, "convergence": 0.28, "cohesion_alerte": 0.20 },
  "ponderations_regionales": { "voix": 0.40, "urgence": 0.25, "etendue": 0.20, "collectif": 0.15, "diviseur_collectif": 3 },
  "ponderations_nationales": { "utr": 0.45, "population": 0.30, "score_regional": 0.25 },
  "classement": { "seuil_nationale": 5, "specifiques_par_utr": 3 },
  "limites": { "contributions_par_jour": 10, "signalements_moderation": 3, "taux_ouverture_etats_generaux": 0.80 }
}
```

Le schéma Zod vérifie que les pondérations de chaque score totalisent 1 (à 0,001 près) et que les seuils sont compris entre 0 et 1.

### 6.2 Similarité textuelle

La mesure est calculée par la fonction SQL `similarite_textes()` (voir `DATABASE_SCHEMA.md` §6, calibration comprise) :

```
similarite(A, B) = 0,5 × chevauchement(racines(A), racines(B)) + 0,5 × trigrammes(texte(A), texte(B))
```

Les racines et le texte normalisé de chaque contribution sont des colonnes générées et indexées ; pour une préoccupation, ce sont `texte_reference` et `lexemes_reference`, recalculés quand sa contribution représentative change.

**Recherche des contributions proches (F-32, NF-04).** La requête se fait en deux temps pour rester rapide :

1. *pré-filtre* : contributions publiées de la même édition et de la même UTR (et du même secteur s'il est choisi) qui partagent au moins une racine avec le texte saisi (`lexemes && :racines`, index GIN) ;
2. *calcul* de `similarite_textes()` sur ces candidates, filtre au seuil `suggestion`, tri décroissant, 5 résultats au plus.

### 6.3 Regroupement en préoccupations

Algorithme exécuté **dans la transaction du dépôt** (le résultat doit être visible immédiatement, critère d'acceptation de F-32) :

```
fonction rattacher(contribution c):
    verrou consultatif transactionnel sur (édition, UTR, secteur)        -- évite que deux dépôts simultanés
                                                                         -- créent deux préoccupations jumelles
    candidates ← préoccupations de (c.édition, c.UTR, c.secteur)
                 de statut PROPOSEE ou VALIDEE, non verrouillées,
                 partageant au moins une racine avec c
    meilleure ← argmax similarite(c, p.texte_reference) sur candidates
    si meilleure existe et similarite ≥ seuils.rattachement :
        c.id_preoccupation ← meilleure ; c.mode_rattachement ← 'AUTO' ; c.similarite_rattachement ← valeur
    sinon :
        créer p (statut PROPOSEE, intitulé provisoire = c.titre, représentative = c, texte de référence = texte de c)
        c.id_preoccupation ← p ; c.mode_rattachement ← 'AUTO'
    publier la tâche scores.recalculer_utr(c.édition, c.UTR)
```

Compléments :

- **Préoccupation verrouillée (RG-56).** Après publication du LBR, les préoccupations de l'UTR sont verrouillées. Une contribution de terrain importée à ce moment ne peut s'y rattacher : elle crée une nouvelle préoccupation `PROPOSEE`, que l'administrateur traitera dans une nouvelle version du LBR.
- **Représentative.** Quand le nombre de soutiens change, la tâche de recalcul désigne comme représentative la contribution la plus soutenue (la plus ancienne en cas d'égalité) et met à jour `texte_reference`.
- **Rattachements manuels.** Le moteur ne déplace jamais une contribution dont le rattachement est `MANUEL` (PRD §10.2, point 5).
- **Suggestions de fusion (F-52).** Calculées à la demande, pour l'écran de l'administrateur : paires de préoccupations non écartées de la même UTR et du même secteur dont la similarité des textes de référence atteint le seuil de rattachement, en excluant les paires déjà ignorées (stockées dans les préférences de l'écran, pas dans le modèle).
- **Doublons stricts (F-41).** Paires de contributions publiées du **même auteur**, même UTR, similarité ≥ `seuils.doublon`.

### 6.4 Scores régionaux

Tâche `scores.recalculer_utr(édition, UTR)` : elle lit `v_statistiques_preoccupation` pour toutes les préoccupations non écartées de l'UTR, calcule les scores en TypeScript (`server/engine/scores.ts`, fonction pure) puis met à jour `nb_voix`, `nb_contributions`, `score`, `score_detail` et `score_calcule_le` en une seule requête.

```
pour chaque préoccupation P de l'UTR R :
    V = ln(1 + voix(P)) / ln(1 + max_voix(R))          (0 si max_voix(R) = 0)
    U = (urgence_moyenne(P) − 1) / 3
    E = unités_concernées(P) / unités_de_R              (départements ; à défaut, mailles sélectionnables)
    C = min(1, organisations_vérifiées(P) / diviseur_collectif)
    score = 100 × (w_voix·V + w_urgence·U + w_etendue·E + w_collectif·C), arrondi à 0,1
    score_detail = { V, U, E, C, pondérations, voix, max_voix, calculé_le }
```

`score_detail` alimente l'affichage de la décomposition (P5). Les tâches sont **regroupées** : plusieurs dépôts rapprochés dans la même UTR ne déclenchent qu'un recalcul (clé d'unicité par UTR et délai de 30 secondes). Une tâche périodique recalcule toutes les UTR actives toutes les 15 minutes, par sécurité.

### 6.5 Consolidation nationale

Tâche `consolidation.calculer(édition)`, lancée par l'administrateur national (F-71) :

1. **Entrées (RG-60).** Les préoccupations incluses dans la version `PUBLIEE` de chaque LBR (`inclusion_preoccupation`), à l'exception de celles déjà rattachées à une convergence décidée (`RETENUE`, `FUSIONNEE`, `REJETEE`).
2. **Arêtes.** Dans chaque secteur, paires de préoccupations d'UTR **différentes** dont la similarité des textes de référence atteint `seuils.convergence` (requête SQL avec pré-filtre sur les racines communes).
3. **Composantes.** Structure *union-find* (union par rang, compression de chemin) : chaque composante connexe devient une convergence candidate.
4. **Cohésion.** Le regroupement par liens successifs peut réunir A et C parce que chacun ressemble à B. La cohésion est la moyenne des similarités entre **toutes** les paires de la composante ; sous `seuils.cohesion_alerte`, la convergence est signalée « à vérifier » dans l'écran d'arbitrage.
5. **Score national.** `T`, `P`, `S` et `Score_N` selon le PRD §10.4, avec pour dénominateurs les UTR couvertes par un LBR publié et leur population.
6. **Classe proposée.** `NATIONALE` si le nombre d'UTR distinctes atteint `classement.seuil_nationale`, `PARTAGEE` de 2 à ce seuil moins un, `SPECIFIQUE` pour une seule UTR. Pour les spécificités, seules les `specifiques_par_utr` premières de chaque UTR (par Score_R) deviennent des convergences ; les autres restent dans leur LBR, sans convergence.
7. **Texte proposé.** Intitulé de la préoccupation au Score_R le plus élevé ; propositions des préoccupations sources, classées par score, en écartant une proposition dont la similarité avec une proposition déjà retenue atteint `seuils.doublon`.
8. **Écriture.** Dans une transaction : suppression des convergences `PROPOSEE` sans décision issues d'un calcul précédent, insertion des nouvelles, mise à jour de `preoccupation.id_convergence`, rapport du calcul (nombre de convergences par classe et par secteur, convergences à vérifier, durée).

Complexité : le nombre de paires comparées est borné par le pré-filtre ; pour 40 000 préoccupations réparties en 14 secteurs (hypothèse NF-01), le calcul reste un traitement de fond de quelques minutes au plus, ce qui est acceptable pour une opération lancée quelques fois par édition.

### 6.6 Évolutions du moteur

| Évolution | Principe | Prérequis |
|---|---|---|
| Similarité sémantique | Plongements vectoriels calculés localement par un modèle multilingue, stockés avec `pgvector`, combinés à la mesure actuelle | Évaluation sur un corpus étiqueté (CS3) ; choix d'un modèle sous licence libre |
| Suggestion de secteur (F-31) | Score par mots-clés des secteurs, puis classifieur entraîné sur les contributions déjà classées | Volume suffisant de contributions classées |
| Projet de synthèse (F-75) | Modèle de langage local via `FournisseurRedaction` (T-12) | Validation humaine obligatoire |

---

## 7. Production des documents

![Pipeline des documents](../diagrams/technique/pipeline_documents.png)

### 7.1 Modèle de document

`DocumentModel` (type dans `shared/types/document.ts`) décrit un livre blanc indépendamment de son rendu :

```ts
interface DocumentModel {
  meta: { type: 'REGIONAL' | 'NATIONAL'; edition: string; utr?: string; version: number;
          publieLe?: string; parametres: ParametresEdition; empreinte?: string }
  sections: Section[]          // arborescence : titre, niveau, blocs
}
type Bloc =
  | { type: 'texte'; contenu: ProseMirrorJSON }
  | { type: 'chiffres'; elements: { libelle: string; valeur: number; unite?: string }[] }
  | { type: 'graphique'; specification: SpecGraphique }        // barres, répartition, évolution
  | { type: 'carte'; specification: SpecCarte }                // choroplèthe UTR ou départements
  | { type: 'preoccupation'; donnees: FichePreoccupation }     // intitulé, synthèse, voix, score détaillé, références
  | { type: 'convergence'; donnees: FicheConvergence }
  | { type: 'tableau'; colonnes: string[]; lignes: string[][] }
```

Les constructeurs `construire-lbr.ts` et `construire-lbn.ts` suivent les structures du PRD (§11, M6 et M8).

### 7.2 Figement

À la publication (RG-54), le modèle est sérialisé dans `version_livre_blanc.contenu_fige`, avec les paramètres dans `parametres_figes` et l'empreinte SHA-256 de la sérialisation canonique (clés triées) dans `empreinte_sha256`. Les rendus d'une version publiée sont produits **uniquement** à partir de `contenu_fige` : un livre blanc publié reste identique même si les données vivantes évoluent ensuite.

### 7.3 Rendus

| Rendu | Technique | Remarques |
|---|---|---|
| Web | Composants Vue qui parcourent le modèle | Sommaire navigable, liens de traçabilité (F-82, F-103) |
| PDF | La tâche `document.generer` ouvre `/impression/livres-blancs/{id}/versions/{n}` dans Chromium (Playwright) et appelle l'impression PDF (A4, en-têtes et pieds de page, numérotation) | CSS d'impression : `@page`, sauts de page avant les chapitres, polices embarquées |
| Word | Bibliothèque `docx` : styles Titre 1 à 3, table des matières, tableaux, images | Graphiques et cartes convertis de SVG en PNG par `@resvg/resvg-js` (rendu sans navigateur) |

Les graphiques et cartes sont produits en SVG **côté serveur** par une même fonction (`server/documents/graphiques.ts`, D3 sans DOM), ce qui garantit des visuels identiques dans les trois rendus. Les fichiers générés sont enregistrés dans `fichier` et liés à la version (`id_fichier_pdf`, `id_fichier_docx`). Objectif NF-05 : moins de 60 secondes par document.

---

## 8. Tâches de fond

| Tâche | Déclencheur | Traitement | Reprises |
|---|---|---|---|
| `scores.recalculer_utr` | Dépôt, modification, soutien, fusion, déplacement, import | §6.4 ; regroupée par UTR (30 s) | 3, délai croissant |
| `scores.recalculer_tout` | Périodique (15 min) pendant `COLLECTE` et `CONSOLIDATION_REGIONALE` | Recalcul de sécurité de toutes les UTR | — |
| `consolidation.calculer` | Administrateur national (F-71) | §6.5 | 1 |
| `document.generer` | Publication, demande d'export (F-81) | §7 ; notification à la fin | 2 |
| `import.terrain` | Téléversement d'un fichier de consultation (F-35) | Contrôle ligne par ligne, insertion, rapport d'erreurs | 0 (rapport) |
| `email.envoyer` | Notifications (F-120), jetons | Envoi SMTP ; marque `email_envoye_le` | 5, délai croissant |
| `maintenance.purger` | Quotidienne | Sessions expirées, jetons utilisés ou expirés, fichiers orphelins de plus de 24 h | — |
| `maintenance.anonymiser` | Quotidienne | Comptes supprimés à anonymiser ; comptes dont la durée de conservation est échue (NF-24) | — |

Chaque tâche est **idempotente** : la rejouer après une panne ne crée pas de doublon (clés d'unicité, `INSERT … ON CONFLICT`, remplacement des résultats d'un calcul).

---

## 9. Sécurité

### 9.1 Comptes et mots de passe

- Mot de passe de 10 caractères au moins, refusé s'il figure dans une liste locale de mots de passe courants ou s'il contient l'adresse e-mail (NF-11).
- Hachage scrypt via `hashPassword()` / `verifyPassword()` de nuxt-auth-utils.
- Verrouillage de 15 minutes après 5 échecs consécutifs (RG-17), réponse identique que le compte existe ou non (pas d'énumération des comptes).
- Jetons à usage unique (vérification d'e-mail 24 h, réinitialisation 1 h, invitation 7 jours) : 32 octets aléatoires envoyés par e-mail, seule leur empreinte SHA-256 est stockée (table `jeton`).
- Changement de mot de passe et réinitialisation : révocation de toutes les autres sessions.

### 9.2 Sessions

- Cookie `HttpOnly`, `SameSite=Lax`, `Secure` hors développement local, scellé avec `NUXT_SESSION_PASSWORD` (32 caractères au moins).
- Contenu du cookie : identifiant de session uniquement. Le middleware `01.session.ts` charge la session, vérifie `expire_le` et `revoquee_le`, puis charge l'utilisateur et ses affectations actives dans `event.context.acteur`.
- Durée : 7 jours d'inactivité au plus, 30 jours au total ; 8 heures pour les comptes d'administration.

### 9.3 Autorisations

Contrôle **côté serveur à chaque requête** (NF-10), en deux temps :

1. **Rôle** : l'acteur possède-t-il un rôle autorisé pour l'action (matrice du PRD §7.3) ?
2. **Périmètre** : la ressource est-elle dans son périmètre (UTR d'une affectation d'administrateur régional, objet dont il est l'auteur, UTR de candidature) ?

Chaque module expose ses règles dans `politique.ts` sous la forme de fonctions pures, par exemple :

```ts
export const politiqueModeration = {
  decider: (acteur: Acteur, c: Contribution) =>
    estAdminNational(acteur) || (administreUtr(acteur, c.idUtr) && c.idAuteur !== acteur.id)   // RG-44
}
```

Le service appelle `exiger(politique.decider(acteur, contribution))`, qui lève une erreur 403. Les listes sont **filtrées** par périmètre dans la requête SQL (jamais après coup). Les tests d'autorisation parcourent la matrice du PRD pour chaque rôle (§13.3).

### 9.4 Protection des requêtes

| Menace | Mesure |
|---|---|
| Falsification de requête (CSRF) | Cookie `SameSite=Lax`, vérification de l'en-tête `Origin` sur toute requête qui modifie des données, jeton CSRF (module `nuxt-csurf` activé par nuxt-security) |
| Injection SQL | Requêtes paramétrées (Drizzle, `sql` tagué) ; aucune concaténation de texte utilisateur |
| XSS | Échappement par Vue ; aucun `v-html` sur du contenu utilisateur ; texte enrichi rendu depuis le JSON ProseMirror avec une liste blanche de nœuds ; politique CSP stricte (nuxt-security) |
| Force brute, abus | Limitation du débit (nuxt-security) : connexion 5/min par adresse IP et par e-mail, inscription 3/h par IP, réinitialisation 3/h, dépôt 10/jour (RG-26, contrôle applicatif), recherche de similarité 30/min |
| En-têtes | `Strict-Transport-Security` (hors local), `X-Content-Type-Options`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy` restrictive (nuxt-security) |
| Exposition de données | Sérialiseurs publics explicites (liste blanche de champs) ; application de RG-29 dans le sérialiseur, pas dans l'interface |

### 9.5 Fichiers téléversés (NF-14)

1. Taille vérifiée avant lecture complète (5 Mo par photo, 10 Mo par procès-verbal ou fichier d'import).
2. Type réel déterminé par la signature binaire (pas par l'extension ni par l'en-tête de la requête) : JPEG, PNG, WebP pour les photos ; PDF ; CSV et XLSX pour les imports.
3. Photos ré-encodées avec `sharp` : métadonnées EXIF supprimées (dont la géolocalisation), plus grand côté limité à 2 000 pixels, conversion en WebP.
4. Stockage hors de la racine web, sous un nom aléatoire (`chemin_stockage`), avec empreinte SHA-256.
5. Diffusion par `/api/v1/fichiers/{id}` : contrôle des droits (photo d'une contribution publiée, procès-verbal d'une version publiée, sinon auteur ou administrateur), en-tête `Content-Disposition` et `X-Content-Type-Options: nosniff`.

### 9.6 Routes d'impression

Les routes `/impression/**` affichent des brouillons non publiés. Elles exigent soit une session d'administrateur ayant accès au livre blanc, soit un jeton signé à courte durée (5 minutes) généré par le worker pour la tâche `document.generer`.

### 9.7 Liste de contrôle OWASP Top 10 (NF-15)

La stratégie de tests (§13) comprend une liste de contrôle reprenant les dix catégories de l'OWASP Top 10 ; pour chacune, le test ou la mesure qui la couvre est indiqué, et la liste est revue avant la démonstration.

---

## 10. Données personnelles

| Exigence | Mise en œuvre |
|---|---|
| Minimisation (NF-21) | Seuls les champs de RG-10 sont demandés ; le téléphone et le sexe sont facultatifs ; l'âge n'est connu que par l'année de naissance |
| Affichage public (RG-29) | Sérialiseur public : « Citoyen·ne de [commune] » sauf choix explicite de l'auteur |
| Droit d'accès (NF-22) | Export JSON des données du compte (F-14) |
| Suppression (RG-16) | Anonymisation immédiate des données d'identification (nom, prénoms, e-mail remplacés, mot de passe effacé, statut `SUPPRIME`) ; contributions et soutiens conservés sans identité |
| Journaux (NF-23) | Journaux techniques sans e-mail ni nom ; le journal d'audit référence les identifiants |
| Conservation (NF-24) | Tâche `maintenance.anonymiser` ; durée paramétrable |
| Statistiques (F-111, F-112) | Agrégats uniquement ; une case de moins de 5 personnes est masquée dans les exports et tableaux publics |

---

## 11. Journalisation et audit

- **Journal technique.** Une ligne JSON par requête (identifiant de requête, route, statut, durée, identifiant d'acteur) et par tâche ; niveau configurable (`NUXT_LOG_LEVEL`). Aucune donnée personnelle ni contenu de contribution.
- **Journal d'audit (F-130, RG-45).** L'utilitaire `auditer(tx, { action, typeObjet, idObjet, avant, apres, motif })` écrit **dans la même transaction** que l'action. Codes d'action au format `OBJET.VERBE` (par exemple `PREOCCUPATION.FUSIONNER`, `EDITION.CHANGER_PHASE`, `LIVRE_BLANC.PUBLIER`). La table refuse toute modification ou suppression (déclencheur).
- **Erreurs.** Réponses au format RFC 9457 (`application/problem+json`) avec un code métier stable (`regle: "RG-53"`) et un message en français ; les erreurs levées par les déclencheurs SQL (`P0001`, message préfixé par la règle) sont converties en 409 ou 422 avec le même code de règle (détails dans `API_SPECIFICATIONS.md`).

---

## 12. Interface : exigences techniques

| Sujet | Exigence |
|---|---|
| Budget de performance (NF-02) | JavaScript initial des pages publiques inférieur à 250 Ko compressé ; carte, GSAP et Tiptap chargés à la demande ; polices auto-hébergées (deux familles au plus, sous-ensemble latin) ; images en WebP avec dimensions déclarées |
| Formulaire de contribution (F-30) | Étapes navigables au clavier ; brouillon enregistré dans le stockage local du navigateur à chaque étape (lecture et écriture protégées par `try/catch`) ; reprise proposée au retour |
| Version mobile (F-38) | Installable (manifeste, icônes) ; indicateur de réseau ; écran « En attente d'envoi » avec l'état de chaque contribution (en attente, envoyée, refusée et pourquoi) ; aucune action proposée qui exige le réseau quand il manque |
| Accessibilité (NF-30) | Composants Reka UI ; contraste vérifié sur les jetons ; focus visible ; libellés explicites ; carte doublée d'un tableau accessible ; graphiques avec résumé textuel |
| Animations (NF-33) | §3, T-08 |
| États de chargement | Squelettes pour les listes, aucune page blanche ; actions longues (exports, calcul) suivies par une notification |
| Textes | Centralisés dans `shared/utils/libelles.ts` (NF-44) |
| Navigateurs (NF-40) | Deux dernières versions de Chrome, Firefox, Edge, Safari et Chrome Android ; tests Playwright sur Chromium, Firefox et WebKit |

---

## 13. Stratégie de tests

### 13.1 Niveaux

| Niveau | Outil | Portée | Seuil |
|---|---|---|---|
| Règles en base | Script SQL (`database/tests`) | Contraintes et déclencheurs : 60 contrôles à ce jour | Tous passants |
| Hors connexion | Playwright avec le réseau coupé (`context.setOffline`) | Contribution préparée sans réseau, envoi au retour, renvoi sans doublon, refus après la clôture | Scénarios passants |
| Unitaire | Vitest | `server/engine`, politiques d'autorisation, schémas Zod, constructeurs de documents | Couverture des lignes ≥ 90 % pour `engine/` et `politique.ts` |
| Intégration | Vitest + PostgreSQL réel (base jetable par fichier de test) | Services : transactions, audit, enchaînement avec les déclencheurs | Couverture ≥ 80 % pour `modules/` |
| API | `@nuxt/test-utils` (`$fetch` sur le serveur démarré) | Codes de statut, format des erreurs, autorisations par rôle | Matrice §7.3 du PRD entièrement couverte |
| Bout en bout | Playwright | Scénario de démonstration du PRD §14.3 et parcours de `APP_FLOW.md` | Scénario complet passant |
| Accessibilité | `@axe-core/playwright` | Pages principales de chaque zone | Aucune violation de niveau A ou AA |
| Performance | Lighthouse (profil mobile) ; k6 pour l'API | NF-02, NF-03, NF-04 sur le jeu de démonstration | Budgets du PRD |

### 13.2 Calibration du moteur (critère CS3)

`scripts/calibrer-similarite.ts` calcule, sur un corpus de paires étiquetées (« même besoin » ou « besoins différents »), la précision et le rappel du rattachement pour une grille de seuils, et propose le seuil qui maximise la précision à rappel ≥ 0,80. Le corpus de démonstration doit compter au moins 200 paires étiquetées.

### 13.3 Tests d'autorisation

Un fichier de cas décrit, pour chaque ligne de la matrice des droits, l'action, la ressource et le résultat attendu pour chaque rôle (y compris hors périmètre). Le même fichier alimente les tests unitaires des politiques et les tests d'API.

---

## 14. Déploiement local

### 14.1 Prérequis

Docker et Docker Compose ; 4 Go de mémoire disponibles. Pour le développement sans conteneur : Node 24 LTS, pnpm, PostgreSQL 18.

### 14.2 Commandes

```bash
cp .env.exemple .env                       # puis renseigner NUXT_SESSION_PASSWORD
docker compose up -d                       # app (http://localhost:3000), worker, postgres, mailpit (http://localhost:8025)
docker compose exec app pnpm migrer        # applique les migrations
docker compose exec app pnpm charger-demo  # territoires, secteurs, comptes et contributions de démonstration
```

### 14.3 Services

| Service | Port local | Volume | Santé |
|---|---|---|---|
| `app` | 3000 | `fichiers` | `GET /api/v1/sante` |
| `worker` | — | `fichiers` | Battement enregistré en base toutes les 30 s |
| `postgres` | 5432 (réservé à la machine hôte) | `donnees_pg` | `pg_isready` |
| `mailpit` | 8025 (web), 1025 (SMTP) | — | — |

### 14.4 Sauvegarde et restauration (NF-43)

`scripts/sauvegarder.sh` produit une archive horodatée (`pg_dump` au format personnalisé et copie du volume `fichiers`) ; `scripts/restaurer.sh` la recharge dans une base vide. La procédure est testée avant la démonstration.

### 14.5 Jeu de démonstration

`scripts/charger-demo.ts` charge : le référentiel territorial (33 UTR et leurs départements ; sous-préfectures et communes pour les UTR du scénario) ; les 14 secteurs ; les comptes de démonstration (un par rôle) ; au moins 5 000 contributions fictives réparties sur les UTR, générées à partir de modèles de constats par secteur, avec des variantes de formulation pour exercer le regroupement. Le scénario du PRD §14.3 s'appuie sur ce jeu.

---

## 15. Configuration

| Variable | Exemple | Rôle |
|---|---|---|
| `DATABASE_URL` | `postgres://lbc:lbc@postgres:5432/lbc` | Connexion PostgreSQL |
| `NUXT_SESSION_PASSWORD` | 32 caractères aléatoires au moins | Scellement des cookies de session |
| `NUXT_PUBLIC_SITE_URL` | `http://localhost:3000` | Liens des e-mails, vérification de l'en-tête `Origin` |
| `RUN_WORKERS` | `false` (app), `true` (worker) | Démarre les gestionnaires de tâches |
| `SMTP_HOST`, `SMTP_PORT` | `mailpit`, `1025` | Envoi des e-mails |
| `EMAIL_EXPEDITEUR` | `Livre Blanc Citoyen <ne-pas-repondre@livreblanc.local>` | Expéditeur |
| `FICHIERS_DIR` | `/data/fichiers` | Racine du stockage des fichiers |
| `IMPRESSION_SECRET` | 32 caractères aléatoires au moins | Signature des jetons d'impression (§9.6) |
| `NUXT_LOG_LEVEL` | `info` | Niveau du journal technique |
| `REDACTION_ASSISTEE` | `off` | Active le fournisseur de rédaction (T-12) |

Les secrets ne sont jamais versionnés ; `.env.exemple` liste les variables sans valeurs secrètes.

---

## 16. Versions des dépendances

Relevé du 12 novembre 2026. Les versions exactes sont figées dans `pnpm-lock.yaml` au démarrage de l'implémentation ; une montée de version majeure en cours de projet fait l'objet d'une décision `T-xx`.

| Dépendance | Version visée | Remarque |
|---|---|---|
| Node.js | 24 LTS | Node 26 est devenu LTS fin octobre 2026 ; Node 24 reste maintenu et éprouvé avec l'écosystème |
| Nuxt | 4.6.x (dernier correctif de sécurité) | Vite 8 |
| Nuxt UI | 4.x | Tailwind CSS 4 |
| PostgreSQL | 18 | Schéma compatible 16 et plus |
| Drizzle ORM / drizzle-kit | dernière version stable 0.x au démarrage | La branche 1.0 était encore en version candidate lors du relevé |
| pg-boss | dernière version majeure | Node ≥ 22.12 et PostgreSQL ≥ 13 exigés |
| nuxt-auth-utils | dernière version | — |
| nuxt-security | 2.x | Compatible Nuxt 3 et 4 |
| Zod | 4.x | — |
| GSAP | 3.x | Licence gratuite, extensions comprises |
| d3-geo, topojson-client | dernières versions | — |
| Tiptap | dernière version majeure | Extensions de base uniquement |
| docx | dernière version | — |
| Playwright | dernière version | PDF et tests de bout en bout |
| @vite-pwa/nuxt, idb-keyval | dernières versions | Version mobile ; compatibilité avec Nuxt 4 vérifiée au lot 6 (T-13) |
| @resvg/resvg-js, sharp | dernières versions | — |
| Vitest, @nuxt/test-utils, @axe-core/playwright | dernières versions | — |

---

## 17. Correspondance des exigences non fonctionnelles

| Exigence | Mécanisme | Vérification |
|---|---|---|
| NF-01 volumétrie | Index (DATABASE_SCHEMA §4.3), pré-filtre du moteur, tâches de fond | Jeu de 5 000 contributions ; extrapolation documentée |
| NF-02 pages publiques | Rendu serveur, budget JS, cache `swr` | Lighthouse mobile |
| NF-03 API de lecture | Index, pagination par curseur, sérialiseurs légers | k6, 95ᵉ centile |
| NF-04 suggestions | Pré-filtre GIN + fonction SQL | Test de charge sur une UTR de 50 000 contributions générées |
| NF-05 documents | Tâche de fond, rendu unique | Mesure dans le test de bout en bout |
| NF-10 à NF-15 sécurité | §9 | Tests d'autorisation, liste OWASP |
| NF-20 à NF-24 données personnelles | §10 | Tests d'intégration (anonymisation, sérialiseurs) |
| NF-30 à NF-33 accessibilité et ergonomie | §12, T-06, T-08 | axe, revue clavier manuelle |
| NF-32 version web et version mobile | T-13, §4.3, §12 | Tests à 1 440 px et 390 px ; tests hors connexion |
| NF-40 navigateurs | — | Playwright sur trois moteurs |
| NF-41 exécution locale | Docker Compose, script de démonstration | Installation sur une machine vierge avant la soutenance |
| NF-42 maintenabilité | TypeScript strict, modules, tests | Seuils de couverture §13.1 |
| NF-43 sauvegarde | §14.4 | Restauration testée |
| NF-44 langue | Textes centralisés | Revue |

---

## 18. Risques techniques

| # | Risque | Effet | Mesure |
|---|---|---|---|
| RT-01 | La similarité lexicale confond ou sépare mal certains besoins | Préoccupations trop fines ou trop larges | Seuils prudents, suggestions de fusion, calibration CS3, similarité sémantique en évolution |
| RT-02 | Le regroupement par liens successifs crée des convergences hétérogènes | Arbitrage plus long | Indicateur de cohésion, scission dans l'écran d'arbitrage |
| RT-03 | Écarts de rendu entre le PDF et le Word | Documents incohérents | Modèle unique, graphiques produits par la même fonction, tests de bout en bout sur les deux exports |
| RT-04 | Chromium alourdit l'image du worker | Démarrage plus long, mémoire | Chromium limité au worker ; un seul navigateur réutilisé entre les tâches |
| RT-05 | Montées de version pendant le projet (Nuxt, Drizzle) | Régressions | Versions figées par le fichier de verrouillage ; montée uniquement pour un correctif de sécurité |
| RT-06 | Référentiel territorial incomplet (sous-préfectures absentes du jeu COD-AB utilisé) | Maille de saisie moins fine | RG-21 : la maille la plus fine disponible est retenue ; compléments saisis pour les UTR de démonstration |
| RT-07 | Module PWA incompatible avec Nuxt 4 ou mise en cache défaillante | Version mobile non installable ou inutilisable sans réseau | Essai au début du lot 6 ; repli sur `vite-plugin-pwa` ou Workbox directement ; à défaut, file d'attente dans IndexedDB sans installation |
