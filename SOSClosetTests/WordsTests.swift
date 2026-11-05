import Foundation
import Testing
@testable import SOSCloset

// Prices, sizes and names in words, standard sizes and photo widths: the cases of the site's
// app/lib/browse/text.test.ts, sizes.test.ts and std-sizes.test.ts for what's ported.

@Suite("Prices")
struct PriceTests {
    @Test func theHomePageShowsWholeDollarsRoundedUp() {
        #expect(priceText(649.14) == "$650")
        #expect(priceText(229.99) == "$230")
        #expect(priceText(2600) == "$2,600")
        #expect(priceText(1166) == "$1,166")
        #expect(priceText(0.01) == "$1")
        // (Arithmetic's last-digit noise doesn't round a whole dollar up.)
        #expect(priceText(0.1 + 0.2 + 99.7) == "$100")
        #expect(priceText(1_250_000) == "$1,250,000")
    }

    @Test func cardsShowWholeDollarsAndTheCentsOnlyWhenAPriceHasThem() {
        #expect(moneyText(2600) == "$2,600")
        #expect(moneyText(204.75) == "$204.75")
        #expect(moneyText(33.75) == "$33.75")
        #expect(moneyText(19.5) == "$19.50")
        #expect(moneyText(1775.0) == "$1,775")
        #expect(moneyText(0.1 + 0.2) == "$0.30")
    }

    @Test func theBagShowsTheCentsAlways() {
        #expect(centsText(2600) == "$2,600.00")
        #expect(centsText(204.75) == "$204.75")
        #expect(centsText(1234.5) == "$1,234.50")
    }

    @Test func counts() {
        #expect(plural(117, "piece") == "117 pieces")
        #expect(plural(1, "piece") == "1 piece")
        #expect(plural(0, "piece") == "0 pieces")
    }
}

@Suite("Sizes in words")
struct SizeWordsTests {
    @Test func saysSizeOrSizesInSizeOrder() {
        #expect(sizeWords([]) == "")
        #expect(sizeWords(["S"]) == "Size S")
        #expect(sizeWords(["10", "8"]) == "Sizes 8, 10")
        #expect(sizeWords(["M", "S"]) == "Sizes S, M")
    }

    @Test func listsEverySizeOnTheProductPage() {
        #expect(sizeWords(["L", "XS", "M"]) == "Sizes XS, M, L")
    }

    @Test func makesThreeOrMoreARangeOnACard() {
        #expect(sizeWords(["L", "XS", "M"], range: true) == "Sizes XS–L")
        #expect(sizeWords(["44R", "40R", "48R", "42R", "46R"], range: true) == "Sizes 40R–48R")
        #expect(sizeWords(["8", "10"], range: true) == "Sizes 8, 10")
    }
}

@Suite("Names")
struct SlugTests {
    @Test func slugsAsTheSiteDoes() {
        #expect(slug("Tops & Blouses") == "tops-blouses")
        #expect(slug("Hermès") == "hermes")
        #expect(slug("Women’s Watches") == "womens-watches")
        #expect(slug("  Like New ") == "like-new")
        #expect(slug("Top-Handle") == "top-handle")
        #expect(fold("Hermès") == "hermes")
    }

    @Test func departmentsAndTheTabMap() {
        #expect(Dept.allCases.map(\.displayName) == ["Women", "Men", "Jewelry & Objects"])
        #expect(Dept.allCases.map(\.tabIndex) == [1, 2, 3])
        #expect(Dept.women.categories == ["Handbags", "Clothing", "Shoes", "Accessories"])
        #expect(RecordMaps.deptOfCat == [
            "Handbags": .women, "Jewelry": .jewelry, "Watches": .jewelry, "Art": .jewelry, "Home": .jewelry,
        ])
    }
}

/// A standard size answer, comparable.
nonisolated struct Std: Equatable {
    var fz: [String]
    var note: String
    init(_ fz: [String], _ note: String) {
        self.fz = fz
        self.note = note
    }
    init(_ r: ([String], String)) { self.init(r.0, r.1) }
}

@Suite("Standard sizes (SPEC §9)")
struct StandardSizesTests {
    func women(_ cat: String, _ sub: String = "", _ designer: String = "STAUD") -> SizedPiece {
        SizedPiece(dept: .women, cat: cat, sub: sub, designer: designer)
    }
    func men(_ cat: String, _ sub: String = "") -> SizedPiece {
        SizedPiece(dept: .men, cat: cat, sub: sub, designer: "Coppley")
    }
    func std(_ x: SizedPiece, _ z: String, fromSearch: Bool = false) -> Std { Std(stdOf(x, z, fromSearch: fromSearch)) }

    @Test func givesEachPieceOneScale() {
        #expect(axisOf(women("Clothing")) == .wc)
        #expect(axisOf(women("Shoes")) == .ws)
        #expect(axisOf(women("Handbags")) == nil)
        #expect(axisOf(men("Clothing", "Suits")) == .mt)
        #expect(axisOf(men("Clothing", "Sport Coats & Blazers")) == .mt)
        #expect(axisOf(men("Clothing", "Shirts")) == .mc)
        #expect(axisOf(men("Shoes")) == .ms)
        #expect(axisOf(SizedPiece(dept: .jewelry, cat: "Rings", sub: nil, designer: "")) == nil)
    }

    @Test func womensClothingFromUSJeansWaistsAndEuropeanSizes() {
        let w = women("Clothing", "Jackets & Coats")
        #expect(std(w, "6") == Std(["S"], ""))
        #expect(std(w, "00") == Std(["XXS"], ""))
        #expect(std(w, "S/M") == Std(["S", "M"], ""))
        #expect(std(w, "MP") == Std(["M"], ""))
        #expect(std(w, "FR 38") == Std(["S"], "US 6"))
        #expect(std(w, "IT 42") == Std(["S"], "US 6"))
        #expect(std(w, "UK 10") == Std(["S"], "US 6"))
        #expect(std(women("Clothing", "Pants & Jeans"), "W27") == Std(["S"], "US 4"))
        #expect(std(women("Clothing", "Pants & Jeans"), "25") == Std(["XS"], "US 0"))
        // A plain European number is Italian, unless the house sizes in German.
        #expect(std(w, "40") == Std(["S"], "US 4"))
        #expect(std(women("Clothing", "", "Escada"), "40") == Std(["M"], "US 10"))
        #expect(std(w, "One Size") == Std([], ""))
    }

    @Test func shoesInUSSizesMensJacketsByChestMensClothingXSToXXL() {
        #expect(std(women("Shoes"), "37") == Std(["7"], "US 7"))
        #expect(std(women("Shoes"), "37.5") == Std(["7.5"], "US 7.5"))
        #expect(std(women("Shoes"), "UK 5") == Std(["7"], "US 7"))
        #expect(std(men("Shoes"), "UK 9") == Std(["10"], "US 10"))
        #expect(std(men("Shoes"), "EU 43") == Std(["10"], "US 10"))
        #expect(std(men("Clothing", "Suits"), "40R") == Std(["40R"], ""))
        #expect(std(men("Clothing", "Suits"), "IT 52") == Std(["42R"], "US 42R"))
        #expect(std(men("Clothing", "Shirts"), "IT 56") == Std(["XL"], "XL"))
        #expect(std(men("Clothing", "Dress Shirts"), "15.5") == Std(["M"], ""))
        #expect(std(men("Clothing", "Pants & Jeans"), "32") == Std(["M"], ""))
    }

    @Test func aTypedSizeReadsOnlyWhereNumbersAreTheScale() {
        #expect(std(women("Clothing", "Dresses"), "8", fromSearch: true) == Std(["M"], ""))
        #expect(std(women("Clothing", "Dresses"), "40", fromSearch: true) == Std([], ""))
        #expect(std(women("Shoes"), "37", fromSearch: true) == Std(["7"], "US 7"))
        #expect(std(men("Clothing", "Shirts"), "32", fromSearch: true) == Std([], ""))
    }

    @Test func notesTheUSSizeOnlyForAPieceInOneSize() {
        let one = fitOf(women("Clothing"), ["FR 38"])
        #expect(one.ax == .wc)
        #expect(one.fz == ["S"])
        #expect(one.fnote == "US 6")
        #expect(fitOf(women("Clothing"), ["FR 38", "FR 40"]).fnote == "")
        let bag = fitOf(women("Handbags"), [])
        #expect(bag.ax == nil)
        #expect(bag.fz == [])
        #expect(bag.fnote == "")
    }
}

@Suite("Photos at the width the screen needs")
struct ImageWidthTests {
    @Test func shopifysImageServiceGetsTheWidth() {
        let shop = URL(string: "https://cdn.shopify.com/s/files/1/0001/files/jackie.jpg?v=1730000000")!
        #expect(sizedImageURL(shop, width: 480).absoluteString == "https://cdn.shopify.com/s/files/1/0001/files/jackie.jpg?v=1730000000&width=480")
        let bare = URL(string: "https://cdn.shopify.com/s/files/1/0001/files/jackie.jpg")!
        #expect(sizedImageURL(bare, width: 360).absoluteString == "https://cdn.shopify.com/s/files/1/0001/files/jackie.jpg?width=360")
        // Asked again, the width is replaced, not added twice.
        #expect(sizedImageURL(sizedImageURL(shop, width: 480), width: 800).absoluteString.components(separatedBy: "width=").count == 2)
    }

    @Test func otherPhotosComeBackAsTheyAre() {
        let file = URL(fileURLWithPath: "/tmp/SampleStore/prototype/img/64fb1a563b115744ebc5af1027e7c69e.jpg")
        #expect(sizedImageURL(file, width: 480) == file)
        let other = URL(string: "https://example.com/a.jpg")!
        #expect(sizedImageURL(other, width: 480) == other)
    }

    @Test func theSitesStepsNeverWiderThanThePhoto() {
        #expect(imageWidth(forPixels: 585, max: 2000) == 640)
        #expect(imageWidth(forPixels: 100, max: nil) == 240)
        #expect(imageWidth(forPixels: 1320, max: 2000) == 1200)
        #expect(imageWidth(forPixels: 900, max: 900) == 800)
        #expect(imageWidth(forPixels: 300, max: 200) == 200)
    }
}
