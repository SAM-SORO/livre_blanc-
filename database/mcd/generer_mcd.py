# -*- coding: utf-8 -*-
"""Génère les diagrammes du MCD (notation MERISE) à partir de mcd_spec.py, avec Graphviz."""
import os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mcd_spec import ENTITES, ASSOCIATIONS, VUES

RACINE = __import__("pathlib").Path(__file__).resolve().parents[2]
OUT = os.environ.get("MCD_OUT", str(RACINE / "diagrams" / "merise") + "/")
os.makedirs(OUT, exist_ok=True)
NAVY, BLUE, LIGHT, GREY = "#1A365D", "#2C5282", "#E6EEF8", "#A0AEC0"
# Réglages de mise en page (lisibilité une fois le diagramme réduit à la largeur d'une page A4)
P = dict(overlap=os.environ.get("MCD_OVERLAP", "prism"), scaling=os.environ.get("MCD_SCALING", "-2"),
         sep=os.environ.get("MCD_SEP", "+10"), len=os.environ.get("MCD_LEN", "1.1"),
         font=int(os.environ.get("MCD_FONT", "14")))
ASSOC = {a[0]: a for a in ASSOCIATIONS}


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def entite_label(nom, complet=True):
    ident, props = ENTITES[nom]
    head = '<TR><TD BGCOLOR="%s" ALIGN="CENTER"><FONT COLOR="white" POINT-SIZE="%d"><B>%s</B></FONT></TD></TR>' % (
        NAVY if complet else "#718096", P["font"] + 1, esc(nom))
    rows = '<TR><TD ALIGN="LEFT"><U>%s</U></TD></TR>' % esc(ident)
    if complet:
        rows += "".join('<TR><TD ALIGN="LEFT">%s</TD></TR>' % esc(p) for p in props)
    return ('<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" CELLPADDING="3" COLOR="%s" BGCOLOR="white">%s%s</TABLE>>'
            % (NAVY if complet else GREY, head, rows))


def assoc_label(nom, props):
    p = "".join('<BR/><FONT POINT-SIZE="%s">%s</FONT>' % (P["font"] - 1.5, esc(x)) for x in props)
    return '<<B>%s</B>%s>' % (esc(nom.replace("_", " ").lower()), p)


def vue(nom_vue, cfg):
    lines = ['graph G {',
             'graph [layout=neato, overlap=%s, overlap_scaling=%s, sep="%s", splines=true, pad=0.3, dpi=200, '
             'fontname="Liberation Sans", bgcolor="white"];' % (P["overlap"], P["scaling"], P["sep"]),
             'node [fontname="Liberation Sans", fontsize=%d];' % P["font"],
             'edge [fontname="Liberation Sans", fontsize=%d, color="#4A5568", fontcolor="#1A202C", len=%s];' % (P["font"], P["len"])]
    for e in cfg["entites"]:
        lines.append('"%s" [shape=plain, label=%s];' % (e, entite_label(e, True)))
    for e in cfg["rappels"]:
        lines.append('"%s" [shape=plain, label=%s];' % (e, entite_label(e, False)))
    for a in cfg["associations"]:
        nom, pattes, props, regle = ASSOC[a]
        lines.append('"A_%s" [shape=ellipse, style=filled, fillcolor="%s", color="%s", margin="0.08,0.04", label=%s];'
                     % (nom, LIGHT, BLUE, assoc_label(nom, props)))
        for ent, card, role in pattes:
            lab = card + (" (%s)" % role if role else "")
            if os.environ.get("MCD_HEADLABEL", "1") == "1":
                reflexive = len({x[0] for x in pattes}) == 1
                base = float(P["len"]) if ent in cfg["entites"] else float(P["len"]) + 0.3
                angle = -28 if reflexive else 22
                if reflexive and pattes.index((ent, card, role)) == 1:
                    # second brin d'une association réflexive : cardinalité au milieu, pour ne pas chevaucher le premier
                    lines.append('"A_%s" -- "%s" [label="%s", len=%.2f];' % (nom, ent, lab, base + 0.9))
                else:
                    lines.append('"A_%s" -- "%s" [headlabel="%s", labeldistance=%s, labelangle=%d, labelfontsize=%s, len=%.2f];'
                                 % (nom, ent, lab, 4.2 if reflexive else 2.2, angle, P["font"] - 1, base + (0.9 if reflexive else 0)))
            else:
                lines.append('"A_%s" -- "%s" [label="%s", len=%s];' % (nom, ent, lab, P["len"] if ent in cfg["entites"] else str(float(P["len"]) + 0.3)))
    lines.append("}")
    dot = "\n".join(lines)
    path = OUT + nom_vue
    open(path + ".dot", "w", encoding="utf8").write(dot)
    subprocess.run(["neato", "-Tpng", path + ".dot", "-o", path + ".png"], check=True)
    subprocess.run(["neato", "-Tsvg", path + ".dot", "-o", path + ".svg"], check=True)
    return path + ".png"


if __name__ == "__main__":
    for k, cfg in VUES.items():
        print(vue(k, cfg))
    # contrôle : chaque association est dessinée dans au moins une vue
    dessinees = {a for cfg in VUES.values() for a in cfg["associations"]}
    manquantes = [a[0] for a in ASSOCIATIONS if a[0] not in dessinees]
    assert not manquantes, manquantes
    print("associations :", len(ASSOCIATIONS), "entités :", len(ENTITES))
