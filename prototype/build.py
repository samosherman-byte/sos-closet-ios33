#!/usr/bin/env python3
"""Builds the app prototype's screens into prototype/build/ (git-ignored).

The screens are the ones on Claude's design canvas ("SOS Closet App Prototype"); src/ holds their sources. The pieces
and photos come from the website, read-only, so nothing copied from the site is committed here (this repo is public):
the pieces from the site's prototype in ../sos-closet-storefront, and the photos from SampleStore/ and SiteAssets/,
which tools/sync-sample-store.sh copies in. The home page's rooms show the live site's own Shopify photos.

    tools/sync-sample-store.sh        # once after cloning, and after pulling the site
    python3 prototype/build.py
    python3 -m http.server 8000       # in the repo's folder
    open http://localhost:8000/prototype/

Needs Python 3 and Node.js.
"""
import os, subprocess, sys

here = os.path.dirname(os.path.abspath(__file__))
repo = os.path.dirname(here)
site = os.path.abspath(os.environ.get('SITE', os.path.join(repo, '..', 'sos-closet-storefront')))
if not os.path.isfile(os.path.join(site, 'prototype', 'src.html')):
    sys.exit("The website repo isn't at " + site + ". Clone it next to this folder, or set SITE=/path/to/sos-closet-storefront.")
if not os.path.isdir(os.path.join(repo, 'SampleStore', 'prototype', 'img')) or not os.path.isdir(os.path.join(repo, 'SiteAssets', 'tiles')):
    sys.exit("The site's photos aren't here yet: run tools/sync-sample-store.sh first.")

out = os.path.join(here, 'build')
work = os.path.join(out, '.work')
os.makedirs(work, exist_ok=True)
env = dict(os.environ, SITE=site, WORK=work, OUT=out)
src = os.path.join(here, 'src')

def run(*cmd):
    r = subprocess.run(cmd, cwd=src, env=env)
    if r.returncode: sys.exit(r.returncode)

run('node', 'extract.js', os.path.join(site, 'prototype'), work)
run(sys.executable, 'build_data.py', work)
for g in ['gen_tabbar.py', 'gen_shop.py', 'gen_main.py', 'gen_rest.py']:
    run(sys.executable, g)
run('node', 'check.js', out)
print('Built the screens into prototype/build/. Serve the repo folder (python3 -m http.server 8000) and open http://localhost:8000/prototype/')
