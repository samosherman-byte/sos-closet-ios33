import SwiftUI
import UIKit

/// A product photo from a file in the app (the sample store), decoded off the main thread at the size it's shown and
/// kept in memory. The file is never changed (Sam's rule); only how many pixels are decoded for the screen.
/// Shopify's photos will load through the image service at the width the screen needs (APP-SPEC §3.1).
struct LocalPhoto: View {
    let url: URL?
    /// How the photo fills its frame: `.fill` crops from the middle (cards), `.fit` shows it whole.
    var contentMode: ContentMode = .fill
    /// The ground while it loads (SPEC §12: stone on cards; white where the photo meets the page).
    var ground: Color = .stone

    @State private var image: UIImage?
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle().fill(ground)
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
            }
            .task(id: url) {
                let pixels = max(geometry.size.width, geometry.size.height) * displayScale
                image = await PhotoCache.shared.image(at: url, maxPixels: pixels)
            }
        }
    }
}

/// Decoded photos, by file and size.
actor PhotoCache {
    static let shared = PhotoCache()
    private let cache = NSCache<NSString, UIImage>()

    func image(at url: URL?, maxPixels: CGFloat) async -> UIImage? {
        guard let url, maxPixels > 0 else { return nil }
        // Round up to steps of 200 pixels so nearby sizes share one decoded copy.
        let size = (maxPixels / 200).rounded(.up) * 200
        let key = "\(url.path())@\(Int(size))" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let decoded = await Task.detached(priority: .userInitiated, operation: { Self.decode(url, maxPixels: size) }).value else { return nil }
        cache.setObject(decoded, forKey: key)
        return decoded
    }

    nonisolated private static func decode(_ url: URL, maxPixels: CGFloat) -> UIImage? {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, options) else { return nil }
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels,
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
