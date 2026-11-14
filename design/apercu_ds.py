# Rendu local des aperçus du système de design (contrôle visuel avant publication).
import json, os, re, sys, asyncio
from playwright.async_api import async_playwright
P = str(__import__("pathlib").Path(__file__).resolve().parent / "design-system" / "project") + "/"
t = json.load(open(P + "tokens.json"))
vals = {x["name"]: x["value"] for x in t["color"]["tokens"]}
css = [":root{"]
for n, v in vals.items():
    css.append("--%s:%s;" % (n, re.sub(r"\{(.+?)\}", r"var(--\1)", v)))
for fam in ("spacing", "radius", "shadow", "trait"):
    for x in t[fam]["tokens"]:
        css.append("--%s:%s;" % (x["name"], x["value"]))
for k, v in t["type"]["families"].items():
    css.append("--font-%s:%s;" % (k, v))
css.append("}")
TOK = "".join(css)
BUNDLE = open(P + "components/bundle.css").read()
async def main(names):
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path="/usr/bin/google-chrome")
        pg = await b.new_page(viewport={"width": 960, "height": 800}, device_scale_factor=1)
        for n in names:
            body = open(P + "components/%s/preview.html" % n).read()
            html = "<!doctype html><html lang=fr data-theme=clair><head><meta charset=utf-8><style>%s</style><style>%s</style><style>body{margin:0;background:var(--papier)}</style></head><body>%s</body></html>" % (TOK, BUNDLE, body)
            await pg.set_content(html, wait_until="networkidle")
            await pg.wait_for_timeout(400)
            await pg.screenshot(path="/tmp/dsprev/%s.png" % n, full_page=True)
        await b.close()
asyncio.run(main(sys.argv[1:]))
