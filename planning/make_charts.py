# -*- coding: utf-8 -*-
"""Diagramme de Gantt, organigramme des tâches et organigramme des responsabilités (figures du rapport)."""
import datetime as dt
import os, sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.patches import FancyBboxPatch, Polygon

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import plan as P

OUT = str(__import__("pathlib").Path(__file__).resolve().parents[1] / "diagrams" / "rapport") + "/"
plt.rcParams["font.family"] = "Liberation Sans"
NAVY, BLUE, LIGHT, GREY, INK = "#1A365D", "#2C5282", "#C9DAF0", "#A0AEC0", "#1A202C"
MOIS = ["janv.", "févr.", "mars", "avr.", "mai", "juin", "juil.", "août", "sept.", "oct.", "nov.", "déc."]


def fr(d):
    return d.strftime("%d/%m/%y")


# ------------------------------------------------------------------ Gantt
rows = P.resolved()
n = len(rows)
fig = plt.figure(figsize=(11.2, 7.6), dpi=200)
gs = fig.add_gridspec(1, 2, width_ratios=[1.32, 1.5], wspace=0.0)
axt = fig.add_subplot(gs[0])
ax = fig.add_subplot(gs[1], sharey=axt)
y = list(range(n))[::-1]
t0, t1 = P.START - dt.timedelta(days=2), P.FINISH + dt.timedelta(days=3)

# colonne tableau
axt.set_xlim(0, 1)
axt.axis("off")
hdr_y = n - 0.1
for x, txt, ha in [(0.02, "N°", "left"), (0.09, "Nom de la tâche", "left"), (0.755, "Durée", "right"),
                   (0.875, "Début", "right"), (0.99, "Fin", "right")]:
    axt.text(x, hdr_y + 0.45, txt, fontsize=8, fontweight="bold", ha=ha, va="center", color=INK)
for yy, r in zip(y, rows):
    if r["summary"]:
        axt.axhspan(yy - 0.5, yy + 0.5, color="#EDF2F7", zorder=0)
    ind = 0.09 + (0.02 if r["level"] > 1 else 0)
    w = "bold" if r["summary"] else "normal"
    axt.text(0.02, yy, r["wbs"], fontsize=7.5, va="center", color=INK, fontweight=w)
    axt.text(ind, yy, r["name"], fontsize=7.5, va="center", color=INK, fontweight=w)
    dur = "0 j" if r["milestone"] else "%d j" % r["days"]
    axt.text(0.755, yy, dur, fontsize=7.5, va="center", ha="right", color=INK, fontweight=w)
    axt.text(0.875, yy, fr(r["start"]), fontsize=7.5, va="center", ha="right", color=INK, fontweight=w)
    axt.text(0.99, yy, fr(r["finish"]), fontsize=7.5, va="center", ha="right", color=INK, fontweight=w)

# zone chronologique
ax.set_xlim(t0, t1)
ax.set_ylim(-0.8, n + 0.9)
d = t0
while d <= t1:
    if d.weekday() >= 5 or d in P.HOLIDAYS:
        ax.axvspan(d, d + dt.timedelta(days=1), color="#F1F3F6", lw=0, zorder=0)
    d += dt.timedelta(days=1)
for yy, r in zip(y, rows):
    if r["summary"]:
        ax.axhspan(yy - 0.5, yy + 0.5, color="#EDF2F7", zorder=0)
    s, f = r["start"], r["finish"] + dt.timedelta(days=1)
    if r["milestone"]:
        cx = r["finish"] + dt.timedelta(hours=20)
        ax.scatter([cx], [yy], marker="D", s=34, color=NAVY, zorder=3)
        ax.text(cx + dt.timedelta(days=1.2), yy, fr(r["finish"]), fontsize=6.5, va="center", color=NAVY)
    elif r["summary"]:
        ax.barh(yy, f - s, left=s, height=0.22, color=INK, zorder=2)
        for xx in (s, f):
            ax.add_patch(Polygon([[mdates.date2num(xx) - 0.6, yy - 0.11], [mdates.date2num(xx) + 0.6, yy - 0.11],
                                  [mdates.date2num(xx), yy - 0.38]], closed=True, color=INK, zorder=2))
    else:
        ax.barh(yy, f - s, left=s, height=0.5, color=LIGHT if r["wbs"] == "6.1" else BLUE,
                edgecolor=BLUE, linewidth=0.6, zorder=2)
ax.xaxis.set_major_locator(mdates.WeekdayLocator(byweekday=mdates.MO))
ax.xaxis.set_major_formatter(mdates.DateFormatter("%d/%m"))
ax.tick_params(axis="x", labelsize=6.5, colors=INK, length=2)
ax.tick_params(axis="y", left=False, labelleft=False)
ax.xaxis.tick_bottom()
for m in [dt.date(2026, 11, 1), dt.date(2026, 12, 1), dt.date(2027, 1, 1)]:
    ax.axvline(m, color=GREY, lw=0.6, ls="--", zorder=1)
for m, lab in [(dt.date(2026, 10, 23), "octobre 2026"), (dt.date(2026, 11, 15), "novembre 2026"),
               (dt.date(2026, 12, 15), "décembre 2026"), (dt.date(2027, 1, 8), "janvier 2027")]:
    ax.text(m, n + 0.35, lab, fontsize=7.5, ha="center", color=NAVY, fontweight="bold")
ax.grid(axis="x", color="#E2E8F0", lw=0.5)
for sp in ["right", "top", "left"]:
    ax.spines[sp].set_visible(False)
ax.spines["bottom"].set_color(GREY)
fig.savefig(OUT + "fig_gantt.png", bbox_inches="tight", facecolor="white")
plt.close(fig)


# ------------------------------------------------------------------ boîtes
def box(ax, x, y, w, h, text, fill="#E6EEF8", edge=BLUE, bold=False, size=8.5, color=INK, dashed=False):
    ax.add_patch(FancyBboxPatch((x - w / 2, y - h / 2), w, h, boxstyle="round,pad=0.008,rounding_size=0.012",
                                fc=fill, ec=edge, lw=1.0, ls="--" if dashed else "-", zorder=2))
    ax.text(x, y, text, ha="center", va="center", fontsize=size, color=color,
            fontweight="bold" if bold else "normal", zorder=3, linespacing=1.25)


def line(ax, pts, dashed=False):
    xs, ys = zip(*pts)
    ax.plot(xs, ys, color="#4A5568", lw=1.0, ls="--" if dashed else "-", zorder=1)


# ------------------------------------------------------------------ organigramme des tâches (WBS)
phases = [r for r in rows if r["summary"]]
fig, ax = plt.subplots(figsize=(11, 5.6), dpi=200)
ax.set_xlim(0, 1)
ax.set_ylim(0.2, 1)
ax.axis("off")
box(ax, 0.5, 0.94, 0.34, 0.07, "PROJET LIVRE BLANC CITOYEN", fill=NAVY, edge=NAVY, bold=True, size=10, color="white")
xs = [0.085 + i * 0.166 for i in range(6)]
line(ax, [(0.5, 0.905), (0.5, 0.86)])
line(ax, [(xs[0], 0.86), (xs[-1], 0.86)])
wrap = {"1": "Audit et\ncompréhension", "2": "Cadrage\nfonctionnel", "3": "Conception\n(MERISE, architecture)",
        "4": "Conception des\ninterfaces", "5": "Réalisation\ndu prototype", "6": "Rédaction et\nsoutenance"}
import textwrap
for x, ph in zip(xs, phases):
    line(ax, [(x, 0.86), (x, 0.825)])
    box(ax, x, 0.78, 0.13, 0.085, "%s. %s" % (ph["wbs"], wrap[ph["wbs"]]), fill=LIGHT, edge=NAVY, bold=True, size=7.6)
    kids = [r for r in rows if r["wbs"].startswith(ph["wbs"] + ".")]
    yk = 0.66
    line(ax, [(x - 0.066, 0.73), (x - 0.066, yk - (len(kids) - 1) * 0.13)])
    for k in kids:
        line(ax, [(x - 0.066, yk), (x - 0.051, yk)])
        txt = "\n".join(textwrap.wrap(k["name"], 18))
        box(ax, x + 0.008, yk, 0.11, 0.10, "%s\n%s" % (k["wbs"], txt), fill="#FFFFFF" if not k["milestone"] else "#EDF2F7",
            edge=BLUE if not k["milestone"] else NAVY, size=6.6)
        yk -= 0.13
fig.savefig(OUT + "fig_organigramme_taches.png", bbox_inches="tight", facecolor="white")
plt.close(fig)

# ------------------------------------------------------------------ organigramme des responsabilités
fig, ax = plt.subplots(figsize=(10, 6.0), dpi=200)
ax.set_xlim(0, 1)
ax.set_ylim(0, 1)
ax.axis("off")
box(ax, 0.5, 0.93, 0.36, 0.09, "Encadreur pédagogique\nDr APPOH", fill="#FFFFFF", edge=NAVY, size=9, dashed=True)
line(ax, [(0.5, 0.885), (0.5, 0.80)], dashed=True)
box(ax, 0.5, 0.75, 0.44, 0.10, "Responsable d'équipe\nSORO Koromiwonah Segneniguetenin Samuel", fill=NAVY, edge=NAVY,
    size=9, bold=True, color="white")
line(ax, [(0.5, 0.70), (0.5, 0.64)])
line(ax, [(0.125, 0.64), (0.875, 0.64)])
members = [m[0] for m in P.TEAM]
mx = [0.125, 0.375, 0.625, 0.875]
for x, m in zip(mx, members):
    line(ax, [(x, 0.64), (x, 0.60)])
    nm = "\n".join(textwrap.wrap(m, 22))
    box(ax, x, 0.54, 0.22, 0.11, nm, fill=LIGHT, edge=BLUE, size=8)
    line(ax, [(x, 0.485), (x, 0.43)])
line(ax, [(0.125, 0.43), (0.875, 0.43)])
line(ax, [(0.5, 0.43), (0.5, 0.39)])
box(ax, 0.5, 0.30, 0.86, 0.17,
    "Participation collective à toutes les grandes phases\n"
    "1. Audit et compréhension   ·   2. Cadrage fonctionnel   ·   3. Conception\n"
    "4. Conception des interfaces   ·   5. Réalisation du prototype   ·   6. Rédaction et soutenance",
    fill="#F7FAFC", edge=BLUE, size=8.5)
ax.text(0.5, 0.15, "Le responsable d'équipe coordonne les travaux, répartit les tâches au sein de chaque phase\n"
        "et assure le lien avec l'encadreur pédagogique.", ha="center", va="center", fontsize=8, color="#4A5568",
        style="italic")
fig.savefig(OUT + "fig_organigramme_responsabilites.png", bbox_inches="tight", facecolor="white")
plt.close(fig)
print("figures générées")
