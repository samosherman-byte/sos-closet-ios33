# Platform notes: Apple and Shopify

What the current documentation says about the pieces phase 1 is built on, read on October 23, 2026. Each item has its source. **Check a page again before relying on it for something new**: these APIs change every year, and the version on the Mac decides. Items marked *(not verified)* couldn't be confirmed from a live page and need checking in Xcode.

## Apple

Read from developer.apple.com (each doc page through its `/tutorials/data/documentation/….json` mirror), Apple's releases feed, the Xcode release notes, the Human Interface Guidelines and WWDC25/26 sessions. *(not verified)* items come from memory, forums or the press.

### Versions (October 23, 2026)

- **Current:** iOS 27.0.1 (iOS 27.2 is a release candidate); **Xcode 27.1** (27A9275, October 15; 27.2 RC October 19). Source: https://developer.apple.com/news/releases/rss/releases.rss
- **Xcode 27 needs a Mac with Apple silicon and macOS Tahoe 26.6 or later.** It builds for iOS 15 to 27 and debugs on iPhones with iOS 17 or later. The fallback, Xcode 26.6, runs on macOS 26.2 and later with the iOS 26.5 SDK. Source: https://developer.apple.com/xcode/system-requirements/ and the Xcode 27 release notes.
- **The app:** deployment target iOS 26.0, built with the iOS 27 SDK. iOS 27-only APIs go behind `if #available(iOS 27, *)`. From April 2027 the App Store requires the iOS 27 SDK (https://developer.apple.com/app-store/submissions/). Apps built with the 27 SDK must have a launch screen key (`UILaunchScreen`).
- **Simulators:** Xcode offers the iOS platform on first launch, or **Xcode › Settings › Components › Get**, or `xcodebuild -downloadPlatform iOS`. In Xcode 27 simulators run in **Device Hub** (run destination menu › Manage Devices…). Source: https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components. Sizes aren't published: plan on about 3 GB for Xcode, 8–10 GB for the iOS platform, and 20 GB or more free *(not verified)*.
- **New in iOS 27 and worth knowing:** Liquid Glass has a refined look and follows a new system Liquid Glass slider (WWDC26 session 269); iPhone apps become resizable (the foldable iPhone Duo on iOS 27.1 *(press reports)*; the system can also put bars on a vertical edge, `toolbarVerticalBehavior(_:)`, iOS 27.1), so layouts must follow the window's width, not the device; `toolbarMinimizationBehavior(_:for:)` minimizes the navigation bar; `TabRole.prominent`; `NavigationTransition.crossFade`; `TabView` crashes if its selection points at a hidden tab; `@State` is a macro and errors when it has a default value and is also assigned in `init`. Nothing in the Liquid Glass APIs below was deprecated.

### Liquid Glass in SwiftUI (iOS 26)

- `glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape())` (a capsule by default; apply it after the other appearance modifiers). `Glass`: `.regular`, `.clear`, `.identity`, `.tint(_:)`, `.interactive(_:)` (lights up and flexes under the finger). https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:), https://developer.apple.com/documentation/swiftui/glass
- `GlassEffectContainer(spacing:) { … }` renders nearby glass together, so shapes blend and morph ("glass can not sample other glass", so neighbours share a container). `glassEffectID(_:in:)`, `glassEffectUnion(id:namespace:)`, `glassEffectTransition(.matchedGeometry | .materialize | .identity)`. https://developer.apple.com/documentation/swiftui/glasseffectcontainer
- Button styles `.glass`, `.glass(.clear)`, `.glassProminent`.
- **Apple's rules** (HIG Materials, "Adopting Liquid Glass", WWDC25 219): "Don't use Liquid Glass in the content layer"; glass is "best reserved for the navigation layer that floats above the content"; "always avoid glass on glass" (on glass, use fills, transparency and vibrancy); use it sparingly; never mix regular and clear; clear only over media, with a dimming layer; tint only primary actions. These match the site's SPEC §12 rules. https://developer.apple.com/design/human-interface-guidelines/materials, https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass

### Tab bars (for direction B)

- `TabView { Tab("Home", systemImage: "house", value: …) { … } … Tab(role: .search) { … } }`. The search tab sits apart at the trailing end and turns into a search field when chosen; `tabViewSearchActivation(_:)`. https://developer.apple.com/documentation/swiftui/tabrole
- `tabBarMinimizeBehavior(.onScrollDown)` (iPhone only; it comes back when you scroll the other way). `tabViewBottomAccessory { … }` sits above the bar. https://developer.apple.com/documentation/swiftui/tabbarminimizebehavior
- **Five tabs fit on an iPhone;** a sixth turns into More. HIG: avoid overflow, and use the tab bar for navigation, not actions.

### Toolbars and navigation bars

- Toolbar items sit on Liquid Glass automatically, grouped; remove custom bar backgrounds, which interfere with the scroll edge effect (WWDC25 323).
- `ToolbarSpacer(.fixed | .flexible, placement:)` splits groups. `.sharedBackgroundVisibility(.hidden)` takes an item out of the glass: Apple's own example is a bare logo in `ToolbarItem(placement: .principal)`, which is how direction A's flat header at rest can use the system bar. https://developer.apple.com/documentation/swiftui/toolbarcontent/sharedbackgroundvisibility(_:)
- `navigationBarTitleDisplayMode`, `toolbarTitleDisplayMode(.inline | .large …)`, `toolbarBackgroundVisibility` *(whether `.visible` still draws a bar background under glass in iOS 26 is not verified)*.

### Scroll edge effect and custom bars

- `scrollEdgeEffectStyle(.automatic | .soft | .hard, for: edges)`, `scrollEdgeEffectHidden(_:for:)`. https://developer.apple.com/documentation/swiftui/scrolledgeeffectstyle
- **A custom bar gets the system scroll edge effect through `safeAreaBar(edge:alignment:spacing:content:)`**, placed outside the scroll view (`ScrollView { … }.safeAreaBar(edge: .top) { Header() }`). It works like `safeAreaInset` and extends the edge effect. This is how direction A's header (top row and tab row) stays native. https://developer.apple.com/documentation/swiftui/view/safeareabar(edge:alignment:spacing:content:)
- `backgroundExtensionEffect()` mirrors a view into the safe areas; not for product photos (it would change how they're shown).

### The zoom transition (opening a piece)

- `.navigationTransition(.zoom(sourceID: piece.id, in: ns))` on the product page (directly, outside any stack), `.matchedTransitionSource(id: piece.id, in: ns)` on the card's photo. Works with `NavigationStack` pushes, sheets and full-screen covers. "Continuously interactive": the page can be grabbed during the transition; an interrupted push turns into a pop. https://developer.apple.com/documentation/swiftui/navigationtransition/zoom(sourceid:in:), https://developer.apple.com/documentation/swiftui/view/matchedtransitionsource(id:in:)
- Closing by dragging down and by the edge swipe zooms back into the card *(not verified in Apple's docs; check)*. **What it does with Reduce Motion isn't documented:** check, and if it still zooms, fall back to the standard push (or `.crossFade` on iOS 27) when `accessibilityReduceMotion` is on.
- It zooms the whole product page out of the card's photo frame; the site's glide flies the photo itself while the page assembles around it. Compare the two side by side before choosing (APP-SPEC §3.6).

### Sheets (the bag)

- On iOS 26, partial-height sheets are inset with a Liquid Glass background; at full height they become opaque and meet the edges (WWDC25 323). `presentationDetents([.medium, .large])`; keep the grabber and swipe-down. Avoid `presentationBackground`, which would replace the glass *(not verified)*.
- A sheet can grow out of the toolbar button that opened it: `matchedTransitionSource(id:in:)` on the `ToolbarItem` (iOS 26) and `.navigationTransition(.zoom(sourceID:in:))` on the sheet's content. https://developer.apple.com/documentation/swiftui/toolbarcontent/matchedtransitionsource(id:in:)

### Accessibility and fonts

- The system glass adapts on its own, including custom `glassEffect`: "Reduced Transparency makes Liquid Glass frostier… Increased contrast makes elements predominantly black or white… with a contrasting border… Reduced Motion decreases the intensity of some effects and disables any elastic properties" (WWDC25 219). Our own colors and animations still need checking.
- Environment: `accessibilityReduceTransparency`, `colorSchemeContrast` (`.increased`), `accessibilityReduceMotion`.
- `Font.custom(_:size:relativeTo:)` scales with Dynamic Type (use the font's PostScript name; a wrong name silently falls back to the system font; SwiftUI doesn't fake bold). `@ScaledMetric(relativeTo:)` for spacing. Fonts go in the target with `UIAppFonts` in Info.plist. https://developer.apple.com/documentation/swiftui/font/custom(_:size:relativeto:)

### On Sam's own iPhone, with a free Apple Account

Source: https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices, https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device, https://developer.apple.com/support/compare-memberships/

- Xcode › Settings › Apple Accounts › sign in (shows as "Personal Team"); the target's Signing & Capabilities › Automatically manage signing › the Personal Team; pair the iPhone in Device Hub (by cable: Trust This Computer on the phone; wirelessly only on iOS 27); on the iPhone, Settings › Privacy & Security › Developer Mode › restart › Enable. After the first install, Settings › General › VPN & Device Management › trust the developer *(the usual step; not in Apple's docs)*.
- **Limits:** the app stops opening 7 days after it's installed (reinstall from Xcode), 3 devices, 3 apps per device, 10 app IDs a week, no TestFlight or App Store. Not available: push notifications, Sign in with Apple, Associated Domains (universal links), Apple Pay, iCloud. Available: Keychain, App Groups, Background Modes.
- **Signing with a Personal Team registers the bundle ID under it, and a paid team then can't use that ID** (Apple's engineer, https://developer.apple.com/forums/thread/843925, August 2026: no self-service release; the quickest fix is a different ID). **So Personal Team builds use `com.soscloset.app.dev`, never `com.soscloset.app`,** which stays unregistered until Sam joins the Developer Program and says so.

---

## Shopify

### Checkout Kit for Swift

Source: https://github.com/Shopify/checkout-sheet-kit-swift (README, `Package.swift`, `Sources/ShopifyCheckoutSheetKit`, `Samples/MobileBuyIntegration`), read at 3.9.2 / `main` 8a33b11 (October 21, 2026); shopify.dev's Checkout Kit pages (read through Shopify's docs search, as shopify.dev itself was out of this session's network).

- **Package:** Swift Package Manager, `https://github.com/Shopify/checkout-sheet-kit-swift`, `from: "3.9.2"`. Product and module: `ShopifyCheckoutSheetKit` (Shopify now calls the product "Checkout Kit"; the package rename comes later). Minimum iOS 13. The successor, `Shopify/checkout-kit` 4.0, is an alpha and not for production: stay on 3.9.x. Strict concurrency since 3.5: the sample app uses `@preconcurrency import ShopifyCheckoutSheetKit`.
- **Where the README and the source disagree, follow the source:** the delegate protocol is `CheckoutDelegate` (not `ShopifyCheckoutSheetKitDelegate`); the SwiftUI view is `CheckoutSheet(checkout: URL)` (not `url:`); `CheckoutError` cases carry `code` and `recoverable`; the default `checkoutDidFail` throws, so implement it.
- **Configure** once at launch: `ShopifyCheckoutSheetKit.configure { $0.colorScheme = .web; $0.tintColor = …; $0.title = "Checkout" }`. `colorScheme`: `.light`, `.dark`, `.automatic` or `.web` ("as rendered by a mobile browser"; the only one that shows the store's own checkout branding; light only). Changing the configuration clears the preload cache.
- **Preload:** `ShopifyCheckoutSheetKit.preload(checkout: url)`, a hint, not a guarantee. Call it when the bag opens and after the bag changes, not on every add.
- **Present (SwiftUI):** `.sheet(isPresented: $show) { CheckoutSheet(checkout: url).onComplete { event in … }.onCancel { show = false }.onFail { error in … }.edgesIgnoringSafeArea(.all) }`. UIKit: `ShopifyCheckoutSheetKit.present(checkout: url, from: viewController, delegate: self)`.
- **Events (`CheckoutDelegate`):** `checkoutDidComplete(event:)` (`event.orderDetails`: `id`, `email`, `deliveries`, `cart`…; after an error recovery only `id`), `checkoutDidCancel()`, `checkoutDidFail(error:)`, `shouldRecoverFromError(error:)`, `checkoutDidClickLink(url:)`, `checkoutDidEmitWebPixelEvent(event:)`.
- **Behavior:** closing (the close button or a swipe down) calls cancel and **does not dismiss the sheet: the app must** (`show = false`). Completing fires complete while the sheet stays up on the thank-you page; closing it then fires cancel too, so reset the bag on complete, not on cancel (shopify.dev says the same). A recoverable failure retries once in a fallback web view; otherwise it closes itself. The samples reset the cart on complete and on an unrecoverable failure.
- **Errors:** `CheckoutErrorCode` includes `storefrontPasswordRequired`, `cartExpired`, `cartCompleted`, `invalidCart`. **A store behind its password page can't check out through Checkout Kit**; the store must also use checkout extensions (not the old `checkout.liquid`), or it's a `configurationError`.
- **What it needs:** a cart's `checkoutUrl` from the Storefront API (read it again right before presenting: "checkout URLs can go stale"); a Storefront API token from the Headless channel. No plan requirement is stated for Checkout Kit itself. Shopify's configuration page: "`.web` pulls branding from your store's checkout settings… Custom checkout branding requires Shopify Plus. On other plans, `.web` displays checkout without custom branding" *(check what Sam's plan shows)*.
- **Later, not phase 1:** native Apple Pay and Shop Pay buttons (`ShopifyAcceleratedCheckouts`, iOS 16+, needs a scope requested from Shopify, an Apple Pay merchant ID and certificates); Shop Pay inside checkout through the cart's `buyerIdentity.walletPreferences`; customer accounts (Customer Account API, OAuth with PKCE, `customerAccessToken` on the cart); Universal Links for payments that leave the app; consent (`@inContext(visitorConsent: …)` on the cart, encoded into the checkout URL) before relaying any pixel events. *(Not verified: whether Apple Pay appears inside the checkout sheet's own page; Checkout Kit 3.9.2 ships no privacy manifest, so the app's own `PrivacyInfo.xcprivacy` covers it.)*

### Storefront API

Source: shopify.dev Storefront API reference and the cart guide (read through Shopify's docs search); the site's `package.json` and `app/lib/fragments.ts`.

- **Version:** 2026-10 is the current stable version (released October 1, 2026, supported until October 16, 2027; 2027-01 is the release candidate). The site is on 2026-04 through Hydrogen 2026.4.7 (supported until April 16, 2027). The app uses 2026-10; cart ids aren't tied to a version.
- **Endpoint:** `POST https://{store}.myshopify.com/api/2026-10/graphql.json`, headers `Content-Type: application/json` and `X-Shopify-Storefront-Access-Token: {public token}`. The private-token headers are for servers only, never in an app. Metafields need the token.
- **Cart mutations:** `cartCreate(input: CartInput)`, `cartLinesAdd(cartId:, lines:)`, `cartLinesRemove(cartId:, lineIds:)`, `cartLinesUpdate`, `cartDiscountCodesUpdate(cartId:, discountCodes:)` (replaces all codes), `cartBuyerIdentityUpdate`; the query `cart(id:)`. Every payload has `userErrors` and `warnings { code target message }`, which can come back on a mutation that succeeded (`MERCHANDISE_OUT_OF_STOCK`, `MERCHANDISE_NOT_ENOUGH_STOCK`, …; `target` is the line id).
- **Fields the bag reads** (as the site's `CartApiQuery`): `id checkoutUrl totalQuantity updatedAt cost{subtotalAmount totalAmount} discountCodes{code applicable} lines(first: 100){nodes{id quantity merchandise{... on ProductVariant{id availableForSale price{amount} image{url altText width height} selectedOptions{name value} product{handle title vendor}}}}}`.
- **The cart id** looks like `gid://shopify/Cart/<token>?key=<secret>`: always keep and send the whole id; without the key, mutations fail and reads lose private details. Shopify says to treat the key like a password, so the app keeps it in the Keychain.
- **Lifetime:** unused carts expire within 30 days of creation; a cart is deleted when its checkout completes and can't be read after. No cart webhooks. Shopify gives no specific guidance for keeping a cart id in a mobile app *(not verified)*; the plan in APP-SPEC §3.7 (read on launch and return, forget when it's gone or completed) follows the general advice.
- **Context:** `@inContext(country: US, language: EN)` on every query and mutation, as the site does.

### How the site does the bag (to mirror)

- `app/lib/bag/bag.server.ts`: a cart becomes a bag (`bagFromCart`); the subtotal adds only lines still `availableForSale`; adding a piece already in the bag does nothing; adds are always quantity 1; any error on add, or the line missing when the cart is read back, is "That piece has just sold."; remove is `cartLinesRemove([lineId])`; an unreadable cart shows as an empty bag (`app/root.tsx`).
- `app/components/bag/BagPage.tsx` and `BagDrawer.tsx`: the copy ("Every piece is one of one and isn't held until you check out.", "This piece has sold since you added it.", "Sold" where the price was).
- `app/routes/discount.$code.tsx` and `cart.$lines.tsx`: discount links and cart permalinks; the app's version (a Universal Link that applies a code) comes later.
