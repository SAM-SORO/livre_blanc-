# MLD — modèle logique des données (relationnel)

> Généré automatiquement depuis le schéma PostgreSQL migré (`generer_mld.py`). Ne pas modifier à la main.

Notation : **clé primaire** en gras, `#` devant une clé étrangère (table référencée entre crochets).

## Référentiels

- **TERRITOIRE** (**id_territoire**, code, code_pcode, libelle, niveau, #id_parent [territoire], est_utr, #id_utr [territoire], #id_departement [territoire], est_selectionnable, population, annee_population, date_debut_validite, date_fin_validite)
- **SECTEUR** (**id_secteur**, code, libelle, description, icone, odd, mots_cles, ordre, actif)
- **EDITION** (**id_edition**, libelle, annee_echeance, phase, date_ouverture_collecte, date_cloture_collecte, date_election, parametres, creee_le, #creee_par [utilisateur], modifie_le)

## Comptes et organisations

- **UTILISATEUR** (**id_utilisateur**, nom, prenoms, email, email_verifie_le, mot_de_passe_hash, telephone, sexe, annee_naissance, #id_territoire_residence [territoire], afficher_nom, statut, tentatives_echouees, verrouille_jusqua, consentement_le, inscrit_le, derniere_connexion_le, anonymise_le, modifie_le)
- **AFFECTATION** (**id_affectation**, #id_utilisateur [utilisateur], role, #id_utr [territoire], date_debut, date_fin, #attribuee_par [utilisateur], attribuee_le)
- **ORGANISATION** (**id_organisation**, denomination, type, numero_enregistrement, description, #id_territoire_siege [territoire], #id_representant [utilisateur], statut_verification, verifiee_le, #id_verificateur [utilisateur], motif_rejet, creee_le, modifie_le)
- **FICHIER** (**id_fichier**, chemin_stockage, nom_original, type_mime, taille_octets, empreinte_sha256, largeur, hauteur, #depose_par [utilisateur], depose_le)
- **NOTIFICATION** (**id_notification**, #id_utilisateur [utilisateur], type, titre, message, lien, creee_le, lue_le, email_envoye_le)

## Collecte et analyse régionale

- **CONSULTATION_TERRAIN** (**id_consultation**, #id_edition [edition], #id_utr [territoire], #id_territoire_lieu [territoire], intitule, date_consultation, nb_participants, description, #id_fichier_source [fichier], #importee_par [utilisateur], importee_le)
- **CONTRIBUTION** (**id_contribution**, reference, #id_edition [edition], source, #id_auteur [utilisateur], #id_organisation [organisation], #id_consultation [consultation_terrain], titre, constat, proposition, #id_secteur [secteur], #id_territoire [territoire], #id_utr [territoire], localite, urgence, tranche_population, hors_residence, statut, #id_preoccupation [preoccupation], mode_rattachement, similarite_rattachement, nb_signalements, version, deposee_le, modifie_le, id_client, saisie_le)
- **VERSION_CONTRIBUTION** (**id_version**, #id_contribution [contribution], numero, titre, constat, proposition, #id_secteur [secteur], #id_territoire [territoire], urgence, tranche_population, localite, enregistree_le)
- **ILLUSTRATION** (**#id_contribution** [contribution], **#id_fichier** [fichier], ordre)
- **SOUTIEN** (**#id_utilisateur** [utilisateur], **#id_contribution** [contribution], soutenu_le)
- **SIGNALEMENT** (**#id_utilisateur** [utilisateur], **#id_contribution** [contribution], motif, commentaire, signale_le, traite)
- **DECISION_MODERATION** (**id_decision**, #id_contribution [contribution], #id_administrateur [utilisateur], action, motif, commentaire, decidee_le)
- **PREOCCUPATION** (**id_preoccupation**, reference, #id_edition [edition], #id_utr [territoire], #id_secteur [secteur], intitule, synthese, propositions_retenues, statut, motif_ecartement, #id_fusionnee_dans [preoccupation], #id_contribution_representative [contribution], texte_reference, lexemes_reference, nb_contributions, nb_voix, score, score_detail, score_calcule_le, verrouillee, #id_convergence [convergence], #validee_par [utilisateur], validee_le, creee_le, modifie_le)

## Livres blancs et consolidation

- **LIVRE_BLANC** (**id_livre_blanc**, #id_edition [edition], type, #id_utr [territoire])
- **VERSION_LIVRE_BLANC** (**id_version**, #id_livre_blanc [livre_blanc], numero, statut, introduction, resume_changements, date_validation, lieu_validation, #id_fichier_pv [fichier], contenu_fige, parametres_figes, empreinte_sha256, #id_fichier_pdf [fichier], #id_fichier_docx [fichier], creee_le, #creee_par [utilisateur], publiee_le, #publiee_par [utilisateur], remplacee_le, modifie_le)
- **INCLUSION_PREOCCUPATION** (**#id_version** [version_livre_blanc], **#id_preoccupation** [preoccupation], rang, intitule_fige, score_fige, nb_voix_fige)
- **CALCUL_CONSOLIDATION** (**id_calcul**, #id_edition [edition], #lance_par [utilisateur], lance_le, termine_le, statut, parametres, rapport)
- **CONVERGENCE** (**id_convergence**, reference, #id_edition [edition], #id_secteur [secteur], #id_calcul [calcul_consolidation], origine, intitule, synthese, propositions, texte_assiste, statut, classe_calculee, classe, motif, #id_fusionnee_dans [convergence], nb_utr, population_couverte, score, score_detail, cohesion, creee_le, modifie_le)
- **INCLUSION_CONVERGENCE** (**#id_version** [version_livre_blanc], **#id_convergence** [convergence], rang, classe_figee, intitule_fige, score_fige)
- **DECISION_ETATS_GENERAUX** (**id_decision**, #id_convergence [convergence], #id_administrateur [utilisateur], action, motif, details, decidee_le)

## Engagements et suivi

- **CANDIDAT** (**id_candidat**, #id_utilisateur [utilisateur], #id_edition [edition], type_election, #id_utr [territoire], nom_affiche, parti, #id_fichier_photo [fichier], statut, cree_le, #cree_par [utilisateur])
- **ENGAGEMENT** (**id_engagement**, #id_candidat [candidat], #id_convergence [convergence], #id_preoccupation [preoccupation], echeance_annee, texte, statut, declare_le, retire_le)
- **SUIVI_REALISATION** (**id_suivi**, #id_engagement [engagement], etat, date_etat, description, #saisi_par [utilisateur], saisi_le, commentaire_candidat, commentaire_le)
- **JUSTIFICATIF** (**id_justificatif**, #id_suivi [suivi_realisation], type, url, #id_fichier [fichier], libelle)

## Tables techniques

- **COMPTEUR_REFERENCE** (**prefixe**, valeur)
- **JETON** (**id_jeton**, #id_utilisateur [utilisateur], type, jeton_hash, cree_le, expire_le, utilise_le)
- **JOURNAL_AUDIT** (**id_entree**, survenue_le, #id_acteur [utilisateur], action, type_objet, id_objet, avant, apres, motif, adresse_ip, id_requete)
- **SESSION** (**id_session**, #id_utilisateur [utilisateur], cree_le, derniere_activite_le, expire_le, revoquee_le, adresse_ip, agent_utilisateur)
- **TERME_INTERDIT** (**id_terme**, terme, actif)
