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

{{NB_ENDPOINTS}} points d'accès, regroupés par module du PRD. Les fonctionnalités F-105 (pages d'information) et F-130 (journal d'audit) n'ont pas de point d'accès propre : la première est du contenu de l'interface, la seconde un mécanisme transversal (chaque service écrit dans le journal, TRD §11).

{{TABLES}}

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
