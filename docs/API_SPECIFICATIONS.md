# API_SPECIFICATIONS — API REST `/api/v1`

| Champ | Valeur |
|---|---|
| Version | 1.0 — phase 3 (conception), soumise à validation |
| Implémentation | Routes serveur Nuxt (Nitro) dans `server/api/v1/` (TRD §4.2) |
| Contrat machine | `api/openapi.yaml` (OpenAPI 3.1, squelette généré depuis `api/endpoints.py`) |
| Références | `PRD.md` v1.1 (F, RG), `TRD.md` (sécurité §9, erreurs §11), `DATABASE_SCHEMA.md` |

L'API sert d'abord l'interface Nuxt du projet. Elle n'est pas ouverte à des clients tiers dans le MVP, mais elle est conçue proprement (ressources, codes HTTP, erreurs normalisées) pour pouvoir l'être.

**Règle pour Claude Code :** la liste des points d'accès est tenue dans `api/endpoints.py`. Ajouter ou modifier un point d'accès commence par ce fichier, puis `python3 api/generer.py` régénère les tableaux de ce document et `api/openapi.yaml`.

---

## 1. Conventions

### 1.1 Format

| Sujet | Règle |
|---|---|
| Base | `/api/v1` ; une rupture de compatibilité ouvre `/api/v2` |
| Corps | JSON UTF-8 ; `multipart/form-data` pour les fichiers |
| Noms de champs | `camelCase`, en français et sans accents, alignés sur le glossaire (`idPreoccupation`, `deposeeLe`, `nbVoix`) |
| Identifiants | UUID v7 (`id…`) ; les objets cités publiquement ont aussi une `reference` lisible (`C-2030-GOH-000123`) |
| Dates | Instants en ISO 8601 avec fuseau (`2026-11-12T14:05:00Z`) ; dates calendaires `AAAA-MM-JJ` |
| Énumérations | Valeurs en majuscules identiques à la base (`EN_MODERATION`, `PARTAGEE`) ; les libellés affichés sont traduits par l'interface |
| Texte enrichi | JSON ProseMirror restreint (TRD T-09) |
| Valeurs absentes | Champ présent avec `null` plutôt qu'omis, pour les réponses |

### 1.2 Authentification et protections

- **Session** : cookie scellé posé par `POST /auth/connexion` (TRD §9.2). Aucun jeton dans les en-têtes.
- **CSRF** : toute requête `POST`, `PUT`, `PATCH`, `DELETE` porte l'en-tête de jeton CSRF fourni par le module `nuxt-csurf` (composable `useCsrfFetch` côté interface) ; l'en-tête `Origin` doit correspondre au site.
- **Limitation du débit** : réponse `429` avec l'en-tête `Retry-After` (seuils au TRD §9.4).

### 1.3 Listes, filtres et tri

```
GET /api/v1/admin/utr/GOH/preoccupations?secteur=SANTE&statut=PROPOSEE&tri=-score&limite=20&curseur=eyJz…
```

- **Pagination par curseur** : `limite` (1 à 100, défaut 20) et `curseur` (valeur opaque renvoyée par la page précédente). Elle reste stable quand des contributions arrivent pendant la lecture.
- **Enveloppe** :

```json
{ "donnees": [ … ], "pagination": { "suivant": "eyJzIjo3Mi41LCJpZCI6Ij…", "total": 214 } }
```

`total` n'est fourni que lorsque son calcul est peu coûteux (listes d'administration filtrées par UTR).

- **Tri** : `tri=champ` (croissant) ou `tri=-champ` (décroissant) ; champs autorisés indiqués pour chaque liste.
- **Filtres** : paramètres nommés comme les champs ; plusieurs valeurs séparées par des virgules (`statut=PROPOSEE,VALIDEE`) ; périodes par `du` et `au`.

### 1.4 Écritures concurrentes

Plusieurs administrateurs peuvent travailler sur la même UTR. Les objets éditables (préoccupation, convergence, version de livre blanc) renvoient un en-tête `ETag` ; leur modification (`PATCH`) exige l'en-tête `If-Match`. Si l'objet a changé entre-temps, la réponse est `412` et l'interface propose de recharger.

### 1.5 Traitements longs

Les traitements longs (import de terrain, calcul de consolidation, génération d'exports) répondent `202 Accepted` :

```json
{ "idTache": "0193a7c2-…", "etat": "EN_ATTENTE", "suivi": "/api/v1/taches/0193a7c2-…" }
```

`GET /taches/{id}` renvoie `EN_ATTENTE`, `EN_COURS`, `TERMINEE` (avec un lien vers le résultat) ou `ECHEC` (avec un message). Une notification est aussi créée à la fin (F-120).

### 1.6 Idempotence

`PUT` et `DELETE` sont idempotents (soutenir deux fois renvoie le même résultat). Les tâches de fond le sont aussi (TRD §8). `POST /contributions` l'est quand la requête porte un `idClient` : c'est le cas des contributions préparées hors connexion dans la version mobile, qui peuvent être envoyées plusieurs fois si le réseau coupe pendant l'envoi (RG-30).

---

## 2. Erreurs

### 2.1 Format (RFC 9457)

Toutes les erreurs ont le type de contenu `application/problem+json` :

```json
{
  "type": "https://livreblanc.local/erreurs/regle-de-gestion",
  "title": "Publication impossible",
  "status": 409,
  "detail": "Toutes les préoccupations doivent être validées, fusionnées ou écartées avant la publication.",
  "instance": "/api/v1/admin/livres-blancs/0193…/versions/1/publication",
  "code": "REGLE_DE_GESTION",
  "regle": "RG-53",
  "idRequete": "req_8f2c…"
}
```

Erreur de validation (`422`), avec une entrée par champ, dans le vocabulaire de l'utilisateur :

```json
{
  "type": "https://livreblanc.local/erreurs/validation",
  "title": "Certains champs sont à corriger",
  "status": 422,
  "code": "VALIDATION",
  "erreurs": [
    { "champ": "constat", "message": "Décrivez le problème en 30 caractères au moins." },
    { "champ": "idTerritoire", "message": "Choisissez la sous-préfecture ou la commune concernée." }
  ]
}
```

### 2.2 Codes

| HTTP | `code` | Situation |
|---|---|---|
| 400 | `REQUETE_INVALIDE` | JSON illisible, paramètre de type incorrect |
| 401 | `NON_CONNECTE` | Session absente, expirée ou révoquée |
| 401 | `IDENTIFIANTS_INVALIDES` | Connexion refusée (message identique que le compte existe ou non) |
| 403 | `INTERDIT` | Rôle insuffisant |
| 403 | `HORS_PERIMETRE` | Ressource hors de l'UTR de l'administrateur |
| 403 | `EMAIL_NON_VERIFIE` | Action réservée aux comptes vérifiés (RG-11) |
| 404 | `INTROUVABLE` | Ressource absente **ou** non visible pour l'appelant (pas de distinction, pour ne rien révéler) |
| 409 | `REGLE_DE_GESTION` | Une règle de gestion s'oppose à l'action ; `regle` précise laquelle |
| 409 | `CONFLIT` | Doublon d'unicité (e-mail déjà utilisé, engagement existant) |
| 412 | `MODIFIE_ENTRE_TEMPS` | `If-Match` ne correspond plus |
| 413 | `FICHIER_TROP_VOLUMINEUX` | Taille maximale dépassée |
| 415 | `TYPE_NON_ACCEPTE` | Type de fichier refusé |
| 422 | `VALIDATION` | Données incorrectes (schéma Zod ou contrainte `CHECK`) |
| 423 | `COMPTE_VERROUILLE` | Verrouillage temporaire (RG-17) ; `Retry-After` indiqué |
| 429 | `TROP_DE_REQUETES` / `LIMITE_QUOTIDIENNE` | Limitation du débit ; limite de dépôts (RG-26) |
| 500 | `ERREUR_INTERNE` | Erreur inattendue ; le détail technique reste dans le journal |

### 2.3 Erreurs remontées par la base

La base garantit les règles critiques (DATABASE_SCHEMA §5). Le service convertit ses erreurs ainsi :

| Erreur PostgreSQL | Conversion |
|---|---|
| `P0001` levée par un déclencheur, message « RG-xx : … » | `409 REGLE_DE_GESTION`, `regle` = `RG-xx`, `detail` = texte du message |
| `23505` violation d'unicité | `409 CONFLIT` ; le nom de la contrainte est traduit en message (ex. `soutien_pkey` → « Vous soutenez déjà cette contribution. ») |
| `23514` violation de `CHECK` | `422 VALIDATION` ; le nom de la contrainte est traduit (ex. `ck_decision_motif` → champ `motif`) |
| `23503` clé étrangère | `422 VALIDATION` sur le champ concerné |

Ces cas sont normalement interceptés plus tôt par les contrôles applicatifs ; la conversion garantit un message propre lorsque la base est la dernière barrière.

---

## 3. Accès

| Code | Signification |
|---|---|
| PUB | Public, sans connexion |
| PUB* | Public si l'objet l'est (fichier d'une contribution publiée, procès-verbal d'une version publiée), sinon selon les droits |
| CON | Utilisateur connecté |
| CV | Contributeur dont l'adresse e-mail est vérifiée (RG-11) |
| AUT | Auteur de l'objet |
| REP | Représentant de l'organisation |
| AR | Administrateur régional, pour les UTR de ses affectations actives |
| AN | Administrateur national |
| CAND | Candidat, pour ses propres engagements |

Le contrôle est fait côté serveur (TRD §9.3). Une route d'administration régionale (`/admin/utr/{utr}/…`) vérifie que `{utr}` figure dans les affectations de l'appelant. `{utr}` est le **code** de l'UTR dans le référentiel (par exemple `GOH`).

---

## 4. Catalogue des points d'accès

118 points d'accès, regroupés par module du PRD. Les fonctionnalités F-105 (pages d'information) et F-130 (journal d'audit) n'ont pas de point d'accès propre : la première est du contenu de l'interface, la seconde un mécanisme transversal (chaque service écrit dans le journal, TRD §11).

### M1 Comptes

| Méthode | Chemin | Accès | Rôle | Références |
|---|---|---|---|---|
| `POST` | `/auth/inscription` | PUB | Inscription d'une personne physique ; envoie l'e-mail de vérification | F-10, RG-10, RG-12 |
| `POST` | `/auth/verification-email` | PUB | Valide l'adresse e-mail à partir du jeton reçu | F-11 |
| `POST` | `/auth/verification-email/renvoi` | CON | Renvoie l'e-mail de vérification | F-11 |
| `POST` | `/auth/connexion` | PUB | Ouvre une session (cookie) | F-12, RG-17 |
| `POST` | `/auth/deconnexion` | CON | Révoque la session courante | F-12 |
| `POST` | `/auth/mot-de-passe/oubli` | PUB | Demande de réinitialisation ; réponse neutre | F-13 |
| `POST` | `/auth/mot-de-passe/reinitialisation` | PUB | Nouveau mot de passe à partir du jeton ; révoque les sessions | F-13 |
| `POST` | `/auth/invitation/acceptation` | PUB | Active un compte d'administration ou de candidat invité | F-16, RG-13 |
| `GET` | `/moi` | CON | Profil, rôles, affectations et organisation représentée | F-14 |
| `PATCH` | `/moi` | CON | Modifie le profil et l'affichage du nom | F-14, RG-29 |
| `PUT` | `/moi/mot-de-passe` | CON | Change le mot de passe ; révoque les autres sessions | F-14, NF-11 |
| `GET` | `/moi/export` | CON | Export JSON des données du compte | F-14, NF-22 |
| `DELETE` | `/moi` | CON | Supprime le compte (anonymisation) après confirmation du mot de passe | F-14, RG-16 |
| `GET` | `/moi/contributions` | CON | Mes contributions : statut, préoccupation, soutiens, historique | F-34 |
| `GET` | `/moi/notifications` | CON | Notifications, non lues en premier | F-120 |
| `POST` | `/moi/notifications/lues` | CON | Marque des notifications (ou toutes) comme lues | F-120 |
| `PATCH` | `/moi/preferences-notification` | CON | Préférences d'envoi par e-mail | F-121 |
| `POST` | `/organisations` | CV | Crée une organisation dont l'utilisateur devient le représentant | F-15, RG-14 |
| `GET` | `/organisations/{id}` | PUB | Fiche publique d'une organisation | F-15 |
| `PATCH` | `/organisations/{id}` | REP | Modifie la fiche (repasse en NON_VERIFIEE si la dénomination change) | F-15, RG-15 |
| `GET` | `/admin/organisations` | AR, AN | Organisations à vérifier dans le périmètre | RG-15 |
| `POST` | `/admin/organisations/{id}/verification` | AR, AN | Vérifie ou rejette (motif) une organisation | RG-15 |

### M2 Référentiels et éditions

| Méthode | Chemin | Accès | Rôle | Références |
|---|---|---|---|---|
| `GET` | `/territoires` | PUB | Recherche dans le référentiel (niveau, parent, sélectionnable, texte) | F-20 |
| `GET` | `/territoires/{id}` | PUB | Un territoire et ses ascendants | F-20 |
| `GET` | `/secteurs` | PUB | Secteurs actifs (tous pour l'administrateur national) | F-21 |
| `GET` | `/editions` | PUB | Éditions (active et archivées) | F-106 |
| `GET` | `/editions/active` | PUB | Édition active, phase et dates | §8.1 |
| `POST` | `/admin/territoires/import` | AN | Import CSV du référentiel ; rapport ligne par ligne | F-20, D-07, RG-04, RG-05 |
| `POST` | `/admin/secteurs` | AN | Crée un secteur | F-21 |
| `PATCH` | `/admin/secteurs/{id}` | AN | Modifie ou désactive un secteur | F-21, RG-06 |
| `POST` | `/admin/editions` | AN | Crée une édition (phase PREPARATION) | F-22 |
| `PATCH` | `/admin/editions/{id}` | AN | Modifie dates et paramètres (paramètres : PREPARATION seulement) | F-22, RG-02 |
| `GET` | `/admin/editions/{id}/transition` | AN | Phase suivante possible, préconditions et effets | F-23, RG-03, RG-61 |
| `POST` | `/admin/editions/{id}/transition` | AN | Change de phase après confirmation | F-23, RG-01, RG-03, RG-61 |
| `GET` | `/admin/comptes` | AN | Comptes d'administration et de candidat | F-16 |
| `POST` | `/admin/comptes` | AN | Crée un compte d'administration et envoie l'invitation | F-16, RG-13 |
| `PATCH` | `/admin/comptes/{id}` | AN | Suspend ou réactive un compte | F-16 |
| `POST` | `/admin/comptes/{id}/affectations` | AN | Ajoute une affectation (rôle, UTR) | D-04 |
| `DELETE` | `/admin/comptes/{id}/affectations/{idAffectation}` | AN | Clôt une affectation (date de fin) | D-04 |
| `GET` | `/admin/termes-interdits` | AN | Liste du filtre de modération | F-24 |
| `PUT` | `/admin/termes-interdits` | AN | Remplace la liste | F-24, RG-40 |

### M3 Contributions

| Méthode | Chemin | Accès | Rôle | Références |
|---|---|---|---|---|
| `GET` | `/contributions` | PUB | Contributions publiées, filtrables (édition, UTR, secteur, lieu, texte, période) | F-104, RG-29 |
| `GET` | `/contributions/{reference}` | PUB | Une contribution publiée et sa préoccupation | F-103, RG-29 |
| `POST` | `/contributions/similaires` | CV | Contributions proches d'un texte en cours de saisie | F-32, §10.1 |
| `POST` | `/contributions/suggestion-secteur` | CV | Secteurs probables d'après les mots-clés du texte | F-31 |
| `POST` | `/contributions` | CV | Dépose une contribution ; rattachement automatique ; idempotent avec idClient (version mobile) | F-30, F-33, F-38, RG-20 à RG-24, RG-26, RG-30 |
| `PATCH` | `/contributions/{id}` | AUT | Modifie sa contribution (historisée, nouveau rattachement si besoin) | RG-25 |
| `POST` | `/contributions/{id}/retrait` | AUT | Retire sa contribution | RG-25 |
| `GET` | `/contributions/{id}/versions` | AUT, AR, AN | Historique des versions | RG-25 |
| `POST` | `/contributions/{id}/illustrations` | AUT | Ajoute une photo (3 au plus) | RG-21, NF-14 |
| `DELETE` | `/contributions/{id}/illustrations/{idFichier}` | AUT | Retire une photo | RG-21 |
| `PUT` | `/contributions/{id}/soutien` | CV | Soutient une contribution (idempotent) | F-36, RG-27 |
| `DELETE` | `/contributions/{id}/soutien` | CV | Retire son soutien | F-36, RG-27 |
| `POST` | `/contributions/{id}/signalements` | CV | Signale une contribution (motif obligatoire) | F-37, RG-40 |
| `POST` | `/admin/utr/{utr}/consultations` | AR, AN | Déclare une consultation de terrain et importe son fichier (tâche de fond) | F-35, RG-28, D-10 |
| `GET` | `/admin/utr/{utr}/consultations` | AR, AN | Consultations importées et rapports d'import | F-35 |
| `GET` | `/modeles/import-terrain.xlsx` | AR, AN | Modèle de fichier d'import | F-35 |

### M4 Modération

| Méthode | Chemin | Accès | Rôle | Références |
|---|---|---|---|---|
| `GET` | `/admin/utr/{utr}/moderation` | AR, AN | File : contributions en modération et signalées | F-40 |
| `POST` | `/admin/contributions/{id}/decisions` | AR, AN | Maintenir, masquer ou retirer (motif, commentaire) | F-40, F-42, RG-41, RG-44 |
| `GET` | `/admin/utr/{utr}/doublons` | AR, AN | Paires de doublons stricts suspects | F-41, RG-42 |

### M5 Analyse régionale

| Méthode | Chemin | Accès | Rôle | Références |
|---|---|---|---|---|
| `GET` | `/admin/utr/{utr}/preoccupations` | AR, AN | Préoccupations de l'UTR (filtres, tri par score ou voix) | F-50 |
| `GET` | `/admin/preoccupations/{id}` | AR, AN | Fiche : textes, contributions, localités, score détaillé | F-51 |
| `PATCH` | `/admin/preoccupations/{id}` | AR, AN | Modifie intitulé, synthèse, propositions retenues | F-51, RG-56 |
| `POST` | `/admin/preoccupations/validation` | AR, AN | Valide une ou plusieurs préoccupations | F-54 |
| `POST` | `/admin/preoccupations/{id}/ecartement` | AR, AN | Écarte une préoccupation (motif) | F-54, RG-52 |
| `GET` | `/admin/utr/{utr}/suggestions-fusion` | AR, AN | Paires de préoccupations proches | F-52, §10.2 |
| `POST` | `/admin/preoccupations/fusion` | AR, AN | Fusionne des préoccupations dans une cible | F-52, RG-43 |
| `POST` | `/admin/preoccupations/{id}/scission` | AR, AN | Sépare des contributions dans une nouvelle préoccupation | F-53 |
| `POST` | `/admin/contributions/{id}/deplacement` | AR, AN | Rattache manuellement une contribution à une autre préoccupation | F-53, RG-24, RG-56 |
| `GET` | `/admin/utr/{utr}/tableau-de-bord` | AR, AN | Participation, profils, avancement du traitement | F-55 |

### M6-M8 Livres blancs

| Méthode | Chemin | Accès | Rôle | Références |
|---|---|---|---|---|
| `GET` | `/admin/utr/{utr}/livre-blanc` | AR, AN | Livre blanc régional de l'édition active et ses versions | F-60 |
| `GET` | `/admin/editions/{id}/livre-blanc-national` | AN | Livre blanc national et ses versions | F-80 |
| `POST` | `/admin/livres-blancs/{id}/versions` | AR, AN | Ouvre un brouillon (nouvelle version, déverrouille) | F-60, F-63, RG-54, RG-56 |
| `GET` | `/admin/livres-blancs/{id}/versions/{numero}` | AR, AN | Brouillon : métadonnées et document calculé à partir des données vivantes | F-60, F-61 |
| `PATCH` | `/admin/livres-blancs/{id}/versions/{numero}` | AR, AN | Introduction, validation régionale, résumé des changements | F-61, RG-55 |
| `GET` | `/admin/livres-blancs/{id}/versions/{numero}/controles` | AR, AN | Conditions de publication et blocages | RG-53, RG-55, RG-63, RG-65 |
| `POST` | `/admin/livres-blancs/{id}/versions/{numero}/publication` | AR, AN | Publie et fige ; lance les exports | F-62, F-80, RG-53 à RG-56, RG-65 |
| `GET` | `/livres-blancs` | PUB | Livres blancs publiés (édition, type, UTR) | F-82 |
| `GET` | `/livres-blancs/{id}/versions/{numero}` | PUB | Version publiée : document figé | F-82, RG-54 |
| `GET` | `/livres-blancs/{id}/versions/{numero}/{format}` | PUB | Téléchargement PDF ou DOCX (202 si en cours de génération) | F-81 |
| `GET` | `/livres-blancs/{id}/comparaison` | PUB | Différences entre deux versions publiées | F-63 |
| `POST` | `/admin/livres-blancs/{id}/versions/{numero}/exports` | AN | Régénère les exports d'une version | F-81 |

### M7 Consolidation et états généraux

| Méthode | Chemin | Accès | Rôle | Références |
|---|---|---|---|---|
| `GET` | `/admin/editions/{id}/avancement` | AN | État des 33 LBR | F-70, RG-61 |
| `POST` | `/admin/editions/{id}/calculs-consolidation` | AN | Lance le calcul des convergences | F-71, §10.4 |
| `GET` | `/admin/calculs-consolidation/{id}` | AN | État et rapport d'un calcul | F-71 |
| `GET` | `/admin/editions/{id}/matrice` | AN | Matrice secteurs × UTR | F-72 |
| `GET` | `/admin/editions/{id}/convergences` | AN | Convergences (classe, secteur, statut, à vérifier) | F-73 |
| `GET` | `/admin/convergences/{id}` | AN | Convergence : sources par UTR, carte, score détaillé, cohésion | F-73 |
| `PATCH` | `/admin/convergences/{id}` | AN | Modifie intitulé, synthèse, propositions | F-73 |
| `POST` | `/admin/convergences/{id}/decisions` | AN | Retenir, rejeter, fusionner, scinder, reclasser, rouvrir | F-73, F-74, RG-62 à RG-64 |
| `GET` | `/admin/editions/{id}/decisions-etats-generaux` | AN | Journal des décisions (JSON ou CSV) | F-74 |

### M9 Candidats et engagements

| Méthode | Chemin | Accès | Rôle | Références |
|---|---|---|---|---|
| `GET` | `/admin/candidats` | AN | Candidats de l'édition | F-90 |
| `POST` | `/admin/candidats` | AN | Crée un candidat et invite son compte | F-90, RG-13, RG-70 |
| `PATCH` | `/admin/candidats/{id}` | AN | Modifie un candidat, marque élu ou non élu | F-90, RG-74 |
| `GET` | `/candidat/elements` | CAND | Éléments du livre blanc applicable et engagements pris | F-91, RG-71 |
| `POST` | `/candidat/engagements` | CAND | Déclare un engagement | F-91, RG-71, RG-72 |
| `POST` | `/candidat/engagements/{id}/retrait` | CAND | Retire un engagement avant l'élection | F-91, RG-73 |
| `POST` | `/candidat/suivis/{id}/commentaire` | CAND | Commente une mise à jour du suivi | F-93 |
| `POST` | `/admin/engagements/{id}/suivis` | AN | Ajoute une mise à jour du suivi avec justificatifs | F-93, RG-74 |
| `GET` | `/candidats` | PUB | Candidats (édition, type d'élection, UTR) | F-92 |
| `GET` | `/candidats/{id}` | PUB | Engagements d'un candidat et leur suivi | F-92, F-93 |
| `GET` | `/elus/tableau-de-bord` | PUB | Taux de réalisation des élus | F-94, RG-75 |

### M10 Portail public

| Méthode | Chemin | Accès | Rôle | Références |
|---|---|---|---|---|
| `GET` | `/portail/accueil` | PUB | Chiffres clés de l'édition active | F-100 |
| `GET` | `/portail/carte` | PUB | Indicateur par UTR pour la carte | F-101 |
| `GET` | `/portail/utr/{code}` | PUB | Page d'UTR : chiffres, préoccupations, LBR | F-102 |
| `GET` | `/preoccupations/{id}` | PUB | Préoccupation validée : synthèse, contributions, engagements | F-102, F-103 |
| `GET` | `/priorites/{id}` | PUB | Priorité du LBN : sources régionales et engagements | F-92, F-103 |
| `GET` | `/tracabilite/{type}/{id}` | PUB | Fil de traçabilité ascendant ou descendant | F-103 |
| `GET` | `/recherche` | PUB | Recherche plein texte multi-objets | F-104 |

### M11 Statistiques

| Méthode | Chemin | Accès | Rôle | Références |
|---|---|---|---|---|
| `GET` | `/statistiques/nationales` | PUB | Participation par UTR, secteur, période ; alertes de sous-représentation | F-110, NF-25 |
| `GET` | `/statistiques/representativite` | PUB | Sexe, âge, organisations, terrain | F-111, NF-25 |
| `GET` | `/statistiques/export.csv` | AN | Export des agrégats | F-112 |

### M13 Audit et services communs

| Méthode | Chemin | Accès | Rôle | Références |
|---|---|---|---|---|
| `GET` | `/admin/audit` | AR, AN | Journal d'audit filtré (périmètre selon le rôle) | F-131, RG-45 |
| `GET` | `/transparence/{utr}` | PUB | Compteurs de modération et de fusions par UTR | F-132 |
| `POST` | `/fichiers` | CON | Téléverse un fichier (photo, procès-verbal, justificatif) | NF-14 |
| `GET` | `/fichiers/{id}` | PUB* | Télécharge un fichier si l'appelant y a droit | NF-14 |
| `GET` | `/taches/{id}` | CON | État d'une tâche de fond lancée par l'appelant | §8 TRD |
| `GET` | `/sante` | PUB | État de l'application et de la base | NF-41 |

---

## 5. Détail des échanges principaux

### 5.1 Inscription — `POST /auth/inscription`

```json
{
  "nom": "KOFFI", "prenoms": "Awa", "email": "awa@exemple.ci", "motDePasse": "••••••••••••",
  "anneeNaissance": 1992, "sexe": "F", "telephone": null,
  "idTerritoireResidence": "0193…", "afficherNom": false,
  "accepteCharte": true, "consentementDonnees": true
}
```

- `201` : `{ "idUtilisateur": "…", "emailVerifie": false }` ; un e-mail de vérification est envoyé.
- Adresse déjà utilisée : `201` avec la même réponse apparente, et un e-mail « vous avez déjà un compte » est envoyé à l'adresse. Le formulaire ne révèle donc pas l'existence d'un compte (critère d'acceptation de M1).
- Âge inférieur à 18 ans : `422`, champ `anneeNaissance`, message renvoyant vers les organisations de jeunesse (RG-12).

### 5.2 Contributions proches — `POST /contributions/similaires`

Requête (texte en cours de saisie) :

```json
{ "idTerritoire": "0193…", "idSecteur": "0193…", "titre": "Maternité sans matériel",
  "constat": "La maternité du quartier manque de lits et de couveuses…", "proposition": "Équiper la maternité…" }
```

Réponse `200` :

```json
{
  "donnees": [
    { "idContribution": "0193…", "reference": "C-2030-GOH-000123", "titre": "Maternité sous-équipée à Gagnoa",
      "extrait": "La maternité du quartier manque de lits, de couveuses…", "lieu": "Gagnoa",
      "similarite": 0.42, "nbSoutiens": 17, "dejaSoutenue": false,
      "preoccupation": { "idPreoccupation": "0193…", "intitule": "Manque d'équipements à la maternité", "nbVoix": 54 } }
  ],
  "seuil": 0.20
}
```

Au plus 5 résultats, triés par similarité. L'appel est limité à 30 par minute.

### 5.3 Dépôt — `POST /contributions`

```json
{
  "titre": "Maternité sous-équipée à Gagnoa",
  "constat": "La maternité du quartier manque de lits, de couveuses et de matériel d'accouchement.",
  "proposition": "Équiper la maternité en lits, couveuses et matériel adapté.",
  "idSecteur": "0193…", "idTerritoire": "0193…", "localite": "Quartier Dioulabougou",
  "urgence": "ELEVEE", "tranchePopulation": "DE_5000_A_50000",
  "idOrganisation": null,
  "idFichiersIllustration": ["0193…"],
  "idClient": null,
  "saisieLe": null
}
```

Réponse `201` :

```json
{
  "idContribution": "0193…", "reference": "C-2030-GOH-000124", "statut": "PUBLIEE",
  "utr": { "code": "GOH", "libelle": "Gôh" }, "horsResidence": false,
  "preoccupation": { "idPreoccupation": "0193…", "intitule": "Manque d'équipements à la maternité",
                     "nouvelle": false, "similarite": 0.36 },
  "enModeration": false
}
```

**Version mobile (RG-30).** Une contribution préparée hors connexion porte `idClient` (UUID attribué par le téléphone) et `saisieLe` (date de rédaction). Si une contribution de même `idClient` existe déjà pour cet auteur, la réponse est `200` avec cette contribution, sans en créer une autre. Les photos d'une contribution en attente sont envoyées par `POST /fichiers` juste avant elle.

Erreurs propres : `409` `RG-20` (hors collecte), `409` `RG-23` (organisation non représentée), `429 LIMITE_QUOTIDIENNE` (RG-26), `403 EMAIL_NON_VERIFIE`. Si le filtre de termes signale le texte, la contribution est enregistrée avec le statut `EN_MODERATION` et `enModeration: true` (RG-40) ; l'interface l'explique au contributeur.

### 5.4 Préoccupations d'une UTR — `GET /admin/utr/{utr}/preoccupations`

Filtres : `secteur`, `statut`, `departement` ; tri : `score`, `nbVoix`, `creeeLe`.

```json
{
  "donnees": [{
    "idPreoccupation": "0193…", "reference": "P-2030-GOH-0012", "intitule": "Manque d'équipements à la maternité",
    "secteur": { "code": "SANTE", "libelle": "Santé" }, "statut": "PROPOSEE", "verrouillee": false,
    "nbContributions": 23, "nbVoix": 54, "score": 72.5,
    "scoreDetail": { "V": 0.91, "U": 0.75, "E": 0.50, "C": 0.33,
                     "ponderations": { "voix": 0.40, "urgence": 0.25, "etendue": 0.20, "collectif": 0.15 },
                     "voix": 54, "maxVoix": 80, "calculeLe": "2026-11-12T14:05:00Z" },
    "departements": ["Gagnoa", "Oumé"]
  }],
  "pagination": { "suivant": null, "total": 1 }
}
```

### 5.5 Fusion — `POST /admin/preoccupations/fusion`

```json
{ "idCible": "0193…", "idsAbsorbees": ["0193…", "0193…"], "intitule": "Maternités du Gôh sous-équipées" }
```

Effets, dans une transaction : les contributions des préoccupations absorbées sont rattachées à la cible (mode `MANUEL`), les absorbées passent `FUSIONNEE` avec un lien vers la cible (RG-43), l'action est journalisée (RG-45), les auteurs concernés sont notifiés (F-120), un recalcul des scores est programmé. Erreurs : `409 RG-56` si une préoccupation est verrouillée ; `422` si les préoccupations ne sont pas de la même UTR, du même secteur et de la même édition.

### 5.6 Publication d'un livre blanc

`GET /admin/livres-blancs/{id}/versions/{numero}/controles` liste ce qui empêche la publication, pour l'afficher avant que l'administrateur ne clique :

```json
{
  "publiable": false,
  "blocages": [
    { "regle": "RG-53", "message": "4 préoccupations sont encore à l'état « proposée ».", "lien": "/admin/utr/GOH/preoccupations?statut=PROPOSEE" },
    { "regle": "RG-55", "message": "Renseignez la date de l'atelier de validation régionale." }
  ],
  "avertissements": [
    { "message": "2 contributions ont été signalées dans les dernières 24 heures." }
  ]
}
```

`POST …/publication` (corps : `{ "confirmation": true }`, en-tête `If-Match`) fige la version (contenu, paramètres, empreinte) dans une transaction et programme la génération du PDF et du DOCX. Réponse `200` :

```json
{ "idVersion": "0193…", "numero": 1, "statut": "PUBLIEE", "publieeLe": "2026-12-18T10:00:00Z",
  "empreinteSha256": "9f2c…", "exports": { "pdf": "EN_COURS", "docx": "EN_COURS" } }
```

### 5.7 Consolidation — `POST /admin/editions/{id}/calculs-consolidation`

Réponse `202` (tâche). Une fois terminé, `GET /admin/calculs-consolidation/{id}` :

```json
{
  "idCalcul": "0193…", "statut": "TERMINE", "lanceLe": "2027-01-05T09:00:00Z", "termineLe": "2027-01-05T09:01:12Z",
  "parametres": { "seuils": { "convergence": 0.28, "cohesion_alerte": 0.20 }, "ponderations_nationales": { "…": "…" } },
  "rapport": {
    "utrCouvertes": 31, "preoccupationsEntrees": 1184,
    "convergences": { "NATIONALE": 22, "PARTAGEE": 57, "SPECIFIQUE": 93 },
    "aVerifier": 6,
    "parSecteur": [{ "secteur": "SANTE", "NATIONALE": 4, "PARTAGEE": 9, "SPECIFIQUE": 11 }]
  }
}
```

### 5.8 Arbitrage — `POST /admin/convergences/{id}/decisions`

Le champ `action` détermine les autres champs :

| `action` | Champs | Règle |
|---|---|---|
| `RETENIR` | `classe` facultative (si différente de la classe calculée, `motif` obligatoire) | RG-64 |
| `REJETER` | `motif` | RG-63 |
| `FUSIONNER` | `idCible`, `motif` | RG-63 |
| `SCINDER` | `groupes` : listes d'identifiants de préoccupations (chaque groupe devient une convergence `MANUELLE`), `motif` | RG-62 |
| `RECLASSER` | `classe`, `motif` | RG-64 |
| `REOUVRIR` | `motif` ; remet la convergence à l'état `PROPOSEE` tant que le LBN n'est pas publié | — |

Exemple :

```json
{ "action": "FUSIONNER", "idCible": "0193…", "motif": "Même besoin formulé sous l'angle de la maintenance et de l'équipement." }
```

Réponse `201` : la décision enregistrée et l'état de la convergence. Chaque décision est inscrite dans `decision_etats_generaux` (journal F-74).

### 5.9 Engagement — `POST /candidat/engagements`

```json
{ "idConvergence": "0193…", "idPreoccupation": null, "echeanceAnnee": 2032,
  "texte": "Équiper chaque maternité de district en couveuses et en matériel d'accouchement d'ici 2032." }
```

Un candidat à la présidentielle renseigne `idConvergence` (priorité du LBN publié) ; un candidat aux régionales renseigne `idPreoccupation` (préoccupation du LBR publié de son UTR). Erreurs : `409 RG-71` (cible non applicable), `409 CONFLIT` (engagement déjà pris sur cet élément, RG-72).

Suivi — `POST /admin/engagements/{id}/suivis` :

```json
{ "etat": "EN_COURS", "dateEtat": "2028-03-15", "description": "Travaux lancés dans trois régions.",
  "justificatifs": [ { "type": "LIEN", "url": "https://exemple.ci/communique", "libelle": "Communiqué officiel" },
                     { "type": "FICHIER", "idFichier": "0193…", "libelle": "Procès-verbal de réception" } ] }
```

Au moins un justificatif est exigé (RG-74).

### 5.10 Traçabilité — `GET /tracabilite/{type}/{id}`

`type` vaut `contribution` (sens ascendant : d'où vient-elle, où est-elle arrivée) ou `priorite` (sens descendant : de quoi est faite cette priorité). Exemple ascendant :

```json
{
  "contribution": { "reference": "C-2030-GOH-000124", "titre": "Maternité sous-équipée à Gagnoa", "auteurAffiche": "Citoyenne de Gagnoa" },
  "preoccupation": { "idPreoccupation": "0193…", "intitule": "Maternités du Gôh sous-équipées", "statut": "VALIDEE", "nbVoix": 54 },
  "livreBlancRegional": { "idLivreBlanc": "0193…", "version": 2, "rang": 1, "publieLe": "2026-12-18T10:00:00Z" },
  "priorite": { "idConvergence": "0193…", "intitule": "Équiper les maternités", "classe": "NATIONALE", "nbUtr": 12 },
  "livreBlancNational": { "idLivreBlanc": "0193…", "version": 1, "rang": 3 },
  "engagements": [ { "candidat": "Candidat Un", "echeanceAnnee": 2032, "statut": "DECLARE", "dernierEtat": "EN_COURS" } ]
}
```

Chaque niveau est `null` tant que l'étape correspondante n'a pas eu lieu. Les rangs viennent des versions publiées (valeurs figées, RG-54).

### 5.11 Import de terrain — `POST /admin/utr/{utr}/consultations`

`multipart/form-data` : métadonnées de la consultation (`intitule`, `dateConsultation`, `idTerritoireLieu`, `nbParticipants`, `description`) et fichier `fichier` (CSV ou XLSX, 10 Mo au plus) au format du modèle :

| Colonne | Obligatoire | Contenu |
|---|---|---|
| `titre` | oui | 10 à 120 caractères |
| `constat` | oui | 30 à 1 500 caractères |
| `proposition` | oui | 20 à 1 500 caractères |
| `code_secteur` | oui | Code du référentiel (`SANTE`, `EDUCATION`…) |
| `code_lieu` | oui | Code du territoire concerné (maille sélectionnable de l'UTR) |
| `urgence` | oui | `FAIBLE`, `MOYENNE`, `ELEVEE`, `CRITIQUE` |
| `localite` | non | Texte libre |
| `tranche_population` | non | Valeurs de la base |

Le rapport de la tâche donne, pour chaque ligne refusée, le numéro de ligne et la raison ; les lignes valides sont importées (RG-28) et rattachées par le moteur (TRD §6.3).

---

## 6. Données exposées publiquement

Les réponses publiques passent par des sérialiseurs à liste blanche (TRD §9.4). Pour une contribution :

| Champ public | Règle |
|---|---|
| `reference`, `titre`, `constat`, `proposition`, `secteur`, `lieu`, `localite`, `urgence`, `deposeeLe`, `nbSoutiens`, `photos` | Contribution `PUBLIEE` uniquement |
| `auteurAffiche` | « Citoyen·ne de [commune] » ; nom et prénoms seulement si l'auteur l'a choisi ; nom de l'organisation pour une contribution d'organisation ; « Consultation de terrain de [lieu], [date] » pour un import (RG-28, RG-29) |
| Jamais exposés | E-mail, téléphone, année de naissance, sexe, identifiant du compte de l'auteur, signalements, historique de modération |

Les statistiques publiques masquent toute case de moins de 5 personnes (NF-25).

---

## 7. Fichier OpenAPI

`api/openapi.yaml` contient tous les chemins, méthodes, accès (`x-acces`), références au PRD (`x-references`), le schéma d'erreur RFC 9457 et les schémas des échanges détaillés au §5. Les schémas des autres corps de requête seront dérivés des schémas Zod de `shared/schemas/` pendant l'implémentation, pour qu'il n'existe qu'une seule définition de chaque structure.
