//

import SwiftUI

/// Small colored swatch used in legends.
struct LegendSwatch: View {
    let color: Color
    let title: String

    var body: some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: LumenoteRadius.legendSwatch, style: .continuous)
                .fill(color)
                .frame(width: LumenoteSpacing.xl, height: LumenoteSpacing.xl)
                .overlay(
                    RoundedRectangle(cornerRadius: LumenoteRadius.legendSwatch, style: .continuous)
                        .stroke(Color.primary.opacity(0.2), lineWidth: LumenoteStroke.hairline)
                )
            Text(title)
                .foregroundStyle(.secondary)
        }
    }
}

/// Amber chip fill behind highlighted formula / scale cells.
struct HighlightChipBackground: View {
    var isLit: Bool
    var cornerRadius: CGFloat = LumenoteRadius.chip

    @Environment(\.appPalette) private var palette

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(isLit ? palette.highlight : Color.clear)
    }
}
