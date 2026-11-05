import SwiftUI
import UIKit

extension HomeContent {
    /// The three bags' cut-outs (SiteAssets/home/, copied unchanged from the site's public/home/), left to right as
    /// Sam named them: the Bréa, the Jackie 1961 and the Bamboo (the site's TURNTABLE). Their credits come from the
    /// closet once it's loaded.
    static func cutout(_ file: String) -> UIImage? {
        guard let url = StoreConfig.siteAssetsURL?.appending(path: "home/\(file)") else { return nil }
        return UIImage(contentsOfFile: url.path())
    }
}
