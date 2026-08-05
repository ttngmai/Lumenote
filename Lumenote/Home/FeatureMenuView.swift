//

import SwiftUI

/// Root feature list: Circle of Fifths and Interval explorer.
struct FeatureMenuView: View {
    @Environment(\.appPalette) private var palette
    @AppStorage(AppearanceMode.storageKey) private var appearance: AppearanceMode = .system

    private enum Destination: Hashable {
        case circleOfFifths
        case interval
    }

    var body: some View {
        List {
            NavigationLink(value: Destination.circleOfFifths) {
                featureRow(
                    title: "5도권",
                    subtitle: "조표 · 모드 · 스케일",
                    systemImage: "circle.circle"
                )
            }

            NavigationLink(value: Destination.interval) {
                featureRow(
                    title: "음정",
                    subtitle: "두 음 사이의 거리",
                    systemImage: "ruler"
                )
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(background)
        .lumenoteCompactHeader(title: "Lumenote") {
            AppearanceToggleButton(appearance: $appearance)
        }
        .navigationDestination(for: Destination.self) { destination in
            switch destination {
            case .circleOfFifths:
                CircleOfFifthsView()
            case .interval:
                IntervalView()
            }
        }
    }

    private func featureRow(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: LumenoteSpacing.xxl) {
            Image(systemName: systemImage)
                .font(LumenoteFont.rounded(size: 22, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: LumenoteSpacing.xxs) {
                Text(title)
                    .font(LumenoteFont.body(.bold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(LumenoteFont.caption(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, LumenoteSpacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)")
    }

    private var background: some View {
        LinearGradient(
            colors: palette.backgroundColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    NavigationStack {
        FeatureMenuView()
    }
    .lumenotePalette()
}
