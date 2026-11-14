---
name: lbc-migration
description: Procédure pour toute évolution du schéma PostgreSQL du Livre Blanc Citoyen (table, colonne, contrainte, déclencheur, vue, index), de la nouvelle migration à la mise à jour des documents générés.
---

# Faire évoluer le schéma de la base

1. **Vérifier le besoin** dans `docs/DATABASE_SCHEMA.md` (§3 règles de passage, §5 où chaque règle est garantie). Si l'évolution touche le modèle conceptuel, mettre aussi à jour `database/mcd/mcd_spec.py` (entités, associations, cardinalités, règle).
2. **Créer une nouvelle migration** `database/migrations/NNNN_description.sql` (numéro suivant, sur 4 chiffres). Ne jamais modifier une migration déjà appliquée : la commande `pnpm migrer` refuse une empreinte changée.
   - Noms en français, sans accents, `snake_case`, alignés sur le glossaire du PRD.
   - Chaque table et chaque colonne nouvelle reçoit un `COMMENT ON` (le dictionnaire est généré à partir d'eux).
   - Énumérations : `text` + `CHECK (... IN (...))`. Contraintes nommées `ck_<table>_<objet>`, index `ix_`, uniques `ux_`.
   - Règle qui protège des données publiées : contrainte ou déclencheur, message d'erreur préfixé par la règle (`RAISE EXCEPTION 'RG-xx : …' USING ERRCODE = 'P0001'`).
3. **Tester** : ajouter les contrôles dans `database/tests/test_regles_gestion.sql` (un cas refusé avec `pg_temp.attendre_erreur(sql, 'RG-xx')`, un cas accepté), puis sur une base jetable :
   ```bash
   dropdb --if-exists lbc_test && createdb lbc_test
   for f in database/migrations/*.sql; do psql -d lbc_test -v ON_ERROR_STOP=1 -f "$f"; done
   psql -d lbc_test -v ON_ERROR_STOP=1 -f database/tests/test_regles_gestion.sql 2>&1 | tee /tmp/tests_sql.log
   ```
   Tous les contrôles doivent afficher OK et se terminer par « Tous les tests sont passés ».
4. **Régénérer** : `pnpm drizzle-kit pull` (schéma TypeScript), `python3 database/mcd/generer_mld.py` (MLD et dictionnaire), `python3 database/mcd/generer_mcd.py` et `generer_sat.py` si le MCD change, `python3 scripts/docs/remplir_database_schema.py /tmp/tests_sql.log`.
5. **Documenter** : tableau RG → mécanisme (`docs/_templates/DATABASE_SCHEMA.tpl.md` §5), PRD si une règle change (avec une ligne dans l'historique des versions), puis `python3 scripts/docs/controle_coherence.py` doit afficher `ANOMALIES 0`.
6. **Code** : adapter services et tests d'intégration ; les erreurs `P0001`, `23505`, `23514` sont converties par l'utilitaire d'erreurs (API §2.3) : ajouter la traduction du nom de toute nouvelle contrainte.
