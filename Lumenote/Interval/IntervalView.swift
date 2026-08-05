//

import SwiftUI

struct IntervalView: View {
    @Environment(\.appPalette) private var palette
    @AppStorage(AppearanceMode.storageKey) private var appearance: AppearanceMode = .system

    @State private var model = IntervalModel()
    @State private var showRootPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: LumenoteSpacing.section) {
                headerLabels
                rulerCard
                infoCard
                rootSelector
            }
            .padding(LumenoteSpacing.xxxl)
        }
        .scrollIndicators(.hidden)
        .background(background)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                AppearanceToggleButton(appearance: $appearance)
            }
        }
        .overlay {
            if showRootPicker {
                rootPickerPopup
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.18), value: showRootPicker)
    }

    // MARK: - Sections

    private var headerLabels: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: LumenoteSpacing.xxs) {
                Text("루트")
                    .font(LumenoteFont.caption2(.semibold))
                    .foregroundStyle(.secondary)
                Text(model.rootDisplayName)
                    .font(LumenoteFont.rounded(size: 28, weight: .bold))
                    .foregroundStyle(.primary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: LumenoteSpacing.xxs) {
                Text("목표음")
                    .font(LumenoteFont.caption2(.semibold))
                    .foregroundStyle(.secondary)
                Text(model.targetDisplayName)
                    .font(LumenoteFont.rounded(size: 28, weight: .bold))
                    .foregroundStyle(.primary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("루트 \(model.rootDisplayName), 목표음 \(model.targetDisplayName)")
    }

    private var rulerCard: some View {
        VStack(alignment: .leading, spacing: LumenoteSpacing.lg) {
            Text("거리")
                .font(LumenoteFont.caption(.bold))
                .foregroundStyle(.secondary)

            IntervalRulerView(semitoneDistance: $model.semitoneDistance)
                .padding(.trailing, 8)
        }
        .padding(.horizontal, LumenoteSpacing.xxl)
        .padding(.vertical, LumenoteSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lumenoteCard()
    }

    private var infoCard: some View {
        VStack(spacing: LumenoteSpacing.md) {
            Text(model.intervalName)
                .font(LumenoteFont.rounded(size: 32, weight: .bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            Text(model.distanceDescription)
                .font(LumenoteFont.callout(.semibold))
                .foregroundStyle(.secondary)

            Text("\(model.rootDisplayName) → \(model.targetDisplayName)")
                .font(LumenoteFont.caption(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, LumenoteSpacing.xxl)
        .padding(.vertical, LumenoteSpacing.xxxl)
        .frame(maxWidth: .infinity)
        .lumenoteCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(model.intervalName), \(model.distanceDescription)")
    }

    private var rootSelector: some View {
        Button {
            showRootPicker = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: LumenoteSpacing.xxs) {
                    Text("루트")
                        .font(LumenoteFont.caption2(.semibold))
                        .foregroundStyle(.secondary)
                    Text(model.rootDisplayName)
                        .font(LumenoteFont.headline(.bold))
                        .foregroundStyle(.primary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.up.chevron.down")
                    .font(LumenoteFont.caption(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, LumenoteSpacing.xxl)
            .padding(.vertical, LumenoteSpacing.xl)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .lumenoteCard(isActive: showRootPicker)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("루트 \(model.rootDisplayName)")
        .accessibilityHint("루트를 변경하려면 두 번 탭하세요")
    }

    // MARK: - Root picker

    private var rootPickerPopup: some View {
        ZStack {
            palette.scrim
                .ignoresSafeArea()
                .onTapGesture { showRootPicker = false }

            VStack(spacing: 0) {
                HStack {
                    Text("루트")
                        .font(LumenoteFont.headline(.bold))
                    Spacer()
                    Button {
                        showRootPicker = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(LumenoteFont.rounded(size: 22, weight: .regular))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("닫기")
                }
                .padding(.horizontal, LumenoteSpacing.xxxl)
                .padding(.vertical, LumenoteSpacing.xxl)
                .background(palette.popupHeaderBackground)
                .foregroundStyle(palette.popupHeaderForeground)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: LumenoteSpacing.md), count: 4),
                    spacing: LumenoteSpacing.md
                ) {
                    ForEach(IntervalModel.rootOptions, id: \.pitchClass) { option in
                        let selected = model.rootPitchClass == option.pitchClass
                        Button {
                            model.rootPitchClass = option.pitchClass
                            showRootPicker = false
                        } label: {
                            Text(option.displayName)
                                .font(LumenoteFont.body(selected ? .bold : .semibold))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, LumenoteSpacing.xl)
                                .background(
                                    RoundedRectangle(cornerRadius: LumenoteRadius.chip, style: .continuous)
                                        .fill(selected ? palette.highlight : palette.popupBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: LumenoteRadius.chip, style: .continuous)
                                        .strokeBorder(
                                            selected ? palette.cardBorderActive : palette.divider,
                                            lineWidth: selected ? LumenoteStroke.compact : LumenoteStroke.hairline
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.displayName)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
                .padding(LumenoteSpacing.xxxl)
            }
            .frame(maxWidth: 360)
            .lumenotePopup()
            .padding(.horizontal, LumenoteSpacing.popupInset)
        }
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
        IntervalView()
            .navigationTitle("음정")
    }
    .lumenotePalette()
}
