//

import SwiftUI

struct IntervalView: View {
    @Environment(\.appPalette) private var palette
    @AppStorage(AppearanceMode.storageKey) private var appearance: AppearanceMode = .system
    @AppStorage(AccidentalPreference.storageKey) private var accidentalPreferenceRaw = AccidentalPreference.sharp.rawValue

    @State private var model = IntervalModel()
    @State private var showRootPicker = false
    @State private var showTargetPicker = false

    private var accidentalPreference: AccidentalPreference {
        AccidentalPreference(rawValue: accidentalPreferenceRaw) ?? .sharp
    }

    var body: some View {
        ScrollView {
            VStack(spacing: LumenoteSpacing.section) {
                headerLabels
                metricCards
                    .animation(.easeOut(duration: 0.2), value: model.semitoneDistance)
                IntervalRulerView(
                    semitoneDistance: $model.semitoneDistance,
                    targetOptions: model.targetOptions
                )
                .id("\(model.rootPitchClass)-\(accidentalPreferenceRaw)")
                .padding(.top, LumenoteSpacing.sm)
            }
            .padding(LumenoteSpacing.xxxl)
        }
        .scrollIndicators(.hidden)
        .background(background)
        .lumenoteCompactHeader(title: "음정", showsBackButton: true) {
            AppearanceToggleButton(appearance: $appearance)
        }
        .overlay {
            if showRootPicker {
                notePickerPopup(
                    title: "루트음",
                    options: model.rootOptions.map { (id: $0.pitchClass, label: $0.displayName) },
                    isSelected: { model.rootPitchClass == $0 },
                    onSelect: { model.rootPitchClass = $0 },
                    onDismiss: { showRootPicker = false }
                )
                .transition(.opacity)
            }
            if showTargetPicker {
                notePickerPopup(
                    title: "목표음",
                    options: model.targetOptions.map { (id: $0.distance, label: $0.displayName) },
                    isSelected: { model.semitoneDistance == $0 },
                    onSelect: { model.semitoneDistance = $0 },
                    onDismiss: { showTargetPicker = false }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.18), value: showRootPicker)
        .animation(.easeOut(duration: 0.18), value: showTargetPicker)
        .onAppear {
            model.accidentalPreference = accidentalPreference
        }
        .onChange(of: accidentalPreferenceRaw) { _, newValue in
            model.accidentalPreference = AccidentalPreference(rawValue: newValue) ?? .sharp
        }
    }

    // MARK: - Sections

    private var headerLabels: some View {
        HStack(alignment: .top, spacing: LumenoteSpacing.md) {
            Button {
                showRootPicker = true
            } label: {
                VStack(alignment: .leading, spacing: LumenoteSpacing.xxs) {
                    Text("루트음")
                        .font(LumenoteFont.caption2(.semibold))
                        .foregroundStyle(.secondary)
                    Text(model.rootDisplayName)
                        .font(LumenoteFont.rounded(size: 34, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("루트음 \(model.rootDisplayName)")
            .accessibilityHint("루트음을 변경하려면 두 번 탭하세요")

            intervalTitleCenter
                .frame(maxWidth: .infinity)
                .animation(.easeOut(duration: 0.2), value: model.semitoneDistance)
                .animation(.easeOut(duration: 0.2), value: accidentalPreferenceRaw)

            Button {
                showTargetPicker = true
            } label: {
                VStack(alignment: .trailing, spacing: LumenoteSpacing.xxs) {
                    Text("목표음")
                        .font(LumenoteFont.caption2(.semibold))
                        .foregroundStyle(.secondary)
                    Text(model.targetDisplayName)
                        .font(LumenoteFont.rounded(size: 34, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityLabel("목표음 \(model.targetDisplayName)")
            .accessibilityHint("목표음을 변경하려면 두 번 탭하세요")
        }
    }

    private var intervalTitleCenter: some View {
        VStack(spacing: LumenoteSpacing.xs) {
            Text(model.intervalNameEnglish)
                .font(LumenoteFont.rounded(size: 18, weight: .bold))
                .foregroundStyle(palette.minor)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .allowsTightening(true)
                .frame(maxWidth: .infinity)
                .frame(height: 22)

            Text(model.intervalName)
                .font(LumenoteFont.caption(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 16)

            AccidentalPreferenceToggle(
                preference: Binding(
                    get: { accidentalPreference },
                    set: { accidentalPreferenceRaw = $0.rawValue }
                )
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(model.intervalNameEnglish), \(model.intervalName)")
    }

    private var metricCards: some View {
        GeometryReader { geo in
            let cardWidth = max((geo.size.width - LumenoteSpacing.xl) / 2, 1)
            HStack(spacing: LumenoteSpacing.xl) {
                metricCard(
                    value: "\(model.semitoneDistance)",
                    korean: "반음",
                    english: "Semi-tones",
                    accent: palette.minor,
                    cardWidth: cardWidth
                )
                metricCard(
                    value: IntervalModel.formatWholeTones(model.wholeTones),
                    korean: "온음",
                    english: "Whole tones",
                    accent: palette.diminished,
                    cardWidth: cardWidth
                )
            }
        }
        .frame(height: 72)
    }

    private func metricCard(
        value: String,
        korean: String,
        english: String,
        accent: Color,
        cardWidth: CGFloat
    ) -> some View {
        let valueFontSize = metricValueFontSize(for: cardWidth, value: value)

        return HStack(spacing: LumenoteSpacing.md) {
            Text(value)
                .font(LumenoteFont.rounded(size: valueFontSize, weight: .bold))
                .foregroundStyle(accent)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .frame(minWidth: cardWidth * 0.28, alignment: .leading)

            VStack(alignment: .leading, spacing: 1) {
                Text(korean)
                    .font(LumenoteFont.callout(.bold))
                    .foregroundStyle(accent)
                    .lineLimit(1)
                Text(english)
                    .font(LumenoteFont.caption2(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, LumenoteSpacing.lg)
        .padding(.vertical, LumenoteSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(palette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: LumenoteRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LumenoteRadius.card, style: .continuous)
                .strokeBorder(palette.divider, lineWidth: LumenoteStroke.compact)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(korean)")
    }

    private func metricValueFontSize(for cardWidth: CGFloat, value: String) -> CGFloat {
        let base: CGFloat = 36
        let available = cardWidth * 0.42
        let estimated = available / max(CGFloat(value.count) * 0.58, 1)
        return min(base, max(22, estimated))
    }

    // MARK: - Note pickers

    private func notePickerPopup<ID: Hashable>(
        title: String,
        options: [(id: ID, label: String)],
        isSelected: @escaping (ID) -> Bool,
        onSelect: @escaping (ID) -> Void,
        onDismiss: @escaping () -> Void
    ) -> some View {
        ZStack {
            palette.scrim
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .font(LumenoteFont.headline(.bold))
                    Spacer()
                    Button(action: onDismiss) {
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
                    ForEach(options, id: \.id) { option in
                        let selected = isSelected(option.id)
                        Button {
                            onSelect(option.id)
                            onDismiss()
                        } label: {
                            Text(option.label)
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
                        .accessibilityLabel(option.label)
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
    }
    .lumenotePalette()
}
