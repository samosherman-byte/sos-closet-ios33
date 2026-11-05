import Foundation
import Testing
@testable import SOSCloset

// Which photos go where (SPEC §10): the cases of the site's app/lib/catalog/photos.test.ts for photoDesc, photoRole
// and sortPhotos. (Its photo check cases, sortPhoto's doubts, are for a page on the site only: not ported.)
@Suite("Which photos go where (SPEC §10)")
struct PhotosTests {
    // Descriptions as the live store has them (November 1), the words after " – " in each photo's alt text.
    let gucci = "Gucci"
    let plain = "Henry Dean"

    func role(_ d: String, _ designer: String = "Henry Dean", _ i: Int = 1) -> String {
        let r = photoRole(d, designer: designer, index: i)
        return "\(r.role.rawValue) \(r.why)".trimmingCharacters(in: .whitespaces)
    }

    @Test func readsTheWordsAfterTheDashOrTheWholeAlt() {
        #expect(photoDesc("Gucci Jackie 1961 Medium Tote – heat stamp") == "heat stamp")
        #expect(
            photoDesc("Gucci heat stamp on the leather interior tab")
                == "Gucci heat stamp on the leather interior tab")
        #expect(photoDesc(nil) == "")
    }

    @Test func keepsThePieceItselfAndTheCoverAlways() {
        #expect(role("back") == "look")
        #expect(role("soles") == "look")
        #expect(role("lapel and jacquard") == "look")
        // "button and brand" is a detail: the part comes before the brand.
        #expect(role("button and brand") == "look")
        #expect(role("brand size", plain, 0) == "look")
    }

    @Test func movesWhatProvesSomethingToLabelsAndMarkings() {
        #expect(role("heat stamp", gucci) == "proof")
        #expect(role("serial number stamp", gucci) == "proof")
        #expect(role("original box") == "proof")
        #expect(role("hallmark") == "proof")
        // A label counts only from a house on the LUX list; a size tag only on the sneakers resale buyers check.
        #expect(role("brand label", gucci) == "proof label")
        #expect(role("brand label") == "off label")
        #expect(role("size tag", "Nike") == "proof size tag")
    }

    @Test func leavesGenericLabelsOriginHangtagsAndModelImagesOff() {
        #expect(role("brand size") == "off label")
        #expect(role("size label") == "off label")
        #expect(role("fabric label") == "off label")
        #expect(role("brand origin") == "off origin")
        #expect(role("original tags") == "off tags")
        #expect(role("model front view") == "off model")
        // A hangtag seen on the piece keeps the photo of the piece.
        #expect(role("front with hangtag") == "look nwt")
    }

    @Test func unnamedPhotosStayOnTheCard() {
        #expect(role("") == "look unnamed")
        #expect(role("union button-front shirt, navy, photo 2 of 3") == "look unnamed")
    }

    @Test func aHangtagPhotoMeansNewWithTags() {
        let photos = [
            "STAUD Gus Leather Pants, Earth Brown",
            "STAUD Gus Leather Pants, Earth Brown – back",
            "STAUD Gus Leather Pants, Earth Brown – original tags",
        ].enumerated().map { i, alt in
            PieceImage(url: URL(string: "https://cdn.shopify.com/\(i).jpg")!, alt: alt, width: nil, height: nil)
        }
        let s = sortPhotos(photos, designer: "STAUD")
        #expect(s.look.count == 2)
        #expect(s.off.count == 1)
        #expect(s.nwt)
    }

    @Test func theLuxuryListIsTheSites() {
        #expect(PhotoRules.lux.count == 18)
        #expect(PhotoRules.lux.contains("hermès"))
        #expect(PhotoRules.lux.contains("ippolita"))
        #expect(PhotoRules.snkr == ["adidas", "nike", "jordan", "new balance"])
    }
}
