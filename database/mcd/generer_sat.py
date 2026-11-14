# -*- coding: utf-8 -*-
"""Structure d'accès théorique (SAT) : graphe des dépendances fonctionnelles entre identifiants,
déduit de mcd_spec.py.
- patte de cardinalité maximale 1 côté X, autre patte côté Y  →  id_X → id_Y
  (trait plein si minimum 1 : dépendance totale ; pointillé si minimum 0 : dépendance partielle) ;
- association à cardinalités maximales n des deux côtés → nœud composé (id_X, id_Y) portant les propriétés.
"""
import os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mcd_spec import ENTITES, ASSOCIATIONS

RACINE = __import__("pathlib").Path(__file__).resolve().parents[2]
OUT = os.environ.get("MCD_OUT", str(RACINE / "diagrams" / "merise") + "/")
NAVY, LIGHT = "#1A365D", "#E6EEF8"
ident = {e: v[0] for e, v in ENTITES.items()}
L = ['digraph SAT {',
     'graph [rankdir=TB, splines=true, nodesep=0.18, ranksep=0.55, newrank=true, pad=0.3, dpi=200, fontname="Liberation Sans"];',
     'node [shape=box, style="rounded,filled", fillcolor="white", color="%s", fontname="Liberation Sans", fontsize=13];' % NAVY,
     'edge [color="#4A5568", fontname="Liberation Sans", fontsize=11, arrowsize=0.7];']
for e, i in ident.items():
    L.append('"%s" [label=<<B>%s</B><BR/><FONT POINT-SIZE="10">%s</FONT>>];' % (e, i, e))
nb_df = 0
for nom, pattes, props, regle in ASSOCIATIONS:
    maxi = [c.split(",")[1] for _, c, _ in pattes]
    if all(m != "1" for m in maxi):
        (a, _, _), (b, _, _) = pattes
        k = "K_" + nom
        lab = "(%s, %s)" % (ident[a], ident[b])
        extra = ("<BR/><FONT POINT-SIZE=\"9\">%s</FONT>" % ", ".join(props)) if props else ""
        L.append('"%s" [shape=ellipse, fillcolor="%s", label=<<B>%s</B><BR/><FONT POINT-SIZE="9">%s</FONT>%s>];'
                 % (k, LIGHT, nom.replace("_", " ").lower(), lab, extra))
        L.append('"%s" -> "%s" [arrowhead=none, style=dotted];' % (k, a))
        L.append('"%s" -> "%s" [arrowhead=none, style=dotted];' % (k, b))
        continue
    sources = [idx for idx, (_, c, _) in enumerate(pattes) if c.split(",")[1] == "1"]
    if len(sources) == 2 and pattes[0][0] != pattes[1][0]:
        # association 1-1 : une seule dépendance, dans le sens retenu pour le MLD
        # (côté de cardinalité minimale 1 s'il existe, sinon la première patte)
        sources = [next((i for i in sources if pattes[i][1].startswith("1")), sources[0])]
    for idx, (x, card, role) in enumerate(pattes):
        if idx not in sources:
            continue
        y = pattes[1 - idx][0]
        style = "solid" if card.startswith("1") else "dashed"
        L.append('"%s" -> "%s" [style=%s, xlabel="%s"];' % (x, y, style, nom.replace("_", " ").lower()))
        nb_df += 1
L.append("}")
open(OUT + "sat.dot", "w", encoding="utf8").write("\n".join(L))
subprocess.run(["dot", "-Tpng", OUT + "sat.dot", "-o", OUT + "sat.png"], check=True)
subprocess.run(["dot", "-Tsvg", OUT + "sat.dot", "-o", OUT + "sat.svg"], check=True)
print("SAT :", nb_df, "dépendances fonctionnelles")
