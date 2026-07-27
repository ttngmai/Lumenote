//

import SwiftUI

/// Appearance chosen by the user. `.system` follows the device setting.
enum AppearanceMode: String, CaseIterable {
    case system
    case light
    case dark

    static let storageKey = "appearanceMode"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Colors for the app chrome, resolved for the active color scheme.
/// Views build one from `@Environment(\.colorScheme)` instead of hardcoding shades,
/// so light and dark can diverge where a single value would be unreadable.
struct AppPalette {
    let colorScheme: ColorScheme

    private var isDark: Bool { colorScheme == .dark }

    // MARK: Surfaces

    var backgroundColors: [Color] {
        isDark
            ? [Color(red: 0.09, green: 0.09, blue: 0.11), Color(red: 0.12, green: 0.13, blue: 0.16)]
            : [Color(red: 0.97, green: 0.96, blue: 0.93), Color(red: 0.92, green: 0.94, blue: 0.96)]
    }

    /// Translucent card background used by the selectors and info cards.
    var cardBackground: Color {
        isDark ? Color(white: 0.16).opacity(0.9) : Color.white.opacity(0.85)
    }

    /// Opaque surface used by the selection popup.
    var popupBackground: Color {
        isDark ? Color(white: 0.14) : Color.white
    }

    var popupHeaderBackground: Color {
        isDark ? Color(white: 0.24) : Color.black
    }

    var popupHeaderForeground: Color { .white }

    var scrim: Color {
        Color.black.opacity(isDark ? 0.5 : 0.28)
    }

    // MARK: Lines

    var cardBorder: Color {
        isDark ? Color(white: 0.85).opacity(0.35) : Color.black.opacity(0.75)
    }

    var cardBorderActive: Color {
        isDark ? Color(white: 0.95) : Color.black
    }

    var divider: Color {
        isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    /// Outlines and separators inside the circle, and the key-signature staff.
    var ringStroke: Color {
        isDark ? Color(white: 0.7) : Color(red: 0.15, green: 0.15, blue: 0.15)
    }

    // MARK: Circle fills

    var major: Color {
        isDark
            ? Color(red: 0xC9 / 255, green: 0x50 / 255, blue: 0x50 / 255)
            : Color(red: 0xE9 / 255, green: 0x5D / 255, blue: 0x5D / 255)
    }

    var minor: Color {
        isDark
            ? Color(red: 0x40 / 255, green: 0x6B / 255, blue: 0xCB / 255)
            : Color(red: 0x4F / 255, green: 0x81 / 255, blue: 0xEE / 255)
    }

    var diminished: Color {
        isDark
            ? Color(red: 0x80 / 255, green: 0x50 / 255, blue: 0xB8 / 255)
            : Color(red: 0x9A / 255, green: 0x64 / 255, blue: 0xDB / 255)
    }

    /// Non-diatonic wedges.
    var chromaticFill: Color {
        isDark ? Color(white: 0.3) : Color(white: 0.86)
    }

    /// Relative-key ring (innermost).
    var relativeFill: Color {
        isDark ? Color(white: 0.22) : Color(red: 0.94, green: 0.94, blue: 0.95)
    }

    // MARK: Emphasis

    /// Chip behind a highlighted formula degree / scale column / selected row.
    /// Dark mode needs a dark amber so `.primary` (white) text stays legible.
    var highlight: Color {
        isDark ? Color(red: 0.45, green: 0.34, blue: 0.1) : Color(red: 1.0, green: 0.88, blue: 0.65)
    }

    /// Softer variant behind the characteristic note / chord rows.
    var highlightSoft: Color {
        isDark ? Color(red: 0.28, green: 0.22, blue: 0.1) : Color(red: 1.0, green: 0.95, blue: 0.86)
    }

    var star: Color {
        isDark ? Color(red: 1.0, green: 0.78, blue: 0.35) : Color(red: 0.85, green: 0.55, blue: 0.1)
    }

    var emphasisFill: Color {
        Color(red: 1.0, green: 0.82, blue: 0.28).opacity(isDark ? 0.3 : 0.42)
    }

    var emphasisStroke: Color {
        isDark
            ? Color(red: 1.0, green: 0.72, blue: 0.25)
            : Color(red: 0.92, green: 0.55, blue: 0.08)
    }

    /// Background of a rarely used tonic row in the picker.
    var obscureRow: Color {
        isDark ? Color(white: 0.22) : Color(white: 0.91)
    }
}
