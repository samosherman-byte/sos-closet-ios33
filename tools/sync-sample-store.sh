#!/bin/sh
# Copies what the app takes from the website, unchanged, from the site's repo next to this one
# (../sos-closet-storefront, read-only: this script only reads it). Run it after cloning, and again after
# `git -C ../sos-closet-storefront pull` when the site's catalog, photos or tiles change. APP-SPEC.md §5.
#
#   SampleStore/  the sample store, for building and testing (Debug builds only; release builds leave it out):
#                 the site's import files (data/shopify-products.csv, data/product-images.csv), the photo sizes
#                 (data/photo-fit.json), the catalog the tests check the mapping against (data/catalog.json),
#                 the stand-ins for what the live store keeps in Shopify (data/merch.json: the case's story
#                 lines and featured piece, and the home page's "Home row" collections), and the prototype's photos (prototype/img/*.jpg), at the same paths as in the site, so the
#                 import file's photo paths work as they are; and for the tests only, what the site's prototype showed
#                 on each browse page (test/golden/, the site's own golden test files; left out of the app).
#   SiteAssets/   the photos the app ships: the category cutouts (public/tiles/) and the home page's (public/home/).
#
# Both folders are git-ignored: this repo is public, and the photos stay out of it.
# SITE=/path/to/sos-closet-storefront tools/sync-sample-store.sh reads the site from somewhere else.
set -eu

here="$(cd "$(dirname "$0")/.." && pwd)"
site="${SITE:-$here/../sos-closet-storefront}"

if [ ! -f "$site/SPEC.md" ] || [ ! -d "$site/data" ]; then
  echo "The website repo isn't at $site."
  echo "Clone it next to this folder: git clone https://github.com/samosherman-byte/sos-closet-storefront.git \"$here/../sos-closet-storefront\""
  exit 1
fi
site="$(cd "$site" && pwd)"

mkdir -p "$here/SampleStore/data" "$here/SampleStore/test/golden" "$here/SampleStore/prototype/img" "$here/SiteAssets/tiles" "$here/SiteAssets/home"

for f in shopify-products.csv product-images.csv photo-fit.json catalog.json merch.json; do
  cp -p "$site/data/$f" "$here/SampleStore/data/$f"
done
for f in scenarios.json prototype.json; do
  cp -p "$site/test/golden/$f" "$here/SampleStore/test/golden/$f"
done
rsync -a --delete --include='*.jpg' --exclude='*' "$site/prototype/img/" "$here/SampleStore/prototype/img/"
rsync -a --delete "$site/public/tiles/" "$here/SiteAssets/tiles/"
rsync -a --delete "$site/public/home/" "$here/SiteAssets/home/"

# Note where the copies came from, so a difference from the site can be traced to a commit.
commit="$(git -C "$site" rev-parse --short HEAD 2>/dev/null || echo unknown)"
if [ -n "$(git -C "$site" status --porcelain 2>/dev/null)" ]; then commit="$commit (with uncommitted changes)"; fi
note="Copied from sos-closet-storefront at $commit on $(date '+%Y-%m-%d %H:%M') by tools/sync-sample-store.sh"
echo "$note" > "$here/SampleStore/SOURCE.txt"
echo "$note" > "$here/SiteAssets/SOURCE.txt"

photos="$(ls "$here/SampleStore/prototype/img" | wc -l | tr -d ' ')"
tiles="$(ls "$here/SiteAssets/tiles" | wc -l | tr -d ' ')"
echo "$note"
echo "SampleStore: 5 data files, 2 golden test files, $photos photos. SiteAssets: $tiles tiles, $(ls "$here/SiteAssets/home" | wc -l | tr -d ' ') home photos."
