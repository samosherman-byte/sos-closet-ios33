import Foundation

/// Which store the app reads, and how to reach it (APP-SPEC §5). The values come from Config/ (Store.xcconfig, and
/// Secrets.xcconfig on Sam's Mac) through Info.plist. Release builds always read Sam's store.
nonisolated enum StoreConfig {
    enum Source: String, Sendable {
        /// The site's sample store: its import files and the prototype's photos, copied in by tools/sync-sample-store.sh.
        case sample
        /// Sam's store, through the Storefront API.
        case shopify
    }

    static let source: Source = {
        #if DEBUG
        Source(rawValue: info("SOSStore")) ?? .shopify
        #else
        .shopify
        #endif
    }()

    /// The store's address without https:// (empty until Config/Secrets.xcconfig is filled in).
    static let storeDomain = info("SOSShopifyStoreDomain")
    /// Shopify's public Storefront API token, made to be inside apps. The private token is never used.
    static let storefrontToken = info("SOSStorefrontToken")
    static let apiVersion = "2026-10"

    /// `POST` GraphQL here, with the token in `X-Shopify-Storefront-Access-Token`. Nil until the address is in.
    static var endpoint: URL? {
        guard !storeDomain.isEmpty else { return nil }
        return URL(string: "https://\(storeDomain)/api/\(apiVersion)/graphql.json")
    }

    /// The sample store's folder in the app (Debug builds reading the sample store; nil otherwise or if it's missing).
    static var sampleStoreURL: URL? {
        #if DEBUG
        guard source == .sample, let url = Bundle.main.url(forResource: "SampleStore", withExtension: nil) else { return nil }
        return url
        #else
        nil
        #endif
    }

    /// The site's photos that ship in the app: tiles/ (the category cutouts) and home/ (the home page's photos).
    static var siteAssetsURL: URL? {
        Bundle.main.url(forResource: "SiteAssets", withExtension: nil)
    }

    private static func info(_ key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String)?.trimmingCharacters(in: .whitespaces) ?? ""
    }
}
