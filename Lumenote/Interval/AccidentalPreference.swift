//

import Foundation

/// Whether chromatic spellings prefer sharps (♯) or flats (♭).
enum AccidentalPreference: String, CaseIterable, Identifiable {
    case sharp
    case flat

    static let storageKey = "intervalAccidentalPreference"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .sharp: return "♯"
        case .flat: return "♭"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .sharp: return "샵 표기"
        case .flat: return "플랫 표기"
        }
    }
}
