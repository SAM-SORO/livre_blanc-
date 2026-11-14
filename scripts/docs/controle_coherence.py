"""Contrôle de cohérence entre les documents (PRD, TRD, schémas, API) et la base migrée.
Usage : python3 scripts/docs/controle_coherence.py  (variables PGHOST, PGPORT, PGUSER, PGDATABASE)."""
import os, re, pathlib, subprocess, sys
R = pathlib.Path(__file__).resolve().parents[2]
docs = {p.name: p.read_text() for p in (R/'docs').glob('*.md')}
prd = docs['PRD.md']
rg_def = set(re.findall(r'\*\*(RG-\d+)\.\*\*', prd))
f_def = set(re.findall(r'^\| (F-\d+) \|', prd, re.M))
nf_def = set(re.findall(r'\*\*(NF-\d+)\.\*\*', prd))
d_def = set(re.findall(r'^\| (D-\d+) \|', prd, re.M))
ko = 0
def sql(q):
    return subprocess.run(['psql','-h',os.environ.get('PGHOST','localhost'),'-p',os.environ.get('PGPORT','5432'),'-U',os.environ.get('PGUSER','postgres'),'-d',os.environ.get('PGDATABASE','lbc_test'),'-Atc',q],capture_output=True,text=True).stdout.split()
contraintes = set(sql("select conname from pg_constraint"))|set(sql("select indexname from pg_indexes where schemaname='public'"))
fonctions = set(sql("select proname from pg_proc where pronamespace='public'::regnamespace"))
tables = set(sql("select tablename from pg_tables where schemaname='public'"))
vues = set(sql("select viewname from pg_views where schemaname='public'"))
api = (R/'api/endpoints.py').read_text()
sources = dict(docs); sources['endpoints.py'] = api
for nom, txt in sources.items():
    for pat, ens, lab in [(r'RG-\d+', rg_def, 'RG'), (r'\bF-\d+', f_def, 'F'), (r'NF-\d+', nf_def, 'NF'), (r'\bD-\d+', d_def, 'D')]:
        for x in sorted(set(re.findall(pat, txt)) - ens):
            print(f'{nom}: {lab} inconnu {x}'); ko += 1
    for img in re.findall(r'!\[[^\]]*\]\(([^)]+)\)', txt):
        if not (R/'docs'/img).resolve().exists(): print(f'{nom}: image absente {img}'); ko += 1
ds = docs['DATABASE_SCHEMA.md'] + docs['API_SPECIFICATIONS.md'] + docs['TRD.md']
for c in sorted(set(re.findall(r'`((?:ck|ux|ix|fk)_[a-z_]+|[a-z_]+_pkey|[a-z_]+_key)`', ds))):
    if c not in contraintes: print('contrainte inconnue', c); ko += 1
for f in sorted(set(re.findall(r'`([a-z_]+)\(\)`', ds))):
    if f not in fonctions and f not in ('hashPassword','verifyPassword','uuidv7','auditer','to_tsvector'): print('fonction inconnue', f); ko += 1
for v in sorted(set(re.findall(r'`(v_[a-z_]+)`', ds))):
    if v not in vues: print('vue inconnue', v); ko += 1
for t in sorted(set(re.findall(r'`([a-z_]+)\.[a-z_]+`', ds))):
    if t not in tables and t not in ('edition','server','calcul_consolidation','version_livre_blanc','preoccupation','contribution','convergence','organisation','territoire') : print('table ?', t)
# seuils
for nom in ('PRD.md','TRD.md','DATABASE_SCHEMA.md'):
    t = docs[nom]
    for v in ('0,20','0,30','0,60','0,28'):
        pass
trd = docs['TRD.md']
for k,v in {'suggestion':'0.20','rattachement':'0.30','doublon':'0.60','convergence':'0.28'}.items():
    if f'"{k}": {v}' not in trd: print('TRD seuil', k); ko += 1
for v in ('| 0,20 |','| 0,30 |','| 0,60 |','| 0,28 |'):
    if v not in prd: print('PRD seuil', v); ko+=1
    if v not in docs['DATABASE_SCHEMA.md']: print('DB doc seuil', v); ko+=1
print('RG définies', len(rg_def), 'F', len(f_def), 'NF', len(nf_def), 'D', len(d_def))
print('ANOMALIES', ko)
