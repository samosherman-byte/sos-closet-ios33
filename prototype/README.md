# The app prototype

The SOS Closet app's screens, as designed on Claude's design canvas ("SOS Closet App Prototype"), in a form that runs in any browser and in the iPhone Simulator's own Safari. **It's the look and motion to build to**: every screen of phase 1 (and phase 2's Search) at the iPhone's 390 × 844 points, with the same sizes, type, colors, spacing and behavior the app should have. A point in the app is a pixel here.

Where this prototype and the website's prototype differ, this one wins for the app (it's where the app's own decisions are: `../docs/design-decisions.md`); for anything it doesn't show, the website's SPEC.md and prototype are the source.

## Run it

From the repo's folder on the Mac, with the website repo cloned next to it:

```sh
tools/sync-sample-store.sh          # copies the site's photos in (once after cloning, and after pulling the site)
python3 prototype/build.py          # builds the screens into prototype/build/
python3 -m http.server 8000         # serve the repo's folder (not prototype/: the photos are in SampleStore/ and SiteAssets/)
```

Then open http://localhost:8000/prototype/ in a browser: the screens are listed on the left. In the Simulator, open it in Safari at the same size as the app to compare: `xcrun simctl openurl booted "http://localhost:8000/prototype/#Shop"` (the name after `#` picks the screen; on a phone-sized window the list hides and the screen fills the top left).

Screens marked **live** scroll and respond: scroll Shop to see the tabs make way for the place line, tap the place line for the directory, turn the bags on Home, swipe the Jackie's photos on its card and its page, type in Search. The others hold one moment of a live screen still (Shop scrolled down, scrolling back up, the directory open, Filter open, Shop All, Jewelry & Objects; Home at its rooms; the product page scrolled). Every piece opens the Jackie's page, which stands in for any product page.

## What's in here

- `src/`: the screens' sources (`gen_*.py` hold each screen's markup and behavior; `common.py` the shared card, glass and colors). The screens are built from the website's own data each time, so nothing copied from the site is committed (this repo is public): `extract.js` reads the pieces, photo roles, story lines and grades from the site's prototype, `build_data.py` picks the pieces each screen shows, and the photos are the site's own files, which `tools/sync-sample-store.sh` copies into `SampleStore/` and `SiteAssets/` (git-ignored). Home's rooms show the live site's Shopify photos (the shadow versions), with the live picks, prices and placements of November 5.
- `build/` (git-ignored): the built screens, one `.dc.html` file each, the format of Claude's design canvas.
- `dc.js`: a small runner for those files (it fills in each screen and patches it in place as it changes), and `index.html`, the page that lists and shows them. `boards.json` is the list, in the canvas's order.
- `src/check.js`: runs every screen's logic once without a browser (each still moment, the Filters rows, the directory, each department) and checks nothing is missing; `build.py` runs it after building.

## Changing a screen

Change it on the canvas with Claude first (Sam's process: settle it in the prototype, then build), then bring the same change into `src/`, rebuild, and update `APP-SPEC.md` and `docs/design-decisions.md` on a `prototype/…` branch.
