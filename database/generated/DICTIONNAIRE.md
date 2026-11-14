# Dictionnaire de données

> Généré automatiquement depuis les commentaires du schéma PostgreSQL (`generer_mld.py`). Ne pas modifier à la main.

## Référentiels

### territoire

Unité du découpage administratif ivoirien (district, région, département, sous-préfecture, commune). Référentiel importable et daté (D-07).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_territoire` | uuid | oui | PK | Identifiant technique (UUID v7). |
| `code` | text | oui |  | Code métier stable du territoire (ex. REG-GOH). |
| `code_pcode` | text | non |  | Code P-code du jeu COD-AB (OCHA/CNTIG), utilisé pour la cartographie. |
| `libelle` | text | oui |  | Nom officiel du territoire. |
| `niveau` | text | oui |  | Niveau administratif : DISTRICT, DISTRICT_AUTONOME, REGION, DEPARTEMENT, SOUS_PREFECTURE, COMMUNE. |
| `id_parent` | uuid | non | FK → territoire | Territoire de rattachement de niveau supérieur (RG-04). |
| `est_utr` | boolean | oui |  | Vrai si le territoire est une unité territoriale de rédaction : région ou district autonome (RG-05, D-06). |
| `id_utr` | uuid | non | FK → territoire | UTR à laquelle appartient le territoire (dénormalisé à l'import pour les agrégations). |
| `id_departement` | uuid | non | FK → territoire | Département d'appartenance (dénormalisé), utilisé pour la composante « étendue » du score. |
| `est_selectionnable` | boolean | oui |  | Vrai si le territoire constitue la maille la plus fine disponible et peut être choisi dans une contribution (RG-21). |
| `population` | integer | non |  | Population de référence (obligatoire pour les UTR avant les états généraux, RG-05). |
| `annee_population` | smallint | non |  | Année de la donnée de population. |
| `date_debut_validite` | date | oui |  | Date d'entrée en vigueur de l'unité dans le découpage. |
| `date_fin_validite` | date | non |  | Date de fin de validité (découpage modifié). |

Contraintes de vérification :

- `ck_territoire_racine` : `CHECK (((niveau = ANY (ARRAY['DISTRICT'::text, 'DISTRICT_AUTONOME'::text])) = (id_parent IS NULL)))`
- `ck_territoire_utr` : `CHECK ((est_utr = (niveau = ANY (ARRAY['REGION'::text, 'DISTRICT_AUTONOME'::text]))))`
- `ck_territoire_utr_soi` : `CHECK (((NOT est_utr) OR (id_utr = id_territoire)))`
- `ck_territoire_validite` : `CHECK (((date_fin_validite IS NULL) OR (date_fin_validite >= date_debut_validite)))`
- `territoire_annee_population_check` : `CHECK (((annee_population >= 1975) AND (annee_population <= 2100)))`
- `territoire_niveau_check` : `CHECK ((niveau = ANY (ARRAY['DISTRICT'::text, 'DISTRICT_AUTONOME'::text, 'REGION'::text, 'DEPARTEMENT'::text, 'SOUS_PREFECTURE'::text, 'COMMUNE'::text])))`
- `territoire_population_check` : `CHECK ((population > 0))`

Unicité : (code) ; (code_pcode)

### secteur

Domaine de développement auquel se rattache une contribution (référentiel administrable, RG-06).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_secteur` | uuid | oui | PK | Secteur. |
| `code` | text | oui |  | Code court du secteur (ex. SANTE). |
| `libelle` | text | oui |  | Libellé affiché. |
| `description` | text | non |  | Description du périmètre du secteur. |
| `icone` | text | non |  | Nom de l'icône du système de design. |
| `odd` | int2[] | oui |  | Objectifs de développement durable de rattachement indicatif. |
| `mots_cles` | text[] | oui |  | Mots-clés d'aide au classement automatique (F-31). |
| `ordre` | smallint | oui |  | Ordre d'affichage. |
| `actif` | boolean | oui |  | Faux si le secteur est désactivé (il reste lié aux données existantes). |

Contraintes de vérification :

- `ck_secteur_odd` : `CHECK ((odd <@ ARRAY[(1)::smallint, (2)::smallint, (3)::smallint, (4)::smallint, (5)::smallint, (6)::smallint, (7)::smallint, (8)::smallint, (9)::smallint, (10)::smallint, (11)::smallint, (12)::smallint, (13)::smallint, (14)::smallint, (15)::smallint, (16)::smallint, (17)::smallint]))`

Unicité : (code) ; (libelle)

### edition

Cycle complet d'élaboration d'un livre blanc, rattaché à une échéance électorale.

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_edition` | uuid | oui | PK | Édition de rattachement. |
| `libelle` | text | oui |  | Nom de l'édition (ex. Édition 2030). |
| `annee_echeance` | smallint | oui |  | Année de l'échéance électorale visée. |
| `phase` | text | oui |  | Phase courante (§8.1 du PRD) ; transitions contrôlées (RG-03). |
| `date_ouverture_collecte` | timestamptz | non |  | Ouverture prévue ou effective de la collecte. |
| `date_cloture_collecte` | timestamptz | non |  | Clôture prévue ou effective de la collecte. |
| `date_election` | date | non |  | Date de l'élection ; au-delà, les engagements sont définitifs (RG-73). |
| `parametres` | jsonb | oui |  | Seuils de similarité, pondérations, limites ; figés hors phase PREPARATION (RG-02). |
| `creee_le` | timestamptz | oui |  | Date de création. |
| `creee_par` | uuid | non | FK → utilisateur | Auteur de la création. |
| `modifie_le` | timestamptz | oui |  | Date de dernière modification. |

Contraintes de vérification :

- `ck_edition_dates` : `CHECK (((date_cloture_collecte IS NULL) OR (date_ouverture_collecte IS NULL) OR (date_cloture_collecte > date_ouverture_collecte)))`
- `ck_edition_parametres` : `CHECK (((parametres ? 'seuils'::text) AND (parametres ? 'ponderations_regionales'::text) AND (parametres ? 'ponderations_nationales'::text)))`
- `edition_annee_echeance_check` : `CHECK (((annee_echeance >= 2020) AND (annee_echeance <= 2100)))`
- `edition_phase_check` : `CHECK ((phase = ANY (ARRAY['PREPARATION'::text, 'COLLECTE'::text, 'CONSOLIDATION_REGIONALE'::text, 'ETATS_GENERAUX'::text, 'ENGAGEMENTS'::text, 'SUIVI'::text, 'CLOTUREE'::text])))`

Unicité : (libelle)

## Comptes et organisations

### utilisateur

Personne physique disposant d'un compte (contributeur, administrateur ou candidat).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_utilisateur` | uuid | oui | PK | Utilisateur concerné. |
| `nom` | text | non |  | Nom de famille (effacé à l'anonymisation). |
| `prenoms` | text | non |  | Prénoms (effacés à l'anonymisation). |
| `email` | text | non |  | Adresse e-mail de connexion, unique sans tenir compte de la casse. |
| `email_verifie_le` | timestamptz | non |  | Date de vérification de l'adresse e-mail ; nulle tant que le compte n'est pas vérifié (RG-11). |
| `mot_de_passe_hash` | text | non |  | Empreinte du mot de passe (scrypt), jamais le mot de passe en clair. |
| `telephone` | text | non |  | Téléphone (facultatif). |
| `sexe` | character(1) | non |  | Sexe déclaré (facultatif) : F ou M ; sert aux indicateurs de représentativité. |
| `annee_naissance` | smallint | non |  | Année de naissance ; l'inscription exige 18 ans atteints dans l'année (RG-12). |
| `id_territoire_residence` | uuid | non | FK → territoire | Sous-préfecture ou commune de résidence. |
| `afficher_nom` | boolean | oui |  | Vrai si l'utilisateur accepte que son nom apparaisse publiquement (RG-29). |
| `statut` | text | oui |  | ACTIF, SUSPENDU ou SUPPRIME (compte anonymisé, RG-16). |
| `tentatives_echouees` | smallint | oui |  | Nombre d'échecs de connexion consécutifs (RG-17). |
| `verrouille_jusqua` | timestamptz | non |  | Fin du verrouillage temporaire après 5 échecs (RG-17). |
| `consentement_le` | timestamptz | non |  | Date d'acceptation de la charte et du traitement des données. |
| `inscrit_le` | timestamptz | oui |  | Date d'inscription. |
| `derniere_connexion_le` | timestamptz | non |  | Date de dernière connexion réussie. |
| `anonymise_le` | timestamptz | non |  | Date d'anonymisation du compte. |
| `modifie_le` | timestamptz | oui |  | Date de dernière modification. |

Contraintes de vérification :

- `ck_utilisateur_actif_complet` : `CHECK (((statut = 'SUPPRIME'::text) OR ((nom IS NOT NULL) AND (prenoms IS NOT NULL) AND (email IS NOT NULL) AND (mot_de_passe_hash IS NOT NULL) AND (consentement_le IS NOT NULL))))`
- `ck_utilisateur_age` : `CHECK (((annee_naissance IS NULL) OR (annee_naissance <= ((EXTRACT(year FROM inscrit_le))::integer - 18))))`
- `ck_utilisateur_supprime_anonyme` : `CHECK (((statut <> 'SUPPRIME'::text) OR ((email IS NULL) AND (nom IS NULL) AND (anonymise_le IS NOT NULL))))`
- `utilisateur_annee_naissance_check` : `CHECK (((annee_naissance >= 1900) AND (annee_naissance <= 2100)))`
- `utilisateur_sexe_check` : `CHECK ((sexe = ANY (ARRAY['F'::bpchar, 'M'::bpchar])))`
- `utilisateur_statut_check` : `CHECK ((statut = ANY (ARRAY['ACTIF'::text, 'SUSPENDU'::text, 'SUPPRIME'::text])))`
- `utilisateur_tentatives_echouees_check` : `CHECK ((tentatives_echouees >= 0))`

### affectation

Attribution d'un rôle d'administration à un utilisateur, avec son périmètre territorial (D-04).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_affectation` | uuid | oui | PK | Identifiant technique (UUID v7). |
| `id_utilisateur` | uuid | oui | FK → utilisateur | Utilisateur concerné. |
| `role` | text | oui |  | ADMIN_REGIONAL (périmètre : une UTR) ou ADMIN_NATIONAL (périmètre : national). |
| `id_utr` | uuid | non | FK → territoire | UTR administrée (obligatoire pour ADMIN_REGIONAL, nulle sinon). |
| `date_debut` | date | oui |  | Début de l'affectation. |
| `date_fin` | date | non |  | Fin de l'affectation (nulle si en cours). |
| `attribuee_par` | uuid | non | FK → utilisateur | Administrateur national ayant attribué le rôle (RG-13). |
| `attribuee_le` | timestamptz | oui |  | Date d'attribution. |

Contraintes de vérification :

- `affectation_role_check` : `CHECK ((role = ANY (ARRAY['ADMIN_REGIONAL'::text, 'ADMIN_NATIONAL'::text])))`
- `ck_affectation_dates` : `CHECK (((date_fin IS NULL) OR (date_fin >= date_debut)))`
- `ck_affectation_perimetre` : `CHECK (((role = 'ADMIN_REGIONAL'::text) = (id_utr IS NOT NULL)))`

### organisation

Personne morale (association, ONG, collectivité, organisation professionnelle, coopérative…) représentée par un contributeur.

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_organisation` | uuid | oui | PK | Identifiant technique (UUID v7). |
| `denomination` | text | oui |  | Nom de l'organisation. |
| `type` | text | oui |  | ASSOCIATION, ONG, COLLECTIVITE, ORGANISATION_PROFESSIONNELLE, COOPERATIVE ou AUTRE. |
| `numero_enregistrement` | text | non |  | Numéro de récépissé ou d'enregistrement (facultatif). |
| `description` | text | non |  | Présentation de l'organisation. |
| `id_territoire_siege` | uuid | oui | FK → territoire | Territoire du siège ; détermine l'administrateur régional compétent pour la vérification (RG-15). |
| `id_representant` | uuid | oui | FK → utilisateur | Contributeur représentant ; un contributeur représente au plus une organisation (RG-14). |
| `statut_verification` | text | oui |  | NON_VERIFIEE, VERIFIEE ou REJETEE (RG-15). |
| `verifiee_le` | timestamptz | non |  | Date de la décision de vérification. |
| `id_verificateur` | uuid | non | FK → utilisateur | Administrateur ayant statué. |
| `motif_rejet` | text | non |  | Motif obligatoire en cas de rejet. |
| `creee_le` | timestamptz | oui |  | Date de création. |
| `modifie_le` | timestamptz | oui |  | Date de dernière modification. |

Contraintes de vérification :

- `ck_organisation_rejet` : `CHECK (((statut_verification = 'REJETEE'::text) = (motif_rejet IS NOT NULL)))`
- `ck_organisation_verification` : `CHECK (((statut_verification = 'NON_VERIFIEE'::text) = ((verifiee_le IS NULL) AND (id_verificateur IS NULL))))`
- `organisation_denomination_check` : `CHECK (((char_length(denomination) >= 3) AND (char_length(denomination) <= 200)))`
- `organisation_description_check` : `CHECK ((char_length(description) <= 2000))`
- `organisation_statut_verification_check` : `CHECK ((statut_verification = ANY (ARRAY['NON_VERIFIEE'::text, 'VERIFIEE'::text, 'REJETEE'::text])))`
- `organisation_type_check` : `CHECK ((type = ANY (ARRAY['ASSOCIATION'::text, 'ONG'::text, 'COLLECTIVITE'::text, 'ORGANISATION_PROFESSIONNELLE'::text, 'COOPERATIVE'::text, 'AUTRE'::text])))`

Unicité : (id_representant)

### fichier

Fichier stocké hors de la racine web : photo, procès-verbal, justificatif, import, export généré.

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_fichier` | uuid | oui | PK | Fichier joint. |
| `chemin_stockage` | text | oui |  | Clé de stockage relative au volume de fichiers. |
| `nom_original` | text | oui |  | Nom du fichier tel que téléversé. |
| `type_mime` | text | oui |  | Type réel détecté à partir du contenu (NF-14). |
| `taille_octets` | integer | oui |  | Taille en octets (photos limitées à 5 Mo par l'application). |
| `empreinte_sha256` | character(64) | oui |  | Empreinte SHA-256 du contenu (intégrité). |
| `largeur` | integer | non |  | Largeur en pixels (images). |
| `hauteur` | integer | non |  | Hauteur en pixels (images). |
| `depose_par` | uuid | non | FK → utilisateur | Utilisateur ayant déposé le fichier (nul pour un fichier généré par le système). |
| `depose_le` | timestamptz | oui |  | Date de dépôt. |

Contraintes de vérification :

- `fichier_hauteur_check` : `CHECK ((hauteur > 0))`
- `fichier_largeur_check` : `CHECK ((largeur > 0))`
- `fichier_taille_octets_check` : `CHECK (((taille_octets > 0) AND (taille_octets <= 52428800)))`
- `fichier_type_mime_check` : `CHECK ((type_mime = ANY (ARRAY['image/jpeg'::text, 'image/png'::text, 'image/webp'::text, 'application/pdf'::text, 'text/csv'::text, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'::text, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'::text])))`

Unicité : (chemin_stockage)

### notification

Notification adressée à un utilisateur dans l'application et, le cas échéant, par e-mail (F-120).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_notification` | uuid | oui | PK | Identifiant technique (UUID v7). |
| `id_utilisateur` | uuid | oui | FK → utilisateur | Utilisateur concerné. |
| `type` | text | oui |  | Type (valeurs contrôlées, voir contraintes). |
| `titre` | text | oui |  | Titre. |
| `message` | text | oui |  | Texte du message. |
| `lien` | text | non |  | Lien interne vers l'objet concerné. |
| `creee_le` | timestamptz | oui |  | Date de création. |
| `lue_le` | timestamptz | non |  | Date de lecture (nulle si non lue). |
| `email_envoye_le` | timestamptz | non |  | Date d'envoi de l'e-mail associé. |

## Collecte et analyse régionale

### consultation_terrain

Atelier ou réunion de terrain dont les contributions ont été importées par un administrateur régional (F-35, RG-28).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_consultation` | uuid | oui | PK | Identifiant technique (UUID v7). |
| `id_edition` | uuid | oui | FK → edition | Édition de rattachement. |
| `id_utr` | uuid | oui | FK → territoire | UTR concernée. |
| `id_territoire_lieu` | uuid | oui | FK → territoire | Lieu de la consultation. |
| `intitule` | text | oui |  | Intitulé de la consultation. |
| `date_consultation` | date | oui |  | Date de tenue. |
| `nb_participants` | integer | oui |  | Nombre de participants déclaré ; détermine le poids en voix (D-10). |
| `description` | text | non |  | Description libre. |
| `id_fichier_source` | uuid | non | FK → fichier | Fichier CSV/XLSX importé. |
| `importee_par` | uuid | oui | FK → utilisateur | Administrateur ayant importé. |
| `importee_le` | timestamptz | oui |  | Date d'import. |

Contraintes de vérification :

- `consultation_terrain_nb_participants_check` : `CHECK ((nb_participants > 0))`

### contribution

Expression d'un problème (constat) et d'une solution souhaitée (proposition), localisée et rattachée à un secteur ; unité de base du système.

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_contribution` | uuid | oui | PK | Contribution concernée. |
| `reference` | text | oui |  | Référence publique lisible (ex. C-2030-GOH-000123). |
| `id_edition` | uuid | oui | FK → edition | Édition de rattachement. |
| `source` | text | oui |  | EN_LIGNE (déposée par un compte) ou TERRAIN (importée d'une consultation). |
| `id_auteur` | uuid | non | FK → utilisateur | Contributeur auteur (nul pour une contribution de terrain, RG-28). |
| `id_organisation` | uuid | non | FK → organisation | Organisation au nom de laquelle la contribution est déposée (RG-23). |
| `id_consultation` | uuid | non | FK → consultation_terrain | Consultation de terrain d'origine (contribution importée). |
| `titre` | text | oui |  | Titre court, de 10 à 120 caractères (RG-21). |
| `constat` | text | oui |  | Description du problème, de 30 à 1 500 caractères. |
| `proposition` | text | oui |  | Solution souhaitée, de 20 à 1 500 caractères. |
| `id_secteur` | uuid | oui | FK → secteur | Secteur de développement. |
| `id_territoire` | uuid | oui | FK → territoire | Territoire concerné : maille la plus fine disponible (RG-21). |
| `id_utr` | uuid | oui | FK → territoire | UTR déduite du territoire concerné (RG-22), dénormalisée. |
| `localite` | text | non |  | Village, quartier ou lieu précis (facultatif). |
| `urgence` | text | oui |  | Urgence perçue : FAIBLE, MOYENNE, ELEVEE, CRITIQUE. |
| `tranche_population` | text | non |  | Tranche de population concernée (facultative). |
| `hors_residence` | boolean | oui |  | Vrai si l'UTR concernée diffère de l'UTR de résidence de l'auteur (RG-22). |
| `statut` | text | oui |  | PUBLIEE, EN_MODERATION, MASQUEE, RETIREE_AUTEUR, RETIREE_ADMIN, ARCHIVEE (§8.3). |
| `id_preoccupation` | uuid | non | FK → preoccupation | Préoccupation de rattachement (RG-24). |
| `mode_rattachement` | text | non |  | AUTO (moteur de regroupement) ou MANUEL (administrateur) ; un rattachement manuel n'est jamais défait automatiquement. |
| `similarite_rattachement` | numeric(4,3) | non |  | Similarité calculée lors du rattachement automatique. |
| `nb_signalements` | integer | oui |  | Nombre de signalements distincts reçus (RG-40). |
| `version` | integer | oui |  | Numéro de version courant (historisation, RG-25). |
| `deposee_le` | timestamptz | oui |  | Date de dépôt. |
| `modifie_le` | timestamptz | oui |  | Date de dernière modification. |
| `titre_normalise` | text (générée) | non |  | Titre normalisé (minuscules, sans accents), indexé en trigrammes. |
| `texte_normalise` | text (générée) | non |  | Texte complet normalisé, indexé en trigrammes pour la similarité. |
| `lexemes` | text[] (générée) | non |  | Racines lexicales françaises du texte, utilisées par la similarité composite. |
| `document_recherche` | tsvector (générée) | non |  | Vecteur de recherche plein texte en français (F-104). |
| `id_client` | uuid | non |  | Identifiant attribué par l'appareil à une contribution préparée dans la version mobile ; un nouvel envoi de la même contribution est reconnu et ne crée pas de doublon (RG-30) |
| `saisie_le` | timestamptz | non |  | Date de rédaction sur l'appareil pour une contribution préparée hors connexion ; la date d'enregistrement reste deposee_le (RG-30) |

Contraintes de vérification :

- `ck_contribution_hors_ligne` : `CHECK (((source = 'EN_LIGNE'::text) OR ((id_client IS NULL) AND (saisie_le IS NULL))))`
- `ck_contribution_rattachement` : `CHECK (((statut <> ALL (ARRAY['PUBLIEE'::text, 'EN_MODERATION'::text])) OR ((id_preoccupation IS NOT NULL) AND (mode_rattachement IS NOT NULL))))`
- `ck_contribution_saisie` : `CHECK (((saisie_le IS NULL) OR (saisie_le <= (deposee_le + '00:05:00'::interval))))`
- `ck_contribution_source` : `CHECK ((((source = 'EN_LIGNE'::text) AND (id_auteur IS NOT NULL) AND (id_consultation IS NULL)) OR ((source = 'TERRAIN'::text) AND (id_auteur IS NULL) AND (id_consultation IS NOT NULL) AND (id_organisation IS NULL))))`
- `contribution_constat_check` : `CHECK (((char_length(constat) >= 30) AND (char_length(constat) <= 1500)))`
- `contribution_localite_check` : `CHECK ((char_length(localite) <= 120))`
- `contribution_mode_rattachement_check` : `CHECK ((mode_rattachement = ANY (ARRAY['AUTO'::text, 'MANUEL'::text])))`
- `contribution_nb_signalements_check` : `CHECK ((nb_signalements >= 0))`
- `contribution_proposition_check` : `CHECK (((char_length(proposition) >= 20) AND (char_length(proposition) <= 1500)))`
- `contribution_similarite_rattachement_check` : `CHECK (((similarite_rattachement >= (0)::numeric) AND (similarite_rattachement <= (1)::numeric)))`
- `contribution_source_check` : `CHECK ((source = ANY (ARRAY['EN_LIGNE'::text, 'TERRAIN'::text])))`
- `contribution_statut_check` : `CHECK ((statut = ANY (ARRAY['PUBLIEE'::text, 'EN_MODERATION'::text, 'MASQUEE'::text, 'RETIREE_AUTEUR'::text, 'RETIREE_ADMIN'::text, 'ARCHIVEE'::text])))`
- `contribution_titre_check` : `CHECK (((char_length(titre) >= 10) AND (char_length(titre) <= 120)))`
- `contribution_tranche_population_check` : `CHECK ((tranche_population = ANY (ARRAY['MOINS_500'::text, 'DE_500_A_5000'::text, 'DE_5000_A_50000'::text, 'PLUS_50000'::text, 'INCONNUE'::text])))`
- `contribution_urgence_check` : `CHECK ((urgence = ANY (ARRAY['FAIBLE'::text, 'MOYENNE'::text, 'ELEVEE'::text, 'CRITIQUE'::text])))`

Unicité : (reference)

### version_contribution

Historique des versions successives d'une contribution modifiée par son auteur (RG-25).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_version` | uuid | oui | PK | Version de livre blanc concernée. |
| `id_contribution` | uuid | oui | FK → contribution | Contribution concernée. |
| `numero` | integer | oui |  | Numéro de la version archivée. |
| `titre` | text | oui |  | Titre. |
| `constat` | text | oui |  | Constat archivé. |
| `proposition` | text | oui |  | Proposition archivée. |
| `id_secteur` | uuid | oui | FK → secteur | Secteur. |
| `id_territoire` | uuid | oui | FK → territoire | Référence vers territoire. |
| `urgence` | text | oui |  | Urgence archivée. |
| `tranche_population` | text | non |  | Tranche de population archivée. |
| `localite` | text | non |  | Localité archivée. |
| `enregistree_le` | timestamptz | oui |  | Date d'archivage de la version. |

Unicité : (id_contribution, numero)

### illustration

Photo jointe à une contribution, au plus 3 par contribution (RG-21).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_contribution` | uuid | oui | PK, FK → contribution | Contribution concernée. |
| `id_fichier` | uuid | oui | PK, FK → fichier | Fichier joint. |
| `ordre` | smallint | oui |  | Position de la photo (1 à 3). |

Contraintes de vérification :

- `illustration_ordre_check` : `CHECK (((ordre >= 1) AND (ordre <= 3)))`

Unicité : (id_contribution, ordre)

### soutien

Adhésion d'un contributeur à une contribution existante ; compte comme une voix (RG-27, RG-51).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_utilisateur` | uuid | oui | PK, FK → utilisateur | Utilisateur concerné. |
| `id_contribution` | uuid | oui | PK, FK → contribution | Contribution concernée. |
| `soutenu_le` | timestamptz | oui |  | Date du soutien. |

### signalement

Signalement d'une contribution par un contributeur (F-37) ; un seul par personne et par contribution.

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_utilisateur` | uuid | oui | PK, FK → utilisateur | Utilisateur concerné. |
| `id_contribution` | uuid | oui | PK, FK → contribution | Contribution concernée. |
| `motif` | text | oui |  | HORS_CHARTE, HORS_SUJET, DOUBLON, DONNEES_PERSONNELLES ou AUTRE. |
| `commentaire` | text | non |  | Commentaire libre. |
| `signale_le` | timestamptz | oui |  | Date du signalement. |
| `traite` | boolean | oui |  | Vrai une fois une décision de modération prise. |

Contraintes de vérification :

- `signalement_commentaire_check` : `CHECK ((char_length(commentaire) <= 500))`
- `signalement_motif_check` : `CHECK ((motif = ANY (ARRAY['HORS_CHARTE'::text, 'HORS_SUJET'::text, 'DOUBLON'::text, 'DONNEES_PERSONNELLES'::text, 'AUTRE'::text])))`

### decision_moderation

Décision d'un administrateur sur une contribution signalée ou suspecte (RG-41).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_decision` | uuid | oui | PK | Identifiant technique (UUID v7). |
| `id_contribution` | uuid | oui | FK → contribution | Contribution concernée. |
| `id_administrateur` | uuid | oui | FK → utilisateur | Administrateur auteur de la décision. |
| `action` | text | oui |  | MAINTENIR, MASQUER ou RETIRER. |
| `motif` | text | non |  | Motif obligatoire pour MASQUER et RETIRER. |
| `commentaire` | text | non |  | Commentaire transmis à l'auteur. |
| `decidee_le` | timestamptz | oui |  | Date de la décision. |

Contraintes de vérification :

- `ck_decision_commentaire` : `CHECK (((action = 'MAINTENIR'::text) OR (commentaire IS NOT NULL)))`
- `ck_decision_motif` : `CHECK (((action = 'MAINTENIR'::text) = (motif IS NULL)))`
- `decision_moderation_action_check` : `CHECK ((action = ANY (ARRAY['MAINTENIR'::text, 'MASQUER'::text, 'RETIRER'::text])))`
- `decision_moderation_motif_check` : `CHECK ((motif = ANY (ARRAY['HORS_CHARTE'::text, 'HORS_SUJET'::text, 'DOUBLON_STRICT'::text, 'DONNEES_PERSONNELLES'::text, 'AUTRE'::text])))`

### preoccupation

Groupe de contributions similaires d'une même UTR et d'un même secteur ; unité du livre blanc régional (RG-50).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_preoccupation` | uuid | oui | PK | Préoccupation concernée. |
| `reference` | text | oui |  | Référence lisible (ex. P-2030-GOH-0042). |
| `id_edition` | uuid | oui | FK → edition | Édition de rattachement. |
| `id_utr` | uuid | oui | FK → territoire | UTR de la préoccupation. |
| `id_secteur` | uuid | oui | FK → secteur | Secteur de la préoccupation. |
| `intitule` | text | oui |  | Intitulé ; provisoirement le titre de la première contribution (§10.2). |
| `synthese` | jsonb | non |  | Synthèse rédigée par l'administrateur (document de texte enrichi). |
| `propositions_retenues` | jsonb | oui |  | Liste ordonnée des propositions retenues (tableau JSON de textes). |
| `statut` | text | oui |  | PROPOSEE (créée par le système), VALIDEE, FUSIONNEE ou ECARTEE. |
| `motif_ecartement` | text | non |  | Motif obligatoire d'écartement (RG-52). |
| `id_fusionnee_dans` | uuid | non | FK → preoccupation | Préoccupation cible d'une fusion (RG-43). |
| `id_contribution_representative` | uuid | non | FK → contribution | Contribution la plus soutenue, servant de référence de similarité (§10.2). |
| `texte_reference` | text | oui |  | Texte normalisé (intitulé + contribution représentative) indexé pour la similarité. |
| `lexemes_reference` | text[] | oui |  | Racines lexicales du texte de référence. |
| `nb_contributions` | integer | oui |  | Nombre de contributions publiées rattachées (valeur calculée). |
| `nb_voix` | integer | oui |  | Nombre de voix au sens de RG-51 (valeur calculée). |
| `score` | numeric(5,2) | non |  | Score de priorité régional de 0 à 100 (§10.3, valeur calculée). |
| `score_detail` | jsonb | non |  | Décomposition du score (V, U, E, C et pondérations) pour l'explicabilité (P5). |
| `score_calcule_le` | timestamptz | non |  | Date du dernier calcul du score. |
| `verrouillee` | boolean | oui |  | Vrai quand le livre blanc régional est publié : toute modification exige une nouvelle version (RG-56). |
| `id_convergence` | uuid | non | FK → convergence | Convergence nationale à laquelle la préoccupation est rattachée (RG-62). |
| `validee_par` | uuid | non | FK → utilisateur | Administrateur ayant validé. |
| `validee_le` | timestamptz | non |  | Date de validation. |
| `creee_le` | timestamptz | oui |  | Date de création. |
| `modifie_le` | timestamptz | oui |  | Date de dernière modification. |

Contraintes de vérification :

- `ck_preoccupation_ecartee` : `CHECK (((statut = 'ECARTEE'::text) = (motif_ecartement IS NOT NULL)))`
- `ck_preoccupation_fusion` : `CHECK ((((statut = 'FUSIONNEE'::text) = (id_fusionnee_dans IS NOT NULL)) AND ((id_fusionnee_dans IS NULL) OR (id_fusionnee_dans <> id_preoccupation))))`
- `ck_preoccupation_score` : `CHECK (((score IS NULL) OR ((score >= (0)::numeric) AND (score <= (100)::numeric))))`
- `ck_preoccupation_validation` : `CHECK (((statut <> 'VALIDEE'::text) OR ((validee_par IS NOT NULL) AND (validee_le IS NOT NULL))))`
- `preoccupation_intitule_check` : `CHECK (((char_length(intitule) >= 5) AND (char_length(intitule) <= 200)))`
- `preoccupation_statut_check` : `CHECK ((statut = ANY (ARRAY['PROPOSEE'::text, 'VALIDEE'::text, 'FUSIONNEE'::text, 'ECARTEE'::text])))`

Unicité : (reference)

## Livres blancs et consolidation

### livre_blanc

Livre blanc régional (une UTR) ou national d'une édition ; son contenu est porté par ses versions.

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_livre_blanc` | uuid | oui | PK | Livre blanc décliné. |
| `id_edition` | uuid | oui | FK → edition | Édition de rattachement. |
| `type` | text | oui |  | REGIONAL ou NATIONAL. |
| `id_utr` | uuid | non | FK → territoire | UTR du livre blanc régional (nulle pour le national). |

Contraintes de vérification :

- `ck_livre_blanc_type` : `CHECK (((type = 'REGIONAL'::text) = (id_utr IS NOT NULL)))`
- `livre_blanc_type_check` : `CHECK ((type = ANY (ARRAY['REGIONAL'::text, 'NATIONAL'::text])))`

Unicité : (id_edition, type, id_utr)

### version_livre_blanc

Version successive d'un livre blanc ; une version publiée est figée et non modifiable (RG-54).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_version` | uuid | oui | PK | Version de livre blanc concernée. |
| `id_livre_blanc` | uuid | oui | FK → livre_blanc | Livre blanc décliné. |
| `numero` | smallint | oui |  | Numéro de version (1, 2, …). |
| `statut` | text | oui |  | BROUILLON, PUBLIEE ou REMPLACEE. |
| `introduction` | jsonb | non |  | Introduction ou préambule (texte enrichi). |
| `resume_changements` | text | non |  | Résumé obligatoire des changements à partir de la version 2 (RG-54). |
| `date_validation` | date | non |  | Date de l'atelier ou de la réunion de validation (obligatoire pour un LBR publié, RG-55). |
| `lieu_validation` | text | non |  | Lieu de la validation (facultatif). |
| `id_fichier_pv` | uuid | non | FK → fichier | Procès-verbal de validation (PDF, facultatif). |
| `contenu_fige` | jsonb | non |  | Modèle de document complet figé à la publication (préoccupations, scores, liens de traçabilité). |
| `parametres_figes` | jsonb | non |  | Pondérations et seuils en vigueur à la publication. |
| `empreinte_sha256` | character(64) | non |  | Empreinte du contenu figé (preuve d'intégrité). |
| `id_fichier_pdf` | uuid | non | FK → fichier | Export PDF généré. |
| `id_fichier_docx` | uuid | non | FK → fichier | Export Word généré. |
| `creee_le` | timestamptz | oui |  | Date de création. |
| `creee_par` | uuid | oui | FK → utilisateur | Auteur de la création. |
| `publiee_le` | timestamptz | non |  | Date de publication. |
| `publiee_par` | uuid | non | FK → utilisateur | Administrateur ayant publié. |
| `remplacee_le` | timestamptz | non |  | Date à laquelle une version plus récente a été publiée. |
| `modifie_le` | timestamptz | oui |  | Date de dernière modification. |

Contraintes de vérification :

- `ck_version_changements` : `CHECK (((numero = 1) OR (statut = 'BROUILLON'::text) OR (resume_changements IS NOT NULL)))`
- `ck_version_publiee` : `CHECK (((statut = 'BROUILLON'::text) OR ((publiee_le IS NOT NULL) AND (publiee_par IS NOT NULL) AND (contenu_fige IS NOT NULL) AND (parametres_figes IS NOT NULL) AND (empreinte_sha256 IS NOT NULL))))`
- `ck_version_remplacee` : `CHECK (((statut = 'REMPLACEE'::text) = (remplacee_le IS NOT NULL)))`
- `version_livre_blanc_numero_check` : `CHECK ((numero >= 1))`
- `version_livre_blanc_statut_check` : `CHECK ((statut = ANY (ARRAY['BROUILLON'::text, 'PUBLIEE'::text, 'REMPLACEE'::text])))`

Unicité : (id_livre_blanc, numero)

### inclusion_preoccupation

Préoccupation figurant dans une version publiée d'un livre blanc régional, avec ses valeurs figées (traçabilité, RG-54).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_version` | uuid | oui | PK, FK → version_livre_blanc | Version de livre blanc concernée. |
| `id_preoccupation` | uuid | oui | PK, FK → preoccupation | Préoccupation concernée. |
| `rang` | integer | oui |  | Rang de priorité dans la version. |
| `intitule_fige` | text | oui |  | Intitulé à la date de publication. |
| `score_fige` | numeric(5,2) | oui |  | Score à la date de publication. |
| `nb_voix_fige` | integer | oui |  | Nombre de voix à la date de publication. |

Contraintes de vérification :

- `inclusion_preoccupation_rang_check` : `CHECK ((rang >= 1))`

Unicité : (id_version, rang)

### calcul_consolidation

Exécution du moteur de consolidation nationale (F-71) avec ses paramètres et son rapport.

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_calcul` | uuid | oui | PK | Calcul de consolidation d'origine. |
| `id_edition` | uuid | oui | FK → edition | Édition de rattachement. |
| `lance_par` | uuid | oui | FK → utilisateur | Administrateur ayant lancé le calcul. |
| `lance_le` | timestamptz | oui |  | Date de lancement. |
| `termine_le` | timestamptz | non |  | Date de fin. |
| `statut` | text | oui |  | Statut (valeurs contrôlées). |
| `parametres` | jsonb | oui |  | Seuils et pondérations utilisés. |
| `rapport` | jsonb | non |  | Synthèse : nombre de convergences par classe et par secteur, cohésion. |

Contraintes de vérification :

- `calcul_consolidation_statut_check` : `CHECK ((statut = ANY (ARRAY['EN_COURS'::text, 'TERMINE'::text, 'ECHEC'::text])))`

### convergence

Groupe de préoccupations régionales similaires proposé par le moteur de consolidation et arbitré lors des états généraux (§10.4).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_convergence` | uuid | oui | PK | Convergence concernée. |
| `reference` | text | oui |  | Référence lisible (ex. N-2030-0007). |
| `id_edition` | uuid | oui | FK → edition | Édition de rattachement. |
| `id_secteur` | uuid | oui | FK → secteur | Secteur. |
| `id_calcul` | uuid | non | FK → calcul_consolidation | Calcul de consolidation d'origine. |
| `origine` | text | oui |  | CALCUL (moteur) ou MANUELLE (créée par scission ou par l'administrateur). |
| `intitule` | text | oui |  | Intitulé ; proposé par le moteur, réécrit librement par l'administrateur. |
| `synthese` | jsonb | non |  | Synthèse (texte enrichi). |
| `propositions` | jsonb | oui |  | Propositions consolidées (tableau JSON de textes). |
| `texte_assiste` | boolean | oui |  | Vrai si la synthèse provient de l'assistance par modèle de langage et n'a pas encore été relue (F-75). |
| `statut` | text | oui |  | PROPOSEE, RETENUE, FUSIONNEE ou REJETEE (RG-63). |
| `classe_calculee` | text | non |  | Classe proposée par le moteur selon le nombre d'UTR (§10.4). |
| `classe` | text | non |  | Classe retenue : NATIONALE, PARTAGEE ou SPECIFIQUE (RG-64). |
| `motif` | text | non |  | Motif de rejet, de fusion ou de reclassement. |
| `id_fusionnee_dans` | uuid | non | FK → convergence | Référence vers convergence. |
| `nb_utr` | integer | oui |  | Nombre d'UTR concernées. |
| `population_couverte` | bigint | oui |  | Population cumulée des UTR concernées. |
| `score` | numeric(5,2) | non |  | Score national de 0 à 100 (§10.4). |
| `score_detail` | jsonb | non |  | Décomposition du score national (T, P, S). |
| `cohesion` | numeric(4,3) | non |  | Similarité moyenne des membres à l'élément central ; une valeur faible signale un regroupement à vérifier. |
| `creee_le` | timestamptz | oui |  | Date de création. |
| `modifie_le` | timestamptz | oui |  | Date de dernière modification. |

Contraintes de vérification :

- `ck_convergence_classe` : `CHECK (((statut <> 'RETENUE'::text) OR (classe IS NOT NULL)))`
- `ck_convergence_fusion` : `CHECK (((statut = 'FUSIONNEE'::text) = (id_fusionnee_dans IS NOT NULL)))`
- `ck_convergence_reclassement` : `CHECK (((classe IS NULL) OR (classe_calculee IS NULL) OR (classe = classe_calculee) OR (motif IS NOT NULL)))`
- `ck_convergence_rejet` : `CHECK (((statut <> 'REJETEE'::text) OR (motif IS NOT NULL)))`
- `convergence_classe_calculee_check` : `CHECK ((classe_calculee = ANY (ARRAY['NATIONALE'::text, 'PARTAGEE'::text, 'SPECIFIQUE'::text])))`
- `convergence_classe_check` : `CHECK ((classe = ANY (ARRAY['NATIONALE'::text, 'PARTAGEE'::text, 'SPECIFIQUE'::text])))`
- `convergence_intitule_check` : `CHECK (((char_length(intitule) >= 5) AND (char_length(intitule) <= 200)))`
- `convergence_origine_check` : `CHECK ((origine = ANY (ARRAY['CALCUL'::text, 'MANUELLE'::text])))`
- `convergence_score_check` : `CHECK (((score IS NULL) OR ((score >= (0)::numeric) AND (score <= (100)::numeric))))`
- `convergence_statut_check` : `CHECK ((statut = ANY (ARRAY['PROPOSEE'::text, 'RETENUE'::text, 'FUSIONNEE'::text, 'REJETEE'::text])))`

Unicité : (reference)

### inclusion_convergence

Convergence figurant dans une version publiée du livre blanc national, avec ses valeurs figées.

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_version` | uuid | oui | PK, FK → version_livre_blanc | Version de livre blanc concernée. |
| `id_convergence` | uuid | oui | PK, FK → convergence | Convergence concernée. |
| `rang` | integer | oui |  | Rang dans sa classe. |
| `classe_figee` | text | oui |  | Classe au moment de la publication. |
| `intitule_fige` | text | oui |  | Intitulé à la date de publication. |
| `score_fige` | numeric(5,2) | oui |  | Score à la date de publication. |

Contraintes de vérification :

- `inclusion_convergence_classe_figee_check` : `CHECK ((classe_figee = ANY (ARRAY['NATIONALE'::text, 'PARTAGEE'::text, 'SPECIFIQUE'::text])))`
- `inclusion_convergence_rang_check` : `CHECK ((rang >= 1))`

Unicité : (id_version, rang, classe_figee)

### decision_etats_generaux

Décision prise lors des états généraux sur une convergence ; journal exporté en annexe du livre blanc national (F-74).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_decision` | uuid | oui | PK | Identifiant technique (UUID v7). |
| `id_convergence` | uuid | oui | FK → convergence | Convergence concernée. |
| `id_administrateur` | uuid | oui | FK → utilisateur | Administrateur auteur de la décision. |
| `action` | text | oui |  | RETENIR, FUSIONNER, SCINDER, REJETER, RECLASSER, MODIFIER_TEXTE ou REOUVRIR. |
| `motif` | text | non |  | Motif obligatoire pour les fusions, scissions, rejets et reclassements (RG-63, RG-64). |
| `details` | jsonb | non |  | Données de l'opération (convergences sources et cibles, ancienne et nouvelle classe…). |
| `decidee_le` | timestamptz | oui |  | Date de la décision. |

Contraintes de vérification :

- `ck_decision_eg_motif` : `CHECK (((action <> ALL (ARRAY['FUSIONNER'::text, 'SCINDER'::text, 'REJETER'::text, 'RECLASSER'::text])) OR (motif IS NOT NULL)))`
- `decision_etats_generaux_action_check` : `CHECK ((action = ANY (ARRAY['RETENIR'::text, 'FUSIONNER'::text, 'SCINDER'::text, 'REJETER'::text, 'RECLASSER'::text, 'MODIFIER_TEXTE'::text, 'REOUVRIR'::text])))`

## Engagements et suivi

### candidat

Candidat déclaré à une élection d'une édition, géré par l'administrateur national (F-90, RG-70).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_candidat` | uuid | oui | PK | Candidat auteur de l'engagement. |
| `id_utilisateur` | uuid | oui | FK → utilisateur | Compte utilisé par le candidat ou son équipe. |
| `id_edition` | uuid | oui | FK → edition | Édition de rattachement. |
| `type_election` | text | oui |  | PRESIDENTIELLE ou REGIONALE dans le MVP. |
| `id_utr` | uuid | non | FK → territoire | UTR de candidature (régionales). |
| `nom_affiche` | text | oui |  | Nom affiché publiquement. |
| `parti` | text | non |  | Parti ou groupement ; nul pour un candidat indépendant. |
| `id_fichier_photo` | uuid | non | FK → fichier | Photo officielle (facultative). |
| `statut` | text | oui |  | CANDIDAT, ELU ou NON_ELU. |
| `cree_le` | timestamptz | oui |  | Date de création. |
| `cree_par` | uuid | oui | FK → utilisateur | Auteur de la création. |

Contraintes de vérification :

- `candidat_nom_affiche_check` : `CHECK (((char_length(nom_affiche) >= 3) AND (char_length(nom_affiche) <= 150)))`
- `candidat_statut_check` : `CHECK ((statut = ANY (ARRAY['CANDIDAT'::text, 'ELU'::text, 'NON_ELU'::text])))`
- `candidat_type_election_check` : `CHECK ((type_election = ANY (ARRAY['PRESIDENTIELLE'::text, 'REGIONALE'::text])))`
- `ck_candidat_utr` : `CHECK (((type_election = 'REGIONALE'::text) = (id_utr IS NOT NULL)))`

Unicité : (id_utilisateur, id_edition)

### engagement

Engagement public d'un candidat sur une priorité du LBN (présidentielle) ou une préoccupation d'un LBR (régionales) (RG-71, RG-72).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_engagement` | uuid | oui | PK | Engagement suivi. |
| `id_candidat` | uuid | oui | FK → candidat | Candidat auteur de l'engagement. |
| `id_convergence` | uuid | non | FK → convergence | Priorité nationale visée (présidentielle). |
| `id_preoccupation` | uuid | non | FK → preoccupation | Préoccupation régionale visée (régionales). |
| `echeance_annee` | smallint | oui |  | Année d'échéance annoncée. |
| `texte` | text | oui |  | Texte de l'engagement, de 20 à 1 000 caractères. |
| `statut` | text | oui |  | DECLARE ou RETIRE (retrait possible jusqu'à l'élection, RG-73). |
| `declare_le` | timestamptz | oui |  | Date et heure : declare. |
| `retire_le` | timestamptz | non |  | Date et heure : retire. |

Contraintes de vérification :

- `ck_engagement_cible` : `CHECK ((num_nonnulls(id_convergence, id_preoccupation) = 1))`
- `ck_engagement_retrait` : `CHECK (((statut = 'RETIRE'::text) = (retire_le IS NOT NULL)))`
- `engagement_echeance_annee_check` : `CHECK (((echeance_annee >= 2020) AND (echeance_annee <= 2100)))`
- `engagement_statut_check` : `CHECK ((statut = ANY (ARRAY['DECLARE'::text, 'RETIRE'::text])))`
- `engagement_texte_check` : `CHECK (((char_length(texte) >= 20) AND (char_length(texte) <= 1000)))`

### suivi_realisation

Mise à jour de l'état d'avancement d'un engagement d'un élu, historisée (RG-74).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_suivi` | uuid | oui | PK | Mise à jour de suivi. |
| `id_engagement` | uuid | oui | FK → engagement | Engagement suivi. |
| `etat` | text | oui |  | NON_DEMARRE, EN_COURS, REALISE, PARTIELLEMENT_REALISE ou ABANDONNE. |
| `date_etat` | date | oui |  | Date à laquelle l'état est constaté. |
| `description` | text | oui |  | Description de l'avancement. |
| `saisi_par` | uuid | oui | FK → utilisateur | Administrateur national ayant saisi la mise à jour. |
| `saisi_le` | timestamptz | oui |  | Date et heure : saisi. |
| `commentaire_candidat` | text | non |  | Réponse publique du candidat (droit de réponse). |
| `commentaire_le` | timestamptz | non |  | Date et heure : commentaire. |

Contraintes de vérification :

- `ck_suivi_commentaire` : `CHECK (((commentaire_candidat IS NULL) = (commentaire_le IS NULL)))`
- `suivi_realisation_commentaire_candidat_check` : `CHECK ((char_length(commentaire_candidat) <= 1000))`
- `suivi_realisation_description_check` : `CHECK (((char_length(description) >= 10) AND (char_length(description) <= 2000)))`
- `suivi_realisation_etat_check` : `CHECK ((etat = ANY (ARRAY['NON_DEMARRE'::text, 'EN_COURS'::text, 'REALISE'::text, 'PARTIELLEMENT_REALISE'::text, 'ABANDONNE'::text])))`

### justificatif

Preuve associée à une mise à jour de suivi : lien ou fichier (RG-74).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_justificatif` | uuid | oui | PK | Identifiant technique (UUID v7). |
| `id_suivi` | uuid | oui | FK → suivi_realisation | Mise à jour de suivi. |
| `type` | text | oui |  | Type (valeurs contrôlées, voir contraintes). |
| `url` | text | non |  | Adresse web (http ou https). |
| `id_fichier` | uuid | non | FK → fichier | Fichier joint. |
| `libelle` | text | oui |  | Description courte de la preuve. |

Contraintes de vérification :

- `ck_justificatif_type` : `CHECK ((((type = 'LIEN'::text) AND (url IS NOT NULL) AND (id_fichier IS NULL)) OR ((type = 'FICHIER'::text) AND (id_fichier IS NOT NULL) AND (url IS NULL))))`
- `justificatif_type_check` : `CHECK ((type = ANY (ARRAY['LIEN'::text, 'FICHIER'::text])))`
- `justificatif_url_check` : `CHECK ((url ~ '^https?://'::text))`

## Tables techniques

### compteur_reference

Table technique : compteurs servant à générer les références lisibles (ex. C-2030-GOH-000123).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `prefixe` | text | oui | PK | Préfixe de la série de références. |
| `valeur` | integer | oui |  | Dernière valeur attribuée. |

### jeton

Table technique : jeton à usage unique (vérification d'e-mail 24 h, réinitialisation 1 h, invitation 7 j). Seule son empreinte SHA-256 est stockée.

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_jeton` | uuid | oui | PK | Identifiant technique (UUID v7). |
| `id_utilisateur` | uuid | oui | FK → utilisateur | Utilisateur concerné. |
| `type` | text | oui |  | Type (valeurs contrôlées, voir contraintes). |
| `jeton_hash` | bytea | oui |  | Empreinte du jeton. |
| `cree_le` | timestamptz | oui |  | Date de création. |
| `expire_le` | timestamptz | oui |  | Date et heure : expire. |
| `utilise_le` | timestamptz | non |  | Date d'utilisation (usage unique). |

Contraintes de vérification :

- `jeton_type_check` : `CHECK ((type = ANY (ARRAY['VERIFICATION_EMAIL'::text, 'REINITIALISATION_MDP'::text, 'INVITATION'::text])))`

Unicité : (jeton_hash)

### journal_audit

Journal non modifiable des actions d'administration et des transitions de statut (RG-45, F-130).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_entree` | bigint | oui | PK | Identifiant technique. |
| `survenue_le` | timestamptz | oui |  | Date de l'action. |
| `id_acteur` | uuid | non | FK → utilisateur | Utilisateur à l'origine de l'action (nul pour le système). |
| `action` | text | oui |  | Code de l'action (ex. CONTRIBUTION.RETIRER). |
| `type_objet` | text | oui |  | Type d'objet concerné. |
| `id_objet` | uuid | non |  | Identifiant de l'objet concerné. |
| `avant` | jsonb | non |  | État de l'objet avant l'action. |
| `apres` | jsonb | non |  | État de l'objet après l'action. |
| `motif` | text | non |  | Motif saisi. |
| `adresse_ip` | inet | non |  | Adresse IP d'origine. |
| `id_requete` | text | non |  | Identifiant de la requête HTTP (corrélation des journaux). |

### session

Table technique : session de connexion, référencée par un cookie scellé ; permet la révocation.

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_session` | uuid | oui | PK | Identifiant technique (UUID v7). |
| `id_utilisateur` | uuid | oui | FK → utilisateur | Utilisateur concerné. |
| `cree_le` | timestamptz | oui |  | Date de création. |
| `derniere_activite_le` | timestamptz | oui |  | Dernière requête authentifiée (expiration glissante). |
| `expire_le` | timestamptz | oui |  | Expiration absolue de la session. |
| `revoquee_le` | timestamptz | non |  | Date de révocation (déconnexion, changement de mot de passe, suspension). |
| `adresse_ip` | inet | non |  | Adresse IP d'origine. |
| `agent_utilisateur` | text | non |  | Navigateur ayant ouvert la session. |

### terme_interdit

Liste de termes déclenchant la mise en modération automatique (F-24).

| Colonne | Type | Oblig. | Clé | Description |
|---|---|---|---|---|
| `id_terme` | uuid | oui | PK | Identifiant technique (UUID v7). |
| `terme` | text | oui |  | Terme recherché dans les contributions. |
| `actif` | boolean | oui |  | Vrai si actif. |

Unicité : (terme)
