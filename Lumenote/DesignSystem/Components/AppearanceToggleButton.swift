//

import SwiftUI

/// Compact circular control that toggles between light and dark appearance.
struct AppearanceToggleButton: View {
    @Binding var appearance: AppearanceMode

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        Button {
            appearance = isDark ? .light : .dark
        } label: {
            Image(systemName: isDark ? "sun.max.fill" : "moon.fill")
                .font(LumenoteFont.rounded(size: 15, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(palette.cardBackground))
                .overlay(Circle().strokeBorder(palette.cardBorder, lineWidth: LumenoteStroke.compact))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isDark ? "라이트 모드로 전환" : "다크 모드로 전환")
    }
}
