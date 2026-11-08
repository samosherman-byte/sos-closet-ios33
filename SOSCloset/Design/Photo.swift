import ImageIO
import SwiftUI
import UIKit

/// Loads a photo once and keeps it (APP-SPEC §1: images load through a small loader on `URLSession` and `URLCache`,
/// no library). The sample store's photos are files in the app; Shopify's come from its image service at the width the
/// screen needs. Photos are shown exactly as they are: this only fetches and decodes them, at most at the pixel size
/// they're drawn at (a department holds 150 cards, and a full-size decode of each would use gigabytes).
@MainActor
final class PhotoLoader {
    static let shared = PhotoLoader()

    private let memory: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 160 << 20
        return cache
    }()
    private var running: [String: Task<UIImage?, Never>] = [:]
    /// The last key decoded for each photo, whatever its size: a page opening on a photo a card has just drawn shows the
    /// card's copy until its own is in.
    private var lastKey: [String: String] = [:]
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 32 << 20, diskCapacity: 256 << 20)
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()

    private static func key(_ url: URL, _ maxPixels: Int?) -> String {
        url.absoluteString + "#" + (maxPixels.map(String.init) ?? "full")
    }

    func cached(_ url: URL, maxPixels: Int? = nil) -> UIImage? { memory.object(forKey: Self.key(url, maxPixels) as NSString) }

    /// Any copy of this photo already decoded, at whatever size (Shopify's image service gives the same photo at each
    /// width).
    func anyCached(_ url: URL) -> UIImage? {
        lastKey[Self.base(url)].flatMap { memory.object(forKey: $0 as NSString) }
    }

    private static func base(_ url: URL) -> String {
        guard var parts = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url.absoluteString }
        parts.queryItems = parts.queryItems?.filter { $0.name != "width" }
        if parts.queryItems?.isEmpty == true { parts.queryItems = nil }
        return parts.string ?? url.absoluteString
    }

    /// The photo, decoded no larger than `maxPixels` on its longer side (nil: as it is).
    func image(_ url: URL, maxPixels: Int? = nil) async -> UIImage? {
        let key = Self.key(url, maxPixels)
        if let hit = memory.object(forKey: key as NSString) { return hit }
        if let task = running[key] { return await task.value }
        let session = session
        let task = Task.detached(priority: .userInitiated) { () -> UIImage? in
            let data: Data?
            if url.isFileURL {
                data = try? Data(contentsOf: url)
            } else {
                data = try? await session.data(from: url).0
            }
            // Decoded off the main thread, so scrolling stays smooth.
            guard let data else { return nil }
            if let maxPixels, let small = Self.downsampled(data, maxPixels: maxPixels) { return small }
            return UIImage(data: data)?.preparingForDisplay()
        }
        running[key] = task
        let image = await task.value
        running[key] = nil
        if let image {
            let cost = Int(image.size.width * image.scale * image.size.height * image.scale * 4)
            memory.setObject(image, forKey: key as NSString, cost: cost)
            lastKey[Self.base(url)] = key
        }
        return image
    }

    /// Starts loading photos a card will slide to next, so they're there when they come in.
    func prefetch(_ urls: [URL], maxPixels: Int?) {
        for url in urls where cached(url, maxPixels: maxPixels) == nil {
            Task { _ = await image(url, maxPixels: maxPixels) }
        }
    }

    /// ImageIO's thumbnail of the file at the drawn size: the same picture, with no more pixels than the screen shows.
    nonisolated private static func downsampled(_ data: Data, maxPixels: Int) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary)
        else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels,
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: cg)
    }
}

/// A photo from a URL, drawn by `content` once it's loaded (nothing, on the page's own ground, until then).
/// `maxPixels` decodes it no larger than it's drawn; `active: false` lets it go while it's far off screen (the
/// loader's cache keeps it for coming back).
struct LoadedPhoto<Content: View>: View {
    let url: URL?
    var maxPixels: Int? = nil
    var active = true
    /// Until this size is in, show any copy of the photo already decoded (a card's, as its piece's page opens).
    var standIn = false
    @ViewBuilder var content: (UIImage) -> Content

    @State private var image: UIImage?

    var body: some View {
        // (What's in the loader's cache shows on the first frame, before the task runs.)
        let shown = image ?? (active ? url.flatMap(quick) : nil)
        ZStack {
            if let shown { content(shown) }
        }
        .task(id: Load(url: url, active: active)) {
            guard let url, active else { image = nil; return }
            if let hit = PhotoLoader.shared.cached(url, maxPixels: maxPixels) { image = hit; return }
            image = await PhotoLoader.shared.image(url, maxPixels: maxPixels)
        }
    }

    private func quick(_ url: URL) -> UIImage? {
        PhotoLoader.shared.cached(url, maxPixels: maxPixels) ?? (standIn ? PhotoLoader.shared.anyCached(url) : nil)
    }

    private struct Load: Equatable {
        var url: URL?
        var active: Bool
    }
}
