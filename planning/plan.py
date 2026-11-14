# -*- coding: utf-8 -*-
"""Planning du projet — source unique pour le fichier MS Project, le Gantt et l'organigramme des tâches."""
import datetime as dt

D = dt.date.fromisoformat
PROJECT_NAME = "Livre Blanc Citoyen — Projet UP-PRO ING2 STIC"
START, FINISH = D("2026-10-15"), D("2027-01-15")
HOLIDAYS = {D("2026-12-25"): "Noël", D("2027-01-01"): "Jour de l'an"}

TEAM = [
    ("SORO Koromiwonah Segneniguetenin Samuel", "SS", True),
    ("AZOUASSI Ômonlôla Sara Océane", "AO", False),
    ("GLEDE Dekongnon Henri Joël", "GH", False),
    ("WOGNIN Noé Phinées", "WN", False),
]

# (wbs, nom, début, fin, prédécesseurs (wbs), jalon)
TASKS = [
    ("1", "Audit et compréhension", None, None, [], False),
    ("1.1", "Étude du sujet et du contexte", "2026-10-15", "2026-10-21", [], False),
    ("1.2", "Analyse du modèle de rapport", "2026-10-22", "2026-10-23", ["1.1"], False),
    ("1.3", "Acteurs, risques et questions métier", "2026-10-26", "2026-10-30", ["1.2"], False),
    ("1.4", "Note d'analyse validée", "2026-10-30", "2026-10-30", ["1.3"], True),
    ("2", "Cadrage fonctionnel", None, None, [], False),
    ("2.1", "Processus et règles de gestion", "2026-11-02", "2026-11-06", ["1.4"], False),
    ("2.2", "Rédaction du PRD", "2026-11-09", "2026-11-12", ["2.1"], False),
    ("2.3", "PRD validé", "2026-11-13", "2026-11-13", ["2.2"], True),
    ("3", "Conception (MERISE et architecture)", None, None, [], False),
    ("3.1", "Modèles des traitements (MCC, MCT, MOT)", "2026-11-16", "2026-11-20", ["2.3"], False),
    ("3.2", "Modèles des données (MCD, MLD, MPD)", "2026-11-23", "2026-11-27", ["3.1"], False),
    ("3.3", "Architecture et spécifications techniques", "2026-11-30", "2026-12-04", ["3.2"], False),
    ("3.4", "Dossier de conception validé", "2026-12-04", "2026-12-04", ["3.3"], True),
    ("4", "Conception des interfaces", None, None, [], False),
    ("4.1", "Parcours et architecture de l'information", "2026-11-23", "2026-11-27", ["2.3"], False),
    ("4.2", "Système de design", "2026-11-30", "2026-12-04", ["4.1"], False),
    ("4.3", "Direction d'interface et écrans de référence", "2026-12-07", "2026-12-11", ["4.2"], False),
    ("5", "Réalisation du prototype", None, None, [], False),
    ("5.1", "Mise en place du projet et de la base", "2026-12-07", "2026-12-11", ["3.4"], False),
    ("5.2", "Collecte, analyse et livres blancs régionaux", "2026-12-14", "2026-12-24", ["5.1"], False),
    ("5.3", "Consolidation, exports, portail, engagements", "2026-12-28", "2027-01-05", ["5.2"], False),
    ("5.4", "Tests et corrections de la version web", "2027-01-06", "2027-01-08", ["5.3"], False),
    ("5.5", "Version mobile (application web progressive)", "2027-01-11", "2027-01-13", ["5.4"], False),
    ("6", "Rédaction du rapport et soutenance", None, None, [], False),
    ("6.1", "Rédaction progressive du rapport", "2026-11-02", "2027-01-08", ["1.4"], False),
    ("6.2", "Finalisation et relecture du rapport", "2027-01-11", "2027-01-13", ["6.1", "5.4"], False),
    ("6.3", "Préparation de la soutenance", "2027-01-13", "2027-01-14", ["6.2"], False),
    ("6.4", "Soutenance", "2027-01-15", "2027-01-15", ["6.3"], True),
]


def workdays(a, b):
    n, d = 0, a
    while d <= b:
        if d.weekday() < 5 and d not in HOLIDAYS:
            n += 1
        d += dt.timedelta(days=1)
    return n


def resolved():
    """Renvoie les tâches avec dates calculées (les récapitulatives couvrent leurs sous-tâches)."""
    rows = []
    for wbs, name, s, f, pred, ms in TASKS:
        rows.append(dict(wbs=wbs, name=name, start=D(s) if s else None, finish=D(f) if f else None,
                         pred=pred, milestone=ms, level=wbs.count(".") + 1, summary=s is None))
    for r in rows:
        if r["summary"]:
            kids = [k for k in rows if k["wbs"].startswith(r["wbs"] + ".")]
            r["start"] = min(k["start"] for k in kids)
            r["finish"] = max(k["finish"] for k in kids)
    for r in rows:
        r["days"] = 0 if r["milestone"] else workdays(r["start"], r["finish"])
    return rows
