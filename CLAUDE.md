# SOS Closet iOS app: notes for Claude Code

## What this project is

The native iPhone app for SOS Closet, Sam Sherman's luxury consignment business in New York City: a second storefront on the same Shopify store as the website. SwiftUI, iOS 26 and later (the first versions with Liquid Glass), iPhone only for now. Shopify holds the products, inventory, cart, checkout, orders and taxes; the app reads them live through the Storefront API and checks out through Shopify's Checkout Kit.

Sam is not an engineer. Explain every change in plain language, and say exactly what he needs to click or decide.

## Read these first

1. `APP-SPEC.md`: what the app does, what's the same as the site, what's native instead and why, and what phase 1 builds. Its "Where we are" section says what's done and what's next.
2. The website's `CLAUDE.md`, `SPEC.md` and `docs/design-decisions.md`, in the website repo next to this one (`../sos-closet-storefront`). **The site's SPEC.md is the source of truth for every shared behavior and the reason for it.** APP-SPEC.md points to its sections instead of copying them; when the two seem to disagree, ask Sam.
3. `docs/platform-notes.md`: what Apple's and Shopify's current documentation says about Liquid Glass, tab bars, toolbars, the scroll edge effect, the zoom transition, sheets, Checkout Kit and the Storefront API cart, with links. Check a page again before relying on it for something new; these APIs change every year.
4. **The app prototype** (`prototype/` in this repo; `prototype/README.md` says how to build and run it): every screen of the app as Sam approved it on Claude's design canvas, at the iPhone's size, with the app's own decisions (the native tab bar, Home as on soscloset.com). **It's the look and motion to build to.** Serve the repo's folder (`python3 -m http.server 8000`) and open `http://localhost:8000/prototype/#Shop` (or `#Main`, `#Product`…) in the Simulator's own Safari (`xcrun simctl openurl booted …`) to compare at exactly the same size.
5. `docs/design-decisions.md`: the app's own decisions and why. The website's prototype (`../sos-closet-storefront/prototype/`) is the reference for anything the app prototype doesn't show.

## The website repo is read-only

`../sos-closet-storefront` (the private repo samosherman-byte/sos-closet-storefront) is a reference. **Never change, commit, branch or push anything in it.** `git -C ../sos-closet-storefront pull` to bring it up to date is fine; nothing else. If it isn't on this Mac, clone it next to this folder.

## Sam's rules (the same as the site's)

- **Product photos:** never edit, replace, re-crop or re-upload them, in the app or in Shopify, and don't change how they're shown (size, framing, grounds, shadows, effects) unless Sam asks. The one exception he has made is the photo size standard on cards (the site's SPEC §7 and §12, the `sos.photo_fit` metafield). The sample store's photos are copied from the site unchanged.
- **Shopify:** ask Sam before creating, changing or deleting anything in his store (products, collections, settings, apps, channels).
- **The Storefront token:** the public token and the store address go in `Config/Secrets.xcconfig` on this Mac (git-ignored; `Config/Secrets.example.xcconfig` shows the format). Never in git, never in a chat. When the app needs it, tell Sam where the file is and that he pastes it himself; it's in Shopify's Headless channel (the site's `docs/shopify-setup.md`, step 7). Never ask for passwords, private tokens or Admin API keys.
- **Apple:** don't sign up for, pay for or register anything with Apple without asking Sam. That includes the Apple Developer Program, registering the app ID `com.soscloset.app` (it can't change once the app is in the App Store), App Store Connect records, TestFlight and push certificates. To put the app on Sam's iPhone, use his free Apple Account (a Personal Team) and walk him through it (`docs/mac-setup.md`, part 3), **always with the bundle ID `com.soscloset.app.dev`, never `com.soscloset.app`**: signing with a free account registers the ID under it, and Apple then won't release it to the paid account the App Store needs.
- **GitHub:** this repo is `samosherman-byte/sos-closet-ios33`, and it is **public**: anyone can read everything committed here, including old commits. So the token never goes in it (above), and nothing copied from the website goes in it either: the sample store, the product photos, the cutout tiles and the home page's photos are copied in by `tools/sync-sample-store.sh` and git-ignored (`SampleStore/`, `SiteAssets/`). No customer or order data, no Shopify admin details, and commit as Claude (`noreply@anthropic.com`), never with Sam's own email. Ask before creating anything else on GitHub.
- **Product copy** (if the app ever writes any): never mention condition or missing measurements; keyword-rich, helpful and direct, not overly clever; if an item is made in China, don't mention it.

## Design rules

- **Preserve the site's design intent** (its SPEC §1, Sam's words: "always more powerful, yet simpler and cleaner to use"). Everything in the site's CLAUDE.md "never introduce" list applies here too, in its native form: no title on Shop All or the departments (the selected tab is their name), no intro paragraphs, no piece counts under tiles, no glass on content (photos, cards, headings), no glass on glass, no glass in the header at the top of a page, no shadow on a photo's frame or card, no page changes between departments without directional motion along the tab map, and never more than one band of navigation plus one panel on screen at once.
- **Same brand:** the site's type, colors and spacing (its SPEC §12). Tenor Sans and Hanken Grotesk are bundled (both SIL Open Font License); a point on iPhone equals a CSS pixel on the site, so the site's sizes carry over as points.
- **Native where iOS has its own way** (APP-SPEC "Native instead"): real Liquid Glass for navigation and panels only, the system scroll edge effect, native swipe-back, the native zoom transition into a piece, and sheets for the bag. Don't recreate the website's CSS glass (the `--g-*` numbers are the web's version of the system material).
- **The page adapts; your place doesn't** (site SPEC §1.5): whatever the customer is looking at stays in view through every change. Check this for every change.
- **Accessibility stays working:** Reduce Transparency, Increase Contrast, Reduce Motion, Dynamic Type (every font through `Font.custom(_:size:relativeTo:)`) and VoiceOver (labels, traits, the result count announced). Every animation has a Reduce Motion fallback.

## Building and checking

- **Work through Xcode itself** (Apple's Xcode plugin for Claude Code, `xcode@claude-plugins-official`, since November 7): open `SOSCloset.xcodeproj` in Xcode first (the first time, Xcode asks whether to let Claude connect, and Sam clicks Allow), then build, run and test through it, read build errors straight from Xcode, render SwiftUI previews to check a view while writing it, drive the Simulator, and search Apple's documentation for anything iOS 26/27 instead of working from memory. If the plugin's tools aren't there, say so and fall back to `xcodebuild` and `simctl` as below.
- Before each step's work: `xcodebuild -version` and `xcrun simctl list devices available` to see what's installed.
- After each step: build, run in the Simulator at a small iPhone and a large one (the smallest and the Pro Max the installed Simulator offers), take screenshots (`xcrun simctl io booted screenshot`), and compare them side by side with the same screen of the app prototype (`prototype/`) at the same size in the Simulator's Safari. Show Sam the pairs and say what differs.
- Unit tests (Swift Testing) cover the catalog mapping, the photo size standard and the bag; they mirror the site's `app/lib/catalog/catalog.test.ts` and `app/lib/bag/bag.test.ts`. Run them before every merge.
- The sample store: `tools/sync-sample-store.sh` copies the site's import files, photo sizes and the prototype's photos into `SampleStore/`, and the cutout tiles and home page photos (which ship in the app) into `SiteAssets/`, unchanged; both are git-ignored, so run it after cloning. Release builds leave the sample store out.

## Branches

One branch per piece of work (`data/catalog`, `nav/tab-bar`, `home`, `browse/departments`, `product/page`, `bag/checkout`, `saved`; `nav/directions` is superseded, don't merge it). Design changes come in on `prototype/…` branches (the prototype, APP-SPEC.md and `docs/design-decisions.md`, no app code); merge those first. Merge into `main` when the step builds, its tests pass and Sam has seen the screenshots. Commit with clear messages; push only to this repo.
