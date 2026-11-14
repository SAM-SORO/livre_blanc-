---
name: lbc-regle-de-gestion
description: Procédure pour implémenter, modifier ou vérifier une règle de gestion RG-xx du Livre Blanc Citoyen, en décidant où elle est garantie (base ou application) et comment elle est testée.
---

# Implémenter ou modifier une règle de gestion

1. **Retrouver la règle** dans `docs/PRD.md` §9 et son mécanisme actuel dans `docs/DATABASE_SCHEMA.md` §5 (colonnes « garantie en base », « garantie applicative », « test SQL »).
2. **Décider où la garantir** :
   - en base (contrainte, index unique partiel, déclencheur) si elle protège l'intégrité des données ou des versions publiées, ou si elle doit tenir quel que soit le code qui écrit ;
   - dans l'application si elle dépend du contexte de la requête (utilisateur connecté, limite de débit, envoi de notification) ;
   - souvent les deux : la base garantit, l'application vérifie avant pour afficher un message clair.
3. **Écrire le test d'abord** : test SQL (skill `lbc-migration`) pour la base, test d'intégration du service pour l'application, avec le cas refusé (code `REGLE_DE_GESTION`, `regle: "RG-xx"`) et le cas accepté.
4. **Implémenter**, puis vérifier que le message d'erreur dit à l'utilisateur ce qu'il peut faire (exemple : « 4 préoccupations sont encore à traiter. » avec un lien vers la liste).
5. **Modifier une règle existante** : c'est une décision de l'équipe. Mettre à jour le PRD (règle et historique des versions), le tableau DATABASE_SCHEMA §5, le MCD si une cardinalité change, puis lancer `python3 scripts/docs/controle_coherence.py`.
6. **Paramètres** : une règle chiffrée (seuil, limite, pondération) lit sa valeur dans `edition.parametres` ; ne jamais l'écrire en dur.
