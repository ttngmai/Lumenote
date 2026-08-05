//

import SwiftUI

/// Compact top chrome that replaces the system navigation bar.
struct CompactHeader<Trailing: View>: View {
    let title: String
    var showsBackButton: Bool = false
    @ViewBuilder var trailing: () -> Trailing

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appPalette) private var palette

    var body: some View {
        ZStack {
            Text(title)
                .font(LumenoteFont.headline(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: LumenoteSpacing.sm) {
                if showsBackButton {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(LumenoteFont.rounded(size: 15, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(width: 34, height: 34)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("뒤로")
                }

                Spacer(minLength: 0)

                trailing()
            }
        }
        .padding(.horizontal, LumenoteSpacing.lg)
        .padding(.vertical, LumenoteSpacing.xs)
        .frame(minHeight: 36)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(palette.divider)
                .frame(height: LumenoteStroke.hairline)
        }
    }
}

// MARK: - Modifier

private struct LumenoteCompactHeaderModifier<Trailing: View>: ViewModifier {
    let title: String
    let showsBackButton: Bool
    @ViewBuilder let trailing: () -> Trailing

    func body(content: Content) -> some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
            .safeAreaInset(edge: .top, spacing: 0) {
                CompactHeader(
                    title: title,
                    showsBackButton: showsBackButton,
                    trailing: trailing
                )
            }
    }
}

extension View {
    /// Hides the system navigation bar and pins a compact custom header.
    func lumenoteCompactHeader(
        title: String,
        showsBackButton: Bool = false
    ) -> some View {
        modifier(
            LumenoteCompactHeaderModifier(
                title: title,
                showsBackButton: showsBackButton,
                trailing: { EmptyView() }
            )
        )
    }

    /// Hides the system navigation bar and pins a compact custom header with trailing actions.
    func lumenoteCompactHeader<Trailing: View>(
        title: String,
        showsBackButton: Bool = false,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) -> some View {
        modifier(
            LumenoteCompactHeaderModifier(
                title: title,
                showsBackButton: showsBackButton,
                trailing: trailing
            )
        )
    }
}

#Preview {
    NavigationStack {
        Color.clear
            .lumenoteCompactHeader(title: "Lumenote") {
                AppearanceToggleButton(appearance: .constant(.system))
            }
            .background(
                LinearGradient(
                    colors: AppPalette(colorScheme: .light).backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
    }
    .lumenotePalette()
}
