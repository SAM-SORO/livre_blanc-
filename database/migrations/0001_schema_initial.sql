-- =============================================================================
-- Livre Blanc Citoyen — Modèle physique des données (MPD)
-- Migration 0001 : schéma initial
-- Cible : PostgreSQL 18 (compatible et testé sur PostgreSQL 16)
-- Conventions : noms en français, snake_case, sans accents ; clés primaires UUID v7 ;
--               énumérations en texte contraint (CHECK) ; horodatages en timestamptz.
-- Les commentaires (COMMENT ON) alimentent le dictionnaire de données.
-- =============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;

-- -----------------------------------------------------------------------------
-- Fonctions utilitaires
-- -----------------------------------------------------------------------------
-- UUID version 7 (ordonné dans le temps). Sous PostgreSQL 18, équivalent à uuidv7().
CREATE OR REPLACE FUNCTION gen_uuid_v7() RETURNS uuid
LANGUAGE sql VOLATILE AS $$
  SELECT encode(
    set_bit(set_bit(
      overlay(uuid_send(gen_random_uuid())
              PLACING substring(int8send(floor(extract(epoch FROM clock_timestamp()) * 1000)::bigint) FROM 3)
              FROM 1 FOR 6),
    52, 1), 53, 1), 'hex')::uuid;
$$;

-- unaccent() n'est pas IMMUTABLE ; ce wrapper permet son usage dans des colonnes générées et des index.
CREATE OR REPLACE FUNCTION immutable_unaccent(texte text) RETURNS text
LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT AS $$
  SELECT public.unaccent('public.unaccent'::regdictionary, texte);
$$;

CREATE OR REPLACE FUNCTION normaliser_texte(texte text) RETURNS text
LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT AS $$
  SELECT regexp_replace(lower(immutable_unaccent(texte)), '[^a-z0-9 ]+', ' ', 'g');
$$;

-- Racines lexicales françaises (mots vides retirés, radicalisation Snowball) d'un texte.
CREATE OR REPLACE FUNCTION lexemes_texte(texte text) RETURNS text[]
LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT AS $$
  SELECT tsvector_to_array(to_tsvector('french', immutable_unaccent(texte)));
$$;

-- Coefficient de chevauchement |A ∩ B| / min(|A|, |B|).
CREATE OR REPLACE FUNCTION chevauchement(a text[], b text[]) RETURNS real
LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $$
  SELECT CASE WHEN COALESCE(cardinality(a), 0) = 0 OR COALESCE(cardinality(b), 0) = 0 THEN 0::real
         ELSE (SELECT count(*) FROM (SELECT unnest(a) INTERSECT SELECT unnest(b)) i)::real
              / LEAST(cardinality(a), cardinality(b)) END;
$$;

-- Similarité composite utilisée par le moteur (§10.1 du PRD, calibrée en phase 3) :
-- 0,5 × chevauchement des racines + 0,5 × similarité trigrammes des textes normalisés.
CREATE OR REPLACE FUNCTION similarite_textes(texte_a text, lex_a text[], texte_b text, lex_b text[]) RETURNS real
LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $$
  SELECT (0.5 * chevauchement(lex_a, lex_b) + 0.5 * similarity(texte_a, texte_b))::real;
$$;

CREATE OR REPLACE FUNCTION maj_modifie_le() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.modifie_le := now();
  RETURN NEW;
END $$;

-- =============================================================================
-- 1. RÉFÉRENTIELS
-- =============================================================================
CREATE TABLE territoire (
  id_territoire        uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  code                 text NOT NULL UNIQUE,
  code_pcode           text UNIQUE,
  libelle              text NOT NULL,
  niveau               text NOT NULL CHECK (niveau IN ('DISTRICT','DISTRICT_AUTONOME','REGION','DEPARTEMENT','SOUS_PREFECTURE','COMMUNE')),
  id_parent            uuid REFERENCES territoire(id_territoire),
  est_utr              boolean NOT NULL DEFAULT false,
  id_utr               uuid REFERENCES territoire(id_territoire),
  id_departement       uuid REFERENCES territoire(id_territoire),
  est_selectionnable   boolean NOT NULL DEFAULT false,
  population           integer CHECK (population > 0),
  annee_population     smallint CHECK (annee_population BETWEEN 1975 AND 2100),
  date_debut_validite  date NOT NULL DEFAULT current_date,
  date_fin_validite    date,
  CONSTRAINT ck_territoire_utr CHECK (est_utr = (niveau IN ('REGION','DISTRICT_AUTONOME'))),
  CONSTRAINT ck_territoire_racine CHECK ((niveau IN ('DISTRICT','DISTRICT_AUTONOME')) = (id_parent IS NULL)),
  CONSTRAINT ck_territoire_validite CHECK (date_fin_validite IS NULL OR date_fin_validite >= date_debut_validite),
  CONSTRAINT ck_territoire_utr_soi CHECK (NOT est_utr OR id_utr = id_territoire)
);
CREATE INDEX ix_territoire_parent ON territoire(id_parent);
CREATE INDEX ix_territoire_utr ON territoire(id_utr);
COMMENT ON TABLE territoire IS 'Unité du découpage administratif ivoirien (district, région, département, sous-préfecture, commune). Référentiel importable et daté (D-07).';
COMMENT ON COLUMN territoire.id_territoire IS 'Identifiant technique (UUID v7).';
COMMENT ON COLUMN territoire.code IS 'Code métier stable du territoire (ex. REG-GOH).';
COMMENT ON COLUMN territoire.code_pcode IS 'Code P-code du jeu COD-AB (OCHA/CNTIG), utilisé pour la cartographie.';
COMMENT ON COLUMN territoire.libelle IS 'Nom officiel du territoire.';
COMMENT ON COLUMN territoire.niveau IS 'Niveau administratif : DISTRICT, DISTRICT_AUTONOME, REGION, DEPARTEMENT, SOUS_PREFECTURE, COMMUNE.';
COMMENT ON COLUMN territoire.id_parent IS 'Territoire de rattachement de niveau supérieur (RG-04).';
COMMENT ON COLUMN territoire.est_utr IS 'Vrai si le territoire est une unité territoriale de rédaction : région ou district autonome (RG-05, D-06).';
COMMENT ON COLUMN territoire.id_utr IS 'UTR à laquelle appartient le territoire (dénormalisé à l''import pour les agrégations).';
COMMENT ON COLUMN territoire.id_departement IS 'Département d''appartenance (dénormalisé), utilisé pour la composante « étendue » du score.';
COMMENT ON COLUMN territoire.est_selectionnable IS 'Vrai si le territoire constitue la maille la plus fine disponible et peut être choisi dans une contribution (RG-21).';
COMMENT ON COLUMN territoire.population IS 'Population de référence (obligatoire pour les UTR avant les états généraux, RG-05).';
COMMENT ON COLUMN territoire.annee_population IS 'Année de la donnée de population.';
COMMENT ON COLUMN territoire.date_debut_validite IS 'Date d''entrée en vigueur de l''unité dans le découpage.';
COMMENT ON COLUMN territoire.date_fin_validite IS 'Date de fin de validité (découpage modifié).';

CREATE TABLE secteur (
  id_secteur   uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  code         text NOT NULL UNIQUE,
  libelle      text NOT NULL UNIQUE,
  description  text,
  icone        text,
  odd          smallint[] NOT NULL DEFAULT '{}',
  mots_cles    text[] NOT NULL DEFAULT '{}',
  ordre        smallint NOT NULL DEFAULT 0,
  actif        boolean NOT NULL DEFAULT true,
  CONSTRAINT ck_secteur_odd CHECK (odd <@ ARRAY[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17]::smallint[])
);
COMMENT ON TABLE secteur IS 'Domaine de développement auquel se rattache une contribution (référentiel administrable, RG-06).';
COMMENT ON COLUMN secteur.code IS 'Code court du secteur (ex. SANTE).';
COMMENT ON COLUMN secteur.libelle IS 'Libellé affiché.';
COMMENT ON COLUMN secteur.description IS 'Description du périmètre du secteur.';
COMMENT ON COLUMN secteur.icone IS 'Nom de l''icône du système de design.';
COMMENT ON COLUMN secteur.odd IS 'Objectifs de développement durable de rattachement indicatif.';
COMMENT ON COLUMN secteur.mots_cles IS 'Mots-clés d''aide au classement automatique (F-31).';
COMMENT ON COLUMN secteur.ordre IS 'Ordre d''affichage.';
COMMENT ON COLUMN secteur.actif IS 'Faux si le secteur est désactivé (il reste lié aux données existantes).';

-- =============================================================================
-- 2. COMPTES ET ORGANISATIONS
-- =============================================================================
CREATE TABLE utilisateur (
  id_utilisateur          uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  nom                     text,
  prenoms                 text,
  email                   text,
  email_verifie_le        timestamptz,
  mot_de_passe_hash       text,
  telephone               text,
  sexe                    char(1) CHECK (sexe IN ('F','M')),
  annee_naissance         smallint CHECK (annee_naissance BETWEEN 1900 AND 2100),
  id_territoire_residence uuid REFERENCES territoire(id_territoire),
  afficher_nom            boolean NOT NULL DEFAULT false,
  statut                  text NOT NULL DEFAULT 'ACTIF' CHECK (statut IN ('ACTIF','SUSPENDU','SUPPRIME')),
  tentatives_echouees     smallint NOT NULL DEFAULT 0 CHECK (tentatives_echouees >= 0),
  verrouille_jusqua       timestamptz,
  consentement_le         timestamptz,
  inscrit_le              timestamptz NOT NULL DEFAULT now(),
  derniere_connexion_le   timestamptz,
  anonymise_le            timestamptz,
  modifie_le              timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_utilisateur_actif_complet CHECK (
    statut = 'SUPPRIME' OR (nom IS NOT NULL AND prenoms IS NOT NULL AND email IS NOT NULL
                            AND mot_de_passe_hash IS NOT NULL AND consentement_le IS NOT NULL)),
  CONSTRAINT ck_utilisateur_age CHECK (annee_naissance IS NULL OR annee_naissance <= extract(year FROM inscrit_le)::int - 18),
  CONSTRAINT ck_utilisateur_supprime_anonyme CHECK (statut <> 'SUPPRIME' OR (email IS NULL AND nom IS NULL AND anonymise_le IS NOT NULL))
);
CREATE UNIQUE INDEX ux_utilisateur_email ON utilisateur (lower(email)) WHERE email IS NOT NULL;
CREATE TRIGGER trg_utilisateur_modifie BEFORE UPDATE ON utilisateur FOR EACH ROW EXECUTE FUNCTION maj_modifie_le();
COMMENT ON TABLE utilisateur IS 'Personne physique disposant d''un compte (contributeur, administrateur ou candidat).';
COMMENT ON COLUMN utilisateur.nom IS 'Nom de famille (effacé à l''anonymisation).';
COMMENT ON COLUMN utilisateur.prenoms IS 'Prénoms (effacés à l''anonymisation).';
COMMENT ON COLUMN utilisateur.email IS 'Adresse e-mail de connexion, unique sans tenir compte de la casse.';
COMMENT ON COLUMN utilisateur.email_verifie_le IS 'Date de vérification de l''adresse e-mail ; nulle tant que le compte n''est pas vérifié (RG-11).';
COMMENT ON COLUMN utilisateur.mot_de_passe_hash IS 'Empreinte du mot de passe (scrypt), jamais le mot de passe en clair.';
COMMENT ON COLUMN utilisateur.telephone IS 'Téléphone (facultatif).';
COMMENT ON COLUMN utilisateur.sexe IS 'Sexe déclaré (facultatif) : F ou M ; sert aux indicateurs de représentativité.';
COMMENT ON COLUMN utilisateur.annee_naissance IS 'Année de naissance ; l''inscription exige 18 ans atteints dans l''année (RG-12).';
COMMENT ON COLUMN utilisateur.id_territoire_residence IS 'Sous-préfecture ou commune de résidence.';
COMMENT ON COLUMN utilisateur.afficher_nom IS 'Vrai si l''utilisateur accepte que son nom apparaisse publiquement (RG-29).';
COMMENT ON COLUMN utilisateur.statut IS 'ACTIF, SUSPENDU ou SUPPRIME (compte anonymisé, RG-16).';
COMMENT ON COLUMN utilisateur.tentatives_echouees IS 'Nombre d''échecs de connexion consécutifs (RG-17).';
COMMENT ON COLUMN utilisateur.verrouille_jusqua IS 'Fin du verrouillage temporaire après 5 échecs (RG-17).';
COMMENT ON COLUMN utilisateur.consentement_le IS 'Date d''acceptation de la charte et du traitement des données.';
COMMENT ON COLUMN utilisateur.inscrit_le IS 'Date d''inscription.';
COMMENT ON COLUMN utilisateur.derniere_connexion_le IS 'Date de dernière connexion réussie.';
COMMENT ON COLUMN utilisateur.anonymise_le IS 'Date d''anonymisation du compte.';
COMMENT ON COLUMN utilisateur.modifie_le IS 'Date de dernière modification.';

CREATE TABLE affectation (
  id_affectation  uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  id_utilisateur  uuid NOT NULL REFERENCES utilisateur(id_utilisateur),
  role            text NOT NULL CHECK (role IN ('ADMIN_REGIONAL','ADMIN_NATIONAL')),
  id_utr          uuid REFERENCES territoire(id_territoire),
  date_debut      date NOT NULL DEFAULT current_date,
  date_fin        date,
  attribuee_par   uuid REFERENCES utilisateur(id_utilisateur),
  attribuee_le    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_affectation_perimetre CHECK ((role = 'ADMIN_REGIONAL') = (id_utr IS NOT NULL)),
  CONSTRAINT ck_affectation_dates CHECK (date_fin IS NULL OR date_fin >= date_debut)
);
CREATE INDEX ix_affectation_utilisateur ON affectation(id_utilisateur);
COMMENT ON TABLE affectation IS 'Attribution d''un rôle d''administration à un utilisateur, avec son périmètre territorial (D-04).';
COMMENT ON COLUMN affectation.role IS 'ADMIN_REGIONAL (périmètre : une UTR) ou ADMIN_NATIONAL (périmètre : national).';
COMMENT ON COLUMN affectation.id_utr IS 'UTR administrée (obligatoire pour ADMIN_REGIONAL, nulle sinon).';
COMMENT ON COLUMN affectation.date_debut IS 'Début de l''affectation.';
COMMENT ON COLUMN affectation.date_fin IS 'Fin de l''affectation (nulle si en cours).';
COMMENT ON COLUMN affectation.attribuee_par IS 'Administrateur national ayant attribué le rôle (RG-13).';
COMMENT ON COLUMN affectation.attribuee_le IS 'Date d''attribution.';

CREATE TABLE session (
  id_session             uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  id_utilisateur         uuid NOT NULL REFERENCES utilisateur(id_utilisateur),
  cree_le                timestamptz NOT NULL DEFAULT now(),
  derniere_activite_le   timestamptz NOT NULL DEFAULT now(),
  expire_le              timestamptz NOT NULL,
  revoquee_le            timestamptz,
  adresse_ip             inet,
  agent_utilisateur      text
);
CREATE INDEX ix_session_utilisateur ON session(id_utilisateur) WHERE revoquee_le IS NULL;
COMMENT ON TABLE session IS 'Table technique : session de connexion, référencée par un cookie scellé ; permet la révocation.';
COMMENT ON COLUMN session.expire_le IS 'Expiration absolue de la session.';
COMMENT ON COLUMN session.revoquee_le IS 'Date de révocation (déconnexion, changement de mot de passe, suspension).';

CREATE TABLE jeton (
  id_jeton        uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  id_utilisateur  uuid NOT NULL REFERENCES utilisateur(id_utilisateur),
  type            text NOT NULL CHECK (type IN ('VERIFICATION_EMAIL','REINITIALISATION_MDP','INVITATION')),
  jeton_hash      bytea NOT NULL UNIQUE,
  cree_le         timestamptz NOT NULL DEFAULT now(),
  expire_le       timestamptz NOT NULL,
  utilise_le      timestamptz
);
COMMENT ON TABLE jeton IS 'Table technique : jeton à usage unique (vérification d''e-mail 24 h, réinitialisation 1 h, invitation 7 j). Seule son empreinte SHA-256 est stockée.';

CREATE TABLE fichier (
  id_fichier        uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  chemin_stockage   text NOT NULL UNIQUE,
  nom_original      text NOT NULL,
  type_mime         text NOT NULL CHECK (type_mime IN ('image/jpeg','image/png','image/webp','application/pdf','text/csv',
                     'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                     'application/vnd.openxmlformats-officedocument.wordprocessingml.document')),
  taille_octets     integer NOT NULL CHECK (taille_octets > 0 AND taille_octets <= 52428800),
  empreinte_sha256  char(64) NOT NULL,
  largeur           integer CHECK (largeur > 0),
  hauteur           integer CHECK (hauteur > 0),
  depose_par        uuid REFERENCES utilisateur(id_utilisateur),
  depose_le         timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE fichier IS 'Fichier stocké hors de la racine web : photo, procès-verbal, justificatif, import, export généré.';
COMMENT ON COLUMN fichier.chemin_stockage IS 'Clé de stockage relative au volume de fichiers.';
COMMENT ON COLUMN fichier.nom_original IS 'Nom du fichier tel que téléversé.';
COMMENT ON COLUMN fichier.type_mime IS 'Type réel détecté à partir du contenu (NF-14).';
COMMENT ON COLUMN fichier.taille_octets IS 'Taille en octets (photos limitées à 5 Mo par l''application).';
COMMENT ON COLUMN fichier.empreinte_sha256 IS 'Empreinte SHA-256 du contenu (intégrité).';
COMMENT ON COLUMN fichier.largeur IS 'Largeur en pixels (images).';
COMMENT ON COLUMN fichier.hauteur IS 'Hauteur en pixels (images).';
COMMENT ON COLUMN fichier.depose_par IS 'Utilisateur ayant déposé le fichier (nul pour un fichier généré par le système).';

CREATE TABLE organisation (
  id_organisation         uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  denomination            text NOT NULL CHECK (char_length(denomination) BETWEEN 3 AND 200),
  type                    text NOT NULL CHECK (type IN ('ASSOCIATION','ONG','COLLECTIVITE','ORGANISATION_PROFESSIONNELLE','COOPERATIVE','AUTRE')),
  numero_enregistrement   text,
  description             text CHECK (char_length(description) <= 2000),
  id_territoire_siege     uuid NOT NULL REFERENCES territoire(id_territoire),
  id_representant         uuid NOT NULL UNIQUE REFERENCES utilisateur(id_utilisateur),
  statut_verification     text NOT NULL DEFAULT 'NON_VERIFIEE' CHECK (statut_verification IN ('NON_VERIFIEE','VERIFIEE','REJETEE')),
  verifiee_le             timestamptz,
  id_verificateur         uuid REFERENCES utilisateur(id_utilisateur),
  motif_rejet             text,
  creee_le                timestamptz NOT NULL DEFAULT now(),
  modifie_le              timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_organisation_verification CHECK (
    (statut_verification = 'NON_VERIFIEE') = (verifiee_le IS NULL AND id_verificateur IS NULL)),
  CONSTRAINT ck_organisation_rejet CHECK ((statut_verification = 'REJETEE') = (motif_rejet IS NOT NULL))
);
CREATE TRIGGER trg_organisation_modifie BEFORE UPDATE ON organisation FOR EACH ROW EXECUTE FUNCTION maj_modifie_le();
COMMENT ON TABLE organisation IS 'Personne morale (association, ONG, collectivité, organisation professionnelle, coopérative…) représentée par un contributeur.';
COMMENT ON COLUMN organisation.denomination IS 'Nom de l''organisation.';
COMMENT ON COLUMN organisation.type IS 'ASSOCIATION, ONG, COLLECTIVITE, ORGANISATION_PROFESSIONNELLE, COOPERATIVE ou AUTRE.';
COMMENT ON COLUMN organisation.numero_enregistrement IS 'Numéro de récépissé ou d''enregistrement (facultatif).';
COMMENT ON COLUMN organisation.description IS 'Présentation de l''organisation.';
COMMENT ON COLUMN organisation.id_territoire_siege IS 'Territoire du siège ; détermine l''administrateur régional compétent pour la vérification (RG-15).';
COMMENT ON COLUMN organisation.id_representant IS 'Contributeur représentant ; un contributeur représente au plus une organisation (RG-14).';
COMMENT ON COLUMN organisation.statut_verification IS 'NON_VERIFIEE, VERIFIEE ou REJETEE (RG-15).';
COMMENT ON COLUMN organisation.verifiee_le IS 'Date de la décision de vérification.';
COMMENT ON COLUMN organisation.id_verificateur IS 'Administrateur ayant statué.';
COMMENT ON COLUMN organisation.motif_rejet IS 'Motif obligatoire en cas de rejet.';

-- =============================================================================
-- 3. ÉDITIONS
-- =============================================================================
CREATE TABLE edition (
  id_edition               uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  libelle                  text NOT NULL UNIQUE,
  annee_echeance           smallint NOT NULL CHECK (annee_echeance BETWEEN 2020 AND 2100),
  phase                    text NOT NULL DEFAULT 'PREPARATION' CHECK (phase IN
                            ('PREPARATION','COLLECTE','CONSOLIDATION_REGIONALE','ETATS_GENERAUX','ENGAGEMENTS','SUIVI','CLOTUREE')),
  date_ouverture_collecte  timestamptz,
  date_cloture_collecte    timestamptz,
  date_election            date,
  parametres               jsonb NOT NULL,
  creee_le                 timestamptz NOT NULL DEFAULT now(),
  creee_par                uuid REFERENCES utilisateur(id_utilisateur),
  modifie_le               timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_edition_dates CHECK (date_cloture_collecte IS NULL OR date_ouverture_collecte IS NULL
                                     OR date_cloture_collecte > date_ouverture_collecte),
  CONSTRAINT ck_edition_parametres CHECK (parametres ? 'seuils' AND parametres ? 'ponderations_regionales'
                                          AND parametres ? 'ponderations_nationales')
);
-- RG-01 : une seule édition active
CREATE UNIQUE INDEX ux_edition_active ON edition ((true)) WHERE phase NOT IN ('PREPARATION','CLOTUREE');
COMMENT ON TABLE edition IS 'Cycle complet d''élaboration d''un livre blanc, rattaché à une échéance électorale.';
COMMENT ON COLUMN edition.libelle IS 'Nom de l''édition (ex. Édition 2030).';
COMMENT ON COLUMN edition.annee_echeance IS 'Année de l''échéance électorale visée.';
COMMENT ON COLUMN edition.phase IS 'Phase courante (§8.1 du PRD) ; transitions contrôlées (RG-03).';
COMMENT ON COLUMN edition.date_ouverture_collecte IS 'Ouverture prévue ou effective de la collecte.';
COMMENT ON COLUMN edition.date_cloture_collecte IS 'Clôture prévue ou effective de la collecte.';
COMMENT ON COLUMN edition.date_election IS 'Date de l''élection ; au-delà, les engagements sont définitifs (RG-73).';
COMMENT ON COLUMN edition.parametres IS 'Seuils de similarité, pondérations, limites ; figés hors phase PREPARATION (RG-02).';

CREATE OR REPLACE FUNCTION edition_controler_transition() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  ordre text[] := ARRAY['PREPARATION','COLLECTE','CONSOLIDATION_REGIONALE','ETATS_GENERAUX','ENGAGEMENTS','SUIVI','CLOTUREE'];
  i_old int; i_new int;
BEGIN
  IF NEW.parametres IS DISTINCT FROM OLD.parametres AND OLD.phase <> 'PREPARATION' THEN
    RAISE EXCEPTION 'RG-02 : les paramètres d''une édition ne sont modifiables qu''en phase PREPARATION' USING ERRCODE = 'P0001';
  END IF;
  IF NEW.phase IS DISTINCT FROM OLD.phase THEN
    i_old := array_position(ordre, OLD.phase);
    i_new := array_position(ordre, NEW.phase);
    IF i_new = i_old + 1 THEN
      RETURN NEW;
    ELSIF OLD.phase = 'CONSOLIDATION_REGIONALE' AND NEW.phase = 'COLLECTE' THEN
      IF EXISTS (SELECT 1 FROM version_livre_blanc v JOIN livre_blanc l USING (id_livre_blanc)
                 WHERE l.id_edition = NEW.id_edition AND v.statut IN ('PUBLIEE','REMPLACEE')) THEN
        RAISE EXCEPTION 'RG-03 : réouverture de la collecte impossible, un livre blanc régional est déjà publié' USING ERRCODE = 'P0001';
      END IF;
      RETURN NEW;
    ELSE
      RAISE EXCEPTION 'RG-03 : transition de phase interdite (% vers %)', OLD.phase, NEW.phase USING ERRCODE = 'P0001';
    END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER trg_edition_transition BEFORE UPDATE ON edition FOR EACH ROW EXECUTE FUNCTION edition_controler_transition();
CREATE TRIGGER trg_edition_modifie BEFORE UPDATE ON edition FOR EACH ROW EXECUTE FUNCTION maj_modifie_le();

CREATE TABLE compteur_reference (
  prefixe  text PRIMARY KEY,
  valeur   integer NOT NULL DEFAULT 0
);
COMMENT ON TABLE compteur_reference IS 'Table technique : compteurs servant à générer les références lisibles (ex. C-2030-GOH-000123).';

CREATE OR REPLACE FUNCTION prochaine_reference(p_prefixe text, p_largeur int DEFAULT 6) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v int;
BEGIN
  INSERT INTO compteur_reference(prefixe, valeur) VALUES (p_prefixe, 1)
  ON CONFLICT (prefixe) DO UPDATE SET valeur = compteur_reference.valeur + 1
  RETURNING valeur INTO v;
  RETURN p_prefixe || '-' || lpad(v::text, p_largeur, '0');
END $$;

-- =============================================================================
-- 4. COLLECTE ET ANALYSE RÉGIONALE
-- =============================================================================
CREATE TABLE consultation_terrain (
  id_consultation      uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  id_edition           uuid NOT NULL REFERENCES edition(id_edition),
  id_utr               uuid NOT NULL REFERENCES territoire(id_territoire),
  id_territoire_lieu   uuid NOT NULL REFERENCES territoire(id_territoire),
  intitule             text NOT NULL,
  date_consultation    date NOT NULL,
  nb_participants      integer NOT NULL CHECK (nb_participants > 0),
  description          text,
  id_fichier_source    uuid REFERENCES fichier(id_fichier),
  importee_par         uuid NOT NULL REFERENCES utilisateur(id_utilisateur),
  importee_le          timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE consultation_terrain IS 'Atelier ou réunion de terrain dont les contributions ont été importées par un administrateur régional (F-35, RG-28).';
COMMENT ON COLUMN consultation_terrain.id_utr IS 'UTR concernée.';
COMMENT ON COLUMN consultation_terrain.id_territoire_lieu IS 'Lieu de la consultation.';
COMMENT ON COLUMN consultation_terrain.intitule IS 'Intitulé de la consultation.';
COMMENT ON COLUMN consultation_terrain.date_consultation IS 'Date de tenue.';
COMMENT ON COLUMN consultation_terrain.nb_participants IS 'Nombre de participants déclaré ; détermine le poids en voix (D-10).';
COMMENT ON COLUMN consultation_terrain.id_fichier_source IS 'Fichier CSV/XLSX importé.';
COMMENT ON COLUMN consultation_terrain.importee_par IS 'Administrateur ayant importé.';

CREATE TABLE preoccupation (
  id_preoccupation                uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  reference                       text NOT NULL UNIQUE,
  id_edition                      uuid NOT NULL REFERENCES edition(id_edition),
  id_utr                          uuid NOT NULL REFERENCES territoire(id_territoire),
  id_secteur                      uuid NOT NULL REFERENCES secteur(id_secteur),
  intitule                        text NOT NULL CHECK (char_length(intitule) BETWEEN 5 AND 200),
  synthese                        jsonb,
  propositions_retenues           jsonb NOT NULL DEFAULT '[]'::jsonb,
  statut                          text NOT NULL DEFAULT 'PROPOSEE' CHECK (statut IN ('PROPOSEE','VALIDEE','FUSIONNEE','ECARTEE')),
  motif_ecartement                text,
  id_fusionnee_dans               uuid REFERENCES preoccupation(id_preoccupation),
  id_contribution_representative  uuid,
  texte_reference                 text NOT NULL DEFAULT '',
  lexemes_reference               text[] NOT NULL DEFAULT '{}',
  nb_contributions                integer NOT NULL DEFAULT 0,
  nb_voix                         integer NOT NULL DEFAULT 0,
  score                           numeric(5,2),
  score_detail                    jsonb,
  score_calcule_le                timestamptz,
  verrouillee                     boolean NOT NULL DEFAULT false,
  id_convergence                  uuid,
  validee_par                     uuid REFERENCES utilisateur(id_utilisateur),
  validee_le                      timestamptz,
  creee_le                        timestamptz NOT NULL DEFAULT now(),
  modifie_le                      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_preoccupation_ecartee CHECK ((statut = 'ECARTEE') = (motif_ecartement IS NOT NULL)),
  CONSTRAINT ck_preoccupation_fusion CHECK ((statut = 'FUSIONNEE') = (id_fusionnee_dans IS NOT NULL)
                                            AND (id_fusionnee_dans IS NULL OR id_fusionnee_dans <> id_preoccupation)),
  CONSTRAINT ck_preoccupation_validation CHECK (statut <> 'VALIDEE' OR (validee_par IS NOT NULL AND validee_le IS NOT NULL)),
  CONSTRAINT ck_preoccupation_score CHECK (score IS NULL OR score BETWEEN 0 AND 100)
);
CREATE INDEX ix_preoccupation_perimetre ON preoccupation(id_edition, id_utr, id_secteur, statut);
CREATE INDEX ix_preoccupation_texte_trgm ON preoccupation USING gin (texte_reference gin_trgm_ops);
CREATE INDEX ix_preoccupation_lexemes ON preoccupation USING gin (lexemes_reference);
CREATE TRIGGER trg_preoccupation_modifie BEFORE UPDATE ON preoccupation FOR EACH ROW EXECUTE FUNCTION maj_modifie_le();
COMMENT ON TABLE preoccupation IS 'Groupe de contributions similaires d''une même UTR et d''un même secteur ; unité du livre blanc régional (RG-50).';
COMMENT ON COLUMN preoccupation.reference IS 'Référence lisible (ex. P-2030-GOH-0042).';
COMMENT ON COLUMN preoccupation.id_utr IS 'UTR de la préoccupation.';
COMMENT ON COLUMN preoccupation.id_secteur IS 'Secteur de la préoccupation.';
COMMENT ON COLUMN preoccupation.intitule IS 'Intitulé ; provisoirement le titre de la première contribution (§10.2).';
COMMENT ON COLUMN preoccupation.synthese IS 'Synthèse rédigée par l''administrateur (document de texte enrichi).';
COMMENT ON COLUMN preoccupation.propositions_retenues IS 'Liste ordonnée des propositions retenues (tableau JSON de textes).';
COMMENT ON COLUMN preoccupation.statut IS 'PROPOSEE (créée par le système), VALIDEE, FUSIONNEE ou ECARTEE.';
COMMENT ON COLUMN preoccupation.motif_ecartement IS 'Motif obligatoire d''écartement (RG-52).';
COMMENT ON COLUMN preoccupation.id_fusionnee_dans IS 'Préoccupation cible d''une fusion (RG-43).';
COMMENT ON COLUMN preoccupation.id_contribution_representative IS 'Contribution la plus soutenue, servant de référence de similarité (§10.2).';
COMMENT ON COLUMN preoccupation.texte_reference IS 'Texte normalisé (intitulé + contribution représentative) indexé pour la similarité.';
COMMENT ON COLUMN preoccupation.lexemes_reference IS 'Racines lexicales du texte de référence.';
COMMENT ON COLUMN preoccupation.nb_contributions IS 'Nombre de contributions publiées rattachées (valeur calculée).';
COMMENT ON COLUMN preoccupation.nb_voix IS 'Nombre de voix au sens de RG-51 (valeur calculée).';
COMMENT ON COLUMN preoccupation.score IS 'Score de priorité régional de 0 à 100 (§10.3, valeur calculée).';
COMMENT ON COLUMN preoccupation.score_detail IS 'Décomposition du score (V, U, E, C et pondérations) pour l''explicabilité (P5).';
COMMENT ON COLUMN preoccupation.score_calcule_le IS 'Date du dernier calcul du score.';
COMMENT ON COLUMN preoccupation.verrouillee IS 'Vrai quand le livre blanc régional est publié : toute modification exige une nouvelle version (RG-56).';
COMMENT ON COLUMN preoccupation.id_convergence IS 'Convergence nationale à laquelle la préoccupation est rattachée (RG-62).';
COMMENT ON COLUMN preoccupation.validee_par IS 'Administrateur ayant validé.';
COMMENT ON COLUMN preoccupation.validee_le IS 'Date de validation.';

CREATE TABLE contribution (
  id_contribution          uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  reference                text NOT NULL UNIQUE,
  id_edition               uuid NOT NULL REFERENCES edition(id_edition),
  source                   text NOT NULL CHECK (source IN ('EN_LIGNE','TERRAIN')),
  id_auteur                uuid REFERENCES utilisateur(id_utilisateur),
  id_organisation          uuid REFERENCES organisation(id_organisation),
  id_consultation          uuid REFERENCES consultation_terrain(id_consultation),
  titre                    text NOT NULL CHECK (char_length(titre) BETWEEN 10 AND 120),
  constat                  text NOT NULL CHECK (char_length(constat) BETWEEN 30 AND 1500),
  proposition              text NOT NULL CHECK (char_length(proposition) BETWEEN 20 AND 1500),
  id_secteur               uuid NOT NULL REFERENCES secteur(id_secteur),
  id_territoire            uuid NOT NULL REFERENCES territoire(id_territoire),
  id_utr                   uuid NOT NULL REFERENCES territoire(id_territoire),
  localite                 text CHECK (char_length(localite) <= 120),
  urgence                  text NOT NULL CHECK (urgence IN ('FAIBLE','MOYENNE','ELEVEE','CRITIQUE')),
  tranche_population       text CHECK (tranche_population IN ('MOINS_500','DE_500_A_5000','DE_5000_A_50000','PLUS_50000','INCONNUE')),
  hors_residence           boolean NOT NULL DEFAULT false,
  statut                   text NOT NULL DEFAULT 'PUBLIEE' CHECK (statut IN
                            ('PUBLIEE','EN_MODERATION','MASQUEE','RETIREE_AUTEUR','RETIREE_ADMIN','ARCHIVEE')),
  id_preoccupation         uuid REFERENCES preoccupation(id_preoccupation),
  mode_rattachement        text CHECK (mode_rattachement IN ('AUTO','MANUEL')),
  similarite_rattachement  numeric(4,3) CHECK (similarite_rattachement BETWEEN 0 AND 1),
  nb_signalements          integer NOT NULL DEFAULT 0 CHECK (nb_signalements >= 0),
  version                  integer NOT NULL DEFAULT 1,
  deposee_le               timestamptz NOT NULL DEFAULT now(),
  modifie_le               timestamptz NOT NULL DEFAULT now(),
  titre_normalise          text GENERATED ALWAYS AS (normaliser_texte(titre)) STORED,
  texte_normalise          text GENERATED ALWAYS AS (normaliser_texte(titre || ' ' || constat || ' ' || proposition)) STORED,
  lexemes                  text[] GENERATED ALWAYS AS (lexemes_texte(titre || ' ' || constat || ' ' || proposition)) STORED,
  document_recherche       tsvector GENERATED ALWAYS AS (
                             setweight(to_tsvector('french', immutable_unaccent(titre)), 'A') ||
                             setweight(to_tsvector('french', immutable_unaccent(constat || ' ' || proposition)), 'B')) STORED,
  CONSTRAINT ck_contribution_source CHECK (
    (source = 'EN_LIGNE' AND id_auteur IS NOT NULL AND id_consultation IS NULL) OR
    (source = 'TERRAIN'  AND id_auteur IS NULL AND id_consultation IS NOT NULL AND id_organisation IS NULL)),
  CONSTRAINT ck_contribution_rattachement CHECK (
    statut NOT IN ('PUBLIEE','EN_MODERATION') OR (id_preoccupation IS NOT NULL AND mode_rattachement IS NOT NULL))
);
ALTER TABLE preoccupation ADD CONSTRAINT fk_preoccupation_representative
  FOREIGN KEY (id_contribution_representative) REFERENCES contribution(id_contribution) DEFERRABLE INITIALLY DEFERRED;
CREATE INDEX ix_contribution_perimetre ON contribution(id_edition, id_utr, id_secteur, statut);
CREATE INDEX ix_contribution_preoccupation ON contribution(id_preoccupation);
CREATE INDEX ix_contribution_auteur ON contribution(id_auteur, deposee_le);
CREATE INDEX ix_contribution_titre_trgm ON contribution USING gin (titre_normalise gin_trgm_ops);
CREATE INDEX ix_contribution_texte_trgm ON contribution USING gin (texte_normalise gin_trgm_ops);
CREATE INDEX ix_contribution_recherche ON contribution USING gin (document_recherche);
CREATE INDEX ix_contribution_lexemes ON contribution USING gin (lexemes);
COMMENT ON TABLE contribution IS 'Expression d''un problème (constat) et d''une solution souhaitée (proposition), localisée et rattachée à un secteur ; unité de base du système.';
COMMENT ON COLUMN contribution.reference IS 'Référence publique lisible (ex. C-2030-GOH-000123).';
COMMENT ON COLUMN contribution.source IS 'EN_LIGNE (déposée par un compte) ou TERRAIN (importée d''une consultation).';
COMMENT ON COLUMN contribution.id_auteur IS 'Contributeur auteur (nul pour une contribution de terrain, RG-28).';
COMMENT ON COLUMN contribution.id_organisation IS 'Organisation au nom de laquelle la contribution est déposée (RG-23).';
COMMENT ON COLUMN contribution.id_consultation IS 'Consultation de terrain d''origine (contribution importée).';
COMMENT ON COLUMN contribution.titre IS 'Titre court, de 10 à 120 caractères (RG-21).';
COMMENT ON COLUMN contribution.constat IS 'Description du problème, de 30 à 1 500 caractères.';
COMMENT ON COLUMN contribution.proposition IS 'Solution souhaitée, de 20 à 1 500 caractères.';
COMMENT ON COLUMN contribution.id_secteur IS 'Secteur de développement.';
COMMENT ON COLUMN contribution.id_territoire IS 'Territoire concerné : maille la plus fine disponible (RG-21).';
COMMENT ON COLUMN contribution.id_utr IS 'UTR déduite du territoire concerné (RG-22), dénormalisée.';
COMMENT ON COLUMN contribution.localite IS 'Village, quartier ou lieu précis (facultatif).';
COMMENT ON COLUMN contribution.urgence IS 'Urgence perçue : FAIBLE, MOYENNE, ELEVEE, CRITIQUE.';
COMMENT ON COLUMN contribution.tranche_population IS 'Tranche de population concernée (facultative).';
COMMENT ON COLUMN contribution.hors_residence IS 'Vrai si l''UTR concernée diffère de l''UTR de résidence de l''auteur (RG-22).';
COMMENT ON COLUMN contribution.statut IS 'PUBLIEE, EN_MODERATION, MASQUEE, RETIREE_AUTEUR, RETIREE_ADMIN, ARCHIVEE (§8.3).';
COMMENT ON COLUMN contribution.id_preoccupation IS 'Préoccupation de rattachement (RG-24).';
COMMENT ON COLUMN contribution.mode_rattachement IS 'AUTO (moteur de regroupement) ou MANUEL (administrateur) ; un rattachement manuel n''est jamais défait automatiquement.';
COMMENT ON COLUMN contribution.similarite_rattachement IS 'Similarité calculée lors du rattachement automatique.';
COMMENT ON COLUMN contribution.nb_signalements IS 'Nombre de signalements distincts reçus (RG-40).';
COMMENT ON COLUMN contribution.version IS 'Numéro de version courant (historisation, RG-25).';
COMMENT ON COLUMN contribution.deposee_le IS 'Date de dépôt.';
COMMENT ON COLUMN contribution.titre_normalise IS 'Titre normalisé (minuscules, sans accents), indexé en trigrammes.';
COMMENT ON COLUMN contribution.texte_normalise IS 'Texte complet normalisé, indexé en trigrammes pour la similarité.';
COMMENT ON COLUMN contribution.lexemes IS 'Racines lexicales françaises du texte, utilisées par la similarité composite.';
COMMENT ON COLUMN contribution.document_recherche IS 'Vecteur de recherche plein texte en français (F-104).';


CREATE TABLE version_contribution (
  id_version          uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  id_contribution     uuid NOT NULL REFERENCES contribution(id_contribution),
  numero              integer NOT NULL,
  titre               text NOT NULL,
  constat             text NOT NULL,
  proposition         text NOT NULL,
  id_secteur          uuid NOT NULL REFERENCES secteur(id_secteur),
  id_territoire       uuid NOT NULL REFERENCES territoire(id_territoire),
  urgence             text NOT NULL,
  tranche_population  text,
  localite            text,
  enregistree_le      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id_contribution, numero)
);
COMMENT ON TABLE version_contribution IS 'Historique des versions successives d''une contribution modifiée par son auteur (RG-25).';
COMMENT ON COLUMN version_contribution.numero IS 'Numéro de la version archivée.';
COMMENT ON COLUMN version_contribution.enregistree_le IS 'Date d''archivage de la version.';

CREATE TABLE illustration (
  id_contribution  uuid NOT NULL REFERENCES contribution(id_contribution),
  id_fichier       uuid NOT NULL REFERENCES fichier(id_fichier),
  ordre            smallint NOT NULL CHECK (ordre BETWEEN 1 AND 3),
  PRIMARY KEY (id_contribution, id_fichier),
  UNIQUE (id_contribution, ordre)
);
COMMENT ON TABLE illustration IS 'Photo jointe à une contribution, au plus 3 par contribution (RG-21).';
COMMENT ON COLUMN illustration.ordre IS 'Position de la photo (1 à 3).';

CREATE TABLE soutien (
  id_utilisateur   uuid NOT NULL REFERENCES utilisateur(id_utilisateur),
  id_contribution  uuid NOT NULL REFERENCES contribution(id_contribution),
  soutenu_le       timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id_utilisateur, id_contribution)
);
CREATE INDEX ix_soutien_contribution ON soutien(id_contribution);
COMMENT ON TABLE soutien IS 'Adhésion d''un contributeur à une contribution existante ; compte comme une voix (RG-27, RG-51).';
COMMENT ON COLUMN soutien.soutenu_le IS 'Date du soutien.';

CREATE TABLE signalement (
  id_utilisateur   uuid NOT NULL REFERENCES utilisateur(id_utilisateur),
  id_contribution  uuid NOT NULL REFERENCES contribution(id_contribution),
  motif            text NOT NULL CHECK (motif IN ('HORS_CHARTE','HORS_SUJET','DOUBLON','DONNEES_PERSONNELLES','AUTRE')),
  commentaire      text CHECK (char_length(commentaire) <= 500),
  signale_le       timestamptz NOT NULL DEFAULT now(),
  traite           boolean NOT NULL DEFAULT false,
  PRIMARY KEY (id_utilisateur, id_contribution)
);
COMMENT ON TABLE signalement IS 'Signalement d''une contribution par un contributeur (F-37) ; un seul par personne et par contribution.';
COMMENT ON COLUMN signalement.motif IS 'HORS_CHARTE, HORS_SUJET, DOUBLON, DONNEES_PERSONNELLES ou AUTRE.';
COMMENT ON COLUMN signalement.traite IS 'Vrai une fois une décision de modération prise.';

CREATE TABLE decision_moderation (
  id_decision        uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  id_contribution    uuid NOT NULL REFERENCES contribution(id_contribution),
  id_administrateur  uuid NOT NULL REFERENCES utilisateur(id_utilisateur),
  action             text NOT NULL CHECK (action IN ('MAINTENIR','MASQUER','RETIRER')),
  motif              text CHECK (motif IN ('HORS_CHARTE','HORS_SUJET','DOUBLON_STRICT','DONNEES_PERSONNELLES','AUTRE')),
  commentaire        text,
  decidee_le         timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_decision_motif CHECK ((action = 'MAINTENIR') = (motif IS NULL)),
  CONSTRAINT ck_decision_commentaire CHECK (action = 'MAINTENIR' OR commentaire IS NOT NULL)
);
CREATE INDEX ix_decision_contribution ON decision_moderation(id_contribution);
COMMENT ON TABLE decision_moderation IS 'Décision d''un administrateur sur une contribution signalée ou suspecte (RG-41).';
COMMENT ON COLUMN decision_moderation.action IS 'MAINTENIR, MASQUER ou RETIRER.';
COMMENT ON COLUMN decision_moderation.motif IS 'Motif obligatoire pour MASQUER et RETIRER.';
COMMENT ON COLUMN decision_moderation.commentaire IS 'Commentaire transmis à l''auteur.';

CREATE TABLE terme_interdit (
  id_terme  uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  terme     text NOT NULL UNIQUE,
  actif     boolean NOT NULL DEFAULT true
);
COMMENT ON TABLE terme_interdit IS 'Liste de termes déclenchant la mise en modération automatique (F-24).';

-- =============================================================================
-- 5. LIVRES BLANCS ET CONSOLIDATION NATIONALE
-- =============================================================================
CREATE TABLE calcul_consolidation (
  id_calcul    uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  id_edition   uuid NOT NULL REFERENCES edition(id_edition),
  lance_par    uuid NOT NULL REFERENCES utilisateur(id_utilisateur),
  lance_le     timestamptz NOT NULL DEFAULT now(),
  termine_le   timestamptz,
  statut       text NOT NULL DEFAULT 'EN_COURS' CHECK (statut IN ('EN_COURS','TERMINE','ECHEC')),
  parametres   jsonb NOT NULL,
  rapport      jsonb
);
COMMENT ON TABLE calcul_consolidation IS 'Exécution du moteur de consolidation nationale (F-71) avec ses paramètres et son rapport.';
COMMENT ON COLUMN calcul_consolidation.parametres IS 'Seuils et pondérations utilisés.';
COMMENT ON COLUMN calcul_consolidation.rapport IS 'Synthèse : nombre de convergences par classe et par secteur, cohésion.';

CREATE TABLE convergence (
  id_convergence      uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  reference           text NOT NULL UNIQUE,
  id_edition          uuid NOT NULL REFERENCES edition(id_edition),
  id_secteur          uuid NOT NULL REFERENCES secteur(id_secteur),
  id_calcul           uuid REFERENCES calcul_consolidation(id_calcul),
  origine             text NOT NULL DEFAULT 'CALCUL' CHECK (origine IN ('CALCUL','MANUELLE')),
  intitule            text NOT NULL CHECK (char_length(intitule) BETWEEN 5 AND 200),
  synthese            jsonb,
  propositions        jsonb NOT NULL DEFAULT '[]'::jsonb,
  texte_assiste       boolean NOT NULL DEFAULT false,
  statut              text NOT NULL DEFAULT 'PROPOSEE' CHECK (statut IN ('PROPOSEE','RETENUE','FUSIONNEE','REJETEE')),
  classe_calculee     text CHECK (classe_calculee IN ('NATIONALE','PARTAGEE','SPECIFIQUE')),
  classe              text CHECK (classe IN ('NATIONALE','PARTAGEE','SPECIFIQUE')),
  motif               text,
  id_fusionnee_dans   uuid REFERENCES convergence(id_convergence),
  nb_utr              integer NOT NULL DEFAULT 0,
  population_couverte bigint NOT NULL DEFAULT 0,
  score               numeric(5,2) CHECK (score IS NULL OR score BETWEEN 0 AND 100),
  score_detail        jsonb,
  cohesion            numeric(4,3),
  creee_le            timestamptz NOT NULL DEFAULT now(),
  modifie_le          timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_convergence_rejet CHECK (statut <> 'REJETEE' OR motif IS NOT NULL),
  CONSTRAINT ck_convergence_fusion CHECK ((statut = 'FUSIONNEE') = (id_fusionnee_dans IS NOT NULL)),
  CONSTRAINT ck_convergence_classe CHECK (statut <> 'RETENUE' OR classe IS NOT NULL),
  CONSTRAINT ck_convergence_reclassement CHECK (classe IS NULL OR classe_calculee IS NULL OR classe = classe_calculee OR motif IS NOT NULL)
);
ALTER TABLE preoccupation ADD CONSTRAINT fk_preoccupation_convergence
  FOREIGN KEY (id_convergence) REFERENCES convergence(id_convergence);
CREATE INDEX ix_convergence_edition ON convergence(id_edition, statut, classe);
CREATE TRIGGER trg_convergence_modifie BEFORE UPDATE ON convergence FOR EACH ROW EXECUTE FUNCTION maj_modifie_le();
COMMENT ON TABLE convergence IS 'Groupe de préoccupations régionales similaires proposé par le moteur de consolidation et arbitré lors des états généraux (§10.4).';
COMMENT ON COLUMN convergence.reference IS 'Référence lisible (ex. N-2030-0007).';
COMMENT ON COLUMN convergence.origine IS 'CALCUL (moteur) ou MANUELLE (créée par scission ou par l''administrateur).';
COMMENT ON COLUMN convergence.intitule IS 'Intitulé ; proposé par le moteur, réécrit librement par l''administrateur.';
COMMENT ON COLUMN convergence.synthese IS 'Synthèse (texte enrichi).';
COMMENT ON COLUMN convergence.propositions IS 'Propositions consolidées (tableau JSON de textes).';
COMMENT ON COLUMN convergence.texte_assiste IS 'Vrai si la synthèse provient de l''assistance par modèle de langage et n''a pas encore été relue (F-75).';
COMMENT ON COLUMN convergence.statut IS 'PROPOSEE, RETENUE, FUSIONNEE ou REJETEE (RG-63).';
COMMENT ON COLUMN convergence.classe_calculee IS 'Classe proposée par le moteur selon le nombre d''UTR (§10.4).';
COMMENT ON COLUMN convergence.classe IS 'Classe retenue : NATIONALE, PARTAGEE ou SPECIFIQUE (RG-64).';
COMMENT ON COLUMN convergence.motif IS 'Motif de rejet, de fusion ou de reclassement.';
COMMENT ON COLUMN convergence.nb_utr IS 'Nombre d''UTR concernées.';
COMMENT ON COLUMN convergence.population_couverte IS 'Population cumulée des UTR concernées.';
COMMENT ON COLUMN convergence.score IS 'Score national de 0 à 100 (§10.4).';
COMMENT ON COLUMN convergence.score_detail IS 'Décomposition du score national (T, P, S).';
COMMENT ON COLUMN convergence.cohesion IS 'Similarité moyenne des membres à l''élément central ; une valeur faible signale un regroupement à vérifier.';

CREATE TABLE decision_etats_generaux (
  id_decision        uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  id_convergence     uuid NOT NULL REFERENCES convergence(id_convergence),
  id_administrateur  uuid NOT NULL REFERENCES utilisateur(id_utilisateur),
  action             text NOT NULL CHECK (action IN ('RETENIR','FUSIONNER','SCINDER','REJETER','RECLASSER','MODIFIER_TEXTE','REOUVRIR')),
  motif              text,
  details            jsonb,
  decidee_le         timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_decision_eg_motif CHECK (action NOT IN ('FUSIONNER','SCINDER','REJETER','RECLASSER') OR motif IS NOT NULL)
);
CREATE INDEX ix_decision_eg_convergence ON decision_etats_generaux(id_convergence);
COMMENT ON TABLE decision_etats_generaux IS 'Décision prise lors des états généraux sur une convergence ; journal exporté en annexe du livre blanc national (F-74).';
COMMENT ON COLUMN decision_etats_generaux.action IS 'RETENIR, FUSIONNER, SCINDER, REJETER, RECLASSER, MODIFIER_TEXTE ou REOUVRIR.';
COMMENT ON COLUMN decision_etats_generaux.motif IS 'Motif obligatoire pour les fusions, scissions, rejets et reclassements (RG-63, RG-64).';
COMMENT ON COLUMN decision_etats_generaux.details IS 'Données de l''opération (convergences sources et cibles, ancienne et nouvelle classe…).';

CREATE TABLE livre_blanc (
  id_livre_blanc  uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  id_edition      uuid NOT NULL REFERENCES edition(id_edition),
  type            text NOT NULL CHECK (type IN ('REGIONAL','NATIONAL')),
  id_utr          uuid REFERENCES territoire(id_territoire),
  CONSTRAINT ck_livre_blanc_type CHECK ((type = 'REGIONAL') = (id_utr IS NOT NULL)),
  CONSTRAINT ux_livre_blanc UNIQUE NULLS NOT DISTINCT (id_edition, type, id_utr)
);
COMMENT ON TABLE livre_blanc IS 'Livre blanc régional (une UTR) ou national d''une édition ; son contenu est porté par ses versions.';
COMMENT ON COLUMN livre_blanc.type IS 'REGIONAL ou NATIONAL.';
COMMENT ON COLUMN livre_blanc.id_utr IS 'UTR du livre blanc régional (nulle pour le national).';

CREATE TABLE version_livre_blanc (
  id_version          uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  id_livre_blanc      uuid NOT NULL REFERENCES livre_blanc(id_livre_blanc),
  numero              smallint NOT NULL CHECK (numero >= 1),
  statut              text NOT NULL DEFAULT 'BROUILLON' CHECK (statut IN ('BROUILLON','PUBLIEE','REMPLACEE')),
  introduction        jsonb,
  resume_changements  text,
  date_validation     date,
  lieu_validation     text,
  id_fichier_pv       uuid REFERENCES fichier(id_fichier),
  contenu_fige        jsonb,
  parametres_figes    jsonb,
  empreinte_sha256    char(64),
  id_fichier_pdf      uuid REFERENCES fichier(id_fichier),
  id_fichier_docx     uuid REFERENCES fichier(id_fichier),
  creee_le            timestamptz NOT NULL DEFAULT now(),
  creee_par           uuid NOT NULL REFERENCES utilisateur(id_utilisateur),
  publiee_le          timestamptz,
  publiee_par         uuid REFERENCES utilisateur(id_utilisateur),
  remplacee_le        timestamptz,
  modifie_le          timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id_livre_blanc, numero),
  CONSTRAINT ck_version_publiee CHECK (statut = 'BROUILLON' OR
    (publiee_le IS NOT NULL AND publiee_par IS NOT NULL AND contenu_fige IS NOT NULL
     AND parametres_figes IS NOT NULL AND empreinte_sha256 IS NOT NULL)),
  CONSTRAINT ck_version_remplacee CHECK ((statut = 'REMPLACEE') = (remplacee_le IS NOT NULL)),
  CONSTRAINT ck_version_changements CHECK (numero = 1 OR statut = 'BROUILLON' OR resume_changements IS NOT NULL)
);
CREATE UNIQUE INDEX ux_version_brouillon ON version_livre_blanc(id_livre_blanc) WHERE statut = 'BROUILLON';
CREATE UNIQUE INDEX ux_version_publiee ON version_livre_blanc(id_livre_blanc) WHERE statut = 'PUBLIEE';
CREATE TRIGGER trg_version_modifie BEFORE UPDATE ON version_livre_blanc FOR EACH ROW EXECUTE FUNCTION maj_modifie_le();
COMMENT ON TABLE version_livre_blanc IS 'Version successive d''un livre blanc ; une version publiée est figée et non modifiable (RG-54).';
COMMENT ON COLUMN version_livre_blanc.numero IS 'Numéro de version (1, 2, …).';
COMMENT ON COLUMN version_livre_blanc.statut IS 'BROUILLON, PUBLIEE ou REMPLACEE.';
COMMENT ON COLUMN version_livre_blanc.introduction IS 'Introduction ou préambule (texte enrichi).';
COMMENT ON COLUMN version_livre_blanc.resume_changements IS 'Résumé obligatoire des changements à partir de la version 2 (RG-54).';
COMMENT ON COLUMN version_livre_blanc.date_validation IS 'Date de l''atelier ou de la réunion de validation (obligatoire pour un LBR publié, RG-55).';
COMMENT ON COLUMN version_livre_blanc.lieu_validation IS 'Lieu de la validation (facultatif).';
COMMENT ON COLUMN version_livre_blanc.id_fichier_pv IS 'Procès-verbal de validation (PDF, facultatif).';
COMMENT ON COLUMN version_livre_blanc.contenu_fige IS 'Modèle de document complet figé à la publication (préoccupations, scores, liens de traçabilité).';
COMMENT ON COLUMN version_livre_blanc.parametres_figes IS 'Pondérations et seuils en vigueur à la publication.';
COMMENT ON COLUMN version_livre_blanc.empreinte_sha256 IS 'Empreinte du contenu figé (preuve d''intégrité).';
COMMENT ON COLUMN version_livre_blanc.id_fichier_pdf IS 'Export PDF généré.';
COMMENT ON COLUMN version_livre_blanc.id_fichier_docx IS 'Export Word généré.';

CREATE TABLE inclusion_preoccupation (
  id_version        uuid NOT NULL REFERENCES version_livre_blanc(id_version),
  id_preoccupation  uuid NOT NULL REFERENCES preoccupation(id_preoccupation),
  rang              integer NOT NULL CHECK (rang >= 1),
  intitule_fige     text NOT NULL,
  score_fige        numeric(5,2) NOT NULL,
  nb_voix_fige      integer NOT NULL,
  PRIMARY KEY (id_version, id_preoccupation),
  UNIQUE (id_version, rang)
);
COMMENT ON TABLE inclusion_preoccupation IS 'Préoccupation figurant dans une version publiée d''un livre blanc régional, avec ses valeurs figées (traçabilité, RG-54).';
COMMENT ON COLUMN inclusion_preoccupation.rang IS 'Rang de priorité dans la version.';

CREATE TABLE inclusion_convergence (
  id_version      uuid NOT NULL REFERENCES version_livre_blanc(id_version),
  id_convergence  uuid NOT NULL REFERENCES convergence(id_convergence),
  rang            integer NOT NULL CHECK (rang >= 1),
  classe_figee    text NOT NULL CHECK (classe_figee IN ('NATIONALE','PARTAGEE','SPECIFIQUE')),
  intitule_fige   text NOT NULL,
  score_fige      numeric(5,2) NOT NULL,
  PRIMARY KEY (id_version, id_convergence),
  UNIQUE (id_version, classe_figee, rang)
);
COMMENT ON TABLE inclusion_convergence IS 'Convergence figurant dans une version publiée du livre blanc national, avec ses valeurs figées.';
COMMENT ON COLUMN inclusion_convergence.rang IS 'Rang dans sa classe.';
COMMENT ON COLUMN inclusion_convergence.classe_figee IS 'Classe au moment de la publication.';

-- =============================================================================
-- 6. CANDIDATS, ENGAGEMENTS ET SUIVI
-- =============================================================================
CREATE TABLE candidat (
  id_candidat      uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  id_utilisateur   uuid NOT NULL REFERENCES utilisateur(id_utilisateur),
  id_edition       uuid NOT NULL REFERENCES edition(id_edition),
  type_election    text NOT NULL CHECK (type_election IN ('PRESIDENTIELLE','REGIONALE')),
  id_utr           uuid REFERENCES territoire(id_territoire),
  nom_affiche      text NOT NULL CHECK (char_length(nom_affiche) BETWEEN 3 AND 150),
  parti            text,
  id_fichier_photo uuid REFERENCES fichier(id_fichier),
  statut           text NOT NULL DEFAULT 'CANDIDAT' CHECK (statut IN ('CANDIDAT','ELU','NON_ELU')),
  cree_le          timestamptz NOT NULL DEFAULT now(),
  cree_par         uuid NOT NULL REFERENCES utilisateur(id_utilisateur),
  CONSTRAINT ck_candidat_utr CHECK ((type_election = 'REGIONALE') = (id_utr IS NOT NULL)),
  UNIQUE (id_utilisateur, id_edition)
);
COMMENT ON TABLE candidat IS 'Candidat déclaré à une élection d''une édition, géré par l''administrateur national (F-90, RG-70).';
COMMENT ON COLUMN candidat.id_utilisateur IS 'Compte utilisé par le candidat ou son équipe.';
COMMENT ON COLUMN candidat.type_election IS 'PRESIDENTIELLE ou REGIONALE dans le MVP.';
COMMENT ON COLUMN candidat.id_utr IS 'UTR de candidature (régionales).';
COMMENT ON COLUMN candidat.nom_affiche IS 'Nom affiché publiquement.';
COMMENT ON COLUMN candidat.parti IS 'Parti ou groupement ; nul pour un candidat indépendant.';
COMMENT ON COLUMN candidat.id_fichier_photo IS 'Photo officielle (facultative).';
COMMENT ON COLUMN candidat.statut IS 'CANDIDAT, ELU ou NON_ELU.';

CREATE TABLE engagement (
  id_engagement     uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  id_candidat       uuid NOT NULL REFERENCES candidat(id_candidat),
  id_convergence    uuid REFERENCES convergence(id_convergence),
  id_preoccupation  uuid REFERENCES preoccupation(id_preoccupation),
  echeance_annee    smallint NOT NULL CHECK (echeance_annee BETWEEN 2020 AND 2100),
  texte             text NOT NULL CHECK (char_length(texte) BETWEEN 20 AND 1000),
  statut            text NOT NULL DEFAULT 'DECLARE' CHECK (statut IN ('DECLARE','RETIRE')),
  declare_le        timestamptz NOT NULL DEFAULT now(),
  retire_le         timestamptz,
  CONSTRAINT ck_engagement_cible CHECK (num_nonnulls(id_convergence, id_preoccupation) = 1),
  CONSTRAINT ck_engagement_retrait CHECK ((statut = 'RETIRE') = (retire_le IS NOT NULL))
);
CREATE UNIQUE INDEX ux_engagement_convergence ON engagement(id_candidat, id_convergence) WHERE statut = 'DECLARE' AND id_convergence IS NOT NULL;
CREATE UNIQUE INDEX ux_engagement_preoccupation ON engagement(id_candidat, id_preoccupation) WHERE statut = 'DECLARE' AND id_preoccupation IS NOT NULL;
COMMENT ON TABLE engagement IS 'Engagement public d''un candidat sur une priorité du LBN (présidentielle) ou une préoccupation d''un LBR (régionales) (RG-71, RG-72).';
COMMENT ON COLUMN engagement.id_convergence IS 'Priorité nationale visée (présidentielle).';
COMMENT ON COLUMN engagement.id_preoccupation IS 'Préoccupation régionale visée (régionales).';
COMMENT ON COLUMN engagement.echeance_annee IS 'Année d''échéance annoncée.';
COMMENT ON COLUMN engagement.texte IS 'Texte de l''engagement, de 20 à 1 000 caractères.';
COMMENT ON COLUMN engagement.statut IS 'DECLARE ou RETIRE (retrait possible jusqu''à l''élection, RG-73).';

CREATE TABLE suivi_realisation (
  id_suivi              uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  id_engagement         uuid NOT NULL REFERENCES engagement(id_engagement),
  etat                  text NOT NULL CHECK (etat IN ('NON_DEMARRE','EN_COURS','REALISE','PARTIELLEMENT_REALISE','ABANDONNE')),
  date_etat             date NOT NULL,
  description           text NOT NULL CHECK (char_length(description) BETWEEN 10 AND 2000),
  saisi_par             uuid NOT NULL REFERENCES utilisateur(id_utilisateur),
  saisi_le              timestamptz NOT NULL DEFAULT now(),
  commentaire_candidat  text CHECK (char_length(commentaire_candidat) <= 1000),
  commentaire_le        timestamptz,
  CONSTRAINT ck_suivi_commentaire CHECK ((commentaire_candidat IS NULL) = (commentaire_le IS NULL))
);
CREATE INDEX ix_suivi_engagement ON suivi_realisation(id_engagement, date_etat);
COMMENT ON TABLE suivi_realisation IS 'Mise à jour de l''état d''avancement d''un engagement d''un élu, historisée (RG-74).';
COMMENT ON COLUMN suivi_realisation.etat IS 'NON_DEMARRE, EN_COURS, REALISE, PARTIELLEMENT_REALISE ou ABANDONNE.';
COMMENT ON COLUMN suivi_realisation.date_etat IS 'Date à laquelle l''état est constaté.';
COMMENT ON COLUMN suivi_realisation.description IS 'Description de l''avancement.';
COMMENT ON COLUMN suivi_realisation.saisi_par IS 'Administrateur national ayant saisi la mise à jour.';
COMMENT ON COLUMN suivi_realisation.commentaire_candidat IS 'Réponse publique du candidat (droit de réponse).';

CREATE TABLE justificatif (
  id_justificatif  uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  id_suivi         uuid NOT NULL REFERENCES suivi_realisation(id_suivi),
  type             text NOT NULL CHECK (type IN ('LIEN','FICHIER')),
  url              text CHECK (url ~ '^https?://'),
  id_fichier       uuid REFERENCES fichier(id_fichier),
  libelle          text NOT NULL,
  CONSTRAINT ck_justificatif_type CHECK ((type = 'LIEN' AND url IS NOT NULL AND id_fichier IS NULL)
                                     OR (type = 'FICHIER' AND id_fichier IS NOT NULL AND url IS NULL))
);
COMMENT ON TABLE justificatif IS 'Preuve associée à une mise à jour de suivi : lien ou fichier (RG-74).';
COMMENT ON COLUMN justificatif.libelle IS 'Description courte de la preuve.';

-- =============================================================================
-- 7. TRANSVERSE : NOTIFICATIONS ET AUDIT
-- =============================================================================
CREATE TABLE notification (
  id_notification   uuid PRIMARY KEY DEFAULT gen_uuid_v7(),
  id_utilisateur    uuid NOT NULL REFERENCES utilisateur(id_utilisateur),
  type              text NOT NULL,
  titre             text NOT NULL,
  message           text NOT NULL,
  lien              text,
  creee_le          timestamptz NOT NULL DEFAULT now(),
  lue_le            timestamptz,
  email_envoye_le   timestamptz
);
CREATE INDEX ix_notification_utilisateur ON notification(id_utilisateur, creee_le DESC) WHERE lue_le IS NULL;
COMMENT ON TABLE notification IS 'Notification adressée à un utilisateur dans l''application et, le cas échéant, par e-mail (F-120).';

CREATE TABLE journal_audit (
  id_entree     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  survenue_le   timestamptz NOT NULL DEFAULT now(),
  id_acteur     uuid REFERENCES utilisateur(id_utilisateur),
  action        text NOT NULL,
  type_objet    text NOT NULL,
  id_objet      uuid,
  avant         jsonb,
  apres         jsonb,
  motif         text,
  adresse_ip    inet,
  id_requete    text
);
CREATE INDEX ix_journal_objet ON journal_audit(type_objet, id_objet);
CREATE INDEX ix_journal_acteur ON journal_audit(id_acteur, survenue_le);
COMMENT ON TABLE journal_audit IS 'Journal non modifiable des actions d''administration et des transitions de statut (RG-45, F-130).';
COMMENT ON COLUMN journal_audit.id_acteur IS 'Utilisateur à l''origine de l''action (nul pour le système).';
COMMENT ON COLUMN journal_audit.action IS 'Code de l''action (ex. CONTRIBUTION.RETIRER).';
COMMENT ON COLUMN journal_audit.avant IS 'État de l''objet avant l''action.';
COMMENT ON COLUMN journal_audit.apres IS 'État de l''objet après l''action.';
COMMENT ON COLUMN journal_audit.motif IS 'Motif saisi.';

CREATE OR REPLACE FUNCTION journal_interdire_modification() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'RG-45 : le journal d''audit n''est pas modifiable' USING ERRCODE = 'P0001';
END $$;
CREATE TRIGGER trg_journal_immuable BEFORE UPDATE OR DELETE ON journal_audit FOR EACH ROW EXECUTE FUNCTION journal_interdire_modification();

-- =============================================================================
-- 8. RÈGLES DE GESTION IMPLÉMENTÉES PAR DÉCLENCHEURS
-- =============================================================================

-- RG-05 / D-06 : une affectation régionale porte sur une UTR
CREATE OR REPLACE FUNCTION affectation_controler() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.id_utr IS NOT NULL AND NOT (SELECT est_utr FROM territoire WHERE id_territoire = NEW.id_utr) THEN
    RAISE EXCEPTION 'D-04 : le périmètre d''un administrateur régional doit être une UTR' USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER trg_affectation_controle BEFORE INSERT OR UPDATE ON affectation FOR EACH ROW EXECUTE FUNCTION affectation_controler();

-- RG-20, RG-21, RG-22, RG-24, RG-50 : cohérence d'une contribution
CREATE OR REPLACE FUNCTION contribution_controler() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  t territoire%ROWTYPE;
  p preoccupation%ROWTYPE;
  ph text;
  utr_residence uuid;
BEGIN
  SELECT * INTO t FROM territoire WHERE id_territoire = NEW.id_territoire;
  IF NOT t.est_selectionnable THEN
    RAISE EXCEPTION 'RG-21 : le territoire concerné doit être la maille la plus fine disponible' USING ERRCODE = 'P0001';
  END IF;
  NEW.id_utr := t.id_utr;

  IF TG_OP = 'INSERT' THEN
    SELECT phase INTO ph FROM edition WHERE id_edition = NEW.id_edition;
    IF NEW.source = 'EN_LIGNE' AND ph <> 'COLLECTE' THEN
      RAISE EXCEPTION 'RG-20 : dépôt possible uniquement pendant la phase de collecte' USING ERRCODE = 'P0001';
    ELSIF NEW.source = 'TERRAIN' AND ph NOT IN ('COLLECTE','CONSOLIDATION_REGIONALE') THEN
      RAISE EXCEPTION 'RG-28 : import de terrain impossible dans la phase %', ph USING ERRCODE = 'P0001';
    END IF;
  END IF;

  IF NEW.source = 'EN_LIGNE' THEN
    SELECT tr.id_utr INTO utr_residence FROM utilisateur u JOIN territoire tr ON tr.id_territoire = u.id_territoire_residence
     WHERE u.id_utilisateur = NEW.id_auteur;
    NEW.hors_residence := utr_residence IS DISTINCT FROM NEW.id_utr AND utr_residence IS NOT NULL;
    IF NEW.id_organisation IS NOT NULL AND NOT EXISTS (
         SELECT 1 FROM organisation WHERE id_organisation = NEW.id_organisation AND id_representant = NEW.id_auteur) THEN
      RAISE EXCEPTION 'RG-23 : seul le représentant peut déposer au nom de l''organisation' USING ERRCODE = 'P0001';
    END IF;
  END IF;

  IF NEW.id_preoccupation IS NOT NULL THEN
    SELECT * INTO p FROM preoccupation WHERE id_preoccupation = NEW.id_preoccupation;
    IF p.id_edition <> NEW.id_edition OR p.id_utr <> NEW.id_utr OR p.id_secteur <> NEW.id_secteur THEN
      RAISE EXCEPTION 'RG-24 : la préoccupation doit appartenir à la même édition, UTR et secteur' USING ERRCODE = 'P0001';
    END IF;
    IF p.statut IN ('FUSIONNEE','ECARTEE') AND NEW.statut IN ('PUBLIEE','EN_MODERATION') THEN
      RAISE EXCEPTION 'RG-24 : rattachement impossible à une préoccupation fusionnée ou écartée' USING ERRCODE = 'P0001';
    END IF;
  END IF;

  -- RG-56 : verrouillage après publication du LBR
  IF TG_OP = 'UPDATE' AND NEW.id_preoccupation IS DISTINCT FROM OLD.id_preoccupation THEN
    IF EXISTS (SELECT 1 FROM preoccupation WHERE id_preoccupation IN (OLD.id_preoccupation, NEW.id_preoccupation) AND verrouillee) THEN
      RAISE EXCEPTION 'RG-56 : rattachement verrouillé, créer d''abord une nouvelle version du livre blanc régional' USING ERRCODE = 'P0001';
    END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER trg_contribution_controle BEFORE INSERT OR UPDATE ON contribution FOR EACH ROW EXECUTE FUNCTION contribution_controler();

-- RG-25 : historisation des modifications de contenu
CREATE OR REPLACE FUNCTION contribution_historiser() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF (NEW.titre, NEW.constat, NEW.proposition, NEW.id_secteur, NEW.id_territoire, NEW.urgence, NEW.tranche_population, NEW.localite)
     IS DISTINCT FROM
     (OLD.titre, OLD.constat, OLD.proposition, OLD.id_secteur, OLD.id_territoire, OLD.urgence, OLD.tranche_population, OLD.localite) THEN
    IF (SELECT phase FROM edition WHERE id_edition = OLD.id_edition) <> 'COLLECTE' THEN
      RAISE EXCEPTION 'RG-25 : modification possible uniquement pendant la collecte' USING ERRCODE = 'P0001';
    END IF;
    INSERT INTO version_contribution(id_contribution, numero, titre, constat, proposition, id_secteur, id_territoire,
                                     urgence, tranche_population, localite)
    VALUES (OLD.id_contribution, OLD.version, OLD.titre, OLD.constat, OLD.proposition, OLD.id_secteur, OLD.id_territoire,
            OLD.urgence, OLD.tranche_population, OLD.localite);
    NEW.version := OLD.version + 1;
  END IF;
  NEW.modifie_le := now();
  RETURN NEW;
END $$;
CREATE TRIGGER trg_contribution_historique BEFORE UPDATE ON contribution FOR EACH ROW EXECUTE FUNCTION contribution_historiser();

-- RG-27 : soutien
CREATE OR REPLACE FUNCTION soutien_controler() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE c contribution%ROWTYPE;
BEGIN
  SELECT * INTO c FROM contribution WHERE id_contribution = NEW.id_contribution;
  IF c.id_auteur = NEW.id_utilisateur THEN
    RAISE EXCEPTION 'RG-27 : on ne peut pas soutenir sa propre contribution' USING ERRCODE = 'P0001';
  END IF;
  IF c.statut <> 'PUBLIEE' THEN
    RAISE EXCEPTION 'RG-27 : seule une contribution publiée peut être soutenue' USING ERRCODE = 'P0001';
  END IF;
  IF (SELECT phase FROM edition WHERE id_edition = c.id_edition) <> 'COLLECTE' THEN
    RAISE EXCEPTION 'RG-27 : soutien possible uniquement pendant la collecte' USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER trg_soutien_controle BEFORE INSERT ON soutien FOR EACH ROW EXECUTE FUNCTION soutien_controler();

-- RG-40 : comptage des signalements
CREATE OR REPLACE FUNCTION signalement_compter() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  UPDATE contribution SET nb_signalements = nb_signalements + 1 WHERE id_contribution = NEW.id_contribution;
  RETURN NEW;
END $$;
CREATE TRIGGER trg_signalement_compte AFTER INSERT ON signalement FOR EACH ROW EXECUTE FUNCTION signalement_compter();

-- RG-44 : un administrateur ne modère pas sa propre contribution
CREATE OR REPLACE FUNCTION decision_moderation_controler() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM contribution WHERE id_contribution = NEW.id_contribution AND id_auteur = NEW.id_administrateur) THEN
    RAISE EXCEPTION 'RG-44 : un administrateur ne peut pas modérer sa propre contribution' USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER trg_decision_moderation_controle BEFORE INSERT ON decision_moderation FOR EACH ROW EXECUTE FUNCTION decision_moderation_controler();

-- RG-56 : préoccupation verrouillée après publication du LBR
CREATE OR REPLACE FUNCTION preoccupation_controler() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.verrouillee AND NEW.verrouillee AND
     (NEW.intitule, NEW.synthese, NEW.propositions_retenues, NEW.statut, NEW.id_fusionnee_dans, NEW.motif_ecartement)
     IS DISTINCT FROM
     (OLD.intitule, OLD.synthese, OLD.propositions_retenues, OLD.statut, OLD.id_fusionnee_dans, OLD.motif_ecartement) THEN
    RAISE EXCEPTION 'RG-56 : préoccupation verrouillée, créer d''abord une nouvelle version du livre blanc régional' USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER trg_preoccupation_controle BEFORE UPDATE ON preoccupation FOR EACH ROW EXECUTE FUNCTION preoccupation_controler();

-- RG-53, RG-54, RG-55, RG-56, RG-61, RG-65 : publication et immuabilité des versions de livre blanc
CREATE OR REPLACE FUNCTION version_livre_blanc_controler() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  lb livre_blanc%ROWTYPE;
  ph text;
BEGIN
  SELECT * INTO lb FROM livre_blanc WHERE id_livre_blanc = NEW.id_livre_blanc;
  SELECT phase INTO ph FROM edition WHERE id_edition = lb.id_edition;

  IF TG_OP = 'UPDATE' AND OLD.statut IN ('PUBLIEE','REMPLACEE') THEN
    -- Seules transitions admises : PUBLIEE -> REMPLACEE, et rattachement unique des fichiers générés
    IF (NEW.introduction, NEW.contenu_fige, NEW.parametres_figes, NEW.empreinte_sha256, NEW.date_validation,
        NEW.lieu_validation, NEW.id_fichier_pv, NEW.publiee_le, NEW.numero, NEW.resume_changements)
       IS DISTINCT FROM
       (OLD.introduction, OLD.contenu_fige, OLD.parametres_figes, OLD.empreinte_sha256, OLD.date_validation,
        OLD.lieu_validation, OLD.id_fichier_pv, OLD.publiee_le, OLD.numero, OLD.resume_changements)
       OR (OLD.id_fichier_pdf IS NOT NULL AND NEW.id_fichier_pdf IS DISTINCT FROM OLD.id_fichier_pdf)
       OR (OLD.id_fichier_docx IS NOT NULL AND NEW.id_fichier_docx IS DISTINCT FROM OLD.id_fichier_docx)
       OR (OLD.statut = 'REMPLACEE' AND NEW.statut <> 'REMPLACEE')
       OR (OLD.statut = 'PUBLIEE' AND NEW.statut NOT IN ('PUBLIEE','REMPLACEE')) THEN
      RAISE EXCEPTION 'RG-54 : une version publiée est figée' USING ERRCODE = 'P0001';
    END IF;
    RETURN NEW;
  END IF;

  IF NEW.statut = 'BROUILLON' AND TG_OP = 'INSERT' AND lb.type = 'REGIONAL' THEN
    -- Une nouvelle version rouvre le travail sur les préoccupations de l'UTR (RG-56)
    UPDATE preoccupation SET verrouillee = false
     WHERE id_edition = lb.id_edition AND id_utr = lb.id_utr AND verrouillee;
  END IF;

  IF NEW.statut = 'PUBLIEE' AND (TG_OP = 'INSERT' OR OLD.statut = 'BROUILLON') THEN
    IF lb.type = 'REGIONAL' THEN
      IF ph <> 'CONSOLIDATION_REGIONALE' THEN
        RAISE EXCEPTION 'RG-53 : un livre blanc régional se publie en phase de consolidation régionale' USING ERRCODE = 'P0001';
      END IF;
      IF NEW.date_validation IS NULL THEN
        RAISE EXCEPTION 'RG-55 : la date de validation régionale est obligatoire' USING ERRCODE = 'P0001';
      END IF;
      IF EXISTS (SELECT 1 FROM contribution WHERE id_edition = lb.id_edition AND id_utr = lb.id_utr AND statut = 'EN_MODERATION') THEN
        RAISE EXCEPTION 'RG-53 : des contributions de l''UTR sont encore en modération' USING ERRCODE = 'P0001';
      END IF;
      IF EXISTS (SELECT 1 FROM preoccupation WHERE id_edition = lb.id_edition AND id_utr = lb.id_utr AND statut = 'PROPOSEE') THEN
        RAISE EXCEPTION 'RG-53 : toutes les préoccupations doivent être validées, fusionnées ou écartées' USING ERRCODE = 'P0001';
      END IF;
      UPDATE preoccupation SET verrouillee = true WHERE id_edition = lb.id_edition AND id_utr = lb.id_utr;
    ELSE
      IF ph <> 'ETATS_GENERAUX' THEN
        RAISE EXCEPTION 'RG-65 : le livre blanc national se publie en phase d''états généraux' USING ERRCODE = 'P0001';
      END IF;
      IF EXISTS (SELECT 1 FROM convergence WHERE id_edition = lb.id_edition AND statut = 'PROPOSEE') THEN
        RAISE EXCEPTION 'RG-63 : toutes les convergences doivent être arbitrées avant publication' USING ERRCODE = 'P0001';
      END IF;
    END IF;
    UPDATE version_livre_blanc SET statut = 'REMPLACEE', remplacee_le = now()
     WHERE id_livre_blanc = NEW.id_livre_blanc AND statut = 'PUBLIEE' AND id_version <> NEW.id_version;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER trg_version_livre_blanc_controle BEFORE INSERT OR UPDATE ON version_livre_blanc
  FOR EACH ROW EXECUTE FUNCTION version_livre_blanc_controler();

-- RG-71, RG-73 : cible et retrait des engagements
CREATE OR REPLACE FUNCTION engagement_controler() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  c candidat%ROWTYPE;
  e edition%ROWTYPE;
BEGIN
  SELECT * INTO c FROM candidat WHERE id_candidat = NEW.id_candidat;
  SELECT * INTO e FROM edition WHERE id_edition = c.id_edition;
  IF TG_OP = 'INSERT' THEN
    IF e.phase <> 'ENGAGEMENTS' THEN
      RAISE EXCEPTION 'RG-71 : les engagements se déclarent pendant la phase ENGAGEMENTS' USING ERRCODE = 'P0001';
    END IF;
    IF c.type_election = 'PRESIDENTIELLE' THEN
      IF NEW.id_convergence IS NULL OR NOT EXISTS (
           SELECT 1 FROM inclusion_convergence ic JOIN version_livre_blanc v USING (id_version)
            WHERE ic.id_convergence = NEW.id_convergence AND v.statut = 'PUBLIEE') THEN
        RAISE EXCEPTION 'RG-71 : un candidat à la présidentielle s''engage sur une priorité du LBN publié' USING ERRCODE = 'P0001';
      END IF;
    ELSE
      IF NEW.id_preoccupation IS NULL OR NOT EXISTS (
           SELECT 1 FROM inclusion_preoccupation ip JOIN version_livre_blanc v USING (id_version)
             JOIN preoccupation p ON p.id_preoccupation = ip.id_preoccupation
            WHERE ip.id_preoccupation = NEW.id_preoccupation AND v.statut = 'PUBLIEE' AND p.id_utr = c.id_utr) THEN
        RAISE EXCEPTION 'RG-71 : un candidat aux régionales s''engage sur une préoccupation du LBR publié de son UTR' USING ERRCODE = 'P0001';
      END IF;
    END IF;
  ELSIF NEW.statut = 'RETIRE' AND OLD.statut = 'DECLARE' THEN
    IF e.date_election IS NOT NULL AND current_date >= e.date_election THEN
      RAISE EXCEPTION 'RG-73 : un engagement ne peut plus être retiré à partir de la date de l''élection' USING ERRCODE = 'P0001';
    END IF;
  ELSIF OLD.statut = 'RETIRE' THEN
    RAISE EXCEPTION 'RG-73 : un engagement retiré est définitif' USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER trg_engagement_controle BEFORE INSERT OR UPDATE ON engagement FOR EACH ROW EXECUTE FUNCTION engagement_controler();

-- RG-74 : suivi réservé aux engagements des élus, en phase SUIVI
CREATE OR REPLACE FUNCTION suivi_controler() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NOT EXISTS (
       SELECT 1 FROM engagement en JOIN candidat c USING (id_candidat) JOIN edition e ON e.id_edition = c.id_edition
        WHERE en.id_engagement = NEW.id_engagement AND en.statut = 'DECLARE' AND c.statut = 'ELU' AND e.phase = 'SUIVI') THEN
    RAISE EXCEPTION 'RG-74 : suivi possible uniquement pour un engagement déclaré d''un élu, en phase SUIVI' USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER trg_suivi_controle BEFORE INSERT ON suivi_realisation FOR EACH ROW EXECUTE FUNCTION suivi_controler();

-- =============================================================================
-- 9. VUES D'ANALYSE (entrées du moteur de scores, §10.3 et RG-51)
-- =============================================================================
CREATE OR REPLACE VIEW v_statistiques_preoccupation AS
WITH contributions_publiees AS (
  SELECT c.*, t.id_departement,
         CASE c.urgence WHEN 'FAIBLE' THEN 1 WHEN 'MOYENNE' THEN 2 WHEN 'ELEVEE' THEN 3 ELSE 4 END AS urgence_num
  FROM contribution c JOIN territoire t ON t.id_territoire = c.id_territoire
  WHERE c.statut = 'PUBLIEE'
),
personnes AS (
  SELECT id_preoccupation, id_auteur AS id_personne FROM contributions_publiees WHERE id_auteur IS NOT NULL
  UNION
  SELECT cp.id_preoccupation, s.id_utilisateur FROM soutien s JOIN contributions_publiees cp USING (id_contribution)
),
terrain AS (
  SELECT cp.id_preoccupation,
         sum(LEAST(10, 1 + ct.nb_participants / 10))::int AS voix_terrain
  FROM contributions_publiees cp JOIN consultation_terrain ct USING (id_consultation)
  GROUP BY cp.id_preoccupation
)
SELECT p.id_preoccupation, p.id_edition, p.id_utr, p.id_secteur,
       count(DISTINCT cp.id_contribution)                                      AS nb_contributions,
       (SELECT count(*) FROM personnes pe WHERE pe.id_preoccupation = p.id_preoccupation)
         + COALESCE((SELECT voix_terrain FROM terrain te WHERE te.id_preoccupation = p.id_preoccupation), 0) AS nb_voix,
       avg(cp.urgence_num)::numeric(4,2)                                       AS urgence_moyenne,
       count(DISTINCT COALESCE(cp.id_departement, cp.id_territoire))           AS nb_unites_etendue,
       count(DISTINCT cp.id_organisation) FILTER (WHERE o.statut_verification = 'VERIFIEE') AS nb_organisations_verifiees
FROM preoccupation p
LEFT JOIN contributions_publiees cp ON cp.id_preoccupation = p.id_preoccupation
LEFT JOIN organisation o ON o.id_organisation = cp.id_organisation
WHERE p.statut IN ('PROPOSEE','VALIDEE')
GROUP BY p.id_preoccupation;
COMMENT ON VIEW v_statistiques_preoccupation IS 'Agrégats par préoccupation utilisés par le moteur de scores : contributions, voix (RG-51), urgence moyenne, étendue, organisations vérifiées.';

CREATE OR REPLACE VIEW v_etendue_utr AS
SELECT u.id_territoire AS id_utr,
       GREATEST(1, COALESCE(
         NULLIF((SELECT count(*) FROM territoire d WHERE d.id_utr = u.id_territoire AND d.niveau = 'DEPARTEMENT'), 0),
         (SELECT count(*) FROM territoire f WHERE f.id_utr = u.id_territoire AND f.est_selectionnable)))::int AS nb_unites_etendue
FROM territoire u WHERE u.est_utr;
COMMENT ON VIEW v_etendue_utr IS 'Nombre d''unités d''étendue par UTR : départements, ou à défaut mailles sélectionnables (dénominateur de la composante E).';

COMMIT;
