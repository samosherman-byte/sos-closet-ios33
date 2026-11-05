# The app's design decisions

The decisions that are the app's own, with the reason for each, newest last. Everything the app shares with the website (the brand, the pages, the photo standards, the place line and the directory, and the reasons for them) is decided in the website's `SPEC.md` and `docs/design-decisions.md`; this file doesn't repeat them. Read it before changing anything a shopper sees, so a simplification doesn't undo a deliberate choice.

## The app is its own native storefront, not the website in a frame (October 23)

SwiftUI, reading the same Shopify store through the Storefront API and checking out with Shopify's Checkout Kit. **Why:** Apple turns down apps that are a website in a wrapper (App Store guideline 4.2), and only a native app gets the real Liquid Glass, the system's transitions, sheets and gestures, and the iPhone's accessibility settings. Physical goods pay Apple no commission.

## The public repo (October 23; kept public November 5)

`samosherman-byte/sos-closet-ios33` is public. **Why:** GitHub's standard hosted runners, the macOS ones included, are free for public repos, so the app can be built and tested in the cloud on every change at no cost; on a private repo, macOS runner minutes are billed (about $0.06 a minute in November 2026, against a $12–18 monthly allowance on GitHub's personal plans), so a few builds a day would use it up. Claude's cloud sessions can also read a public repo without being given access. **What that asks of us** (CLAUDE.md): nothing secret and nothing copied from the website is committed. The Storefront token stays in a git-ignored file on the Mac; the sample store, the product photos, the cutout tiles and the home page's photos are copied in from the site by `tools/sync-sample-store.sh` and git-ignored; the prototype's screens are built from the site on the Mac (`prototype/build.py`); commits are Claude's. The private `sos-closet-ios` holds only the first plan and isn't used.

## Design the screens first, then build (October 24)

The app's screens are designed on Claude's design canvas ("SOS Closet App Prototype") before Claude Code builds them, the same way every website change starts in the site's prototype. A copy that runs in a browser lives in `prototype/` (its README says how to run it), so each screen built in Xcode can be compared side by side with its design in the Simulator's Safari.

## A native Liquid Glass tab bar, with the site's header at the top (October 24)

Sam: "it should absolutely be native liquid glass tab bar". The tab bar holds the app's places, **Home, Shop, Saved and Bag**, with **Search** as its own round button beside it (iOS's own pattern for search), and shrinks to the current tab while you scroll down. The site's header stays at the top of Home and Shop: Menu, the logo, and the tab row of departments as the map. **Why:** the tab bar is what an iPhone app is expected to have and where the thumb is; the departments stay one row at the top so the map is whole and moves between departments still go sideways along it (the website's rule). It replaced the October 23 recommendation (the site's header alone) and the `nav/directions` branch.

- **Search and Bag aren't repeated at the top.** They're in the tab bar, so the top row is Menu and the logo, and the place line can run nearly the width of the screen.
- **Monochrome.** The selected tab is ink on a light lens; no blue tint (the site's SPEC §12: brand color lives in the content).
- **The Filter button joins the tab bar's row** while you scroll down through the pieces (between the shrunken tab and Search), and floats just above the full tab bar otherwise. One band of navigation at the bottom instead of two stacked.
- **The product page keeps the tab bar** (Shop selected). Its top is the site's: Back and the place line under the logo, flat at rest, floating up into the logo's row in glass when you scroll.

## Home is the website's home page (November 5)

Sam asked for the app to look exactly like the website, then: "check the homepage of the actual website with the carousel of the bags … and replicate that". So Home is soscloset.com's home page: the words, the turntable of three bags (ported from the site's `turntable.ts`, numbers and all), the four rooms read from the same Shopify "Home row" collections and placed by the same `home` measurements, the View all rings, the service notes and the disclosure. **Why:** one house, one front door; and because the rooms read Sam's collections, swapping a piece in Shopify changes the site and the app together. It replaces the app prototype's October 24 home (a story of the Jackie, a Just listed shelf and a department grid), which the site had moved on from.
