# DATABASE_SCHEMA — Modèles de données (MCD, MLD, MPD)

| Champ | Valeur |
|---|---|
| Version | 1.0 — phase 3 (conception), soumise à validation |
| SGBD cible | PostgreSQL 18 (schéma testé sur PostgreSQL 16 pour la compatibilité) |
| Source de vérité | `database/migrations/` : `0001_schema_initial.sql` (MPD), `0002_version_mobile.sql` (contributions préparées hors connexion, D-16) |
| Documents générés | `database/generated/MLD.md`, `database/generated/DICTIONNAIRE.md` (depuis le catalogue PostgreSQL) |
| Tests | `database/tests/test_regles_gestion.sql` — {{NB_TESTS}} contrôles, tous passants |
| Références | `PRD.md` v1.1 (glossaire §5, règles §9, moteur §10), `MERISE_TRAITEMENTS.md` |

> **Règle pour Claude Code :** le script SQL de migration est la référence. Le MLD et le dictionnaire sont régénérés à partir de la base migrée (`python3 database/mcd/generer_mld.py`) et ne se modifient jamais à la main. Toute évolution du modèle passe par une **nouvelle** migration numérotée (`0002_…sql`), jamais par la modification d'une migration déjà appliquée.

---

## 1. Démarche

La modélisation suit les trois niveaux de MERISE pour les données :

1. **MCD** (conceptuel) : entités, associations et cardinalités, indépendamment de toute technologie. Il découle du glossaire et des règles de gestion du PRD.
2. **MLD** (logique, relationnel) : tables, clés primaires et clés étrangères, obtenues en appliquant les règles de passage (§3).
3. **MPD** (physique) : script PostgreSQL complet, avec types, contraintes, index, déclencheurs et vues.

Pour garantir la cohérence entre les trois niveaux, le MCD est décrit dans un fichier de spécification unique (`database/mcd/mcd_spec.py`) dont sont tirés les diagrammes. Le MLD et le dictionnaire sont extraits automatiquement du MPD une fois celui-ci appliqué.

---

## 2. Modèle conceptuel des données (MCD)

### 2.1 Conventions de lecture

- Une **entité** est un rectangle : son nom en en-tête, puis son **identifiant souligné**, puis ses propriétés.
- Une **association** est une ellipse reliée aux entités qu'elle met en relation ; ses éventuelles propriétés figurent sous son nom.
- Chaque patte porte la **cardinalité** (minimum, maximum) du point de vue de l'entité : « 1,1 » signifie qu'une occurrence de l'entité participe exactement une fois à l'association.
- Dans chaque vue, les entités grisées et réduites à leur identifiant sont des **rappels** d'entités détaillées dans une autre vue.

Le MCD compte **{{NB_ENTITES}} entités** et **{{NB_ASSOCIATIONS}} associations**. Il est présenté en quatre vues par domaine, pour rester lisible.

### 2.2 Vue 1 — Référentiels, comptes et organisations

![MCD vue 1](../diagrams/merise/mcd_1_acteurs.png)

### 2.3 Vue 2 — Collecte et analyse régionale

![MCD vue 2](../diagrams/merise/mcd_2_collecte.png)

### 2.4 Vue 3 — Livres blancs et consolidation nationale

![MCD vue 3](../diagrams/merise/mcd_3_livres_blancs.png)

### 2.5 Vue 4 — Candidats, engagements et suivi

![MCD vue 4](../diagrams/merise/mcd_4_engagements.png)

### 2.6 Entités

{{ENTITES}}

### 2.7 Associations et cardinalités

{{ASSOCIATIONS}}

### 2.8 Structure d'accès théorique

La structure d'accès théorique (SAT) est le graphe des dépendances fonctionnelles entre identifiants, déduit des cardinalités du MCD (`database/mcd/generer_sat.py`) : une patte de cardinalité maximale 1 donne une dépendance (trait plein pour 1,1, pointillés pour 0,1) ; une association n-n donne un identifiant composé (ellipse).

![SAT](../diagrams/merise/sat.png)

### 2.9 Choix de modélisation notables

- **Territoire réflexif.** Un seul type d'entité porte toute la hiérarchie (district, région, département, sous-préfecture, commune). Cela évite une table par niveau et permet de suivre l'évolution du découpage (D-07).
- **Contribution et préoccupation distinctes.** La contribution est la parole d'un citoyen et n'est jamais réécrite par un administrateur. La préoccupation est l'objet de travail de l'administration : intitulé, synthèse, propositions retenues. Cette séparation garantit le principe P1 (« la voix d'abord »).
- **Soutien comme association.** Un soutien n'a pas d'existence propre : c'est le lien entre une personne et une contribution, daté. La paire (utilisateur, contribution) suffit à l'identifier, ce qui interdit le double soutien (RG-27).
- **Versions de livre blanc.** Le livre blanc est stable dans le temps (une UTR, une édition) ; ce sont ses versions qui portent le contenu. Les associations INCLURE_PREOCCUPATION et INCLURE_CONVERGENCE conservent, pour chaque version publiée, les valeurs figées (rang, score, intitulé) : c'est le socle de la traçabilité (RG-54).
- **Engagement à cible exclusive.** Un engagement vise soit une convergence (présidentielle), soit une préoccupation (régionales). Ces deux associations sont mutuellement exclusives (contrainte d'exclusion, matérialisée en MPD par `ck_engagement_cible`).
- **Calcul de consolidation.** Chaque exécution du moteur est une entité, pour savoir avec quels paramètres une convergence a été proposée.

---

## 3. Passage du MCD au MLD

### 3.1 Règles appliquées

| Situation dans le MCD | Traduction dans le MLD | Exemples |
|---|---|---|
| Entité | Table ; l'identifiant devient la clé primaire | CONTRIBUTION → `contribution(id_contribution)` |
| Association binaire avec une patte de cardinalité maximale 1 (0,1 ou 1,1) | Clé étrangère dans la table de cette entité ; les propriétés de l'association migrent avec elle | RATTACHER → `contribution.id_preoccupation`, `mode_rattachement`, `similarite_rattachement` |
| Patte 1,1 | Clé étrangère obligatoire (NOT NULL) | CONCERNER → `contribution.id_territoire NOT NULL` |
| Patte 0,1 | Clé étrangère facultative | AU_NOM_DE → `contribution.id_organisation` |
| Association binaire n-n (0,n ou 1,n des deux côtés) | Table dont la clé primaire est la concaténation des identifiants | SOUTENIR → `soutien(id_utilisateur, id_contribution)` |
| Association réflexive | Clé étrangère vers la même table | APPARTENIR → `territoire.id_parent` ; FUSIONNER → `preoccupation.id_fusionnee_dans` |
| Associations exclusives | Deux clés étrangères facultatives et une contrainte « exactement une » | CIBLER_PRIORITE / CIBLER_PREOCCUPATION → `ck_engagement_cible` |
| Association 1,1 – 0,1 entre deux entités | Clé étrangère unique | REPRESENTER → `organisation.id_representant UNIQUE` (RG-14) |

### 3.2 Écarts assumés par rapport à la règle stricte

| Écart | Raison |
|---|---|
| ILLUSTRER (CONTRIBUTION 0,3 – FICHIER 0,1) est traduite en table `illustration` et non en clé étrangère dans `fichier` | `fichier` est une table générique (photos, PV, exports, justificatifs) : y placer une clé vers `contribution` la spécialiserait. La table porte aussi l'ordre d'affichage. |
| Colonnes dénormalisées `contribution.id_utr`, `territoire.id_utr`, `territoire.id_departement` | Les agrégations par UTR et par département sont au cœur du moteur de scores. La cohérence est garantie par un déclencheur (`contribution_controler`) et par l'import du référentiel. |
| Valeurs calculées en cache sur `preoccupation` (`nb_voix`, `score`, `score_detail`) et `convergence` | Évite de recalculer les scores à chaque affichage. La source reste la vue `v_statistiques_preoccupation` ; les caches sont recalculés par le moteur (TRD §6). |
| Colonnes générées sur `contribution` (`titre_normalise`, `texte_normalise`, `lexemes`, `document_recherche`) | Index de similarité et de recherche plein texte toujours à jour sans code applicatif. |
| `preoccupation.id_contribution_representative` | Propriété technique du moteur de regroupement (§10.2), sans signification métier : absente du MCD. |
| `contribution.id_client` | Identifiant attribué par le téléphone à une contribution préparée hors connexion, pour qu'un nouvel envoi ne crée pas de doublon (RG-30) : propriété technique, absente du MCD. La date de rédaction (`saisie_le`), elle, figure au MCD. |
| Tables techniques `session`, `jeton`, `compteur_reference`, `journal_audit`, `terme_interdit` | Nécessaires au fonctionnement mais hors du domaine métier : absentes du MCD. |

### 3.3 MLD

Le MLD complet (32 relations) est généré dans `database/generated/MLD.md`. Extrait du domaine central :

{{MLD_EXTRAIT}}

Le schéma relationnel d'ensemble (tables, clés primaires et étrangères, regroupées par domaine) est disponible dans `diagrams/merise/mld_relationnel.png`.

---

## 4. Modèle physique des données (MPD)

### 4.1 Conventions

| Sujet | Choix | Justification |
|---|---|---|
| Nommage | Français, `snake_case`, sans accents ; identique au MCD | Le même vocabulaire du glossaire au code (langage omniprésent) ; le MPD se lit comme le MCD |
| Clés primaires | UUID version 7 (`gen_uuid_v7()`) | Identifiants non devinables pour les URL publiques, mais ordonnés dans le temps, donc favorables aux index B-tree. Sous PostgreSQL 18, la fonction native `uuidv7()` peut la remplacer. |
| Références lisibles | Colonne `reference` (ex. `C-2030-GOH-000123`) via `prochaine_reference()` | Référence citée dans les documents et par les citoyens |
| Énumérations | Texte contraint par `CHECK` | Plus simple à faire évoluer qu'un type `ENUM` ; lisible dans le dictionnaire |
| Dates | `timestamptz` pour les instants, `date` pour les dates calendaires | Pas d'ambiguïté de fuseau horaire |
| Suppression | Aucune suppression physique des données métier ; les états passent par `statut` | Traçabilité (P3) et intégrité des versions publiées |
| Texte enrichi | `jsonb` au format de l'éditeur (Tiptap / ProseMirror) | Rendu fidèle en web, PDF et Word à partir de la même structure |
| Paramètres d'édition | `jsonb` validé par un schéma applicatif et figé hors préparation (RG-02) | Les seuils et pondérations évoluent sans migration |

### 4.2 Extensions et fonctions

| Objet | Rôle |
|---|---|
| `pg_trgm` | Similarité par trigrammes et index GIN `gin_trgm_ops` |
| `unaccent` (+ `immutable_unaccent()`) | Comparaisons insensibles aux accents, utilisables dans des colonnes générées |
| `normaliser_texte()` | Minuscules, accents retirés, ponctuation supprimée |
| `lexemes_texte()` | Racines lexicales françaises (mots vides retirés, radicalisation Snowball) |
| `chevauchement()` | Coefficient de chevauchement entre deux ensembles de racines |
| `similarite_textes()` | Similarité composite du moteur (§6) |
| `prochaine_reference()` | Génération des références lisibles, sans trou ni doublon (verrou de ligne) |
| `gen_uuid_v7()` | Identifiants UUID v7 |

### 4.3 Index

| Table | Index | Usage |
|---|---|---|
| `contribution` | `(id_edition, id_utr, id_secteur, statut)` | Listes et agrégats par périmètre |
| `contribution` | GIN trigrammes sur `titre_normalise` et `texte_normalise` | Recherche des contributions proches (F-32) |
| `contribution` | GIN sur `lexemes` | Pré-filtrage des candidates par racines communes |
| `contribution` | GIN sur `document_recherche` | Recherche plein texte (F-104) |
| `preoccupation` | `(id_edition, id_utr, id_secteur, statut)`, GIN trigrammes et lexèmes sur le texte de référence | Rattachement automatique (§10.2) |
| `edition` | Index unique partiel sur les éditions actives | RG-01 |
| `version_livre_blanc` | Index uniques partiels (un brouillon, une version publiée par livre blanc) | RG-54 |
| `engagement` | Index uniques partiels (candidat, cible) sur les engagements déclarés | RG-72 |
| `utilisateur` | Index unique sur `lower(email)` | Unicité insensible à la casse |
| `journal_audit` | `(type_objet, id_objet)`, `(id_acteur, survenue_le)` | Consultation de l'historique d'un objet ou d'un acteur |

### 4.4 Vues

| Vue | Contenu |
|---|---|
| `v_statistiques_preoccupation` | Par préoccupation : contributions publiées, **voix** (RG-51 et D-10), urgence moyenne, nombre d'unités d'étendue, organisations vérifiées. Entrée du calcul du score régional. |
| `v_etendue_utr` | Par UTR : nombre de départements, ou à défaut de mailles sélectionnables (dénominateur de la composante E). |

---

## 5. Où chaque règle de gestion est garantie

Principe : **toute règle qui protège l'intégrité des données publiées est garantie par la base**, même si l'application la vérifie aussi pour afficher un message clair. Les règles qui dépendent du contexte de la requête (utilisateur connecté, limites de débit) sont garanties par l'application.

| Règle | Garantie en base | Garantie applicative | Test SQL |
|---|---|---|---|
| RG-01 une édition active | `ux_edition_active` | Contrôle avant transition | oui |
| RG-02 paramètres figés | `edition_controler_transition` | Formulaire désactivé | oui |
| RG-03 ordre des phases | `edition_controler_transition` | Écran de transition (F-23) | oui |
| RG-04 hiérarchie | `ck_territoire_racine`, `id_parent` | Validation de l'import | — |
| RG-05 UTR avec population | `ck_territoire_utr` | Contrôle à l'ouverture des états généraux | — |
| RG-06 secteur désactivable | Clés étrangères sans suppression | Pas de suppression dans l'API | — |
| RG-10 champs d'inscription | `ck_utilisateur_actif_complet` | Schéma Zod | — |
| RG-11 e-mail vérifié | — | Garde d'accès au dépôt | — |
| RG-12 âge | `ck_utilisateur_age` | Schéma Zod | oui |
| RG-13 comptes d'administration | — | API réservée à l'administrateur national | — |
| RG-14 un représentant | `organisation.id_representant UNIQUE` | — | oui |
| RG-15 vérification | `ck_organisation_verification`, `ck_organisation_rejet` | Politique d'accès par UTR du siège | oui |
| RG-16 anonymisation | `ck_utilisateur_supprime_anonyme` | Service de suppression de compte | — |
| RG-17 verrouillage | Colonnes `tentatives_echouees`, `verrouille_jusqua` | Service de connexion | — |
| RG-20 phase de collecte | `contribution_controler` | Garde d'accès | oui |
| RG-21 champs et maille | Contraintes de longueur, `contribution_controler` | Schéma Zod | oui |
| RG-22 UTR déduite | `contribution_controler` | — | oui |
| RG-23 au nom d'une organisation | `contribution_controler` | — | oui |
| RG-24 rattachement | `ck_contribution_rattachement`, `contribution_controler` | Moteur de regroupement | oui |
| RG-25 modification et historique | `contribution_historiser` | — | oui |
| RG-26 limite quotidienne | — | Service de dépôt | — |
| RG-27 soutien | `soutien_pkey`, `soutien_controler` | — | oui |
| RG-28 contributions de terrain | `ck_contribution_source`, `contribution_controler` | Service d'import | oui |
| RG-29 affichage public | — | Sérialisation publique | — |
| RG-30 contribution préparée hors connexion | `ux_contribution_id_client`, `ck_contribution_hors_ligne`, `ck_contribution_saisie` ; RG-20 à RG-26 appliquées à la réception par `contribution_controler` | File d'attente de la version mobile, envoi idempotent | oui |
| RG-40 modération automatique | `signalement_compter` | Filtre de termes, seuil de signalements | oui |
| RG-41 décision motivée | `ck_decision_motif`, `ck_decision_commentaire` | — | oui |
| RG-42 doublon strict | — | Service de modération (même auteur) | — |
| RG-43 fusion | `ck_preoccupation_fusion` | Transfert des contributions en transaction | — |
| RG-44 pas d'auto-modération | `decision_moderation_controler` | — | — |
| RG-45 journal non modifiable | `journal_interdire_modification` | Écriture par l'utilitaire d'audit | oui |
| RG-50 périmètre d'une préoccupation | `contribution_controler` (même contrôle que RG-24) | — | oui |
| RG-51 voix | `v_statistiques_preoccupation` | Moteur de scores | oui |
| RG-52 écartement motivé | `ck_preoccupation_ecartee` | — | — |
| RG-53 conditions de publication | `version_livre_blanc_controler` | Écran de publication (liste des blocages) | oui |
| RG-54 figement | `version_livre_blanc_controler`, `ck_version_publiee`, `ck_version_changements` | — | oui |
| RG-55 date de validation | `version_livre_blanc_controler` | Formulaire de publication | oui |
| RG-56 verrouillage après publication | `preoccupation_controler`, `contribution_controler` | — | oui |
| RG-60 LBR publiés seulement | — | Moteur de consolidation | — |
| RG-61 seuil d'ouverture | — | Contrôle de transition de phase | — |
| RG-62 une convergence par préoccupation | `preoccupation.id_convergence` (une seule valeur) | — | — |
| RG-63 arbitrage motivé | `ck_convergence_rejet`, `ck_decision_eg_motif`, `version_livre_blanc_controler` | — | oui |
| RG-64 reclassement motivé | `ck_convergence_reclassement` | — | oui |
| RG-65 publication du LBN | `version_livre_blanc_controler` | — | oui |
| RG-70 candidat | `ck_candidat_utr`, unicité (utilisateur, édition) | — | oui |
| RG-71 cible de l'engagement | `engagement_controler` | — | oui |
| RG-72 un engagement par élément | `ux_engagement_convergence`, `ux_engagement_preoccupation` | — | oui |
| RG-73 retrait jusqu'à l'élection | `engagement_controler` | — | — |
| RG-74 suivi des élus | `suivi_controler`, `ck_justificatif_type` | Au moins un justificatif (transaction) | oui |
| RG-75 taux de réalisation | — | Calcul applicatif | — |

---

## 6. Similarité textuelle : choix et calibration

### 6.1 Constat

Le PRD prévoyait une similarité par trigrammes. Les tests de la phase 3 ont montré que cette mesure seule est trop faible pour des reformulations : deux contributions qui décrivent le même manque d'équipement d'une maternité n'obtiennent que 0,32. Une mesure fondée sur les mots est nécessaire.

### 6.2 Mesure retenue

```
similarite = 0,5 × chevauchement(racines A, racines B) + 0,5 × trigrammes(texte A, texte B)
```

- **Racines** : mots du titre, du constat et de la proposition, sans accents, sans mots vides, réduits à leur racine par la configuration `french` de PostgreSQL (« équipements » et « équiper » deviennent « equip »).
- **Chevauchement** : nombre de racines communes divisé par la taille du plus petit ensemble. Une contribution courte n'est donc pas pénalisée face à une longue.
- **Trigrammes** : rattrapent les variantes orthographiques et les fautes de frappe que la radicalisation ne traite pas.

### 6.3 Calibration (corpus de 12 contributions, 66 paires)

| Mesure | Paires « même besoin » : minimum | Paires de besoins différents : maximum |
|---|---|---|
| Trigrammes seuls | 0,13 | 0,26 |
| Chevauchement seul | 0,07 | 0,21 |
| **Composite retenue** (reformulations nettes) | **0,32** | **0,23** |

Les paires que le corpus classait dans un même thème mais qui décrivent des besoins différents (par exemple une extension de réseau d'eau et la réparation d'une pompe) restent sous 0,30. C'est le comportement attendu : elles doivent former des préoccupations distinctes, que l'administrateur peut fusionner s'il le juge pertinent.

### 6.4 Seuils retenus (paramètres par défaut d'une édition)

| Usage | Seuil | Logique |
|---|---|---|
| Suggestions au contributeur avant dépôt | 0,20 | Rappel élevé : mieux vaut montrer une contribution de trop, le citoyen choisit |
| Rattachement automatique | 0,30 | Précision élevée : en cas de doute, le système crée une nouvelle préoccupation et propose une fusion à l'administrateur |
| Doublon strict (même auteur) | 0,60 | Quasi-copie |
| Rapprochement inter-régional | 0,28 | Les textes de référence des préoccupations sont plus riches, donc un peu plus proches |

**Limite assumée :** la marge entre 0,23 et 0,30 est étroite et le corpus est petit. Les seuils seront recalibrés sur le jeu de démonstration avec au moins 200 paires étiquetées (critère CS3 du PRD). Le levier d'amélioration principal, prévu en évolution, est une mesure sémantique par plongements vectoriels calculés localement (TRD §6.5).

---

## 7. Historisation et traçabilité

| Besoin | Mécanisme |
|---|---|
| Modification d'une contribution par son auteur | `version_contribution` : copie de la version précédente à chaque changement de contenu (RG-25) |
| Version publiée d'un livre blanc | `version_livre_blanc.contenu_fige` (modèle de document complet), `parametres_figes`, `empreinte_sha256` ; immuabilité par déclencheur |
| Lien entre une version publiée et les éléments inclus | `inclusion_preoccupation`, `inclusion_convergence` (valeurs figées) |
| Fil de traçabilité public | Version publiée du LBN → `inclusion_convergence` → `preoccupation.id_convergence` → `contribution.id_preoccupation`. Pour les versions anciennes, le chemin est lu dans `contenu_fige`. |
| Décisions de l'administration | `decision_moderation`, `decision_etats_generaux`, `journal_audit` (non modifiable) |
| Fusions | `preoccupation.id_fusionnee_dans`, `convergence.id_fusionnee_dans` : l'objet absorbé reste consultable |
| Suivi des réalisations | `suivi_realisation` : une ligne par mise à jour, jamais écrasée |

---

## 8. Volumétrie et dimensionnement

| Table | Prototype (démonstration) | Hypothèse nationale (NF-01) |
|---|---|---|
| `territoire` | environ 700 | environ 700 |
| `contribution` | environ 5 000 | 500 000 par édition |
| `soutien` | environ 20 000 | 5 000 000 par édition |
| `preoccupation` | environ 800 | environ 40 000 |
| `convergence` | environ 150 | environ 2 000 |
| `journal_audit` | quelques milliers | quelques millions (partitionnement mensuel envisageable) |

À l'échelle nationale, la requête la plus coûteuse est la recherche de contributions proches. Elle est toujours restreinte à une UTR et à un secteur, puis pré-filtrée par l'index sur les racines avant le calcul de similarité.

---

## 9. Référentiels et données initiales

| Référentiel | Source | Format d'import |
|---|---|---|
| Territoires | COD-AB Côte d'Ivoire (CNTIG / OCHA, sur HDX) : 33 unités de niveau 1 (31 régions et 2 districts autonomes) et départements ; sous-préfectures et communes à compléter pour les UTR de démonstration | CSV : `code, code_pcode, libelle, niveau, code_parent, population, annee_population` |
| Population des UTR | RGPH 2021 (INS) ou COD-PS (HDX), à confirmer | Colonne `population` du CSV |
| Secteurs | PRD §11 (M2), 14 secteurs | CSV : `code, libelle, description, icone, odd, mots_cles, ordre` |
| Termes interdits | À constituer | Une colonne `terme` |

Règles d'import : un territoire sans enfant sélectionnable devient lui-même sélectionnable (maille la plus fine disponible, RG-21) ; `id_utr` et `id_departement` sont calculés lors de l'import.

---

## 10. Exécuter les tests

```bash
createdb lbc_test
for f in database/migrations/*.sql; do psql -d lbc_test -v ON_ERROR_STOP=1 -f "$f"; done
psql -d lbc_test -f database/tests/test_regles_gestion.sql   # chaque contrôle affiche « OK »
python3 database/mcd/generer_mld.py                          # régénère MLD.md et DICTIONNAIRE.md
```

---

## Annexe — Dictionnaire de données

Le dictionnaire complet ({{NB_COLONNES}} colonnes réparties en 32 tables, avec types, caractère obligatoire, clés, descriptions et contraintes) est généré dans `database/generated/DICTIONNAIRE.md`.
