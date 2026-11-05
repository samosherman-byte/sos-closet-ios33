import SwiftUI
import UIKit

/// Loads a photo once and keeps it (APP-SPEC §1: images load through a small loader on `URLSession` and `URLCache`,
/// no library). The sample store's photos are files in the app; Shopify's come from its image service at the width the
/// screen needs. Photos are shown exactly as they are: this only fetches and decodes them.
@MainActor
final class PhotoLoader {
    static let shared = PhotoLoader()

    private let memory = NSCache<NSURL, UIImage>()
    private var running: [URL: Task<UIImage?, Never>] = [:]
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 32 << 20, diskCapacity: 256 << 20)
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()

    func cached(_ url: URL) -> UIImage? { memory.object(forKey: url as NSURL) }

    func image(_ url: URL) async -> UIImage? {
        if let hit = cached(url) { return hit }
        if let task = running[url] { return await task.value }
        let session = session
        let task = Task.detached(priority: .userInitiated) { () -> UIImage? in
            let data: Data?
            if url.isFileURL {
                data = try? Data(contentsOf: url)
            } else {
                data = try? await session.data(from: url).0
            }
            // Decoded off the main thread, so scrolling stays smooth.
            return data.flatMap { UIImage(data: $0)?.preparingForDisplay() }
        }
        running[url] = task
        let image = await task.value
        running[url] = nil
        if let image { memory.setObject(image, forKey: url as NSURL) }
        return image
    }
}

/// A photo from a URL, drawn by `content` once it's loaded (nothing, on the page's own ground, until then).
struct LoadedPhoto<Content: View>: View {
    let url: URL?
    @ViewBuilder var content: (UIImage) -> Content

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image { content(image) }
        }
        .task(id: url) {
            guard let url else { image = nil; return }
            if let hit = PhotoLoader.shared.cached(url) { image = hit; return }
            image = await PhotoLoader.shared.image(url)
        }
    }
}
