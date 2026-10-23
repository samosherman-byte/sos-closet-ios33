# SOS Closet iOS app: spec

The iPhone app is a second storefront on the same Shopify store as soscloset.com: the same closet, the same brand and the same principles, built natively in SwiftUI for iOS 26 and later. **The site's `SPEC.md` (in `../sos-closet-storefront`) is the source of truth for every behavior the two share, and the reason for it.** This file says only what is the app's own: what each phase builds, where the app does something the native iOS way instead of copying the web, how it gets its data, and what Sam still has to decide. Section numbers like "SPEC §7" mean the site's SPEC.md.

Written October 23, 2026 from the site's `main` at `540ceb6`. When the site's SPEC changes, the app follows it; when this file and the site's SPEC disagree on shared behavior, the site's SPEC wins, and Sam decides anything that's unclear.

---

## 1. The app

- **Platform:** iPhone, iOS 26 and later (deployment target 26.0), built with the current Xcode and iOS SDK (Xcode 27.1 and iOS 27 in October 2026; the App Store requires the iOS 27 SDK from April 2027). iOS 27-only features sit behind an availability check. iPhone only for now: an iPad would need the site's wider layouts (three across, the desktop Search column), which is a later decision. iPhone apps can be resized on iOS 27 (the foldable iPhone Duo), so layouts follow the window's width with the site's own breakpoints (two across up to 640pt, as on the site's phones), not the device's name.
- **App ID:** `com.soscloset.app`, provisional, for Simulator builds and, later, the App Store. It is not registered with Apple and isn't until Sam says so (it can't change once the app is in the App Store). **Builds for Sam's iPhone with his free Apple Account use `com.soscloset.app.dev`**: signing with a free account registers the ID under it, and Apple then won't let a paid account use the same ID (`docs/platform-notes.md`, "On Sam's own iPhone").
- **Data:** live from Shopify's Storefront API (the same queries as the site), or the site's sample store for building and testing (§5).
- **Checkout:** Shopify's own checkout inside the app, through Checkout Kit for Swift (§3.7).
- **Light appearance only,** like the site (SPEC §12).
- **Libraries:** Checkout Kit for Swift, 3.9.x (`https://github.com/Shopify/checkout-sheet-kit-swift`, module `ShopifyCheckoutSheetKit`; not the 4.0 alpha), required for checkout. Nothing else unless it earns its place: GraphQL is plain `URLSession` with the query text, images load through a small loader on `URLSession` and `URLCache`.

## 2. Phases

**Phase 1 (now):** the data (live and sample), Shop All and the four departments, Home, the product page, the bag and checkout, Saved. Done well, and nothing else.

**Not yet:** Search and its filters (so also the floating Filter button, the filter line and its tags), the directory, the place line and the compact tile row that comes back on the way up, swiping between departments, New Arrivals, Vintage and designer pages, The Archive, the Claude concierge, push notifications, App Store submission.

**Where phase 1 meets a missing piece** (each is temporary, and goes when its piece is built):

| Where | Phase 1 | Why |
|---|---|---|
| The magnifier | Not shown | A control that does nothing breaks "show only what helps right now" (SPEC §1.4). |
| Menu (the key) | Opens a short interim list: Saved (with its count) and the house's contact line. The directory replaces it in phase 2. | Saved lives in the directory (SPEC §4); without one, Saved needs a way in. *Sam to confirm (§8).* |
| Headings | Category and type headings are plain headings; they don't narrow (narrowing is always a tag, and tags come with Search). Shop All's department headings still open that department. | SPEC §7: narrowing is a tag, never a page. |
| "See all ›" on The Latest, "Shop new arrivals" on Home | Left out until New Arrivals exists. *Sam to confirm (§8).* | No link to a page that isn't there. |
| A link to a type (the Hermès tile's Shop: Women › Small Leather Goods) | Opens Women at that type's heading | What the directory does for a type (SPEC §4); the tag version comes with Search. |
| The designer on a product page | Plain text (no designer pages yet) | SPEC §10 already shows it as plain text where there's no page. |

## 3. The same as the site

Build these exactly as the site does, from the site's own files. A point on iPhone equals a CSS pixel on the site, so the site's sizes carry over as points; text sizes are the default size of a Dynamic Type style and grow with it (§6).

### 3.1 Data (SPEC §13)

- **The queries:** the same fields as `app/lib/catalog/shopify.server.ts`. The catalog: `products(first: 100, after:, query: "available_for_sale:true", sortKey: CREATED_AT, reverse: true)`, paged until done (at most 20 pages), with `handle title vendor productType tags createdAt featuredImage{url altText width height} media(first:1){nodes{id}} variants(first:10){nodes{id availableForSale price{amount} selectedOptions{name value}}}` and the metafields `custom.detail_line`, `custom.authenticated`, `custom.place_after` (a product reference: its `handle`) and `sos.photo_fit`. The product page adds `id descriptionHtml seo{title description} images(first:20) variants(first:50)` and `custom.color_name`, `custom.swatch`, `custom.details`. Same `@inContext(country:, language:)`.
- **The mapping**, ported from `app/lib/catalog/record.ts` line for line: the structure tags (`dept:`, `cat:`, `sub:`, `color:`, `id:`, `no-designer`, plain tags), the category from the product type when the tag is missing, the department from a category that only one department has, a one-piece "S/M" counting as S and M, the price as the lowest of the sizes still for sale, and **a piece with nothing left for sale is gone** (sold pieces disappear). The departments, categories, the type order, colors and price ranges come from `app/settings/taxonomy.ts` (kept in step with `data/catalog.json` → `cfg`).
- **The order**, from `app/lib/catalog/order.ts`: pieces listed after the import, newest first, then the imported pieces in `app/settings/legacy-order.ts` order; then the hold-backs (`custom.place_after`, or `HOLD_BACK` in `app/settings/merch.ts` until any piece has one).
- **The photo size standard's numbers**, from `photoFit()` in `record.ts`: used only when the metafield's `imageId` is the product's first media id, and only values the tool would write (scale over 0.2 and at most 1.4, drop from 0 to under 50, top from 0 to under 100).
- **Tests:** the Swift port runs the same cases as the site's `app/lib/catalog/catalog.test.ts`, and maps every piece of the sample store exactly as `data/catalog.json` has it (department, category, type, designer, price, colors, order).
- **Freshness:** one fetch of the whole closet when the app opens, again when it comes back after a minute or more, and on pull to refresh. The site caches the catalog for about 30 to 90 seconds; a piece that sells disappears at the next fetch, and checkout never sells a piece twice (SPEC §1.7).
- **Images:** Shopify's image service at the width the screen needs (the site does the same: the card's photo and the product page's are different widths of the same image). The file in Shopify is never changed.

### 3.2 Shop All and the departments (SPEC §2, §7)

- **Shop All:** The Latest (the 6 newest, three rows of two), then each department in full, Women, Men, Jewelry & Watches, Art & Home, each piece once (a piece in The Latest isn't repeated below it unless that would leave its department empty). No tile row, no title.
- **A department is one page:** the tile row, then every piece in category sections (the tile row's order), each organized by type (`cfg.subs` order). No title, no intro, no counts. A category with one type has no type heading; empty sections don't appear.
- **The tile row** (SPEC §7): the cutouts from `public/tiles/`, copied unchanged, shown whole on their 4:3 canvas, bottom-aligned, never nudged; all tiles fit one screen width (54–92pt each, cutouts up to 64 × 50pt, 12pt labels, 11pt under 375pt wide); no ALL on a department's row; one soft shadow under every cutout (`--e-obj`: 0 9 7 ink at 12% plus 0 2 2 at 7%; match it side by side, as SwiftUI's shadow radius is not CSS's blur); press: a slight scale; the entrance floats up staggered once and never replays. **Tapping a tile glides the page to that section,** its heading landing just under the header (long trips skip most of the way and glide the last ~0.6 of a screen). Tapping the department's tab glides back to the top.
- **Headings:** category headings in the display face, uppercase, letter-spaced, 15pt, with a hairline running to the right; type headings 12.5pt semibold uppercase letter-spaced in grey ink with a small chevron, no rule, 36pt apart. About 30pt from the tile labels to the first heading's words. Not sticky.
- **The grid, two across, edge to edge** (SPEC §7): the photos run to the screen's sides with 3pt between them; the words keep the page's 16pt margin (16pt left, 10pt right inside each card), 12pt under the photo; rows 32pt apart.

### 3.3 Cards and the photo size standard (SPEC §7, §12)

- **Card text: designer, name, price · size.** The designer in Tenor Sans, spaced capitals (0.16em), full ink, 13pt, one line, stepping down just enough to fit (never below 11pt), past that two lines. The name in Hanken Grotesk 14pt, `ink-2`, wrapping to two lines at most. Then price 15pt weight 500, a middle dot, and the size 13pt muted ("Size S"; "Sizes 8, 10"; three or more as a range, "Sizes XS–L"; the wording is `sizeWords()` in `app/lib/browse/sizes.ts`). A heart (save) on the photo's top right, 6pt from the top. No detail line, no "View piece".
- **The photo:** fills the card's 4:5 tile, cropped from the middle. With `sos.photo_fit` numbers, it sits on a pure white tile and is scaled about its center by `scale` and moved down by `drop`% of its own height (the order of the site's `translateY(drop%) scale(scale)`: scale first, then the move). At phone widths (up to 640pt) the stored numbers apply as they are; a wider window (an unfolded iPhone Duo) adds the site's 0.85 (`--fk`) about the baseline, exactly as SPEC §12 says. Without numbers, the photo shows as it is, on the stone ground while it loads.
- **A row's white:** the cards of a row share one tile height, the most any of them needs: a card's tile is its full 4:5 height minus the white above its piece beyond the heart's 44pt, `H − max(0, H × top − 44)` with `H` = 1.25 × width and `top` the stored top as a share of the tile (a card with no top needs the whole `H`). The photo hangs from the tile's bottom and its empty top is clipped, so every photo keeps its size and its place on the baseline, and the designer, name and price stay level along a row.
- **Never added:** no glass, shadow or effect on a photo or its card (SPEC §1.8). The photo files are never changed.

### 3.4 Home (SPEC §12 "the home page is all white"; `HOME` in `app/settings/merch.ts`; `app/components/home/HomePage.tsx`)

All white, top to bottom: the hero (the Gucci Jackie: eyebrow, title, line, price and "Professionally authenticated" when it is; Shop now → the piece; See all handbags → Women at Handbags; the Jackie's own cover, whole, 4:5, 86% of the width), the four feature tiles (eyebrow, title, copy, Shop, the second link; a tile hides once all its pieces have sold; "From {from}" is their lowest price), Just listed (the 10 newest on a sideways shelf of cards), the evening edit (the two editorial photos from `public/home/`, with designer, name, size and price, each opening its piece), and the three services (Ask SOS Closet, Follow the closet, Consign with us, as mail and Instagram links). The home page's settings live in one Swift file mirroring `HOME`, so changing a tile is one edit, as on the site.

### 3.5 The product page (SPEC §10)

- **The gallery:** swipe sideways one photo per swipe, however fast, like the Photos app; the counter (2 / 7) and, with several photos, a row of thumbnails that follows and keeps the current one in view; tapping a thumbnail glides to its photo; tapping the photo zooms it (pinch too), and a zoomed photo doesn't swipe.
- **The designer leads:** Tenor Sans spaced capitals, 28pt; the name under it as a caption, 18pt weight 500.
- **Price and status on one line:** the price, then in quiet spaced capitals (11pt, muted) whichever apply: Authenticated, Vintage (or the era, "Vintage 1980s"), the size. Nothing when none apply; never "One of one".
- **The description** under the price, 15pt with the site's line height (1.65), `ink-2`, keeping its paragraph breaks; three lines with an ellipsis and an underlined **Read more** (14pt, weight 600, at least 44pt to tap) only when there's more; it becomes Read less. VoiceOver hears whether it's expanded.
- **Add to Bag and the heart in one row:** Add to Bag fills the row (square corners: content is square), the heart a 52pt square beside it, which pops when saved.
- **One line:** "Ships from New York City · Questions? Email us" (13pt, muted; Email us opens Mail).
- **Details** (only for pieces with written facts or an authentication card) and **Shipping & returns**, both folded, under one hairline.
- **You may also like:** six pieces from the same category, topped up from the department, two across, each opening the same way.
- **A sold piece** (opened from a saved link or the bag): "This piece has sold. Similar pieces are below."

### 3.6 Opening a piece (SPEC §5)

The feeling to match: the piece you tapped becomes the page, one decelerating move with no bounce (560ms on the site), and going back returns the page exactly as you left it. In the app this is the native zoom transition (§4); judge it side by side with the prototype before settling on it.

### 3.7 The bag and checkout (SPEC §11)

- **The bag is a Storefront API cart,** with the same fields as the site's cart (`app/lib/fragments.ts`) and the same rules as `app/lib/bag/bag.server.ts`. Its id is kept in the iPhone's Keychain (Shopify treats the key inside a cart id like a password), so the bag survives closing the app. When the app opens or comes back, it reads the cart again; a cart Shopify no longer has (carts expire within 30 days, and a completed one is deleted) starts a fresh, empty bag.
- Every piece is one of one: one line per piece, always quantity 1, no quantities shown; adding a piece that's already in the bag does nothing. "Every piece is one of one and isn't held until you check out." Nothing is held until checkout.
- **Adding opens the bag** (a sheet, §4) with the piece, the subtotal, Check Out and the rest of the bag. If Shopify refuses the add, or the piece is missing when the cart is read back, the button says "That piece has just sold." Removing a piece slides it out. A piece that has sold since it was added stays, saying "This piece has sold since you added it." with "Sold" where its price was, and leaves the subtotal (the subtotal is the pieces still for sale, added up, as on the site).
- **Check Out opens Shopify's own checkout** through Checkout Kit: the cart's `checkoutUrl` is read again right before it opens, and checkout is preloaded when the bag opens and after it changes, so it opens quickly. Closing checkout (its close button or a swipe down) returns to the bag. **When the order completes, the bag starts fresh** (Checkout Kit reports the completion before the buyer closes its thank-you page, and reports a close after it too, so the bag resets on completion, not on close). Checkout branding is Shopify's (the site's setup step 9).
- **The Bag control:** top right, with a small black count badge, hidden at zero.
- **In the sample store** the bag is a short list on the phone and Check Out says checkout needs Sam's store (the site's sample store has no checkout either).

### 3.8 Saved (SPEC §11)

Hearts are kept on the phone (the site keeps them in the browser), by the piece's id (its `id:` tag, or its handle), so the same ids as the site. The Saved page lists the hearted pieces that are still for sale; sold ones drop out. Its count shows where Saved is reached (Menu in phase 1, the directory later). Customer accounts can come later, as on the site.

## 4. Native instead

Where iOS has its own way of doing something, the app uses it instead of copying the web code. Each of these keeps the site's intent (the "why" in SPEC and `docs/design-decisions.md`); `docs/platform-notes.md` has the API names and links.

| The site | The app | Why |
|---|---|---|
| CSS glass (the `--g-*` settings: white at 42%, blur, rim, edge, shadow) | **Real Liquid Glass**: the system's regular glass on floating navigation, thicker system materials for panels (the bag sheet, later the directory and Search); system bars, toolbars and sheets get it on their own | The site's glass is its web version of this material ("it's the web version of the effect"). The real one refracts, adapts to what's behind it, follows the iPhone's own glass setting and turns solid or high-contrast with the accessibility settings. Same rules: navigation and panels only, never photos, cards or headings, never glass on glass, regular and untinted. |
| The scroll edge band (white 95% → 88%, blurred) | **The system scroll edge effect** under the floating controls | The site's band is a copy of iOS's own. |
| Pressing glass: a glow under the finger and a flex | **Interactive glass** | It's what the system glass does when touched. |
| The photo glide into a piece and back (a custom flight) | **The native zoom transition** from the card's photo into the product page, and back by the back button, the edge swipe or pulling the page down | Built for this exact moment, and interactive (the page can be grabbed mid-move). Apple doesn't say what it does with Reduce Motion: check, and fall back to a plain push or a fade if it still zooms. To confirm side by side with the prototype: if it doesn't give the same feeling (the photo you picked becomes the page, one move, no bounce), build the glide instead. |
| Back keeps your place (a saved scroll position) | **Native navigation**: the page you came from is kept as it was; **native swipe-back** from the left edge | iOS keeps the previous page alive, place and all. |
| Bag drawer from the right | **A sheet from the bottom** (half height, then full), glass at half height, swiped down to close | iOS's panel for a task you step into; one thumb reaches it. |
| Shopify checkout in the browser | **Checkout Kit's sheet** | Shopify's own checkout, inside the app. |
| One tap works while the page glides (SPEC §3) | **Nothing to build** | iOS bars and floating controls sit outside the scrolling page and already take the first tap; the problem the site solved is mobile Safari's. Check it on the phone anyway. |
| Saved in browser storage | **Kept on the phone** | The same "on this device", until customer accounts. |
| Web fonts from Google | **Tenor Sans and Hanken Grotesk bundled** (both SIL Open Font License), scaled with Dynamic Type | Offline, and the text grows with the iPhone's text size. |
| `prefers-reduced-motion` and the other media queries | **The iPhone's own settings** (Reduce Motion, Reduce Transparency, Increase Contrast, Bold Text, text size) | The app can read every one of them, including some the web can't. |
| Hover-only behavior ("View piece", hover zoom, the desktop hover directory) | Dropped | There's no hover on an iPhone. |

Not native on purpose: **the tab row is still the map** (SPEC §1.1), the header at the top of a page is still flat (no glass at rest), **content stays square and glass round**, and every move between departments goes sideways along the map. These are Sam's design, not web limitations.

## 5. Config and the sample store

- **One switch:** `Config/Store.xcconfig` → `SOS_STORE = sample` or `shopify`. Debug builds use it; release builds always read Sam's store and leave the sample store out (the site's production builds do the same).
- **The token:** `Config/Secrets.xcconfig` on this Mac only (git-ignored), with `SHOPIFY_STORE_DOMAIN` and `SHOPIFY_STOREFRONT_TOKEN` (the format is in `Config/Secrets.example.xcconfig`). Sam pastes them himself from the Headless channel (the site's `docs/shopify-setup.md`, step 7). It's Shopify's *public* token, meant to be inside apps and web pages; the private token is never used.
- **The sample store** reads the same import files the site's `npm run dev:sample` reads, `data/shopify-products.csv` and `data/product-images.csv` (both built from `data/catalog.json`), with the photo sizes in `data/photo-fit.json` and the prototype's photos in `prototype/img/`. It goes through the same mapper as Shopify's answers, so it checks the import file too, and the sample store looks exactly like what Shopify will send. `tools/sync-sample-store.sh` copies those files, `public/tiles/` and `public/home/` from `../sos-closet-storefront` into `SampleStore/` and `Resources/` unchanged, and notes the site's commit.
- **Endpoint:** `POST https://{SHOPIFY_STORE_DOMAIN}/api/2026-10/graphql.json` with the `X-Shopify-Storefront-Access-Token` header. 2026-10 is the current stable Storefront API (supported until October 2027); the site is on 2026-04 through its Hydrogen version (supported until April 2027). The queries the app uses are the same in both. Move to the next version once a year, when Shopify announces it.

## 6. Accessibility

- **Reduce Transparency, Increase Contrast:** the system glass handles itself; anything custom checks the same settings and goes solid white (with an ink border for Increase Contrast), as the site's SPEC §12 says.
- **Reduce Motion:** no stretch, spring, flex, blur-in or flight; fades or nothing. The zoom transition and sheets follow the system's own behavior.
- **Dynamic Type:** every font is `Font.custom(_:size:relativeTo:)`, with the site's size as the default. Cards stay two across at large sizes; their text wraps.
- **VoiceOver:** each card reads designer, name, price and size as one element, with the heart as its own button ("Save", selected when saved); headings are headings; Read more and the folds say whether they're expanded; the bag's count is in the Bag button's label.

## 7. Navigation: two directions for Sam to pick

Before building the navigation, both are built as quick screens on the sample store, shown in the Simulator at a small and a large iPhone beside the prototype, and Sam picks.

- **(A) The site's header, natively.** At the top of a page, the classic flat header: Menu, the logo and Bag as plain icons on white, and the tab row (SHOP ALL · WOMEN · MEN · JEWELRY · ART & HOME) between hairlines with the gliding underline. Scrolling down, the tabs dematerialize, and Menu and Bag float in real Liquid Glass over the pieces with the system scroll edge effect behind them; scrolling up brings the flat header back. The departments sit side by side, so tapping a tab slides the page sideways along the map (and swiping between departments, later, is the same motion under the finger).
- **(B) Native iOS: a Liquid Glass tab bar at the bottom.** A floating glass tab bar (Home, Shop, Saved, and Search later as its own round tab), which shrinks while you scroll down; Bag in the top bar; the departments as a row at the top of Shop.

**Recommendation: A.** It's what Sam chose for the site after comparing it side by side with a glass tab bar (October 19 and 21), so the app and the site open the same way and a customer finds everything in the same place. It keeps the whole map in one row with every move sideways; a bottom tab bar can't hold Home and five departments, so the map would split in two, and switching tabs doesn't move sideways (the site's rule: no page changes between sections without directional motion). B also adds a second band of navigation (the bar at the bottom and the logo and Bag at the top), past the site's depth budget of one band and one panel, and it's the Poshmark, Depop and Vinted look the site steps away from. **What B does better:** it's the most familiar iPhone layout, the thumb reaches it on a big phone, and the system draws and animates it, so it's less to build and maintain. A asks for more custom work on the header, and the top of a big phone is a stretch for the thumb (the floating Filter button at the bottom and sideways swipes, both later, help with that).

## 8. Decisions for Sam

- [ ] **Create the private GitHub repo `sos-closet-ios`** for this app (asked October 23).
- [ ] **Navigation: A or B** (§7), once the Simulator screenshots are in front of him. Recommended: A.
- [ ] **Saved in phase 1:** Menu opens a short interim list with Saved (and its count) until the directory exists. [Default: yes.]
- [ ] **The Latest's "See all" and Home's "Shop new arrivals"** wait for New Arrivals (phase 2). [Default: left out in phase 1.]
- [ ] **iPhone only** for now. [Default: yes.]
- [ ] **Checkout's look:** Checkout Kit can show checkout with the store's own checkout branding (its "web" scheme, light only, which suits the brand) or in a plain iOS style. [Default: the store's branding.] Shopify's page says full custom branding needs Shopify Plus, so what shows on Sam's plan gets checked on the first real checkout.
- [ ] **Testing checkout before launch:** Checkout Kit can't open checkout while the store's password page is on (the site's launch checklist puts the old Online Store behind one). The first real test checkout needs a moment with it off, or Sam's go-ahead to test some other way. [Ask when the token is in.]
- [ ] **A separate storefront in the Headless channel for the app** (its own public token, so the app and any other client can be told apart or switched off separately). [Default: yes, when Sam adds the token; it's one more click in Headless.]
- [ ] **When phase 1 runs:** putting it on his iPhone with his free Apple Account, as `com.soscloset.app.dev` (this registers that test ID, not the real one, under his free account; the app then needs reinstalling from the Mac every 7 days). [Ask then.]
- [ ] **Later:** joining the Apple Developer Program (paid, yearly) and registering `com.soscloset.app`: needed for TestFlight, the App Store, push notifications, Apple Pay and universal links. The free account is enough to try the app on his own iPhone.

## 9. Where we are

- **October 23 (a cloud session, which can't run Xcode):** read the site's CLAUDE.md, SPEC.md, design decisions and catalog, home, product, bag and saved code at `540ceb6`; read Apple's and Shopify's current docs (`docs/platform-notes.md`); wrote this file, `CLAUDE.md` and `docs/mac-setup.md`. No app code yet.
- **Next, on Sam's Mac** (`docs/mac-setup.md` is Sam's part):
  1. `xcodebuild -version` and `xcrun simctl list devices available`; if Xcode or the iOS Simulator is missing, tell Sam exactly what to install and wait (`docs/mac-setup.md`, part 1: Xcode 27 needs an Apple silicon Mac on macOS Tahoe 26.6 or later).
  2. Clone the site next to this folder if it isn't there (read-only).
  3. Check `docs/platform-notes.md` against the Xcode and iOS versions on the Mac; re-read any page that has changed.
  4. Branch `setup/project`: the Xcode project (SwiftUI app, iOS 26, iPhone, `com.soscloset.app`), the fonts, colors and type styles from SPEC §12, `Config/`, `tools/sync-sample-store.sh`, the Checkout Kit package. Build and run at a small and a large iPhone.
  5. Branch `nav/directions`: directions A and B on the sample store; screenshots beside the prototype; Sam picks.
  6. Then `data/catalog`, `browse/departments`, `home`, `product/page`, `bag/checkout`, `saved`, each built, tested, run at both sizes and compared with the prototype.
  7. When phase 1 runs: put it on Sam's iPhone with his free Apple Account (`docs/mac-setup.md`, part 3).
