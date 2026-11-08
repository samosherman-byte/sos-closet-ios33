import SwiftUI
import UIKit

/// The product photos (SPEC §10; the site's Gallery.tsx): the main photo, the width of the screen at 4:5, each photo
/// shown whole on white; a sideways track that moves exactly one photo a swipe, however fast, like the Photos app. The
/// counter (2 / 7) and, with several photos, a row of thumbnails that follows and keeps the current one in view; then
/// Labels & markings over a second row of smaller thumbnails for the proof photos, which follow the piece's own on the
/// same track. Tapping a thumbnail glides to its photo; tapping the photo zooms it (pinch too), a zoomed photo doesn't
/// swipe, and moving to another photo zooms back out. The photo files are never changed: this only shows them.
struct ProductGallery: View {
    /// The piece's own photos, then what proves something.
    let look: [PieceImage]
    let proof: [PieceImage]
    let width: CGFloat
    /// The photo in view (the page opens on the one its card was showing).
    @Binding var at: Int

    @Environment(\.displayScale) private var displayScale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var zoomed = false
    @State private var thumbRow = ScrollPosition(idType: Int.self)
    @State private var thumbOffset: CGFloat = 0

    private var photos: [PieceImage] { look + proof }
    private var height: CGFloat { (width * 1.25).rounded() }
    /// The look thumbnails (56 × 70pt, 8pt apart, from the page's margin) and the proof ones (64pt square).
    private static let thumb = CGSize(width: 56, height: 70)
    private static let proofThumb: CGFloat = 64

    var body: some View {
        let n = photos.count
        VStack(alignment: .leading, spacing: 0) {
            main(n)
            if n > 1, !look.isEmpty {
                thumbs
                    .padding(.top, 12)
            }
            if !proof.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Labels & markings")
                        .textStyle(.proofLabel)
                        .foregroundStyle(.muted)
                        .accessibilityAddTraits(.isHeader)
                    HStack(spacing: 8) {
                        ForEach(Array(proof.enumerated()), id: \.offset) { j, photo in
                            thumbButton(look.count + j, photo, size: CGSize(width: Self.proofThumb, height: Self.proofThumb))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
            }
        }
        .onChange(of: at) { _, k in
            zoomed = false
            keepThumbInView(k)
        }
    }

    // MARK: The main photo

    private func main(_ n: Int) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(Array(photos.enumerated()), id: \.offset) { i, photo in
                    slide(i, photo, of: n)
                        .frame(width: width, height: height)
                        .id(i)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        // (The track and the photo in view are one: a swipe moves `at`, and a thumbnail moves the track.)
        .scrollPosition(id: Binding(get: { at }, set: { if let k = $0, k != at { at = k } }))
        .scrollDisabled(zoomed || n < 2)
        .frame(width: width, height: height)
        .background(.paper)
        .overlay(alignment: .bottomTrailing) {
            if n > 1 {
                Text("\(at + 1) / \(n)")
                    .textStyle(.photoCounter)
                    .foregroundStyle(.ink2)
                    .monospacedDigit()
                    // (It sits on the photo's corner: it grows only so far.)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .padding(.trailing, 16)
                    .padding(.bottom, 14)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Photos")
    }

    /// One photo, whole (`contain`) on white, decoded at the size it's drawn; zoomed, a sharper copy comes in.
    private func slide(_ i: Int, _ photo: PieceImage, of n: Int) -> some View {
        let here = i == at
        let pixels = Int((height * displayScale).rounded(.up))
        return LoadedPhoto(
            url: photo.url(points: width, scale: displayScale), maxPixels: pixels, active: abs(i - at) <= 1,
            standIn: true
        ) { image in
            ZoomablePhoto(
                image: image, sharp: here && zoomed ? sharpURL(photo) : nil, current: here, animate: !reduceMotion
            ) { z in
                if here { zoomed = z }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(n > 1 ? "Photo \(i + 1) of \(n)" : "Photo")
        .accessibilityValue(photo.alt)
        .accessibilityHint(here && zoomed ? "Double-tap to zoom out" : "Double-tap to zoom in")
        .accessibilityAddTraits(.isImage)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: go(min(n - 1, i + 1))
            case .decrement: go(max(0, i - 1))
            @unknown default: break
            }
        }
        .accessibilityHidden(!here)
    }

    /// The photo as large as Shopify keeps it (up to 2400px), for looking closely.
    private func sharpURL(_ photo: PieceImage) -> URL {
        sizedImageURL(photo.url, width: min(photo.width ?? 2400, 2400))
    }

    /// Glides the track to a photo (a jump with Reduce Motion).
    private func go(_ i: Int) {
        guard i != at else { return }
        if reduceMotion {
            at = i
        } else {
            withAnimation(Motion.glide(0.5)) { at = i }
        }
    }

    // MARK: The thumbnails

    private var thumbs: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Array(look.enumerated()), id: \.offset) { i, photo in
                    thumbButton(i, photo, size: Self.thumb)
                        .id(i)
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .scrollPosition($thumbRow)
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.x } action: { _, x in thumbOffset = x }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Choose a photo")
    }

    private func thumbButton(_ i: Int, _ photo: PieceImage, size: CGSize) -> some View {
        let on = i == at
        return Button { go(i) } label: {
            LoadedPhoto(
                url: photo.url(points: size.width, scale: displayScale), maxPixels: Int(size.height * displayScale * 1.5)
            ) { image in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
            }
            .frame(width: size.width, height: size.height)
            .background(.paper)
            .overlay { Rectangle().strokeBorder(on ? Color.ink : .clear, lineWidth: 1) }
            .animation(.easeOut(duration: 0.3), value: on)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Photo \(i + 1)" + (photo.alt.isEmpty ? "" : ", \(photo.alt)"))
        .accessibilityAddTraits(on ? [.isSelected] : [])
    }

    /// When the thumbnail row runs past the edge, the pressed thumbnail stays in view: it comes to the middle of the
    /// row if it's out of view (SPEC §10).
    private func keepThumbInView(_ i: Int) {
        guard i < look.count else { return }
        let w = Self.thumb.width
        let content = 32 + CGFloat(look.count) * w + CGFloat(max(0, look.count - 1)) * 8
        guard content > width else { return }
        let left = 16 + CGFloat(i) * (w + 8)
        guard left < thumbOffset || left + w > thumbOffset + width else { return }
        let x = min(max(0, left - (width - w) / 2), content - width)
        if reduceMotion {
            thumbRow.scrollTo(x: x)
        } else {
            withAnimation(Motion.glide(0.5)) { thumbRow.scrollTo(x: x) }
        }
    }
}

// MARK: - Zooming a photo

/// A photo that zooms: tapping it zooms to 1.6× about the point tapped (and back), pinching zooms up to 4×, and a
/// zoomed photo pans. It's UIKit's own zooming scroll view, so it feels like the Photos app. Not the current photo: back
/// to normal.
private struct ZoomablePhoto: UIViewRepresentable {
    let image: UIImage
    /// A sharper copy to load while zoomed.
    let sharp: URL?
    let current: Bool
    let animate: Bool
    let onZoom: (Bool) -> Void

    func makeUIView(context: Context) -> ZoomView {
        ZoomView()
    }

    func updateUIView(_ view: ZoomView, context: Context) {
        view.onZoom = onZoom
        view.animate = animate
        if view.shown !== image && view.sharpShown == nil { view.show(image) }
        if !current { view.zoomOut(animated: false) }
        view.loadSharp(sharp)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: ZoomView, context: Context) -> CGSize? {
        proposal.replacingUnspecifiedDimensions()
    }
}

private final class ZoomView: UIScrollView, UIScrollViewDelegate {
    private let imageView = UIImageView()
    var onZoom: (Bool) -> Void = { _ in }
    var animate = true
    private(set) var shown: UIImage?
    private(set) var sharpShown: URL?
    private var sharpTask: Task<Void, Never>?
    private var zoomedIn = false

    /// The site's tap zoom (`.pd-slide.zoomed img { transform: scale(1.6) }`).
    private static let tapZoom: CGFloat = 1.6

    init() {
        super.init(frame: .zero)
        delegate = self
        minimumZoomScale = 1
        maximumZoomScale = 4
        bouncesZoom = true
        alwaysBounceHorizontal = false
        alwaysBounceVertical = false
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        decelerationRate = .fast
        backgroundColor = .white
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    func show(_ image: UIImage) {
        shown = image
        imageView.image = image
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if zoomScale <= 1.001, imageView.frame.size != bounds.size {
            imageView.frame = CGRect(origin: .zero, size: bounds.size)
            contentSize = bounds.size
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    func scrollViewDidZoom(_ scrollView: UIScrollView) { report() }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) { report() }

    private func report() {
        let z = zoomScale > 1.01
        guard z != zoomedIn else { return }
        zoomedIn = z
        onZoom(z)
    }

    func zoomOut(animated: Bool) {
        guard zoomScale > 1.001 else { return }
        setZoomScale(1, animated: animated)
        report()
    }

    @objc private func tapped(_ tap: UITapGestureRecognizer) {
        if zoomScale > 1.01 {
            run { self.setZoomScale(1, animated: false) }
        } else {
            let p = tap.location(in: imageView)
            let w = bounds.width / Self.tapZoom
            let h = bounds.height / Self.tapZoom
            run { self.zoom(to: CGRect(x: p.x - w / 2, y: p.y - h / 2, width: w, height: h), animated: false) }
        }
        report()
    }

    /// The site's 0.6s ease-out (`--ease-out`); at once with Reduce Motion.
    private func run(_ change: @escaping () -> Void) {
        guard animate else { change(); return }
        let animator = UIViewPropertyAnimator(
            duration: 0.6, controlPoint1: CGPoint(x: 0.16, y: 1), controlPoint2: CGPoint(x: 0.3, y: 1), animations: change)
        animator.startAnimation()
    }

    /// While zoomed, the photo at a sharper size replaces the one drawn for the page.
    func loadSharp(_ url: URL?) {
        guard url != sharpShown else { return }
        sharpTask?.cancel()
        guard let url else {
            sharpShown = nil
            if let shown { imageView.image = shown }
            return
        }
        sharpShown = url
        sharpTask = Task { [weak self] in
            // (2400px on its long side: sharp at the zoom a finger uses, without holding the whole file.)
            guard let image = await PhotoLoader.shared.image(url, maxPixels: 2400), !Task.isCancelled else { return }
            self?.imageView.image = image
        }
    }
}
