# IMPLEMENTATION_PLAN — Plan de réalisation du prototype

| Champ | Valeur |
|---|---|
| Version | 1.1 — version web d'abord, version mobile en lot 6 (13 novembre 2026) |
| Période | Du 7 décembre 2026 au 13 janvier 2027 (tâches 5.1 à 5.5 du planning) |
| Équipe | SORO K. S. Samuel (responsable), AZOUASSI Ô. Sara Océane, GLEDE D. Henri Joël, WOGNIN Noé Phinées |
| Exécution | Développement assisté par Claude Code, à partir de `CLAUDE.md` |
| Références | `PRD.md` v1.2 · `TRD.md` · `DATABASE_SCHEMA.md` · `API_SPECIFICATIONS.md` · `APP_FLOW.md` · `UX_SPECIFICATIONS.md` · `UI_DESIGN_SYSTEM.md` |

---

## 1. Stratégie

1. **Le socle d'abord.** La base de données et ses règles sont déjà écrites et testées (60 contrôles). Le premier lot les branche à une application qui démarre, se connecte et applique les autorisations ; tout le reste s'appuie dessus.
2. **Une tranche verticale par lot.** Chaque lot livre des écrans utilisables de bout en bout (base, service, API, interface, tests), dans l'ordre de la chaîne métier : collecte, analyse régionale, consolidation nationale, portail et engagements. À la fin de chaque lot, le scénario de démonstration (PRD §14.3) avance d'une ou deux étapes.
3. **Le moteur d'analyse est testé à part.** Ses calculs sont des fonctions pures (TRD §4.2) couvertes par des tests unitaires avant d'être branchées.
4. **Les fonctionnalités S viennent après les M**, dans l'ordre du PRD §14.1 ; elles sont abandonnées sans hésiter si un lot prend du retard (§6).
5. **La version web d'abord, la version mobile ensuite.** Les lots 0 à 5 réalisent et stabilisent la version web, utilisée en ligne. La version mobile installable (D-16, F-38) n'est commencée qu'une fois la version web terminée et testée : c'est le lot 6. Le portail propose alors une page « Télécharger l'application mobile ».
6. **Les interfaces sont conçues par Claude Code.** Les premières maquettes n'ont pas été retenues. Claude Code propose au lot 0 deux directions d'interface sur des écrans réels, l'équipe en choisit une (tâche 0.8), puis chaque écran est conçu dans cette direction à partir de `UX_SPECIFICATIONS.md` (ce que l'écran doit permettre) et validé par l'équipe sur ordinateur et sur un téléphone. Exigence : aucune présentation qui fasse « générée par une IA » (skill `lbc-interface`).

## 2. Vue d'ensemble des lots

| Lot | Dates | Tâche du planning | Contenu | Étapes du scénario §14.3 couvertes |
|---|---|---|---|---|
| 0 | 7 au 11 décembre | 5.1 | Socle technique, comptes, autorisations, direction d'interface | 1 (partiellement), 2 (inscription) |
| 1 | 14 au 18 décembre | 5.2 | Collecte, modération, organisations, notifications | 2, 3 |
| 2 | 21 au 24 décembre | 5.2 | Analyse régionale et livre blanc régional, exports | 5 |
| 3 | 28 au 31 décembre | 5.3 | Consolidation nationale, états généraux, livre blanc national | 6 |
| 4 | 4 et 5 janvier | 5.3 | Portail public, traçabilité, candidats, engagements, suivi, jeu de démonstration | 4, 7, 8, 9 |
| 5 | 6 au 8 janvier | 5.4 | Tests de bout en bout, accessibilité, performance, sécurité, installation propre de la version web | 1 à 9 enchaînés |
| 6 | 11 au 13 janvier | 5.5 | Version mobile installable, utilisable sans réseau ; page « Télécharger l'application mobile » | 3 (sans réseau) |

Le 25 décembre et le 1er janvier ne sont pas travaillés. La rédaction du chapitre V du rapport (captures et commentaires des interfaces) se fait du 6 au 13 janvier, à partir de l'application réalisée.

## 3. Détail des lots

### Lot 0 — Socle (7 au 11 décembre)

| Tâche | Livrable | Références |
|---|---|---|
| 0.1 Créer le projet Nuxt 4 (TypeScript strict, pnpm), l'arborescence du TRD §5, ESLint, Vitest, Playwright | Le projet démarre et les tests vides passent | TRD §5, §16 |
| 0.2 Docker Compose : `app`, `worker`, `postgres`, `mailpit` ; `.env.exemple` | `docker compose up -d` démarre l'ensemble | TRD §14, §15 |
| 0.3 Commande `pnpm migrer` (table `migration_appliquee`, empreintes) ; migration `0001` appliquée ; `drizzle-kit pull` | Schéma Drizzle généré ; tests SQL passants dans le conteneur | TRD T-03 ; `database/` |
| 0.4 Données initiales : 33 UTR et départements (CSV), 14 secteurs, une édition en préparation, un compte par rôle | `pnpm charger-demo --base` | DATABASE_SCHEMA §9 |
| 0.5 Utilitaires serveur : erreurs RFC 9457 et conversion des erreurs PostgreSQL, `auditer()`, transactions, pagination par curseur, `exiger()` et politiques | Tests unitaires des conversions et des politiques | TRD §9.3, §11 ; API §1, §2 |
| 0.6 Comptes : inscription, vérification d'e-mail, connexion, déconnexion, mot de passe oublié, sessions révocables, verrouillage, limitation du débit | F-10 à F-13, RG-10 à RG-12, RG-17 | API M1 ; TRD §9.1, §9.2 |
| 0.7 Gabarits techniques : `main.css` (`@theme`), polices auto-hébergées, thème Nuxt UI, gabarits `public`, `espace`, `admin`, `impression`, pages d'erreur | Gabarits prêts à recevoir la direction retenue | UI_DESIGN_SYSTEM §6 |
| 0.8 Direction d'interface : deux directions sur trois écrans réels (accueil du portail, une étape du formulaire de contribution, liste et fiche des préoccupations régionales), captures, choix de l'équipe, mise à jour des jetons et de `UI_DESIGN_SYSTEM.md` | Direction validée par l'équipe le 11 décembre | skill `lbc-interface` ; UX_SPECIFICATIONS |

**Fini quand** : un visiteur s'inscrit, reçoit le lien dans Mailpit, se connecte ; un administrateur régional n'accède qu'à son UTR (test d'API) ; la chaîne d'intégration continue locale (`pnpm test`) passe ; la direction d'interface est validée et appliquée aux pages d'inscription et de connexion.

### Lot 1 — Collecte (14 au 18 décembre)

| Tâche | Fonctionnalités |
|---|---|
| 1.1 Administration minimale des éditions : création, paramètres, écran de transition de phase avec préconditions | F-22, F-23, RG-01 à RG-03 |
| 1.2 Moteur : recherche des contributions proches, rattachement automatique avec verrou consultatif, doublons stricts | §10.1, §10.2 ; TRD §6.2, §6.3 |
| 1.3 Formulaire de contribution en 7 étapes avec brouillon local, contributions proches à la relecture, publication | F-30, F-32, F-33 ; UX §5 |
| 1.4 Soutiens et signalements ; filtre de termes ; mise en modération automatique | F-36, F-37, RG-27, RG-40 |
| 1.5 « Mes contributions » avec frise d'état, modification et retrait historisés | F-34, RG-25 |
| 1.6 Organisations : création, représentant, vérification par l'administration régionale | F-15, RG-14, RG-15 |
| 1.7 Modération : file, décisions motivées, doublons stricts, notification de l'auteur | F-40 à F-42, RG-41 à RG-44 |
| 1.8 Notifications dans l'application et par e-mail (tâche `email.envoyer`) | F-120 |
| 1.9 Fichiers : téléversement sécurisé des photos (sharp, EXIF retirés), diffusion contrôlée | NF-14 ; TRD §9.5 |

**Fini quand** : les étapes 2 et 3 du scénario passent dans un test Playwright ; le dépôt d'une contribution renvoie sa préoccupation en moins de 2 secondes sur le jeu de base.

### Lot 2 — Analyse régionale et livre blanc régional (21 au 24 décembre)

| Tâche | Fonctionnalités |
|---|---|
| 2.1 File pg-boss et worker ; tâche `scores.recalculer_utr` regroupée par UTR ; recalcul périodique | TRD §6.4, §8 |
| 2.2 Préoccupations : liste filtrée, fiche, suggestions de fusion, fusion, déplacement, scission, validation par lot, écartement motivé | F-50 à F-54, RG-43, RG-52, RG-56 ; UX §7.1 |
| 2.3 Tableau de bord régional | F-55 |
| 2.4 `DocumentModel`, constructeur du LBR, aperçu web, éditeur Tiptap de l'introduction | F-60, F-61 ; TRD §7 |
| 2.5 Contrôles de publication, publication avec figement et empreinte, nouvelle version | F-62, F-63 (S), RG-53 à RG-56 |
| 2.6 Exports : route d'impression et PDF (Playwright), DOCX (`docx`), graphiques SVG et PNG | F-81, NF-05 |
| 2.7 (S) Import des consultations de terrain | F-35, RG-28, D-10 |

**Fini quand** : l'étape 5 du scénario passe ; le PDF et le DOCX du LBR du Gôh s'ouvrent et contiennent les mêmes préoccupations dans le même ordre.

### Lot 3 — Consolidation nationale (28 au 31 décembre)

| Tâche | Fonctionnalités |
|---|---|
| 3.1 Avancement des 33 LBR ; contrôle d'ouverture des états généraux (80 %) | F-70, RG-61 |
| 3.2 Moteur de consolidation : arêtes, union-find, cohésion, score national, classes, texte proposé ; tâche `consolidation.calculer` et rapport | F-71 ; TRD §6.5 |
| 3.3 Matrice secteurs × UTR | F-72 |
| 3.4 Liste des convergences et écran d'arbitrage : retenir, reclasser, fusionner, scinder, rejeter, rouvrir ; journal des décisions | F-73, F-74, RG-62 à RG-64 ; UX §7.2 |
| 3.5 Constructeur du LBN, publication et exports | F-80, F-81, RG-65 |

**Fini quand** : l'étape 6 du scénario passe ; le LBN est généré en PDF et DOCX en moins de 60 secondes (CS4).

### Lot 4 — Portail public, engagements et démonstration (4 et 5 janvier)

| Tâche | Fonctionnalités |
|---|---|
| 4.1 Accueil narratif, page Carte (D3, COD-AB), pages d'UTR | F-100 à F-102 ; UX §4 |
| 4.2 Pages de préoccupation, de priorité, de contribution ; fil de traçabilité | F-103 ; UX §6 ; CS2 |
| 4.3 Recherche plein texte ; pages d'information (charte, méthode, données personnelles, FAQ) | F-104, F-105 |
| 4.4 Bibliothèque et lecture des livres blancs | F-82 |
| 4.5 Candidats, espace candidat, engagements, comparaison publique, suivi des réalisations, tableau de bord des élus | F-90 à F-94, RG-70 à RG-75 |
| 4.6 Statistiques nationales et de représentativité ; journal d'audit consultable | F-110, F-111, F-131 |
| 4.7 Jeu de démonstration : environ 5 000 contributions sur 8 UTR, avec reformulations ; publication par script d'au moins 27 LBR (seuil de 80 %) ; 200 paires étiquetées ; script de calibration | PRD §14.3 étape 4 ; TRD §13.2 ; CS3 |

**Fini quand** : les étapes 4, 7, 8 et 9 du scénario passent ; depuis une priorité nationale, on atteint une contribution d'origine en trois clics au plus (CS2).

### Lot 5 — Stabilisation (6 au 8 janvier)

| Tâche | Critère |
|---|---|
| 5.1 Test Playwright du scénario complet, sans intervention en base | CS1 |
| 5.2 Tests d'autorisation sur toute la matrice des droits | NF-10 |
| 5.3 axe sur les pages principales ; parcours clavier manuel | NF-30 |
| 5.4 Lighthouse mobile sur l'accueil, une page d'UTR et une priorité ; k6 sur l'API de lecture | NF-02, NF-03, NF-04 |
| 5.5 Liste de contrôle OWASP Top 10 | NF-15 |
| 5.6 Sauvegarde et restauration testées ; installation sur une machine vierge en suivant le README | NF-41, NF-43 |
| 5.7 Calibration des seuils sur les 200 paires ; mise à jour éventuelle des paramètres par défaut | CS3 |
| 5.8 Test d'utilisabilité avec 5 personnes au moins | CS5 ; UX §10 |

### Lot 6 — Version mobile (11 au 13 janvier)

Commencé seulement quand la version web est terminée et que le scénario complet passe (fin du lot 5). La version mobile est la même application Nuxt, rendue installable (TRD T-13) ; elle reprend la direction d'interface de la version web, adaptée au téléphone.

| Tâche | Références |
|---|---|
| 6.1 Essai du module PWA avec Nuxt 4 (`@vite-pwa/nuxt`) : manifeste, installation, mise en cache de la coquille ; décision sur le module ou le repli | TRD T-13, RT-07 |
| 6.2 Page « Télécharger l'application mobile » du portail (`/application-mobile`, lien dans l'en-tête et le pied de page) : explication, bouton d'installation, marche à suivre sur Android et iPhone | F-38 ; APP_FLOW §1.7 |
| 6.3 Référentiels gardés sur le téléphone ; file d'attente des contributions dans IndexedDB (`idClient`, `saisieLe`) ; envoi au retour du réseau, à l'ouverture et toutes les 5 minutes ; écran « En attente d'envoi » | F-38, RG-30 ; UX §3.1 |
| 6.4 Relecture sans réseau de « Mes contributions » et des livres blancs déjà ouverts ; page « Hors connexion » | F-38 ; APP_FLOW §1.7 |
| 6.5 Tests : Playwright réseau coupé (une contribution envoyée une seule fois au retour du réseau) ; essai sur un vrai téléphone Android | F-38, RG-30 |

**Fini quand** : depuis la page « Télécharger l'application mobile », l'application s'installe sur un téléphone Android ; une contribution préparée en mode avion est envoyée une seule fois au retour du réseau et apparaît dans « Mes contributions ».

## 4. Organisation de l'équipe

Tous les membres participent à chaque lot, sous la conduite du responsable d'équipe. Dans chaque lot, le travail se répartit en deux binômes qui avancent en parallèle sur des fichiers distincts :

| Binôme | Responsabilité dans le lot | Exemple (lot 1) |
|---|---|---|
| Binôme « données et services » | Moteur, services, API, tâches, tests d'intégration | Rattachement automatique, API des contributions, modération |
| Binôme « interfaces et parcours » | Écrans, composants, tests Playwright et d'accessibilité | Formulaire en 7 étapes, « Mes contributions », file de modération |

Le responsable d'équipe ouvre chaque lot (relecture du lot dans ce plan, répartition des tâches), relit les fusions de branches et tient la démonstration à jour. Une courte réunion quotidienne fait le point sur l'avancement et les blocages.

## 5. Méthode de travail avec Claude Code

- **Une tâche du plan = une session** (ou quelques-unes) : la tâche est citée par son numéro (« Tâche 1.3 du plan »).
- **Planifier avant de coder** : Claude Code lit `CLAUDE.md`, les sections citées dans la tâche, puis propose un plan court (fichiers touchés, tests) que le binôme valide.
- **Tests d'abord pour les règles** : pour une règle de gestion, écrire le test qui échoue, puis le code.
- **Interfaces** : Claude Code conçoit chaque écran dans la direction validée à la tâche 0.8, avec ses compétences de conception d'interface, le relit contre la liste des tics à éviter (skill `lbc-interface`), puis produit une capture sur téléphone (390 px) et sur ordinateur (1 440 px) que le binôme valide.
- **Branches** : une branche par tâche (`lot1/1.3-formulaire-contribution`), fusion après relecture par un membre de l'autre binôme et tests passants.
- **Messages de commit** en français, au présent : « Ajoute le rattachement automatique des contributions ».

## 6. Risques de planning et replis

| Risque | Signal | Repli |
|---|---|---|
| Le lot 1 dépasse sa semaine | Formulaire non terminé le 17 décembre | Photos (étape 6) reportées en fin de lot 4 ; suggestion de secteur (F-31) abandonnée |
| La génération PDF ou DOCX bloque | Rendu incorrect au 23 décembre | Livrer le PDF seul pour le LBR ; DOCX traité au lot 3 avec le LBN |
| La consolidation produit des groupes incohérents | Cohésion faible sur le jeu de démonstration | Relever le seuil `convergence` ; compter sur l'arbitrage (fusion, scission) |
| Retard cumulé au 31 décembre | Lot 3 incomplet | Portail réduit à l'accueil, aux priorités et à la traçabilité ; statistiques et carte précise reportées |
| La version mobile installable ne fonctionne pas avec Nuxt 4 | Essai 6.1 non concluant | Repli de la RT-07 : `vite-plugin-pwa` ou Workbox directement ; à défaut, file d'attente dans IndexedDB sans installation |
| Retard de la version web | Lot 5 non terminé le 8 janvier | La version web passe d'abord : le lot 6 est réduit à la file d'attente hors connexion, ou présenté en perspective |
| Manque de temps en lot 5 | — | Ordre de priorité : CS1, puis sécurité, puis accessibilité, puis performance |

Fonctionnalités S abandonnées en premier, dans cet ordre : F-132, F-121, F-112, F-106, F-24, F-63, F-31, F-35.

## 7. Définition de « fini » pour une tâche

- Le comportement décrit par les fonctionnalités et règles citées est réalisé, y compris les messages d'erreur et les états vides.
- Les tests correspondants existent et passent (`pnpm test`, et `pnpm test:e2e` pour un parcours).
- Les autorisations sont vérifiées côté serveur et testées.
- Les actions d'administration sont journalisées dans la même transaction.
- L'écran suit la direction d'interface validée, a été relu contre la liste des tics à éviter et validé par l'équipe ; il est utilisable au clavier, sur téléphone et sur ordinateur ; axe ne signale aucune violation.
- Les documents de référence sont à jour si un comportement, un point d'API ou le schéma a changé (procédures dans `.claude/skills/`).
