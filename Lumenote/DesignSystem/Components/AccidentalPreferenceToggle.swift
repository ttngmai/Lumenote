//

import SwiftUI

/// Segmented ♯ / ♭ control for chromatic spelling preference.
struct AccidentalPreferenceToggle: View {
    @Binding var preference: AccidentalPreference

    @Environment(\.appPalette) private var palette

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AccidentalPreference.allCases) { option in
                let selected = preference == option
                Button {
                    preference = option
                } label: {
                    Text(option.symbol)
                        .font(LumenoteFont.rounded(size: 14, weight: .bold))
                        .foregroundStyle(selected ? Color.white : Color.secondary)
                        .frame(width: 30, height: 26)
                        .background(
                            RoundedRectangle(cornerRadius: LumenoteRadius.chip, style: .continuous)
                                .fill(selected ? palette.minor : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.accessibilityLabel)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: LumenoteRadius.softRow, style: .continuous)
                .fill(palette.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LumenoteRadius.softRow, style: .continuous)
                .strokeBorder(palette.divider, lineWidth: LumenoteStroke.hairline)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("임시표 표기")
    }
}
