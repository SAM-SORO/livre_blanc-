"""Régénère docs/DATABASE_SCHEMA.md depuis son modèle, mcd_spec.py, le MLD généré et le journal des tests SQL.
Usage : python3 scripts/docs/remplir_database_schema.py <journal_des_tests_sql.log>"""
import sys, re
import pathlib
R = str(pathlib.Path(__file__).resolve().parents[2]) + '/'
sys.path.insert(0, R + 'database/mcd')
from mcd_spec import ENTITES, ASSOCIATIONS, VUES
tpl = open(R+'docs/_templates/DATABASE_SCHEMA.tpl.md').read()
vue_de = {}
noms_vues = {'mcd_1_acteurs':'1','mcd_2_collecte':'2','mcd_3_livres_blancs':'3','mcd_4_engagements':'4'}
for k,v in VUES.items():
    for e in v['entites']: vue_de[e]=noms_vues[k]
    for a in v['associations']: vue_de[a]=noms_vues[k]
lig = ['| Entité | Identifiant | Propriétés | Vue |','|---|---|---|---|']
for e,(i,props) in ENTITES.items():
    lig.append(f'| {e} | `{i}` | {", ".join(props)} | {vue_de.get(e,"—")} |')
ent = '\n'.join(lig)
lig = ['| Association | Pattes (entité : cardinalité, rôle) | Propriétés | Règle | Vue |','|---|---|---|---|---|']
for nom,pattes,props,rg in ASSOCIATIONS:
    p = ' ; '.join(f'{e} : {c}' + (f' ({r})' if r else '') for e,c,r in pattes)
    lig.append(f'| {nom} | {p} | {", ".join(props) or "—"} | {rg} | {vue_de.get(nom,"—")} |')
ass = '\n'.join(lig)
mld = open(R+'database/generated/MLD.md').read()
m = re.search(r'## Collecte et analyse régionale\n\n(.*?)\n\n## ', mld, re.S)
extrait = m.group(1)
dico = open(R+'database/generated/DICTIONNAIRE.md').read()
# une ligne de tableau par colonne dans le dictionnaire : « | nom | type | … »
nbcol = str(sum(1 for l in dico.splitlines() if l.startswith('| ') and not l.startswith('| Colonne') and l.count('|') >= 6))
log = open(sys.argv[1]).read() if len(sys.argv) > 1 else ''
nbt = log.count('NOTICE:  OK') + len(re.findall(r'^OK', log, re.M))
out = (tpl.replace('{{ENTITES}}', ent).replace('{{ASSOCIATIONS}}', ass).replace('{{MLD_EXTRAIT}}', extrait)
       .replace('{{NB_ENTITES}}', str(len(ENTITES))).replace('{{NB_ASSOCIATIONS}}', str(len(ASSOCIATIONS)))
       .replace('{{NB_COLONNES}}', nbcol).replace('{{NB_TESTS}}', str(nbt)))
assert '{{' not in out
open(R+'docs/DATABASE_SCHEMA.md','w').write(out)
print(len(ENTITES), len(ASSOCIATIONS), nbcol, nbt)
