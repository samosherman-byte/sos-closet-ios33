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
    @ViewBuilder var content: (UIImage) -> Content

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image { content(image) }
        }
        .task(id: Load(url: url, active: active)) {
            guard let url, active else { image = nil; return }
            if let hit = PhotoLoader.shared.cached(url, maxPixels: maxPixels) { image = hit; return }
            image = await PhotoLoader.shared.image(url, maxPixels: maxPixels)
        }
    }

    private struct Load: Equatable {
        var url: URL?
        var active: Bool
    }
}
