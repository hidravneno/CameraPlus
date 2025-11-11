
import Foundation

enum FilterOption: String, CaseIterable, Identifiable {
    case original = "Original"
    case noir = "Noir"
    case sepia = "Sepia"
    case bloom = "Bloom"
    case vignette = "Vignette"
    case colorControls = "Color Controls"

    var id: String { rawValue }

    /// Returns whether this filter supports an adjustable intensity.
    var supportsIntensity: Bool {
        switch self {
        case .sepia, .bloom, .vignette, .colorControls:
            return true
        default:
            return false
        }
    }
}

