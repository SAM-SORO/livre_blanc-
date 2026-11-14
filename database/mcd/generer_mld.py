# -*- coding: utf-8 -*-
"""Extrait du catalogue PostgreSQL le MLD textuel, le dictionnaire de données et un schéma relationnel.

Usage : python3 generer_mld.py  (base migrée désignée par les variables PGHOST, PGPORT, PGUSER, PGDATABASE ; par défaut lbc_test en local)
Sorties : database/generated/MLD.md, database/generated/DICTIONNAIRE.md, diagrams/merise/mld_relationnel.png
"""
import json, os, subprocess

import os as _os
PSQL = ["psql", "-h", _os.environ.get("PGHOST", "localhost"), "-p", _os.environ.get("PGPORT", "5432"), "-U", _os.environ.get("PGUSER", "postgres"), "-d", _os.environ.get("PGDATABASE", "lbc_test"), "-At", "-c"]
RACINE = __import__("pathlib").Path(__file__).resolve().parents[2]
GEN = str(RACINE / "database" / "generated") + "/"
DIAG = str(RACINE / "diagrams" / "merise") + "/"
os.makedirs(GEN, exist_ok=True)
TECHNIQUES = {"session", "jeton", "compteur_reference", "journal_audit", "terme_interdit"}
DOMAINES = [
    ("Référentiels", ["territoire", "secteur", "edition"]),
    ("Comptes et organisations", ["utilisateur", "affectation", "organisation", "fichier", "notification"]),
    ("Collecte et analyse régionale", ["consultation_terrain", "contribution", "version_contribution", "illustration",
                                       "soutien", "signalement", "decision_moderation", "preoccupation"]),
    ("Livres blancs et consolidation", ["livre_blanc", "version_livre_blanc", "inclusion_preoccupation",
                                        "calcul_consolidation", "convergence", "inclusion_convergence",
                                        "decision_etats_generaux"]),
    ("Engagements et suivi", ["candidat", "engagement", "suivi_realisation", "justificatif"]),
    ("Tables techniques", sorted(TECHNIQUES)),
]


def q(sql):
    return json.loads(subprocess.run(PSQL + [sql], capture_output=True, text=True, check=True).stdout or "null")


tables = q("""SELECT json_agg(json_build_object('t', c.relname, 'c', obj_description(c.oid)) ORDER BY c.relname)
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relkind='r'""")
cols = q("""SELECT json_agg(json_build_object('t', c.table_name, 'col', c.column_name, 'type',
  CASE WHEN c.data_type='ARRAY' THEN replace(c.udt_name,'_','')||'[]' WHEN c.data_type='USER-DEFINED' THEN c.udt_name
       WHEN c.data_type IN ('character','character varying') AND c.character_maximum_length IS NOT NULL
            THEN c.data_type||'('||c.character_maximum_length||')'
       WHEN c.data_type='numeric' AND c.numeric_precision IS NOT NULL THEN 'numeric('||c.numeric_precision||','||c.numeric_scale||')'
       ELSE c.data_type END,
  'null', c.is_nullable, 'gen', c.is_generated, 'def', c.column_default,
  'com', col_description(('public.'||c.table_name)::regclass, c.ordinal_position)) ORDER BY c.table_name, c.ordinal_position)
FROM information_schema.columns c WHERE c.table_schema='public' AND c.table_name IN
  (SELECT relname FROM pg_class WHERE relkind='r' AND relnamespace='public'::regnamespace)""")
pks = q("""SELECT json_agg(json_build_object('t', tc.table_name, 'col', kcu.column_name))
FROM information_schema.table_constraints tc JOIN information_schema.key_column_usage kcu
  ON kcu.constraint_name=tc.constraint_name AND kcu.table_schema=tc.table_schema
WHERE tc.constraint_type='PRIMARY KEY' AND tc.table_schema='public'""")
fks = q("""SELECT json_agg(json_build_object('t', cl.relname, 'col', a.attname, 'rt', rcl.relname, 'rcol', ra.attname))
FROM pg_constraint co JOIN pg_class cl ON cl.oid=co.conrelid JOIN pg_class rcl ON rcl.oid=co.confrelid
JOIN unnest(co.conkey) WITH ORDINALITY k(attnum, i) ON true
JOIN unnest(co.confkey) WITH ORDINALITY rk(attnum, i) ON rk.i=k.i
JOIN pg_attribute a ON a.attrelid=co.conrelid AND a.attnum=k.attnum
JOIN pg_attribute ra ON ra.attrelid=co.confrelid AND ra.attnum=rk.attnum
WHERE co.contype='f' AND cl.relnamespace='public'::regnamespace""")
uniq = q("""SELECT json_agg(json_build_object('t', cl.relname, 'cols', (SELECT string_agg(a.attname, ', ') FROM unnest(co.conkey) k
  JOIN pg_attribute a ON a.attrelid=co.conrelid AND a.attnum=k)))
FROM pg_constraint co JOIN pg_class cl ON cl.oid=co.conrelid WHERE co.contype='u' AND cl.relnamespace='public'::regnamespace""")
checks = q("""SELECT json_agg(json_build_object('t', cl.relname, 'n', co.conname, 'd', pg_get_constraintdef(co.oid)) ORDER BY cl.relname, co.conname)
FROM pg_constraint co JOIN pg_class cl ON cl.oid=co.conrelid WHERE co.contype='c' AND cl.relnamespace='public'::regnamespace""")

GENERIQUES = {
    "creee_le": "Date de création.", "cree_le": "Date de création.", "modifie_le": "Date de dernière modification.",
    "type": "Type (valeurs contrôlées, voir contraintes).", "titre": "Titre.", "message": "Texte du message.",
    "lien": "Lien interne vers l'objet concerné.", "description": "Description libre.",
    "constat": "Constat archivé.", "proposition": "Proposition archivée.", "urgence": "Urgence archivée.",
    "tranche_population": "Tranche de population archivée.", "localite": "Localité archivée.",
    "commentaire": "Commentaire libre.", "lue_le": "Date de lecture (nulle si non lue).",
    "email_envoye_le": "Date d'envoi de l'e-mail associé.", "publiee_le": "Date de publication.",
    "remplacee_le": "Date à laquelle une version plus récente a été publiée.", "publiee_par": "Administrateur ayant publié.",
    "creee_par": "Auteur de la création.", "cree_par": "Auteur de la création.", "lance_le": "Date de lancement.",
    "lance_par": "Administrateur ayant lancé le calcul.", "termine_le": "Date de fin.", "statut": "Statut (valeurs contrôlées).",
    "intitule_fige": "Intitulé à la date de publication.", "score_fige": "Score à la date de publication.",
    "nb_voix_fige": "Nombre de voix à la date de publication.", "url": "Adresse web (http ou https).",
    "id_fichier": "Fichier joint.", "agent_utilisateur": "Navigateur ayant ouvert la session.",
    "adresse_ip": "Adresse IP d'origine.", "id_requete": "Identifiant de la requête HTTP (corrélation des journaux).",
    "type_objet": "Type d'objet concerné.", "id_objet": "Identifiant de l'objet concerné.", "survenue_le": "Date de l'action.",
    "jeton_hash": "Empreinte du jeton.", "utilise_le": "Date d'utilisation (usage unique).", "valeur": "Dernière valeur attribuée.",
    "prefixe": "Préfixe de la série de références.", "terme": "Terme recherché dans les contributions.", "actif": "Vrai si actif.",
    "id_edition": "Édition de rattachement.", "id_utilisateur": "Utilisateur concerné.", "id_contribution": "Contribution concernée.",
    "id_version": "Version de livre blanc concernée.", "id_convergence": "Convergence concernée.",
    "id_preoccupation": "Préoccupation concernée.", "id_engagement": "Engagement suivi.", "id_suivi": "Mise à jour de suivi.",
    "id_candidat": "Candidat auteur de l'engagement.", "id_livre_blanc": "Livre blanc décliné.", "id_secteur": "Secteur.",
    "id_administrateur": "Administrateur auteur de la décision.", "id_calcul": "Calcul de consolidation d'origine.",
    "derniere_activite_le": "Dernière requête authentifiée (expiration glissante).", "numero": "Numéro d'ordre.",
    "libelle": "Libellé.", "signale_le": "Date du signalement.", "decidee_le": "Date de la décision.",
    "importee_le": "Date d'import.", "depose_le": "Date de dépôt.",
}
pk = {}
for r in pks:
    pk.setdefault(r["t"], []).append(r["col"])
fk = {}
for r in fks:
    fk.setdefault(r["t"], {})[r["col"]] = (r["rt"], r["rcol"])
by_t = {}
for c in cols:
    by_t.setdefault(c["t"], []).append(c)
tcom = {t["t"]: t["c"] for t in tables}
assert set(by_t) == {t for _, ts in DOMAINES for t in ts}, set(by_t) ^ {t for _, ts in DOMAINES for t in ts}

# ------------------------------------------------------------------ MLD textuel
mld = ["# MLD — modèle logique des données (relationnel)", "",
       "> Généré automatiquement depuis le schéma PostgreSQL migré (`generer_mld.py`). Ne pas modifier à la main.", "",
       "Notation : **clé primaire** en gras, `#` devant une clé étrangère (table référencée entre crochets).", ""]
for dom, ts in DOMAINES:
    mld += ["## " + dom, ""]
    for t in ts:
        parts = []
        for c in by_t[t]:
            if c["gen"] == "ALWAYS":
                continue
            name = c["col"]
            if name in pk.get(t, []):
                s = "**%s**" % name
                if name in fk.get(t, {}):
                    s = "**#%s**" % name
            elif name in fk.get(t, {}):
                s = "#%s" % name
            else:
                s = name
            if name in fk.get(t, {}):
                s += " [%s]" % fk[t][name][0]
            parts.append(s)
        mld.append("- **%s** (%s)" % (t.upper(), ", ".join(parts)))
    mld.append("")
open(GEN + "MLD.md", "w", encoding="utf8").write("\n".join(mld))

# ------------------------------------------------------------------ dictionnaire
dic = ["# Dictionnaire de données", "",
       "> Généré automatiquement depuis les commentaires du schéma PostgreSQL (`generer_mld.py`). Ne pas modifier à la main.", ""]
n_cols = 0
for dom, ts in DOMAINES:
    dic += ["## " + dom, ""]
    for t in ts:
        dic += ["### %s" % t, "", tcom.get(t) or "", "",
                "| Colonne | Type | Oblig. | Clé | Description |", "|---|---|---|---|---|"]
        for c in by_t[t]:
            n_cols += 1
            key = []
            if c["col"] in pk.get(t, []):
                key.append("PK")
            if c["col"] in fk.get(t, {}):
                key.append("FK → " + fk[t][c["col"]][0])
            typ = c["type"].replace("timestamp with time zone", "timestamptz").replace("character varying", "varchar")
            if c["gen"] == "ALWAYS":
                typ += " (générée)"
            com = c["com"] or GENERIQUES.get(c["col"], "")
            if not com and c["col"].endswith("_le"):
                com = "Date et heure : " + c["col"][:-3].replace("_", " ") + "."
            if not com and c["col"] in pk.get(t, []) and c["col"] not in fk.get(t, {}):
                com = "Identifiant technique (UUID v7)." if c["type"] == "uuid" else "Identifiant technique."
            if not com and c["col"] in fk.get(t, {}):
                com = "Référence vers %s." % fk[t][c["col"]][0]
            dic.append("| `%s` | %s | %s | %s | %s |" % (c["col"], typ, "oui" if c["null"] == "NO" else "non",
                                                        ", ".join(key), (com or "").replace("|", "\\|")))
        cks = [k for k in checks if k["t"] == t and not k["n"].endswith("_not_null")]
        if cks:
            dic += ["", "Contraintes de vérification :", ""]
            dic += ["- `%s` : `%s`" % (k["n"], k["d"].replace("|", "\\|")) for k in cks]
        us = [u for u in uniq if u["t"] == t]
        if us:
            dic += ["", "Unicité : " + " ; ".join("(%s)" % u["cols"] for u in us)]
        dic.append("")
open(GEN + "DICTIONNAIRE.md", "w", encoding="utf8").write("\n".join(dic))

# ------------------------------------------------------------------ schéma relationnel (vue d'ensemble)
colors = ["#E6EEF8", "#EEF5EA", "#FFF4E5", "#F3EEFA", "#FDECEC", "#F1F3F6"]
dot = ['digraph R {', 'graph [rankdir=LR, splines=true, nodesep=0.25, ranksep=0.9, pad=0.3, dpi=200, '
       'fontname="Liberation Sans", newrank=true];',
       'node [shape=plain, fontname="Liberation Sans", fontsize=10];',
       'edge [color="#718096", arrowhead=crow, arrowtail=none, dir=both, arrowsize=0.6, penwidth=0.8];']
for i, (dom, ts) in enumerate(DOMAINES):
    if dom == "Tables techniques":
        continue
    dot.append('subgraph cluster_%d { label=<<B>%s</B>>; style="rounded,filled"; color="#CBD5E0"; fillcolor="%s"; fontsize=12;'
               % (i, dom, colors[i]))
    for t in ts:
        rows = "".join('<TR><TD ALIGN="LEFT"><FONT POINT-SIZE="8.5">%s%s</FONT></TD></TR>' % (
            "<U>%s</U>" % c["col"] if c["col"] in pk.get(t, []) else c["col"],
            " #" if c["col"] in fk.get(t, {}) else "")
            for c in by_t[t] if c["col"] in pk.get(t, []) or c["col"] in fk.get(t, {}))
        dot.append('"%s" [label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" CELLPADDING="2" BGCOLOR="white" COLOR="#1A365D">'
                   '<TR><TD BGCOLOR="#1A365D"><FONT COLOR="white"><B>%s</B></FONT></TD></TR>%s</TABLE>>];' % (t, t.upper(), rows))
    dot.append("}")
seen = set()
for t, d in fk.items():
    if t in TECHNIQUES:
        continue
    for col, (rt, _) in d.items():
        if rt in TECHNIQUES or (t, rt) in seen or rt == t:
            continue
        seen.add((t, rt))
        dot.append('"%s" -> "%s";' % (rt, t))
dot.append("}")
open(DIAG + "mld_relationnel.dot", "w", encoding="utf8").write("\n".join(dot))
subprocess.run(["dot", "-Tpng", DIAG + "mld_relationnel.dot", "-o", DIAG + "mld_relationnel.png"], check=True)
subprocess.run(["dot", "-Tsvg", DIAG + "mld_relationnel.dot", "-o", DIAG + "mld_relationnel.svg"], check=True)
print("tables :", len(by_t), "colonnes :", n_cols, "clés étrangères :", len(fks), "contraintes CHECK :",
      len([k for k in checks if not k['n'].endswith('_not_null')]))
