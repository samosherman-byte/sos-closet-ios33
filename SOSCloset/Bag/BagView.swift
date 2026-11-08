import SwiftUI
@preconcurrency import ShopifyCheckoutSheetKit

/// The Bag tab (APP-SPEC §3.7; SPEC §11; the app prototype's Bag), under the top row alone: BAG, each piece with
/// Remove, the honest note that nothing is held, the subtotal and shipping, and Check Out to Shopify's own checkout. A
/// piece that has sold since it was added stays, saying so, with "Sold" where its price was, and leaves the subtotal;
/// when every piece has sold, Continue shopping takes Check Out's place. Pull down to read the cart again.
struct BagView: View {
    @Environment(Bag.self) private var bag

    var body: some View {
        HeaderPage(showsMap: false, refresh: { await bag.load() }) { width in
            BagPage(width: width)
        }
        .onAppear { bag.preload() }
    }
}

private struct BagPage: View {
    let width: CGFloat

    @Environment(Bag.self) private var bag
    @Environment(AppState.self) private var app
    @Environment(Closet.self) private var closet
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let contents = bag.contents
        VStack(alignment: .leading, spacing: 0) {
            Text("Bag")
                .textStyle(.bagTitle)
                .foregroundStyle(.ink)
                .padding(.leading, TextStyle.bagTitle.tracking * TextStyle.bagTitle.size)
                .frame(maxWidth: .infinity)
                .accessibilityAddTraits(.isHeader)
            if contents.lines.isEmpty {
                empty
            } else {
                if contents.allSold {
                    Text("Everything in your bag has sold.")
                        .textStyle(.bagRow)
                        .foregroundStyle(.ink2)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                }
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(contents.lines) { line in
                        BagLineRow(line: line, piece: closet.piece(handle: line.handle)) {
                            Task { await bag.remove(line, reduceMotion: reduceMotion) }
                        }
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
                    }
                }
                .padding(.top, 24)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Pieces in your bag")
                Text("Every piece is one of one and isn’t held until you check out.")
                    .textStyle(.productNote)
                    .foregroundStyle(.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 14)
                    .hairlineAbove()
                summary(contents)
            }
        }
        .padding(.horizontal, Layout.gutter(forWidth: width))
        .padding(.top, 24)
        .padding(.bottom, 56)
        .frame(width: width, alignment: .topLeading)
    }

    // MARK: The summary and Check Out

    private func summary(_ contents: BagContents) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Subtotal").textStyle(.bagSubtotal)
                    Spacer(minLength: 12)
                    // (An amount never breaks across lines; the words beside it wrap instead.)
                    Text(centsText(contents.subtotal)).textStyle(.bagSubtotalAmount).monospacedDigit().fixedSize()
                }
                .foregroundStyle(.ink)
                .accessibilityElement(children: .combine)
                HStack(alignment: .firstTextBaseline) {
                    Text("Shipping")
                    Spacer(minLength: 12)
                    Text("$12 standard · $35 express")
                }
                .textStyle(.bagRow)
                .foregroundStyle(.ink2)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Shipping: $12 standard, $35 express")
                Text("Shipping and tax are added at checkout. Returns within 14 days.")
                    .textStyle(.productNote)
                    .foregroundStyle(.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 14)
            .hairlineAbove()
            if contents.allSold {
                SquareButton(title: "Continue shopping", look: .solid) { app.tab = .shop }
                    .padding(.top, 22)
            } else {
                CheckOutButton(place: .page)
                    .padding(.top, 22)
            }
        }
    }

    /// Nothing in it: one line and the way back to the pieces.
    private var empty: some View {
        VStack(spacing: 12) {
            Text("Your bag is empty.")
                .textStyle(.bagEmpty)
                .foregroundStyle(.ink)
            Button { app.tab = .shop } label: {
                Text("Continue shopping")
                    .textStyle(.smallButton)
                    .foregroundStyle(.paper)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 8)
                    .frame(minHeight: 48)
                    .background(.ink)
                    .contentShape(.rect)
            }
            .buttonStyle(Dimmed())
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 64)
    }
}

/// One piece in the bag: its photo (104 × 130, opening its page), designer, name, size, price, and Remove.
private struct BagLineRow: View {
    let line: BagLine
    /// The piece in the closet, while it's for sale.
    let piece: Piece?
    let remove: () -> Void

    @Environment(AppState.self) private var app
    @Environment(\.pieceZoom) private var zoom
    @Environment(\.displayScale) private var displayScale

    private var zoomID: String { "bag|" + line.lineId }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Button {
                if let piece { app.open(piece, zoomID: zoomID) }
            } label: {
                BagPhoto(image: piece?.image ?? line.image, size: CGSize(width: 104, height: 130))
                    .zoomSource(zoomID, in: zoom)
            }
            .buttonStyle(.plain)
            // (A sold piece's photo isn't a link; it isn't dimmed either: photos are shown as they are.)
            .allowsHitTesting(piece != nil)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(piece?.designer ?? line.designer)
                        .textStyle(.cardDesigner)
                        .foregroundStyle(.ink)
                    Text(piece?.title ?? line.title)
                        .textStyle(.cardName)
                        .foregroundStyle(.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                    if let size = line.size {
                        Text("Size \(size)")
                            .textStyle(.cardSize)
                            .foregroundStyle(.muted)
                    }
                    if !line.available {
                        Text("This piece has sold since you added it.")
                            .textStyle(.productNote)
                            .foregroundStyle(.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(line.available ? centsText(line.price) : "Sold")
                        .textStyle(.cardPrice)
                        .foregroundStyle(.ink)
                        .monospacedDigit()
                        .padding(.top, 2)
                }
                .accessibilityElement(children: .combine)
                Spacer(minLength: 0)
                Button(action: remove) {
                    Text("Remove")
                        .textStyle(.bagRemove)
                        .foregroundStyle(.ink)
                        .lineUnder(true, offset: 3)
                        .frame(height: 36)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(piece?.title ?? line.title)")
            }
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        }
        .padding(.vertical, 18)
        .hairlineAbove()
    }
}

/// A piece's photo in the bag, filling its frame on white.
struct BagPhoto: View {
    let image: PieceImage?
    let size: CGSize

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        LoadedPhoto(
            url: image?.url(points: size.width, scale: displayScale), maxPixels: Int(size.height * displayScale * 1.2),
            standIn: true
        ) { photo in
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
        }
        .frame(width: size.width, height: size.height)
        .background(.paper)
    }
}

// MARK: - Check Out

/// Check Out (52pt, square, ink) and the line under it: Shopify's own checkout opens over the bag. In the sample store
/// there's no checkout, so it's the disabled button and the reason (the site's sample store does the same).
struct CheckOutButton: View {
    let place: Bag.Place

    @Environment(Bag.self) private var bag
    @State private var opening = false

    var body: some View {
        VStack(spacing: 10) {
            SquareButton(title: opening ? "Opening checkout…" : "Check Out", look: bag.canCheckOut ? .solid : .off) {
                guard !opening else { return }
                opening = true
                Task {
                    await bag.checkOut(from: place)
                    opening = false
                }
            }
            .disabled(!bag.canCheckOut || opening)
            // (Shopify's checkout offers Shop Pay, PayPal and Apple Pay at its top: seen on Sam's store, November 7.)
            Text(bag.canCheckOut ? "Secure checkout by Shopify, with Apple Pay" : "Checkout is Shopify’s own page: it opens once the app is connected to the store.")
                .textStyle(.productNote)
                .foregroundStyle(.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            if let notice = bag.notice {
                Text(notice)
                    .textStyle(.productMessage)
                    .foregroundStyle(.ink2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

/// A square button of the page (the site's `.btn.lg`): solid ink, outlined, or off (stone and muted).
struct SquareButton: View {
    enum Look { case solid, outline, off }

    let title: String
    let look: Look
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .textStyle(.bigButton)
                .foregroundStyle(look == .solid ? Color.paper : look == .off ? Color.muted : Color.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(look == .solid ? Color.ink : look == .off ? Color.stone : Color.paper)
                .overlay { Rectangle().strokeBorder(look == .off ? Color.lineStrong : Color.ink, lineWidth: 1) }
                .contentShape(.rect)
        }
        .buttonStyle(Dimmed())
    }
}

/// Pressing a square button: it dims a touch.
struct Dimmed: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    // (Checkout Kit has a `Configuration` of its own, hence the full name.)
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .opacity(configuration.isPressed && isEnabled ? 0.82 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    /// The page's hairline (`line`) along the top.
    func hairlineAbove() -> some View {
        overlay(alignment: .top) { Rectangle().fill(.line).frame(height: 1) }
    }

    /// Shopify's checkout, opened from here (`place`): closing it (its close button, or a swipe down) comes back here.
    func checkout(over place: Bag.Place) -> some View {
        modifier(CheckoutPresenter(place: place))
    }
}

/// Shopify's own checkout through Checkout Kit (APP-SPEC §3.7): its completion starts the bag fresh; its close
/// returns to the bag; a failure says so in the bag.
private struct CheckoutPresenter: ViewModifier {
    let place: Bag.Place

    @Environment(Bag.self) private var bag

    func body(content: Content) -> some View {
        content.sheet(
            isPresented: Binding(get: { bag.checkout?.over == place }, set: { if !$0 { bag.closeCheckout() } })
        ) {
            if let url = bag.checkout?.url {
                CheckoutSheet(checkout: url)
                    .onComplete { _ in bag.completed() }
                    .onCancel { bag.closeCheckout() }
                    .onFail { error in bag.checkoutFailed(error) }
                    .ignoresSafeArea()
            }
        }
    }
}
