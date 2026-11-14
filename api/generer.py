# -*- coding: utf-8 -*-
"""Régénère les tableaux de docs/API_SPECIFICATIONS.md et le squelette api/openapi.yaml depuis endpoints.py."""
import re, sys, pathlib, collections
ICI = pathlib.Path(__file__).resolve().parent
RACINE = ICI.parent
sys.path.insert(0, str(ICI))
from endpoints import E
import yaml

# ---------- Markdown
modules = collections.OrderedDict()
for m, meth, chemin, acces, resume, refs, code in E:
    modules.setdefault(m, []).append((meth, chemin, acces, resume, refs, code))
blocs = []
for m, lignes in modules.items():
    t = [f"### {m}", "", "| Méthode | Chemin | Accès | Rôle | Références |", "|---|---|---|---|---|"]
    for meth, chemin, acces, resume, refs, code in lignes:
        t.append(f"| `{meth}` | `{chemin}` | {acces} | {resume} | {refs} |")
    blocs.append("\n".join(t))
tpl = (RACINE / "docs/_templates/API_SPECIFICATIONS.tpl.md").read_text()
md = tpl.replace("{{TABLES}}", "\n\n".join(blocs)).replace("{{NB_ENDPOINTS}}", str(len(E)))
assert "{{" not in md
(RACINE / "docs/API_SPECIFICATIONS.md").write_text(md)

# ---------- OpenAPI
def ref(nom): return {"$ref": f"#/components/schemas/{nom}"}
def probleme(desc): return {"description": desc, "content": {"application/problem+json": {"schema": ref("Probleme")}}}
ID = {"type": "string", "format": "uuid"}
schemas = {
  "Probleme": {"type": "object", "required": ["type", "title", "status", "code"], "properties": {
      "type": {"type": "string", "format": "uri"}, "title": {"type": "string"}, "status": {"type": "integer"},
      "detail": {"type": "string"}, "instance": {"type": "string"}, "code": {"type": "string"},
      "regle": {"type": "string", "pattern": "^RG-\\d+$"}, "idRequete": {"type": "string"},
      "erreurs": {"type": "array", "items": {"type": "object", "properties": {"champ": {"type": "string"}, "message": {"type": "string"}}}}}},
  "Pagination": {"type": "object", "properties": {"suivant": {"type": ["string", "null"]}, "total": {"type": "integer"}}},
  "Tache": {"type": "object", "properties": {"idTache": ID, "etat": {"enum": ["EN_ATTENTE", "EN_COURS", "TERMINEE", "ECHEC"]}, "suivi": {"type": "string"}}},
  "Urgence": {"enum": ["FAIBLE", "MOYENNE", "ELEVEE", "CRITIQUE"]},
  "TranchePopulation": {"enum": ["MOINS_500", "DE_500_A_5000", "DE_5000_A_50000", "PLUS_50000", "INCONNUE"]},
  "Inscription": {"type": "object", "required": ["nom", "prenoms", "email", "motDePasse", "anneeNaissance", "idTerritoireResidence", "accepteCharte", "consentementDonnees"],
      "properties": {"nom": {"type": "string", "maxLength": 100}, "prenoms": {"type": "string", "maxLength": 150}, "email": {"type": "string", "format": "email"},
                     "motDePasse": {"type": "string", "minLength": 10}, "anneeNaissance": {"type": "integer"}, "sexe": {"enum": ["F", "M", None]},
                     "telephone": {"type": ["string", "null"]}, "idTerritoireResidence": ID, "afficherNom": {"type": "boolean"},
                     "accepteCharte": {"const": True}, "consentementDonnees": {"const": True}}},
  "TexteContribution": {"type": "object", "required": ["idTerritoire", "titre", "constat", "proposition"], "properties": {
      "idTerritoire": ID, "idSecteur": ID, "titre": {"type": "string"}, "constat": {"type": "string"}, "proposition": {"type": "string"}}},
  "ContributionCreation": {"type": "object", "required": ["titre", "constat", "proposition", "idSecteur", "idTerritoire", "urgence"], "properties": {
      "titre": {"type": "string", "minLength": 10, "maxLength": 120}, "constat": {"type": "string", "minLength": 30, "maxLength": 1500},
      "proposition": {"type": "string", "minLength": 20, "maxLength": 1500}, "idSecteur": ID, "idTerritoire": ID,
      "localite": {"type": ["string", "null"], "maxLength": 150}, "urgence": ref("Urgence"), "tranchePopulation": {"anyOf": [ref("TranchePopulation"), {"type": "null"}]},
      "idOrganisation": {"anyOf": [ID, {"type": "null"}]}, "idFichiersIllustration": {"type": "array", "maxItems": 3, "items": ID},
      "idClient": {"anyOf": [ID, {"type": "null"}], "description": "Identifiant attribué par la version mobile (RG-30)"},
      "saisieLe": {"type": ["string", "null"], "format": "date-time", "description": "Date de rédaction hors connexion"}}},
  "ContributionCreee": {"type": "object", "properties": {"idContribution": ID, "reference": {"type": "string"}, "statut": {"type": "string"},
      "horsResidence": {"type": "boolean"}, "enModeration": {"type": "boolean"},
      "preoccupation": {"type": "object", "properties": {"idPreoccupation": ID, "intitule": {"type": "string"}, "nouvelle": {"type": "boolean"}, "similarite": {"type": ["number", "null"]}}}}},
  "Fusion": {"type": "object", "required": ["idCible", "idsAbsorbees"], "properties": {"idCible": ID, "idsAbsorbees": {"type": "array", "minItems": 1, "items": ID}, "intitule": {"type": "string"}}},
  "DecisionConvergence": {"type": "object", "required": ["action"], "properties": {
      "action": {"enum": ["RETENIR", "REJETER", "FUSIONNER", "SCINDER", "RECLASSER", "REOUVRIR"]}, "motif": {"type": "string"},
      "classe": {"enum": ["NATIONALE", "PARTAGEE", "SPECIFIQUE"]}, "idCible": ID, "groupes": {"type": "array", "items": {"type": "array", "items": ID}}}},
  "EngagementCreation": {"type": "object", "required": ["echeanceAnnee", "texte"], "properties": {
      "idConvergence": {"anyOf": [ID, {"type": "null"}]}, "idPreoccupation": {"anyOf": [ID, {"type": "null"}]},
      "echeanceAnnee": {"type": "integer"}, "texte": {"type": "string", "minLength": 20, "maxLength": 1000}}},
  "SuiviCreation": {"type": "object", "required": ["etat", "dateEtat", "description", "justificatifs"], "properties": {
      "etat": {"enum": ["NON_DEMARRE", "EN_COURS", "REALISE", "PARTIELLEMENT_REALISE", "ABANDONNE"]}, "dateEtat": {"type": "string", "format": "date"},
      "description": {"type": "string"}, "justificatifs": {"type": "array", "minItems": 1, "items": {"type": "object", "required": ["type", "libelle"], "properties": {
          "type": {"enum": ["LIEN", "FICHIER"]}, "url": {"type": "string", "format": "uri"}, "idFichier": ID, "libelle": {"type": "string"}}}}}},
  "ControlesPublication": {"type": "object", "properties": {"publiable": {"type": "boolean"},
      "blocages": {"type": "array", "items": {"type": "object", "properties": {"regle": {"type": "string"}, "message": {"type": "string"}, "lien": {"type": "string"}}}},
      "avertissements": {"type": "array", "items": {"type": "object", "properties": {"message": {"type": "string"}}}}}},
}
corps = {
  ("POST", "/auth/inscription"): "Inscription",
  ("POST", "/contributions/similaires"): "TexteContribution",
  ("POST", "/contributions/suggestion-secteur"): "TexteContribution",
  ("POST", "/contributions"): "ContributionCreation",
  ("POST", "/admin/preoccupations/fusion"): "Fusion",
  ("POST", "/admin/convergences/{id}/decisions"): "DecisionConvergence",
  ("POST", "/candidat/engagements"): "EngagementCreation",
  ("POST", "/admin/engagements/{id}/suivis"): "SuiviCreation",
}
reponses = {
  ("POST", "/contributions"): "ContributionCreee",
  ("GET", "/admin/livres-blancs/{id}/versions/{numero}/controles"): "ControlesPublication",
}
multipart = {("POST", "/fichiers"), ("POST", "/admin/territoires/import"), ("POST", "/admin/utr/{utr}/consultations"),
             ("POST", "/contributions/{id}/illustrations")}
etag = {("PATCH", "/admin/preoccupations/{id}"), ("PATCH", "/admin/convergences/{id}"),
        ("PATCH", "/admin/livres-blancs/{id}/versions/{numero}"), ("POST", "/admin/livres-blancs/{id}/versions/{numero}/publication")}
paths = {}
for m, meth, chemin, acces, resume, refs, code in E:
    op = {"tags": [m], "summary": resume, "operationId": (meth.lower() + re.sub(r"[^A-Za-z0-9]+", "_", chemin)).strip("_"),
          "x-acces": acces, "x-references": refs}
    params = [{"name": p, "in": "path", "required": True, "schema": {"type": "string"}} for p in re.findall(r"\{(\w+)\}", chemin)]
    if (meth, chemin) in etag:
        params.append({"name": "If-Match", "in": "header", "required": True, "schema": {"type": "string"}})
    if params: op["parameters"] = params
    if acces == "PUB": op["security"] = []
    elif acces == "PUB*": op["security"] = [{}, {"session": []}]
    else: op["security"] = [{"session": []}]
    if (meth, chemin) in corps:
        op["requestBody"] = {"required": True, "content": {"application/json": {"schema": ref(corps[(meth, chemin)])}}}
    elif (meth, chemin) in multipart:
        op["requestBody"] = {"required": True, "content": {"multipart/form-data": {"schema": {"type": "object", "properties": {"fichier": {"type": "string", "format": "binary"}}}}}}
    elif meth in ("POST", "PUT", "PATCH") and not chemin.endswith(("/retrait", "/deconnexion", "/renvoi")):
        op["requestBody"] = {"required": False, "content": {"application/json": {"schema": {"type": "object"}}}}
    rep = {}
    if code == 204: rep["204"] = {"description": "Succès, sans contenu"}
    elif code == 202: rep["202"] = {"description": "Tâche de fond acceptée", "content": {"application/json": {"schema": ref("Tache")}}}
    else:
        sch = ref(reponses[(meth, chemin)]) if (meth, chemin) in reponses else {"type": "object"}
        rep[str(code)] = {"description": "Succès", "content": {"application/json": {"schema": sch}}}
    if not acces.startswith("PUB"): rep["401"] = probleme("Non connecté"); rep["403"] = probleme("Interdit ou hors périmètre")
    rep["404"] = probleme("Introuvable")
    if meth != "GET": rep["409"] = probleme("Règle de gestion ou conflit"); rep["422"] = probleme("Validation")
    if (meth, chemin) in etag: rep["412"] = probleme("Modifié entre-temps")
    op["responses"] = rep
    paths.setdefault(chemin, {})[meth.lower()] = op
doc = {
  "openapi": "3.1.0",
  "info": {"title": "Livre Blanc Citoyen — API", "version": "1.0.0",
           "description": "Squelette généré depuis api/endpoints.py. Voir docs/API_SPECIFICATIONS.md pour les conventions."},
  "servers": [{"url": "http://localhost:3000/api/v1"}],
  "tags": [{"name": m} for m in modules],
  "paths": paths,
  "components": {"schemas": schemas, "securitySchemes": {"session": {"type": "apiKey", "in": "cookie", "name": "nuxt-session",
      "description": "Cookie de session scellé (nuxt-auth-utils) ; nom configurable"}}},
}
class D(yaml.SafeDumper): pass
D.ignore_aliases = lambda *a: True
(ICI / "openapi.yaml").write_text(yaml.dump(doc, Dumper=D, allow_unicode=True, sort_keys=False, width=140))
print(len(E), "points d'accès ;", len(paths), "chemins")
