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
