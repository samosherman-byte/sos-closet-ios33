import SwiftUI

/// Adding a piece opens the bag (APP-SPEC §3.7, §4; the site's BagDrawer): a sheet from the bottom, half height on the
/// system's glass, with the piece just added, the subtotal, Check Out and View Bag, and the honest note that nothing is
/// held until checkout; pulled up to full height, the rest of the bag. Swiped down, it closes.
struct BagSheet: View {
    let added: AddedPiece

    @Environment(Bag.self) private var bag
    @Environment(AppState.self) private var app
    @Environment(Closet.self) private var closet

    var body: some View {
        let contents = bag.contents
        let line = contents.lines.first { $0.variantId == added.variantId }
        let piece = closet.piece(handle: added.handle)
        let others = contents.lines.filter { $0.variantId != added.variantId }
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    AddedMark()
                    Text("Added to your bag")
                        .textStyle(.sectionLabel)
                        .foregroundStyle(.ink)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 12)
                    Button { bag.sheet = nil } label: {
                        Polyline(box: CGSize(width: 24, height: 24), points: [(6.5, 6.5), (17.5, 17.5)])
                            .stroke(.ink, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                            .overlay {
                                Polyline(box: CGSize(width: 24, height: 24), points: [(17.5, 6.5), (6.5, 17.5)])
                                    .stroke(.ink, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                            }
                            .frame(width: 18, height: 18)
                            .frame(width: 44, height: 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, -12)
                    .accessibilityLabel("Close")
                }
                HStack(alignment: .top, spacing: 16) {
                    BagPhoto(image: piece?.image ?? line?.image, size: CGSize(width: 104, height: 130))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(piece?.designer ?? line?.designer ?? "")
                            .textStyle(.cardDesigner)
                            .foregroundStyle(.ink)
                        Text(piece?.title ?? line?.title ?? "")
                            .textStyle(.cardName)
                            .foregroundStyle(.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                        if let size = line?.size {
                            Text("Size \(size)")
                                .textStyle(.cardSize)
                                .foregroundStyle(.muted)
                        }
                        Text(moneyText(line?.price ?? piece?.price ?? 0))
                            .textStyle(.cardPrice)
                            .foregroundStyle(.ink)
                            .monospacedDigit()
                            .padding(.top, 2)
                    }
                    .accessibilityElement(children: .combine)
                }
                .padding(.top, 10)
                HStack(alignment: .firstTextBaseline) {
                    Text("Subtotal · \(plural(contents.lines.count, "piece"))").textStyle(.bagSubtotal)
                    Spacer(minLength: 12)
                    Text(centsText(contents.subtotal)).textStyle(.bagSubtotalAmount).monospacedDigit()
                }
                .foregroundStyle(.ink)
                .accessibilityElement(children: .combine)
                .padding(.top, 14)
                .hairlineAbove()
                .padding(.top, 18)
                CheckOutButton(place: .sheet)
                    .padding(.top, 18)
                SquareButton(title: "View Bag", look: .outline) {
                    bag.sheet = nil
                    app.tab = .bag
                }
                .padding(.top, 10)
                Text("Every piece is one of one and isn’t held until you check out.")
                    .textStyle(.productNote)
                    .foregroundStyle(.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)
                if !others.isEmpty {
                    Text("Also in your bag")
                        .textStyle(.sectionLabel)
                        .foregroundStyle(.ink)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, 36)
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(others) { other in
                            let p = closet.piece(handle: other.handle)
                            HStack(alignment: .top, spacing: 14) {
                                BagPhoto(image: p?.image ?? other.image, size: CGSize(width: 64, height: 80))
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(p?.designer ?? other.designer)
                                        .textStyle(.cardDesigner)
                                        .foregroundStyle(.ink)
                                    Text(p?.title ?? other.title)
                                        .textStyle(.cardName)
                                        .foregroundStyle(.ink2)
                                        .lineLimit(2)
                                    Text(other.available ? centsText(other.price) : "Sold")
                                        .textStyle(.cardPrice)
                                        .foregroundStyle(.ink)
                                        .monospacedDigit()
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                    .padding(.top, 14)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 28)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear { bag.preload() }
    }
}

/// The small check beside "Added to your bag" (the site's AddedIcon), drawn in as the sheet opens. Reduce Motion: it's
/// simply there.
private struct AddedMark: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawn = false

    var body: some View {
        Polyline(box: CGSize(width: 24, height: 24), points: [(5, 12.5), (10, 17.5), (19, 7)])
            .trim(from: 0, to: drawn || reduceMotion ? 1 : 0)
            .stroke(.ink, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
            .frame(width: 16, height: 16)
            .accessibilityHidden(true)
            .onAppear {
                withAnimation(Motion.easeOut(0.6).delay(0.1)) { drawn = true }
            }
    }
}
