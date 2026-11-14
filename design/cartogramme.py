# -*- coding: utf-8 -*-
"""Cartogramme en tuiles des 33 UTR de Côte d'Ivoire (31 régions + 2 districts autonomes).
Positions approximatives des chefs-lieux (degrés décimaux, à vérifier sur le référentiel COD-AB),
affectées à une grille par affectation optimale (méthode hongroise)."""
import json, math
from scipy.optimize import linear_sum_assignment

UTR = [  # code, libellé, chef-lieu, lat, lon, district
 ("ABJ","Abidjan","Abidjan",5.35,-4.01,"District autonome"),("YAM","Yamoussoukro","Yamoussoukro",6.82,-5.28,"District autonome"),
 ("TON","Tonkpi","Man",7.41,-7.55,"Montagnes"),("GUE","Guémon","Duékoué",6.74,-7.35,"Montagnes"),("CAV","Cavally","Guiglo",6.54,-7.49,"Montagnes"),
 ("SPE","San-Pédro","San-Pédro",4.75,-6.64,"Bas-Sassandra"),("NAW","Nawa","Soubré",5.78,-6.60,"Bas-Sassandra"),("GBO","Gbôklé","Sassandra",4.95,-6.08,"Bas-Sassandra"),
 ("HSA","Haut-Sassandra","Daloa",6.88,-6.45,"Sassandra-Marahoué"),("MAR","Marahoué","Bouaflé",6.99,-5.75,"Sassandra-Marahoué"),
 ("GBE","Gbêkê","Bouaké",7.69,-5.03,"Vallée du Bandama"),("HAM","Hambol","Katiola",8.13,-5.10,"Vallée du Bandama"),
 ("BEL","Bélier","Toumodi",6.55,-5.02,"Lacs"),("IFF","Iffou","Daoukro",7.06,-3.96,"Lacs"),("NZI","N'Zi","Dimbokro",6.65,-4.70,"Lacs"),("MOR","Moronou","Bongouanou",6.65,-4.20,"Lacs"),
 ("AGT","Agnéby-Tiassa","Agboville",5.93,-4.21,"Lagunes"),("GPO","Grands-Ponts","Dabou",5.32,-4.38,"Lagunes"),("LME","La Mé","Adzopé",6.10,-3.86,"Lagunes"),
 ("SCO","Sud-Comoé","Aboisso",5.47,-3.21,"Comoé"),("IDJ","Indénié-Djuablin","Abengourou",6.73,-3.49,"Comoé"),
 ("GON","Gontougo","Bondoukou",8.04,-2.80,"Zanzan"),("BKA","Bounkani","Bouna",9.27,-3.00,"Zanzan"),
 ("BER","Béré","Mankono",8.06,-6.19,"Woroba"),("BAF","Bafing","Touba",8.28,-7.68,"Woroba"),("WOR","Worodougou","Séguéla",7.96,-6.67,"Woroba"),
 ("KAB","Kabadougou","Odienné",9.50,-7.56,"Denguélé"),("FOL","Folon","Minignan",9.99,-7.84,"Denguélé"),
 ("POR","Poro","Korhogo",9.46,-5.63,"Savanes"),("TCH","Tchologo","Ferkessédougou",9.60,-5.20,"Savanes"),("BAG","Bagoué","Boundiali",9.52,-6.49,"Savanes"),
 ("GOH","Gôh","Gagnoa",6.13,-5.95,"Gôh-Djiboua"),("LDJ","Lôh-Djiboua","Divo",5.84,-5.36,"Gôh-Djiboua"),
]
assert len(UTR) == 33
COLS, ROWS = 7, 7
lat0, lat1, lon0, lon1 = 4.6, 10.1, -8.0, -2.7
pts = [((lon - lon0) / (lon1 - lon0) * (COLS - 1), (lat1 - lat) / (lat1 - lat0) * (ROWS - 1)) for _, _, _, lat, lon, _ in UTR]
cells = [(c, r) for r in range(ROWS) for c in range(COLS)]
cost = [[(px - c) ** 2 + (py - r) ** 2 for (c, r) in cells] for (px, py) in pts]
ri, ci = linear_sum_assignment(cost)
res = {UTR[i][0]: cells[j] for i, j in zip(ri, ci)}
grid = [["   "] * COLS for _ in range(ROWS)]
for k, (c, r) in res.items():
    grid[r][c] = k
print("\n".join(" ".join(row) for row in grid))
json.dump([{"code": u[0], "libelle": u[1], "chef_lieu": u[2], "district": u[5], "col": res[u[0]][0], "row": res[u[0]][1]} for u in UTR],
          open(__import__("pathlib").Path(__file__).resolve().parent / "cartogramme_utr.json", "w"), ensure_ascii=False, indent=1)
