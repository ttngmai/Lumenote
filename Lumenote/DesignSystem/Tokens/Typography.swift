//

import SwiftUI

/// Rounded system type scale used across Lumenote chrome.
enum LumenoteFont {
    static func rounded(size: CGFloat, weight: Font.Weight) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func caption2(_ weight: Font.Weight = .semibold) -> Font {
        .system(.caption2, design: .rounded).weight(weight)
    }

    static func caption(_ weight: Font.Weight = .semibold) -> Font {
        .system(.caption, design: .rounded).weight(weight)
    }

    static func callout(_ weight: Font.Weight = .semibold) -> Font {
        .system(.callout, design: .rounded).weight(weight)
    }

    static func subheadline(_ weight: Font.Weight = .semibold) -> Font {
        .system(.subheadline, design: .rounded).weight(weight)
    }

    static func body(_ weight: Font.Weight = .semibold) -> Font {
        .system(.body, design: .rounded).weight(weight)
    }

    static func headline(_ weight: Font.Weight = .bold) -> Font {
        .system(.headline, design: .rounded).weight(weight)
    }
}
