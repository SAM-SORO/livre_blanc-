# -*- coding: utf-8 -*-
"""Diagrammes MERISE des traitements : MCC, ordonnancement des flux, MCT (3 vues)."""
import os, subprocess, textwrap
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

RACINE = __import__("pathlib").Path(__file__).resolve().parents[2]
OUT = str(RACINE / "diagrams" / "merise") + "/"
NAVY, BLUE, LIGHT, INK, GREY = "#1A365D", "#2C5282", "#E6EEF8", "#1A202C", "#718096"
plt.rcParams["font.family"] = "Liberation Sans"

# ----------------------------------------------------------------------------- acteurs et flux
EXTERNES = {"CONTRIB": "Contributeur", "ORG": "Représentant\nd'organisation", "CAND": "Candidat",
            "VISIT": "Visiteur", "MAIL": "Service de\nmessagerie"}
INTERNES = {"SYS": "Système\nLivre Blanc Citoyen", "ADMR": "Administration\nrégionale", "ADMN": "Administration\nnationale"}
FLUX = [  # (n°, source, cible, libellé, phase)
    (1, "CONTRIB", "SYS", "Demande d'inscription", "Collecte"),
    (2, "SYS", "MAIL", "Lien de vérification du compte", "Collecte"),
    (3, "ADMN", "SYS", "Paramétrage de l'édition et référentiels", "Préparation"),
    (4, "ORG", "SYS", "Fiche de l'organisation", "Collecte"),
    (5, "SYS", "ADMR", "Organisation à vérifier", "Collecte"),
    (6, "ADMR", "SYS", "Décision de vérification", "Collecte"),
    (7, "CONTRIB", "SYS", "Contribution (constat et proposition)", "Collecte"),
    (8, "SYS", "CONTRIB", "Contributions similaires suggérées", "Collecte"),
    (9, "CONTRIB", "SYS", "Soutien ou signalement", "Collecte"),
    (10, "ADMR", "SYS", "Résultats des consultations de terrain", "Collecte"),
    (11, "SYS", "ADMR", "Contributions à modérer, doublons et fusions suggérés", "Consolidation régionale"),
    (12, "ADMR", "SYS", "Décisions de modération et de regroupement", "Consolidation régionale"),
    (13, "SYS", "MAIL", "Notification de décision au contributeur", "Consolidation régionale"),
    (14, "SYS", "ADMR", "Brouillon du livre blanc régional", "Consolidation régionale"),
    (15, "ADMR", "SYS", "Validation et publication du livre blanc régional", "Consolidation régionale"),
    (16, "SYS", "ADMN", "Convergences proposées", "États généraux"),
    (17, "ADMN", "SYS", "Décisions des états généraux", "États généraux"),
    (18, "SYS", "VISIT", "Livres blancs publiés, carte et traçabilité", "Engagements"),
    (19, "CAND", "SYS", "Déclaration d'engagements", "Engagements"),
    (20, "ADMN", "SYS", "Mise à jour du suivi des réalisations", "Suivi"),
    (21, "SYS", "VISIT", "Tableau de bord des réalisations", "Suivi"),
]


def mcc():
    from matplotlib.patches import FancyBboxPatch, Ellipse
    import math
    fig, ax = plt.subplots(figsize=(13, 8.2), dpi=200)
    ax.set_xlim(0, 16); ax.set_ylim(0, 10.4); ax.axis("off"); ax.set_aspect("equal")
    ax.add_patch(FancyBboxPatch((4.0, 0.7), 8.0, 7.4, boxstyle="round,pad=0.1,rounding_size=0.4",
                                fc="#F7FAFC", ec=BLUE, ls="--", lw=1.4))
    ax.text(4.3, 0.95, "Domaine d'étude : gestion des livres blancs", fontsize=13.5, color=BLUE, fontweight="bold")
    pos = {"SYS": (8, 5.6), "ADMR": (5.75, 2.0), "ADMN": (10.25, 2.0), "CONTRIB": (1.7, 8.2), "ORG": (1.7, 4.3),
           "MAIL": (8, 9.6), "CAND": (14.3, 8.2), "VISIT": (14.3, 4.3)}
    W, H = 3.1, 1.4
    TAILLE = {"SYS": (3.9, 1.5)}
    for k, (x, y) in pos.items():
        internal = k in INTERNES
        ax.add_patch(Ellipse((x, y), *TAILLE.get(k, (W, H)), fc=LIGHT if internal else "white", ec=NAVY if internal else GREY,
                             ls="-" if internal else "--", lw=1.6 if internal else 1.2, zorder=3))
        ax.text(x, y, (INTERNES if internal else EXTERNES)[k], ha="center", va="center", fontsize=13.5,
                color=NAVY if internal else INK, fontweight="bold" if internal else "normal", zorder=4)
    groups = {}
    for n, s_, t, lab, ph in FLUX:
        groups.setdefault((s_, t), []).append(str(n))

    def edge_pt(c, toward):
        (x, y), (tx, ty) = c, toward
        ang = math.atan2(ty - y, tx - x)
        k = next(n for n, v in pos.items() if v == c)
        a, b = TAILLE.get(k, (W, H))[0] / 2, TAILLE.get(k, (W, H))[1] / 2
        r = a * b / math.sqrt((b * math.cos(ang)) ** 2 + (a * math.sin(ang)) ** 2)
        return x + r * math.cos(ang), y + r * math.sin(ang)

    for (s_, t), ns in groups.items():
        p1, p2 = pos[s_], pos[t]
        dx, dy = p2[0] - p1[0], p2[1] - p1[1]
        L = math.hypot(dx, dy); nx, ny = -dy / L, dx / L
        off = 0.17 if (t, s_) in groups else 0
        a1 = edge_pt(p1, p2); a2 = edge_pt(p2, p1)
        a1 = (a1[0] + nx * off, a1[1] + ny * off); a2 = (a2[0] + nx * off, a2[1] + ny * off)
        ax.annotate("", xy=a2, xytext=a1, arrowprops=dict(arrowstyle="-|>", color=BLUE, lw=1.3, mutation_scale=16), zorder=2)
        # étiquette placée plus près de l'administration, pour ne pas se chevaucher près du système
        f = 0.62 if t in ("ADMR", "ADMN") else (0.38 if s_ in ("ADMR", "ADMN") else 0.5)
        mx = a1[0] + (a2[0] - a1[0]) * f + nx * 0.32 * (1 if off else 0)
        my = a1[1] + (a2[1] - a1[1]) * f + ny * 0.32 * (1 if off else 0)
        ax.text(mx, my, ", ".join(ns), fontsize=12.5, ha="center", va="center", color=INK, zorder=5,
                bbox=dict(boxstyle="round,pad=0.18", fc="white", ec="#CBD5E0", lw=0.6))
    ax.text(0.2, 0.15, "Ellipse pleine : acteur interne ; ellipse en pointillés : acteur externe. "
            "Les numéros renvoient à la liste des flux.", fontsize=11.5, color=GREY, style="italic")
    fig.savefig(OUT + "mcc.png", bbox_inches="tight", facecolor="white")
    plt.close(fig)


def ordonnancement():
    cols = ["CONTRIB", "ORG", "ADMR", "SYS", "ADMN", "CAND", "VISIT", "MAIL"]
    names = {**EXTERNES, **INTERNES, "SYS": "Système"}
    order = sorted(FLUX, key=lambda f: (["Préparation", "Collecte", "Consolidation régionale", "États généraux",
                                         "Engagements", "Suivi"].index(f[4]), f[0]))
    h = 0.5 * len(order) + 1.6
    fig, ax = plt.subplots(figsize=(11.5, h), dpi=200)
    xs = {c: i * 2.0 for i, c in enumerate(cols)}
    ax.set_xlim(-3.6, xs[cols[-1]] + 1.0)
    ax.set_ylim(-len(order) - 0.8, 2.7)
    ax.axis("off")
    for c in cols:
        internal = c in INTERNES
        ax.text(xs[c], 1.0 if cols.index(c) % 2 == 0 else 2.1, names[c], ha="center", va="center", fontsize=10.5, fontweight="bold",
                color="white" if internal else INK,
                bbox=dict(boxstyle="round,pad=0.3", fc=NAVY if internal else "white", ec=NAVY if internal else GREY,
                          ls="-" if internal else "--"))
        ax.plot([xs[c], xs[c]], [0.45 if cols.index(c) % 2 == 0 else 1.55, -len(order) - 0.5], color="#CBD5E0", lw=1, ls="--", zorder=0)
    last_phase = None
    for i, (n, s, t, lab, ph) in enumerate(order):
        y = -i - 0.3
        if ph != last_phase:
            ax.plot([-3.6, xs[cols[-1]] + 1.0], [y + 0.5, y + 0.5], color="#A0AEC0", lw=0.6)
            ax.text(-3.5, y + 0.05, ph.replace(" ", "\n", 1) if len(ph) > 14 else ph, fontsize=11.5, color=BLUE, fontweight="bold", va="center")
            last_phase = ph
        x1, x2 = xs[s], xs[t]
        ax.annotate("", xy=(x2, y), xytext=(x1, y), arrowprops=dict(arrowstyle="-|>", color=BLUE, lw=1.3))
        ax.text((x1 + x2) / 2, y + 0.16, "%d. %s" % (n, lab), ha="center", va="bottom", fontsize=11, color=INK)
    fig.savefig(OUT + "ordonnancement_flux.png", bbox_inches="tight", facecolor="white")
    plt.close(fig)


# ----------------------------------------------------------------------------- MCT
def op_label(nom, actions, emissions):
    acts = "".join('<TR><TD ALIGN="LEFT"><FONT POINT-SIZE="12">• %s</FONT></TD></TR>' % a for a in actions)
    emis = " | ".join(emissions)
    return ('<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" CELLPADDING="3" COLOR="%s" BGCOLOR="white">'
            '<TR><TD BGCOLOR="%s"><FONT COLOR="white"><B>%s</B></FONT></TD></TR>%s'
            '<TR><TD BGCOLOR="%s" ALIGN="CENTER"><FONT POINT-SIZE="12"><I>%s</I></FONT></TD></TR></TABLE>>'
            % (NAVY, NAVY, nom, acts, LIGHT, emis))


def mct(nom, titre, items):
    """items : liste d'instructions (type, ...)"""
    lines = ['digraph MCT {', 'graph [rankdir=TB, nodesep=0.35, ranksep=0.35, pad=0.3, dpi=200, fontname="Liberation Sans"];',
             'node [fontname="Liberation Sans", fontsize=13];',
             'edge [color="#4A5568", arrowsize=0.8, fontname="Liberation Sans", fontsize=11];']
    for it in items:
        k = it[0]
        if k == "ev":
            lines.append('"%s" [shape=ellipse, style=filled, fillcolor="#FFF4E5", color="#B7791F", label="%s"];' % (it[1], it[2]))
        elif k == "res":
            lines.append('"%s" [shape=ellipse, style=filled, fillcolor="#EEF5EA", color="#2F855A", label="%s"];' % (it[1], it[2]))
        elif k == "sync":
            lines.append('"%s" [shape=circle, width=0.7, fixedsize=true, style=filled, fillcolor="white", color="%s", label="%s"];'
                         % (it[1], NAVY, it[2]))
        elif k == "op":
            lines.append('"%s" [shape=plain, label=%s];' % (it[1], op_label(it[2], it[3], it[4])))
        elif k == "e":
            lab = ', label="%s"' % it[3] if len(it) > 3 else ""
            lines.append('"%s" -> "%s" [%s];' % (it[1], it[2], lab.strip(", ")))
        elif k == "rank":
            lines.append("{rank=same; %s}" % "; ".join('"%s"' % x for x in it[1]))
    lines.append("}")
    p = OUT + nom
    open(p + ".dot", "w", encoding="utf8").write("\n".join(lines))
    subprocess.run(["dot", "-Tpng", p + ".dot", "-o", p + ".png"], check=True)


MCT_COMPTES = [
    ("ev", "e1", "Demande\\nd'inscription"), ("op", "o1", "OP1 — Inscrire le contributeur",
     ["contrôler les données et l'âge (RG-10, RG-12)", "vérifier l'unicité de l'e-mail", "créer le compte non vérifié",
      "émettre un lien de vérification (24 h)"], ["données valides", "sinon refus"]),
    ("res", "r1", "Compte créé\\n+ lien envoyé"), ("res", "r1b", "Inscription\\nrefusée"),
    ("ev", "e2", "Lien de vérification\\nutilisé"), ("op", "o2", "OP2 — Vérifier le compte",
     ["contrôler le jeton (usage unique, validité)", "marquer l'e-mail comme vérifié"], ["jeton valide", "sinon nouveau lien"]),
    ("res", "r2", "Compte\\nvérifié"), ("res", "r2b", "Nouveau lien\\nenvoyé"),
    ("e", "e1", "o1"), ("e", "o1", "r1"), ("e", "o1", "r1b"), ("e", "r1", "e2"), ("e", "e2", "o2"), ("e", "o2", "r2"),
    ("e", "o2", "r2b"),
]
MCT_COLLECTE = [
    ("ev", "r2", "Compte\\nvérifié"), ("ev", "e3", "Contribution\\nsoumise"), ("ev", "c3", "Phase de collecte\\nouverte"),
    ("sync", "s3", "ET"),
    ("op", "o3", "OP3 — Enregistrer la contribution",
     ["contrôler les champs (RG-21) et la limite (RG-26)", "rechercher les contributions proches (≥ 0,20)",
      "rattacher à une préoccupation (≥ 0,30) ou en créer une", "appliquer le filtre de termes (RG-40)",
      "recalculer les scores de l'UTR"], ["publiée", "en modération", "soutien choisi"]),
    ("res", "r3", "Contribution publiée\\net rattachée"), ("res", "r3b", "Contribution\\nen modération"),
    ("res", "r3c", "Soutien\\nenregistré"),
    ("ev", "e4", "3 signalements ou\\nterme interdit détecté"), ("op", "o4", "OP4 — Modérer la contribution",
     ["examiner la contribution (administrateur régional)", "décider : maintenir, masquer ou retirer (motif)",
      "notifier l'auteur (RG-41)"], ["maintenue", "masquée ou retirée"]),
    ("res", "r4", "Contribution\\nmaintenue"), ("res", "r4b", "Contribution masquée\\nou retirée + notification"),
    ("e", "r2", "s3"), ("e", "e3", "s3"), ("e", "c3", "s3"), ("e", "s3", "o3"), ("e", "o3", "r3"), ("e", "o3", "r3b"),
    ("e", "o3", "r3c"), ("e", "r3b", "o4"), ("e", "e4", "o4"), ("e", "o4", "r4"), ("e", "o4", "r4b"),
    ("rank", ["r2", "e3", "c3"]),
]
MCT_REGIONAL = [
    ("ev", "e5", "Clôture de\\nla collecte"), ("op", "o5", "OP5 — Traiter les préoccupations de l'UTR",
     ["examiner les suggestions de fusion", "fusionner, scinder, déplacer des contributions",
      "rédiger intitulés et synthèses", "valider ou écarter (motif)"], ["toutes traitées"]),
    ("res", "r5", "Préoccupations\\ntraitées"), ("ev", "c5", "Aucune contribution\\nen modération"),
    ("ev", "c6", "Validation régionale\\ntenue (atelier)"), ("sync", "s6", "ET"),
    ("op", "o6", "OP6 — Composer et publier le LBR",
     ["générer le brouillon (classement par score)", "rédiger l'introduction", "saisir la date de validation (RG-55)",
      "figer le contenu et les paramètres (RG-54)", "générer les exports PDF et Word"], ["publication"]),
    ("res", "r6", "Livre blanc régional\\npublié et figé"),
    ("ev", "e7", "Correction\\ndemandée"), ("op", "o7", "OP7 — Ouvrir une nouvelle version",
     ["créer un brouillon n+1", "déverrouiller les préoccupations (RG-56)"], ["brouillon créé"]),
    ("res", "r7", "Brouillon\\nversion n+1"),
    ("e", "e5", "o5"), ("e", "o5", "r5"), ("e", "r5", "s6"), ("e", "c5", "s6"), ("e", "c6", "s6"), ("e", "s6", "o6"),
    ("e", "o6", "r6"), ("e", "r6", "e7"), ("e", "e7", "o7"), ("e", "o7", "r7"), ("e", "r7", "o5"),
    ("rank", ["r5", "c5", "c6"]),
]
MCT_NATIONAL = [
    ("ev", "c8", "≥ 80 % des LBR\\npubliés (RG-61)"), ("ev", "e8", "Ouverture des\\nétats généraux"), ("sync", "s8", "ET"),
    ("op", "o8", "OP8 — Calculer la consolidation nationale",
     ["comparer les préoccupations validées entre UTR", "regrouper en convergences (≥ 0,28)",
      "calculer le score national (T, P, S)", "proposer une classe et un texte"], ["calcul terminé"]),
    ("res", "r8", "Convergences\\nproposées"),
    ("op", "o9", "OP9 — Arbitrer en états généraux",
     ["retenir, fusionner, scinder, rejeter, reclasser", "motiver chaque décision (RG-63, RG-64)",
      "réécrire intitulés et synthèses"], ["toutes arbitrées"]),
    ("res", "r9", "Convergences\\narbitrées"), ("op", "o10", "OP10 — Publier le livre blanc national",
     ["générer le document national", "figer contenu et paramètres", "générer les exports PDF et Word"], ["publication"]),
    ("res", "r10", "Livre blanc national\\npublié"),
    ("e", "c8", "s8"), ("e", "e8", "s8"), ("e", "s8", "o8"), ("e", "o8", "r8"), ("e", "r8", "o9"), ("e", "o9", "r9"),
    ("e", "r9", "o10"), ("e", "o10", "r10"),
    ("rank", ["c8", "e8"]),
]
MCT_ENGAGEMENTS = [
    ("ev", "r10", "Livre blanc national\\npublié"),
    ("ev", "c11", "Candidat enregistré\\net date d'élection future"), ("ev", "e11", "Engagement\\nsoumis"), ("sync", "s11", "ET"),
    ("op", "o11", "OP11 — Enregistrer l'engagement",
     ["contrôler la cible (RG-71)", "contrôler l'unicité (RG-72)", "publier l'engagement"], ["accepté", "sinon refus"]),
    ("res", "r11", "Engagement\\npublié"), ("res", "r11b", "Engagement\\nrefusé"),
    ("ev", "c12", "Phase de suivi\\net candidat élu"), ("ev", "e12", "Information sur\\nune réalisation"), ("sync", "s12", "ET"),
    ("op", "o12", "OP12 — Mettre à jour le suivi",
     ["saisir état, date et description", "joindre au moins un justificatif (RG-74)", "recalculer le taux (RG-75)"],
     ["mise à jour enregistrée"]),
    ("res", "r12", "Taux de réalisation\\nactualisé"),
    ("e", "r10", "s11"), ("e", "c11", "s11"), ("e", "e11", "s11"), ("e", "s11", "o11"), ("e", "o11", "r11"),
    ("e", "o11", "r11b"), ("e", "r11", "s12"), ("e", "c12", "s12"), ("e", "e12", "s12"),
    ("e", "s12", "o12"), ("e", "o12", "r12"),
    ("rank", ["r10", "c11", "e11"]), ("rank", ["r11", "c12", "e12"]),
]

VUES_MCT = [("mct_1_comptes", MCT_COMPTES), ("mct_2_collecte", MCT_COLLECTE), ("mct_3_regional", MCT_REGIONAL),
            ("mct_4_national", MCT_NATIONAL), ("mct_5_engagements", MCT_ENGAGEMENTS)]

if __name__ == "__main__":
    mcc()
    ordonnancement()
    for nom, items in VUES_MCT:
        mct(nom, nom, items)
    print("ok")
