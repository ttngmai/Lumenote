//

import SwiftUI

/// Standard translucent card chrome: background, continuous clip, border.
struct LumenoteCardStyle: ViewModifier {
    var isActive: Bool = false

    @Environment(\.appPalette) private var palette

    func body(content: Content) -> some View {
        content
            .background(palette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: LumenoteRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LumenoteRadius.card, style: .continuous)
                    .strokeBorder(
                        isActive ? palette.cardBorderActive : palette.cardBorder,
                        lineWidth: isActive ? LumenoteStroke.emphasis : LumenoteStroke.card
                    )
            )
    }
}

/// Selection popup chrome: opaque fill, larger radius, thicker border, shadow.
struct LumenotePopupStyle: ViewModifier {
    @Environment(\.appPalette) private var palette

    func body(content: Content) -> some View {
        content
            .background(palette.popupBackground)
            .clipShape(RoundedRectangle(cornerRadius: LumenoteRadius.popup, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LumenoteRadius.popup, style: .continuous)
                    .strokeBorder(palette.cardBorder, lineWidth: LumenoteStroke.popup)
            )
            .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
    }
}

extension View {
    func lumenoteCard(isActive: Bool = false) -> some View {
        modifier(LumenoteCardStyle(isActive: isActive))
    }

    func lumenotePopup() -> some View {
        modifier(LumenotePopupStyle())
    }
}
