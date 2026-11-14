-- =============================================================================
-- Tests des règles de gestion portées par la base (à exécuter sur une base vide
-- après la migration 0001). Chaque test affiche OK ou lève une exception.
-- =============================================================================
\set ON_ERROR_STOP 1
SET client_min_messages = warning;

CREATE OR REPLACE FUNCTION pg_temp.attendre_erreur(p_sql text, p_regle text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE '%' || p_regle || '%' OR p_regle = '*' THEN
      RAISE NOTICE 'OK  % rejeté comme attendu', p_regle;
      RETURN;
    END IF;
    RAISE EXCEPTION 'ÉCHEC % : erreur inattendue : %', p_regle, SQLERRM;
  END;
  RAISE EXCEPTION 'ÉCHEC % : l''instruction aurait dû être rejetée : %', p_regle, p_sql;
END $$;

SET client_min_messages = notice;

-- ---------------------------------------------------------------- jeu de données
INSERT INTO territoire(id_territoire, code, libelle, niveau, est_utr, population) VALUES
  ('00000000-0000-7000-8000-000000000001', 'DIS-GDO', 'Gôh-Djiboua', 'DISTRICT', false, NULL),
  ('00000000-0000-7000-8000-000000000002', 'DA-ABJ', 'Abidjan', 'DISTRICT_AUTONOME', true, 6300000);
UPDATE territoire SET id_utr = id_territoire WHERE est_utr;
INSERT INTO territoire(id_territoire, code, libelle, niveau, id_parent, est_utr, population) VALUES
  ('00000000-0000-7000-8000-000000000010', 'REG-GOH', 'Gôh', 'REGION', '00000000-0000-7000-8000-000000000001', true, 1000000);
UPDATE territoire SET id_utr = id_territoire WHERE code = 'REG-GOH';
INSERT INTO territoire(id_territoire, code, libelle, niveau, id_parent, id_utr) VALUES
  ('00000000-0000-7000-8000-000000000020', 'DEP-GAG', 'Gagnoa', 'DEPARTEMENT', '00000000-0000-7000-8000-000000000010', '00000000-0000-7000-8000-000000000010'),
  ('00000000-0000-7000-8000-000000000021', 'DEP-OUM', 'Oumé',   'DEPARTEMENT', '00000000-0000-7000-8000-000000000010', '00000000-0000-7000-8000-000000000010');
INSERT INTO territoire(id_territoire, code, libelle, niveau, id_parent, id_utr, id_departement, est_selectionnable) VALUES
  ('00000000-0000-7000-8000-000000000030', 'COM-GAG', 'Gagnoa', 'COMMUNE', '00000000-0000-7000-8000-000000000020', '00000000-0000-7000-8000-000000000010', '00000000-0000-7000-8000-000000000020', true),
  ('00000000-0000-7000-8000-000000000031', 'COM-OUM', 'Oumé',   'COMMUNE', '00000000-0000-7000-8000-000000000021', '00000000-0000-7000-8000-000000000010', '00000000-0000-7000-8000-000000000021', true),
  ('00000000-0000-7000-8000-000000000032', 'COM-COC', 'Cocody', 'COMMUNE', '00000000-0000-7000-8000-000000000002', '00000000-0000-7000-8000-000000000002', NULL, true);

INSERT INTO secteur(id_secteur, code, libelle, odd) VALUES
  ('00000000-0000-7000-8000-000000000100', 'SANTE', 'Santé', '{3}'),
  ('00000000-0000-7000-8000-000000000101', 'EAU', 'Eau potable et assainissement', '{6}');

INSERT INTO utilisateur(id_utilisateur, nom, prenoms, email, mot_de_passe_hash, annee_naissance, id_territoire_residence, consentement_le, email_verifie_le) VALUES
  ('00000000-0000-7000-8000-000000000200', 'Koné', 'Awa', 'awa@exemple.ci', 'x', 1992, '00000000-0000-7000-8000-000000000030', now(), now()),
  ('00000000-0000-7000-8000-000000000201', 'Yao', 'Kouassi', 'kouassi@exemple.ci', 'x', 1999, '00000000-0000-7000-8000-000000000031', now(), now()),
  ('00000000-0000-7000-8000-000000000202', 'Gnahoré', 'Marie', 'admin.goh@exemple.ci', 'x', 1980, '00000000-0000-7000-8000-000000000030', now(), now()),
  ('00000000-0000-7000-8000-000000000203', 'Diabaté', 'Issa', 'admin.national@exemple.ci', 'x', 1975, '00000000-0000-7000-8000-000000000032', now(), now()),
  ('00000000-0000-7000-8000-000000000204', 'Candidat', 'Un', 'candidat@exemple.ci', 'x', 1970, '00000000-0000-7000-8000-000000000032', now(), now());

\echo '--- Comptes'
SELECT pg_temp.attendre_erreur($$INSERT INTO utilisateur(nom, prenoms, email, mot_de_passe_hash, annee_naissance, consentement_le)
  VALUES ('Jeune','Ado','ado@exemple.ci','x', extract(year from now())::int - 16, now())$$, 'ck_utilisateur_age');
SELECT pg_temp.attendre_erreur($$INSERT INTO utilisateur(nom, prenoms, email, mot_de_passe_hash, consentement_le)
  VALUES ('Koné','Awa','AWA@exemple.ci','x', now())$$, 'ux_utilisateur_email');
SELECT pg_temp.attendre_erreur($$INSERT INTO affectation(id_utilisateur, role, id_utr)
  VALUES ('00000000-0000-7000-8000-000000000202','ADMIN_REGIONAL','00000000-0000-7000-8000-000000000020')$$, 'D-04');
INSERT INTO affectation(id_utilisateur, role, id_utr) VALUES ('00000000-0000-7000-8000-000000000202','ADMIN_REGIONAL','00000000-0000-7000-8000-000000000010');
INSERT INTO affectation(id_utilisateur, role) VALUES ('00000000-0000-7000-8000-000000000203','ADMIN_NATIONAL');
SELECT pg_temp.attendre_erreur($$INSERT INTO affectation(id_utilisateur, role) VALUES ('00000000-0000-7000-8000-000000000202','ADMIN_REGIONAL')$$, 'ck_affectation_perimetre');

INSERT INTO organisation(id_organisation, denomination, type, id_territoire_siege, id_representant) VALUES
  ('00000000-0000-7000-8000-000000000300', 'Association des jeunes d''Oumé', 'ASSOCIATION', '00000000-0000-7000-8000-000000000031', '00000000-0000-7000-8000-000000000201');
SELECT pg_temp.attendre_erreur($$INSERT INTO organisation(denomination, type, id_territoire_siege, id_representant)
  VALUES ('Deuxième organisation', 'ONG', '00000000-0000-7000-8000-000000000031', '00000000-0000-7000-8000-000000000201')$$, 'organisation_id_representant_key');
SELECT pg_temp.attendre_erreur($$UPDATE organisation SET statut_verification = 'REJETEE', verifiee_le = now(),
  id_verificateur = '00000000-0000-7000-8000-000000000202' WHERE id_organisation = '00000000-0000-7000-8000-000000000300'$$, 'ck_organisation_rejet');
UPDATE organisation SET statut_verification = 'VERIFIEE', verifiee_le = now(), id_verificateur = '00000000-0000-7000-8000-000000000202'
 WHERE id_organisation = '00000000-0000-7000-8000-000000000300';

\echo '--- Éditions'
INSERT INTO edition(id_edition, libelle, annee_echeance, parametres) VALUES
  ('00000000-0000-7000-8000-000000000400', 'Édition 2030', 2030,
   '{"seuils":{"suggestion":0.20,"rattachement":0.30,"doublon":0.60,"convergence":0.28},
     "ponderations_regionales":{"voix":0.40,"urgence":0.25,"etendue":0.20,"collectif":0.15,"diviseur_collectif":3},
     "ponderations_nationales":{"utr":0.45,"population":0.30,"score_regional":0.25}}');
SELECT pg_temp.attendre_erreur($$INSERT INTO edition(libelle, annee_echeance, parametres) VALUES ('Sans paramètres', 2031, '{}')$$, 'ck_edition_parametres');
SELECT pg_temp.attendre_erreur($$UPDATE edition SET phase = 'ETATS_GENERAUX' WHERE id_edition = '00000000-0000-7000-8000-000000000400'$$, 'RG-03');
UPDATE edition SET phase = 'COLLECTE' WHERE id_edition = '00000000-0000-7000-8000-000000000400';
SELECT pg_temp.attendre_erreur($$UPDATE edition SET parametres = parametres || '{"x":1}' WHERE id_edition = '00000000-0000-7000-8000-000000000400'$$, 'RG-02');
INSERT INTO edition(id_edition, libelle, annee_echeance, parametres) VALUES
  ('00000000-0000-7000-8000-000000000401', 'Édition 2035', 2035, '{"seuils":{},"ponderations_regionales":{},"ponderations_nationales":{}}');
SELECT pg_temp.attendre_erreur($$UPDATE edition SET phase = 'COLLECTE' WHERE id_edition = '00000000-0000-7000-8000-000000000401'$$, 'ux_edition_active');

\echo '--- Contributions'
INSERT INTO preoccupation(id_preoccupation, reference, id_edition, id_utr, id_secteur, intitule) VALUES
  ('00000000-0000-7000-8000-000000000500', prochaine_reference('P-2030-GOH', 4), '00000000-0000-7000-8000-000000000400',
   '00000000-0000-7000-8000-000000000010', '00000000-0000-7000-8000-000000000100', 'Manque d''équipements à la maternité');
INSERT INTO contribution(id_contribution, reference, id_edition, source, id_auteur, titre, constat, proposition, id_secteur, id_territoire, id_utr, urgence, id_preoccupation, mode_rattachement)
VALUES ('00000000-0000-7000-8000-000000000600', prochaine_reference('C-2030-GOH'), '00000000-0000-7000-8000-000000000400', 'EN_LIGNE',
        '00000000-0000-7000-8000-000000000200', 'Maternité sous-équipée à Gagnoa',
        'La maternité du quartier manque de lits, de couveuses et de matériel d''accouchement.',
        'Équiper la maternité en lits, couveuses et matériel adapté.',
        '00000000-0000-7000-8000-000000000100', '00000000-0000-7000-8000-000000000030', '00000000-0000-7000-8000-000000000002',
        'ELEVEE', '00000000-0000-7000-8000-000000000500', 'AUTO');
UPDATE preoccupation SET id_contribution_representative = '00000000-0000-7000-8000-000000000600' WHERE id_preoccupation = '00000000-0000-7000-8000-000000000500';
-- RG-30 : une contribution préparée hors connexion n'est enregistrée qu'une fois (identifiant de l'appareil)
INSERT INTO contribution(reference, id_edition, source, id_auteur, titre, constat, proposition, id_secteur, id_territoire, urgence, id_preoccupation, mode_rattachement, id_client, saisie_le)
VALUES (prochaine_reference('C-2030-GOH'), '00000000-0000-7000-8000-000000000400', 'EN_LIGNE', '00000000-0000-7000-8000-000000000200',
        'Maternité sans couveuse à Gagnoa', 'Les prématurés doivent être transférés faute de couveuse à la maternité.',
        'Installer au moins deux couveuses à la maternité.', '00000000-0000-7000-8000-000000000100',
        '00000000-0000-7000-8000-000000000030', 'ELEVEE', '00000000-0000-7000-8000-000000000500', 'AUTO',
        '0193a000-0000-7000-8000-00000000c11e', now() - interval '2 days');
\echo 'OK  RG-30 contribution préparée hors connexion acceptée'
SELECT pg_temp.attendre_erreur($$INSERT INTO contribution(reference, id_edition, source, id_auteur, titre, constat, proposition, id_secteur, id_territoire, urgence, id_preoccupation, mode_rattachement, id_client)
VALUES ('X9', '00000000-0000-7000-8000-000000000400', 'EN_LIGNE', '00000000-0000-7000-8000-000000000200',
        'Maternité sans couveuse à Gagnoa', 'Les prématurés doivent être transférés faute de couveuse à la maternité.',
        'Installer au moins deux couveuses à la maternité.', '00000000-0000-7000-8000-000000000100',
        '00000000-0000-7000-8000-000000000030', 'ELEVEE', '00000000-0000-7000-8000-000000000500', 'AUTO',
        '0193a000-0000-7000-8000-00000000c11e')$$, 'ux_contribution_id_client');
SELECT pg_temp.attendre_erreur($$INSERT INTO contribution(reference, id_edition, source, id_auteur, titre, constat, proposition, id_secteur, id_territoire, urgence, id_preoccupation, mode_rattachement, saisie_le)
VALUES ('X10', '00000000-0000-7000-8000-000000000400', 'EN_LIGNE', '00000000-0000-7000-8000-000000000200',
        'Date de saisie dans le futur', 'Une date de rédaction postérieure à la réception est impossible.',
        'Refuser une telle contribution.', '00000000-0000-7000-8000-000000000100',
        '00000000-0000-7000-8000-000000000030', 'FAIBLE', '00000000-0000-7000-8000-000000000500', 'AUTO',
        now() + interval '1 day')$$, 'ck_contribution_saisie');
DO $$ BEGIN
  IF (SELECT id_utr FROM contribution WHERE id_contribution = '00000000-0000-7000-8000-000000000600') <> '00000000-0000-7000-8000-000000000010' THEN
    RAISE EXCEPTION 'ÉCHEC RG-22 : UTR non déduite du territoire';
  END IF;
  RAISE NOTICE 'OK  RG-22 UTR déduite du territoire (valeur fournie ignorée)';
END $$;
SELECT pg_temp.attendre_erreur($$INSERT INTO contribution(reference, id_edition, source, id_auteur, titre, constat, proposition, id_secteur, id_territoire, id_utr, urgence, id_preoccupation, mode_rattachement)
VALUES ('X1', '00000000-0000-7000-8000-000000000400', 'EN_LIGNE', '00000000-0000-7000-8000-000000000200', 'Titre suffisamment long',
        'Un constat de plus de trente caractères au minimum.', 'Une proposition de plus de vingt caractères.',
        '00000000-0000-7000-8000-000000000100', '00000000-0000-7000-8000-000000000020', '00000000-0000-7000-8000-000000000010', 'FAIBLE',
        '00000000-0000-7000-8000-000000000500', 'AUTO')$$, 'RG-21');
SELECT pg_temp.attendre_erreur($$INSERT INTO contribution(reference, id_edition, source, id_auteur, titre, constat, proposition, id_secteur, id_territoire, id_utr, urgence, id_preoccupation, mode_rattachement)
VALUES ('X2', '00000000-0000-7000-8000-000000000400', 'EN_LIGNE', '00000000-0000-7000-8000-000000000200', 'Titre suffisamment long',
        'Un constat de plus de trente caractères au minimum.', 'Une proposition de plus de vingt caractères.',
        '00000000-0000-7000-8000-000000000101', '00000000-0000-7000-8000-000000000030', '00000000-0000-7000-8000-000000000010', 'FAIBLE',
        '00000000-0000-7000-8000-000000000500', 'AUTO')$$, 'RG-24');
SELECT pg_temp.attendre_erreur($$INSERT INTO contribution(reference, id_edition, source, id_auteur, titre, constat, proposition, id_secteur, id_territoire, id_utr, urgence)
VALUES ('X3', '00000000-0000-7000-8000-000000000400', 'EN_LIGNE', '00000000-0000-7000-8000-000000000200', 'Titre suffisamment long',
        'Un constat de plus de trente caractères au minimum.', 'Une proposition de plus de vingt caractères.',
        '00000000-0000-7000-8000-000000000100', '00000000-0000-7000-8000-000000000030', '00000000-0000-7000-8000-000000000010', 'FAIBLE')$$, 'ck_contribution_rattachement');
SELECT pg_temp.attendre_erreur($$INSERT INTO contribution(reference, id_edition, source, id_auteur, id_organisation, titre, constat, proposition, id_secteur, id_territoire, id_utr, urgence, id_preoccupation, mode_rattachement)
VALUES ('X4', '00000000-0000-7000-8000-000000000400', 'EN_LIGNE', '00000000-0000-7000-8000-000000000200', '00000000-0000-7000-8000-000000000300', 'Titre suffisamment long',
        'Un constat de plus de trente caractères au minimum.', 'Une proposition de plus de vingt caractères.',
        '00000000-0000-7000-8000-000000000100', '00000000-0000-7000-8000-000000000030', '00000000-0000-7000-8000-000000000010', 'FAIBLE',
        '00000000-0000-7000-8000-000000000500', 'AUTO')$$, 'RG-23');
SELECT pg_temp.attendre_erreur($$INSERT INTO contribution(reference, id_edition, source, id_auteur, titre, constat, proposition, id_secteur, id_territoire, id_utr, urgence, id_preoccupation, mode_rattachement)
VALUES ('X5', '00000000-0000-7000-8000-000000000400', 'EN_LIGNE', '00000000-0000-7000-8000-000000000200', 'Court',
        'Un constat de plus de trente caractères au minimum.', 'Une proposition de plus de vingt caractères.',
        '00000000-0000-7000-8000-000000000100', '00000000-0000-7000-8000-000000000030', '00000000-0000-7000-8000-000000000010', 'FAIBLE',
        '00000000-0000-7000-8000-000000000500', 'AUTO')$$, 'contribution_titre_check');

-- contribution de l'association (Kouassi, résident d'Oumé, contribue pour Gagnoa → hors résidence ? non : même UTR)
INSERT INTO contribution(id_contribution, reference, id_edition, source, id_auteur, id_organisation, titre, constat, proposition, id_secteur, id_territoire, id_utr, urgence, id_preoccupation, mode_rattachement)
VALUES ('00000000-0000-7000-8000-000000000601', prochaine_reference('C-2030-GOH'), '00000000-0000-7000-8000-000000000400', 'EN_LIGNE',
        '00000000-0000-7000-8000-000000000201', '00000000-0000-7000-8000-000000000300', 'Maternité de Gagnoa : matériel insuffisant',
        'Les femmes accouchent dans des conditions difficiles faute de matériel à la maternité.',
        'Doter la maternité de matériel moderne et de lits supplémentaires.',
        '00000000-0000-7000-8000-000000000100', '00000000-0000-7000-8000-000000000031', '00000000-0000-7000-8000-000000000010',
        'CRITIQUE', '00000000-0000-7000-8000-000000000500', 'AUTO');

\echo '--- Historisation (RG-25)'
UPDATE contribution SET titre = 'Maternité de Gagnoa sous-équipée' WHERE id_contribution = '00000000-0000-7000-8000-000000000600';
DO $$ BEGIN
  IF (SELECT version FROM contribution WHERE id_contribution = '00000000-0000-7000-8000-000000000600') <> 2
     OR (SELECT count(*) FROM version_contribution WHERE id_contribution = '00000000-0000-7000-8000-000000000600') <> 1 THEN
    RAISE EXCEPTION 'ÉCHEC RG-25 : historisation';
  END IF;
  RAISE NOTICE 'OK  RG-25 ancienne version archivée, numéro de version incrémenté';
END $$;

\echo '--- Soutiens et signalements'
SELECT pg_temp.attendre_erreur($$INSERT INTO soutien(id_utilisateur, id_contribution) VALUES ('00000000-0000-7000-8000-000000000200','00000000-0000-7000-8000-000000000600')$$, 'RG-27');
INSERT INTO soutien(id_utilisateur, id_contribution) VALUES ('00000000-0000-7000-8000-000000000201','00000000-0000-7000-8000-000000000600');
INSERT INTO soutien(id_utilisateur, id_contribution) VALUES ('00000000-0000-7000-8000-000000000203','00000000-0000-7000-8000-000000000600');
SELECT pg_temp.attendre_erreur($$INSERT INTO soutien(id_utilisateur, id_contribution) VALUES ('00000000-0000-7000-8000-000000000201','00000000-0000-7000-8000-000000000600')$$, 'soutien_pkey');
INSERT INTO signalement(id_utilisateur, id_contribution, motif) VALUES ('00000000-0000-7000-8000-000000000203','00000000-0000-7000-8000-000000000601','HORS_SUJET');
DO $$ BEGIN
  IF (SELECT nb_signalements FROM contribution WHERE id_contribution = '00000000-0000-7000-8000-000000000601') <> 1 THEN
    RAISE EXCEPTION 'ÉCHEC RG-40 : compteur';
  END IF;
  RAISE NOTICE 'OK  RG-40 signalement compté';
END $$;
SELECT pg_temp.attendre_erreur($$INSERT INTO decision_moderation(id_contribution, id_administrateur, action, motif, commentaire)
  VALUES ('00000000-0000-7000-8000-000000000601','00000000-0000-7000-8000-000000000202','RETIRER',NULL,'x')$$, 'ck_decision_motif');

\echo '--- Voix (RG-51) : Awa (auteure) + Kouassi (auteur et soutien, compté une fois) + Issa (soutien) = 3'
DO $$ DECLARE v int; BEGIN
  SELECT nb_voix INTO v FROM v_statistiques_preoccupation WHERE id_preoccupation = '00000000-0000-7000-8000-000000000500';
  IF v <> 3 THEN RAISE EXCEPTION 'ÉCHEC RG-51 : % voix au lieu de 3', v; END IF;
  RAISE NOTICE 'OK  RG-51 une voix par personne et par préoccupation (3 voix)';
END $$;

\echo '--- Consultation de terrain (D-10) : 45 participants → 1 + 4 = 5 voix, soit 8 au total'
INSERT INTO consultation_terrain(id_consultation, id_edition, id_utr, id_territoire_lieu, intitule, date_consultation, nb_participants, importee_par)
VALUES ('00000000-0000-7000-8000-000000000700', '00000000-0000-7000-8000-000000000400', '00000000-0000-7000-8000-000000000010',
        '00000000-0000-7000-8000-000000000031', 'Atelier de Oumé', current_date, 45, '00000000-0000-7000-8000-000000000202');
INSERT INTO contribution(reference, id_edition, source, id_consultation, titre, constat, proposition, id_secteur, id_territoire, id_utr, urgence, id_preoccupation, mode_rattachement)
VALUES (prochaine_reference('C-2030-GOH'), '00000000-0000-7000-8000-000000000400', 'TERRAIN', '00000000-0000-7000-8000-000000000700',
        'Maternité de Oumé sans matériel', 'Les participants signalent l''absence de matériel à la maternité de Oumé.',
        'Équiper la maternité de Oumé.', '00000000-0000-7000-8000-000000000100', '00000000-0000-7000-8000-000000000031',
        '00000000-0000-7000-8000-000000000010', 'ELEVEE', '00000000-0000-7000-8000-000000000500', 'MANUEL');
DO $$ DECLARE v int; e int; BEGIN
  SELECT nb_voix, nb_unites_etendue INTO v, e FROM v_statistiques_preoccupation WHERE id_preoccupation = '00000000-0000-7000-8000-000000000500';
  IF v <> 8 THEN RAISE EXCEPTION 'ÉCHEC D-10 : % voix au lieu de 8', v; END IF;
  IF e <> 2 THEN RAISE EXCEPTION 'ÉCHEC étendue : % départements au lieu de 2', e; END IF;
  RAISE NOTICE 'OK  D-10 poids des consultations de terrain (8 voix) ; étendue = 2 départements';
END $$;

\echo '--- Recherche et similarité'
DO $$ DECLARE s real; BEGIN
  SELECT similarite_textes(a.texte_normalise, a.lexemes, b.texte_normalise, b.lexemes) INTO s FROM contribution a, contribution b
   WHERE a.id_contribution = '00000000-0000-7000-8000-000000000600' AND b.id_contribution = '00000000-0000-7000-8000-000000000601';
  IF s < 0.30 THEN RAISE EXCEPTION 'ÉCHEC similarité composite trop faible : %', s; END IF;
  RAISE NOTICE 'OK  similarité composite entre deux contributions proches : % (seuil de rattachement 0,30)', round(s::numeric, 3);
  IF NOT EXISTS (SELECT 1 FROM contribution WHERE document_recherche @@ websearch_to_tsquery('french', immutable_unaccent('maternite equipement'))) THEN
    RAISE EXCEPTION 'ÉCHEC recherche plein texte';
  END IF;
  RAISE NOTICE 'OK  recherche plein texte insensible aux accents';
END $$;

\echo '--- Livre blanc régional (RG-53 à RG-56)'
UPDATE edition SET phase = 'CONSOLIDATION_REGIONALE' WHERE id_edition = '00000000-0000-7000-8000-000000000400';
SELECT pg_temp.attendre_erreur($$UPDATE contribution SET titre = 'Titre modifié trop tard' WHERE id_contribution = '00000000-0000-7000-8000-000000000600'$$, 'RG-25');
-- RG-20 : plus de dépôt en ligne hors collecte
SELECT pg_temp.attendre_erreur($$INSERT INTO contribution(reference, id_edition, source, id_auteur, titre, constat, proposition, id_secteur, id_territoire, urgence, id_preoccupation, mode_rattachement)
VALUES ('X6', '00000000-0000-7000-8000-000000000400', 'EN_LIGNE', '00000000-0000-7000-8000-000000000200', 'Dépôt après la clôture',
        'Un constat de plus de trente caractères au minimum.', 'Une proposition de plus de vingt caractères.',
        '00000000-0000-7000-8000-000000000100', '00000000-0000-7000-8000-000000000030', 'FAIBLE',
        '00000000-0000-7000-8000-000000000500', 'AUTO')$$, 'RG-20');
-- RG-28 : une contribution de terrain n'a pas d'auteur en ligne
SELECT pg_temp.attendre_erreur($$INSERT INTO contribution(reference, id_edition, source, id_auteur, id_consultation, titre, constat, proposition, id_secteur, id_territoire, urgence, id_preoccupation, mode_rattachement)
VALUES ('X7', '00000000-0000-7000-8000-000000000400', 'TERRAIN', '00000000-0000-7000-8000-000000000200', '00000000-0000-7000-8000-000000000700', 'Terrain avec auteur',
        'Un constat de plus de trente caractères au minimum.', 'Une proposition de plus de vingt caractères.',
        '00000000-0000-7000-8000-000000000100', '00000000-0000-7000-8000-000000000031', 'FAIBLE',
        '00000000-0000-7000-8000-000000000500', 'MANUEL')$$, 'ck_contribution_source');
-- RG-28 : l'import de terrain reste possible pendant la consolidation régionale
INSERT INTO contribution(reference, id_edition, source, id_consultation, titre, constat, proposition, id_secteur, id_territoire, urgence, id_preoccupation, mode_rattachement)
VALUES (prochaine_reference('C-2030-GOH'), '00000000-0000-7000-8000-000000000400', 'TERRAIN', '00000000-0000-7000-8000-000000000700',
        'Matériel manquant à la maternité', 'Compte rendu tardif de l''atelier : le matériel d''accouchement manque toujours.',
        'Compléter l''équipement de la maternité.', '00000000-0000-7000-8000-000000000100', '00000000-0000-7000-8000-000000000031',
        'ELEVEE', '00000000-0000-7000-8000-000000000500', 'MANUEL');
\echo 'OK  RG-28 import de terrain accepté en consolidation régionale'
INSERT INTO livre_blanc(id_livre_blanc, id_edition, type, id_utr) VALUES
  ('00000000-0000-7000-8000-000000000800', '00000000-0000-7000-8000-000000000400', 'REGIONAL', '00000000-0000-7000-8000-000000000010');
SELECT pg_temp.attendre_erreur($$INSERT INTO livre_blanc(id_edition, type, id_utr) VALUES ('00000000-0000-7000-8000-000000000400', 'REGIONAL', '00000000-0000-7000-8000-000000000010')$$, 'ux_livre_blanc');
SELECT pg_temp.attendre_erreur($$INSERT INTO livre_blanc(id_edition, type) VALUES ('00000000-0000-7000-8000-000000000400', 'REGIONAL')$$, 'ck_livre_blanc_type');
INSERT INTO version_livre_blanc(id_version, id_livre_blanc, numero, creee_par) VALUES
  ('00000000-0000-7000-8000-000000000810', '00000000-0000-7000-8000-000000000800', 1, '00000000-0000-7000-8000-000000000202');
SELECT pg_temp.attendre_erreur($$INSERT INTO version_livre_blanc(id_livre_blanc, numero, creee_par) VALUES ('00000000-0000-7000-8000-000000000800', 2, '00000000-0000-7000-8000-000000000202')$$, 'ux_version_brouillon');
SELECT pg_temp.attendre_erreur($$UPDATE version_livre_blanc SET statut='PUBLIEE', publiee_le=now(), publiee_par='00000000-0000-7000-8000-000000000202',
  contenu_fige='{}', parametres_figes='{}', empreinte_sha256=repeat('a',64), date_validation=current_date
  WHERE id_version='00000000-0000-7000-8000-000000000810'$$, 'RG-53');
UPDATE preoccupation SET statut='VALIDEE', validee_par='00000000-0000-7000-8000-000000000202', validee_le=now()
 WHERE id_preoccupation='00000000-0000-7000-8000-000000000500';
SELECT pg_temp.attendre_erreur($$UPDATE version_livre_blanc SET statut='PUBLIEE', publiee_le=now(), publiee_par='00000000-0000-7000-8000-000000000202',
  contenu_fige='{}', parametres_figes='{}', empreinte_sha256=repeat('a',64)
  WHERE id_version='00000000-0000-7000-8000-000000000810'$$, 'RG-55');
UPDATE version_livre_blanc SET statut='PUBLIEE', publiee_le=now(), publiee_par='00000000-0000-7000-8000-000000000202',
  contenu_fige='{"v":1}', parametres_figes='{}', empreinte_sha256=repeat('a',64), date_validation=current_date
 WHERE id_version='00000000-0000-7000-8000-000000000810';
INSERT INTO inclusion_preoccupation(id_version, id_preoccupation, rang, intitule_fige, score_fige, nb_voix_fige)
VALUES ('00000000-0000-7000-8000-000000000810', '00000000-0000-7000-8000-000000000500', 1, 'Manque d''équipements à la maternité', 72.5, 8);
SELECT pg_temp.attendre_erreur($$UPDATE version_livre_blanc SET contenu_fige='{"v":2}' WHERE id_version='00000000-0000-7000-8000-000000000810'$$, 'RG-54');
SELECT pg_temp.attendre_erreur($$UPDATE preoccupation SET intitule='Nouvel intitulé interdit' WHERE id_preoccupation='00000000-0000-7000-8000-000000000500'$$, 'RG-56');
SELECT pg_temp.attendre_erreur($$UPDATE edition SET phase='COLLECTE' WHERE id_edition='00000000-0000-7000-8000-000000000400'$$, 'RG-03');
-- Une nouvelle version déverrouille, sa publication remplace la précédente
INSERT INTO version_livre_blanc(id_version, id_livre_blanc, numero, creee_par) VALUES
  ('00000000-0000-7000-8000-000000000811', '00000000-0000-7000-8000-000000000800', 2, '00000000-0000-7000-8000-000000000202');
UPDATE preoccupation SET intitule='Maternités du Gôh sous-équipées' WHERE id_preoccupation='00000000-0000-7000-8000-000000000500';
SELECT pg_temp.attendre_erreur($$UPDATE version_livre_blanc SET statut='PUBLIEE', publiee_le=now(), publiee_par='00000000-0000-7000-8000-000000000202',
  contenu_fige='{"v":2}', parametres_figes='{}', empreinte_sha256=repeat('b',64), date_validation=current_date
  WHERE id_version='00000000-0000-7000-8000-000000000811'$$, 'ck_version_changements');
UPDATE version_livre_blanc SET statut='PUBLIEE', publiee_le=now(), publiee_par='00000000-0000-7000-8000-000000000202',
  contenu_fige='{"v":2}', parametres_figes='{}', empreinte_sha256=repeat('b',64), date_validation=current_date,
  resume_changements='Intitulé élargi à l''ensemble des maternités du Gôh.'
 WHERE id_version='00000000-0000-7000-8000-000000000811';
INSERT INTO inclusion_preoccupation(id_version, id_preoccupation, rang, intitule_fige, score_fige, nb_voix_fige)
VALUES ('00000000-0000-7000-8000-000000000811', '00000000-0000-7000-8000-000000000500', 1, 'Maternités du Gôh sous-équipées', 72.5, 8);
DO $$ BEGIN
  IF (SELECT statut FROM version_livre_blanc WHERE id_version='00000000-0000-7000-8000-000000000810') <> 'REMPLACEE' THEN
    RAISE EXCEPTION 'ÉCHEC RG-54 : version précédente non remplacée';
  END IF;
  RAISE NOTICE 'OK  RG-54/RG-56 nouvelle version publiée, précédente REMPLACEE, préoccupations reverrouillées';
END $$;

\echo '--- États généraux et livre blanc national (RG-61 à RG-65)'
UPDATE edition SET phase='ETATS_GENERAUX' WHERE id_edition='00000000-0000-7000-8000-000000000400';
INSERT INTO convergence(id_convergence, reference, id_edition, id_secteur, intitule, classe_calculee, nb_utr, population_couverte, score)
VALUES ('00000000-0000-7000-8000-000000000900', prochaine_reference('N-2030', 4), '00000000-0000-7000-8000-000000000400',
        '00000000-0000-7000-8000-000000000100', 'Équiper les maternités', 'SPECIFIQUE', 1, 1000000, 55);
UPDATE preoccupation SET id_convergence='00000000-0000-7000-8000-000000000900' WHERE id_preoccupation='00000000-0000-7000-8000-000000000500';
SELECT pg_temp.attendre_erreur($$UPDATE convergence SET statut='REJETEE' WHERE id_convergence='00000000-0000-7000-8000-000000000900'$$, 'ck_convergence_rejet');
SELECT pg_temp.attendre_erreur($$UPDATE convergence SET statut='RETENUE', classe='NATIONALE' WHERE id_convergence='00000000-0000-7000-8000-000000000900'$$, 'ck_convergence_reclassement');
INSERT INTO livre_blanc(id_livre_blanc, id_edition, type) VALUES ('00000000-0000-7000-8000-000000000801', '00000000-0000-7000-8000-000000000400', 'NATIONAL');
SELECT pg_temp.attendre_erreur($$INSERT INTO livre_blanc(id_edition, type) VALUES ('00000000-0000-7000-8000-000000000400', 'NATIONAL')$$, 'ux_livre_blanc');
INSERT INTO version_livre_blanc(id_version, id_livre_blanc, numero, creee_par) VALUES
  ('00000000-0000-7000-8000-000000000820', '00000000-0000-7000-8000-000000000801', 1, '00000000-0000-7000-8000-000000000203');
SELECT pg_temp.attendre_erreur($$UPDATE version_livre_blanc SET statut='PUBLIEE', publiee_le=now(), publiee_par='00000000-0000-7000-8000-000000000203',
  contenu_fige='{}', parametres_figes='{}', empreinte_sha256=repeat('c',64) WHERE id_version='00000000-0000-7000-8000-000000000820'$$, 'RG-63');
UPDATE convergence SET statut='RETENUE', classe='SPECIFIQUE' WHERE id_convergence='00000000-0000-7000-8000-000000000900';
INSERT INTO decision_etats_generaux(id_convergence, id_administrateur, action) VALUES ('00000000-0000-7000-8000-000000000900', '00000000-0000-7000-8000-000000000203', 'RETENIR');
UPDATE version_livre_blanc SET statut='PUBLIEE', publiee_le=now(), publiee_par='00000000-0000-7000-8000-000000000203',
  contenu_fige='{"n":1}', parametres_figes='{}', empreinte_sha256=repeat('c',64) WHERE id_version='00000000-0000-7000-8000-000000000820';
INSERT INTO inclusion_convergence(id_version, id_convergence, rang, classe_figee, intitule_fige, score_fige)
VALUES ('00000000-0000-7000-8000-000000000820', '00000000-0000-7000-8000-000000000900', 1, 'SPECIFIQUE', 'Équiper les maternités', 55);
\echo 'OK  LBN publié après arbitrage de toutes les convergences'

\echo '--- Engagements et suivi (RG-70 à RG-75)'
INSERT INTO candidat(id_candidat, id_utilisateur, id_edition, type_election, nom_affiche, cree_par) VALUES
  ('00000000-0000-7000-8000-000000000a00', '00000000-0000-7000-8000-000000000204', '00000000-0000-7000-8000-000000000400', 'PRESIDENTIELLE', 'Candidat Un', '00000000-0000-7000-8000-000000000203');
SELECT pg_temp.attendre_erreur($$INSERT INTO candidat(id_utilisateur, id_edition, type_election, nom_affiche, cree_par) VALUES
  ('00000000-0000-7000-8000-000000000200', '00000000-0000-7000-8000-000000000400', 'REGIONALE', 'Sans UTR', '00000000-0000-7000-8000-000000000203')$$, 'ck_candidat_utr');
SELECT pg_temp.attendre_erreur($$INSERT INTO engagement(id_candidat, id_convergence, echeance_annee, texte)
  VALUES ('00000000-0000-7000-8000-000000000a00', '00000000-0000-7000-8000-000000000900', 2032, 'Équiper toutes les maternités du pays.')$$, 'RG-71');
UPDATE edition SET phase='ENGAGEMENTS', date_election = current_date + 30 WHERE id_edition='00000000-0000-7000-8000-000000000400';
-- RG-28 : plus d'import de terrain après la consolidation régionale
SELECT pg_temp.attendre_erreur($$INSERT INTO contribution(reference, id_edition, source, id_consultation, titre, constat, proposition, id_secteur, id_territoire, urgence, id_preoccupation, mode_rattachement)
VALUES ('X8', '00000000-0000-7000-8000-000000000400', 'TERRAIN', '00000000-0000-7000-8000-000000000700', 'Import trop tardif',
        'Un constat de plus de trente caractères au minimum.', 'Une proposition de plus de vingt caractères.',
        '00000000-0000-7000-8000-000000000100', '00000000-0000-7000-8000-000000000031', 'FAIBLE',
        '00000000-0000-7000-8000-000000000500', 'MANUEL')$$, 'RG-28');
-- RG-65 : le livre blanc national ne se publie qu'en phase d'états généraux
INSERT INTO version_livre_blanc(id_version, id_livre_blanc, numero, creee_par, resume_changements) VALUES
  ('00000000-0000-7000-8000-000000000821', '00000000-0000-7000-8000-000000000801', 2, '00000000-0000-7000-8000-000000000203', 'Correction tardive.');
SELECT pg_temp.attendre_erreur($$UPDATE version_livre_blanc SET statut='PUBLIEE', publiee_le=now(), publiee_par='00000000-0000-7000-8000-000000000203',
  contenu_fige='{"n":2}', parametres_figes='{}', empreinte_sha256=repeat('d',64) WHERE id_version='00000000-0000-7000-8000-000000000821'$$, 'RG-65');
SELECT pg_temp.attendre_erreur($$INSERT INTO engagement(id_candidat, id_preoccupation, echeance_annee, texte)
  VALUES ('00000000-0000-7000-8000-000000000a00', '00000000-0000-7000-8000-000000000500', 2032, 'Engagement mal ciblé pour un candidat présidentiel.')$$, 'RG-71');
SELECT pg_temp.attendre_erreur($$INSERT INTO engagement(id_candidat, id_convergence, id_preoccupation, echeance_annee, texte)
  VALUES ('00000000-0000-7000-8000-000000000a00', '00000000-0000-7000-8000-000000000900', '00000000-0000-7000-8000-000000000500', 2032, 'Deux cibles à la fois, interdit.')$$, 'ck_engagement_cible');
INSERT INTO engagement(id_engagement, id_candidat, id_convergence, echeance_annee, texte)
VALUES ('00000000-0000-7000-8000-000000000b00', '00000000-0000-7000-8000-000000000a00', '00000000-0000-7000-8000-000000000900', 2032, 'Équiper toutes les maternités du pays.');
SELECT pg_temp.attendre_erreur($$INSERT INTO engagement(id_candidat, id_convergence, echeance_annee, texte)
  VALUES ('00000000-0000-7000-8000-000000000a00', '00000000-0000-7000-8000-000000000900', 2033, 'Second engagement sur la même priorité.')$$, 'ux_engagement_convergence');
SELECT pg_temp.attendre_erreur($$INSERT INTO suivi_realisation(id_engagement, etat, date_etat, description, saisi_par)
  VALUES ('00000000-0000-7000-8000-000000000b00', 'EN_COURS', current_date, 'Travaux lancés dans trois régions.', '00000000-0000-7000-8000-000000000203')$$, 'RG-74');
UPDATE edition SET phase='SUIVI' WHERE id_edition='00000000-0000-7000-8000-000000000400';
SELECT pg_temp.attendre_erreur($$INSERT INTO suivi_realisation(id_engagement, etat, date_etat, description, saisi_par)
  VALUES ('00000000-0000-7000-8000-000000000b00', 'EN_COURS', current_date, 'Candidat non élu : refus attendu.', '00000000-0000-7000-8000-000000000203')$$, 'RG-74');
UPDATE candidat SET statut='ELU' WHERE id_candidat='00000000-0000-7000-8000-000000000a00';
INSERT INTO suivi_realisation(id_suivi, id_engagement, etat, date_etat, description, saisi_par)
VALUES ('00000000-0000-7000-8000-000000000c00', '00000000-0000-7000-8000-000000000b00', 'EN_COURS', current_date,
        'Travaux lancés dans trois régions.', '00000000-0000-7000-8000-000000000203');
SELECT pg_temp.attendre_erreur($$INSERT INTO justificatif(id_suivi, type, libelle) VALUES ('00000000-0000-7000-8000-000000000c00', 'LIEN', 'Sans URL')$$, 'ck_justificatif_type');
INSERT INTO justificatif(id_suivi, type, url, libelle) VALUES ('00000000-0000-7000-8000-000000000c00', 'LIEN', 'https://exemple.ci/communique', 'Communiqué officiel');
\echo 'OK  suivi enregistré pour un élu, avec justificatif'

\echo '--- Audit (RG-45)'
INSERT INTO journal_audit(id_acteur, action, type_objet, id_objet) VALUES ('00000000-0000-7000-8000-000000000202', 'PREOCCUPATION.VALIDER', 'preoccupation', '00000000-0000-7000-8000-000000000500');
SELECT pg_temp.attendre_erreur($$UPDATE journal_audit SET action = 'X'$$, 'RG-45');
SELECT pg_temp.attendre_erreur($$DELETE FROM journal_audit$$, 'RG-45');

\echo '=== Tous les tests sont passés ==='
