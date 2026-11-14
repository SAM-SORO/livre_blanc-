---
name: lbc-endpoint
description: Procédure pour ajouter ou modifier un point de l'API REST /api/v1 du Livre Blanc Citoyen, de la liste de référence aux tests d'autorisation.
---

# Ajouter ou modifier un point d'API

1. **Déclarer** le point dans `api/endpoints.py` : module, méthode, chemin (ressources en français, `{id}` ou `{utr}` pour le code de l'UTR), accès (`PUB`, `CON`, `CV`, `AUT`, `REP`, `AR`, `AN`, `CAND`), résumé, références PRD (F-xx, RG-xx), code de succès. Puis `python3 api/generer.py` : les tableaux de la doc et `api/openapi.yaml` sont régénérés ; valider le fichier OpenAPI (par exemple avec `openapi-spec-validator`).
2. **Schéma Zod** dans `shared/schemas/` (corps et paramètres), messages d'erreur en français qui disent quoi faire. Le même schéma sert au formulaire côté client.
3. **Route** dans `server/api/v1/...` : lire et valider, appeler le service, rien d'autre. Méthodes qui modifient : protection CSRF et vérification de l'en-tête `Origin` (déjà globales).
4. **Service** dans `server/modules/<module>/service.ts` :
   - `exiger(politique.<action>(acteur, ressource))` avant toute lecture sensible ; listes filtrées par périmètre dans la requête SQL ;
   - transaction ; `auditer(tx, …)` pour toute action d'administration ;
   - objets éditables : `ETag` en lecture, `If-Match` exigé en écriture (412 sinon) ;
   - traitements longs : publier une tâche pg-boss et répondre 202 avec `idTache`.
5. **Sérialiseur** : liste blanche de champs ; pour une réponse publique, appliquer RG-29 et NF-25 (API §6).
6. **Tests** : intégration (cas nominal, chaque règle refusée avec le bon `code` et `regle`, réponse 404 identique pour « absent » et « hors périmètre ») et ajout des cas à la matrice d'autorisations (TRD §13.3).
7. Si le point change un parcours, mettre à jour `docs/APP_FLOW.md` ; puis `python3 scripts/docs/controle_coherence.py`.
