//

import SwiftUI

struct CircleOfFifthsView: View {
    @Environment(\.appPalette) private var palette
    @AppStorage(AppearanceMode.storageKey) private var appearance: AppearanceMode = .system

    @State private var model = CircleOfFifthsModel()
    @State private var activePicker: ActivePicker?
    @State private var emphasisClearToken = UUID()

    private enum ActivePicker: Identifiable, Equatable {
        case tonic
        case mode

        var id: String {
            switch self {
            case .tonic: return "tonic"
            case .mode: return "mode"
            }
        }

        var title: String {
            switch self {
            case .tonic: return "Tonic"
            case .mode: return "Mode"
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            let isWide = geo.size.width > geo.size.height * 0.9

            Group {
                if isWide {
                    HStack(alignment: .top, spacing: LumenoteSpacing.section) {
                        circleSection
                        ScrollView {
                            VStack(spacing: LumenoteSpacing.xl) {
                                HStack {
                                    Spacer(minLength: 0)
                                    AppearanceToggleButton(appearance: $appearance)
                                }
                                selectors(stacked: true)
                            }
                        }
                        .scrollIndicators(.hidden)
                        .frame(width: min(280, geo.size.width * 0.32))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: LumenoteSpacing.xxxl) {
                            circleSection
                            selectors(stacked: false)
                        }
                    }
                    .scrollIndicators(.hidden)
                    // Sits in the empty corner beside the circle, so it costs no layout height.
                    .overlay(alignment: .topTrailing) {
                        AppearanceToggleButton(appearance: $appearance)
                    }
                }
            }
            .padding(LumenoteSpacing.xxxl)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .background(background)
        // Overlay sits above the whole screen so opening it never reflows the circle layout.
        .overlay {
            if let activePicker {
                selectionPopup(for: activePicker)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.18), value: activePicker)
    }

    private var background: some View {
        LinearGradient(
            colors: palette.backgroundColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var circleSection: some View {
        VStack(spacing: LumenoteSpacing.xxs) {
            CircleOfFifthsRingView(model: model)
                .frame(maxWidth: 520)
                .padding(.horizontal, LumenoteSpacing.xs)

            legend
        }
    }

    private var legend: some View {
        HStack(spacing: LumenoteSpacing.xxl) {
            LegendSwatch(color: palette.major, title: "Major")
            LegendSwatch(color: palette.minor, title: "Minor")
            LegendSwatch(color: palette.diminished, title: "Dim")
            LegendSwatch(color: palette.chromaticFill, title: "Non-diatonic")
        }
        .font(LumenoteFont.caption2(.semibold))
    }

    @ViewBuilder
    private func selectors(stacked: Bool) -> some View {
        let tonicButton = pickerButton(
            title: "Tonic",
            value: model.selectedTonic.displayName,
            isActive: activePicker == .tonic
        ) {
            togglePicker(.tonic)
        }

        let modeButton = pickerButton(
            title: "Mode",
            value: model.selectedMode.displayName,
            isActive: activePicker == .mode
        ) {
            togglePicker(.mode)
        }

        // Landscape: one selector per row. Portrait: side by side.
        // Scale table sits under Tonic / Mode in both layouts.
        VStack(spacing: LumenoteSpacing.xl) {
            Group {
                if stacked {
                    VStack(spacing: LumenoteSpacing.xl) {
                        tonicButton
                        modeButton
                    }
                } else {
                    HStack(spacing: LumenoteSpacing.xl) {
                        tonicButton
                        modeButton
                    }
                }
            }

            modeCharacterCard
            scaleNotesTable
        }
        // Keep selector chrome height stable so the circle never jumps when a popup opens.
        .frame(maxWidth: .infinity)
        .onChange(of: model.selectedTonic) { _, _ in
            model.clearEmphasis()
        }
        .onChange(of: model.selectedMode) { _, _ in
            model.clearEmphasis()
        }
    }

    private var modeCharacterCard: some View {
        let character = model.modeCharacter

        return VStack(alignment: .leading, spacing: LumenoteSpacing.lg) {
            Text("Mode Character")
                .font(LumenoteFont.caption(.bold))
                .foregroundStyle(.secondary)

            Text(character.summary)
                .font(LumenoteFont.body(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: LumenoteSpacing.sm) {
                Text("Formula")
                    .font(LumenoteFont.caption2(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: LumenoteSpacing.xxs) {
                    ForEach(Array(character.formula.enumerated()), id: \.element.id) { index, tone in
                        if index > 0 {
                            Text("·")
                                .font(LumenoteFont.caption(.semibold))
                                .foregroundStyle(.secondary.opacity(0.5))
                        }

                        let isLit = model.emphasizedScaleDegrees.contains(tone.scaleDegree)
                            || (model.emphasizedScaleDegrees.isEmpty && tone.isEmphasized)

                        Button {
                            flashEmphasis(scaleDegrees: [tone.scaleDegree])
                        } label: {
                            Text(tone.symbol)
                                .font(LumenoteFont.callout(isLit ? .bold : .semibold))
                                .foregroundStyle(isLit ? Color.primary : Color.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, LumenoteSpacing.xs)
                                .background(HighlightChipBackground(isLit: isLit))
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            if character.characteristicNote != nil || character.characteristicChord != nil {
                VStack(alignment: .leading, spacing: LumenoteSpacing.sm) {
                    if let note = character.characteristicNote {
                        characteristicRow(symbol: "★", text: note.text) {
                            flashEmphasis(
                                scaleDegree: note.scaleDegree,
                                clockPosition: note.clockPosition
                            )
                        }
                    }
                    if let chord = character.characteristicChord {
                        characteristicRow(symbol: "★", text: chord.text) {
                            flashEmphasis(
                                scaleDegree: chord.scaleDegree,
                                clockPosition: chord.clockPosition
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, LumenoteSpacing.xxl)
        .padding(.vertical, LumenoteSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lumenoteCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("모드 캐릭터, \(character.summary)")
    }

    private func characteristicRow(
        symbol: String,
        text: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: LumenoteSpacing.sm) {
                Text(symbol)
                    .font(LumenoteFont.subheadline(.bold))
                    .foregroundStyle(palette.star)
                Text(text)
                    .font(LumenoteFont.subheadline(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, LumenoteSpacing.md)
            .padding(.vertical, LumenoteSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: LumenoteRadius.softRow, style: .continuous)
                    .fill(palette.highlightSoft)
            )
        }
        .buttonStyle(.plain)
    }

    private func flashEmphasis(scaleDegree: Int, clockPosition: Int) {
        model.emphasize(scaleDegree: scaleDegree, clockPosition: clockPosition)
        scheduleEmphasisClear()
    }

    private func flashEmphasis(scaleDegrees: [Int]) {
        model.emphasize(scaleDegrees: Set(scaleDegrees))
        scheduleEmphasisClear()
    }

    private func scheduleEmphasisClear() {
        let token = UUID()
        emphasisClearToken = token
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1200))
            guard emphasisClearToken == token else { return }
            model.clearEmphasis()
        }
    }

    private var scaleNotesTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Scale")
                .font(LumenoteFont.caption(.bold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, LumenoteSpacing.xxl)
                .padding(.top, LumenoteSpacing.xl)
                .padding(.bottom, LumenoteSpacing.lg)

            HStack(spacing: 0) {
                ForEach(Array(model.scaleTones.enumerated()), id: \.element.id) { index, tone in
                    if index > 0 {
                        Rectangle()
                            .fill(palette.divider)
                            .frame(width: 1)
                            .padding(.vertical, LumenoteSpacing.xs)
                    }

                    let isLit = model.emphasizedScaleDegrees.contains(tone.scaleDegree)

                    VStack(spacing: LumenoteSpacing.sm) {
                        Text(tone.degree)
                            .font(LumenoteFont.caption2(.semibold))
                            .foregroundStyle(isLit ? Color.primary : .secondary)
                        Text(tone.note)
                            .font(LumenoteFont.body(index == 0 || isLit ? .bold : .semibold))
                            .foregroundStyle(.primary)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LumenoteSpacing.xs)
                    .background(
                        HighlightChipBackground(
                            isLit: isLit,
                            cornerRadius: LumenoteRadius.scaleCell
                        )
                    )
                }
            }
            .padding(.horizontal, LumenoteSpacing.lg)
            .padding(.bottom, LumenoteSpacing.xl)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lumenoteCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("스케일 구성음")
    }

    private func pickerButton(
        title: String,
        value: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: LumenoteSpacing.xs) {
                HStack(spacing: LumenoteSpacing.xs) {
                    Text(title)
                        .font(LumenoteFont.caption(.bold))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(LumenoteFont.rounded(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isActive ? 180 : 0))
                }

                Text(value)
                    .font(LumenoteFont.body(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, LumenoteSpacing.xxl)
            .padding(.vertical, LumenoteSpacing.xl)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .lumenoteCard(isActive: isActive)
        }
        .buttonStyle(.plain)
    }

    private func togglePicker(_ picker: ActivePicker) {
        if activePicker == picker {
            activePicker = nil
        } else {
            activePicker = picker
        }
    }

    private func dismissPicker() {
        activePicker = nil
    }

    @ViewBuilder
    private func selectionPopup(for picker: ActivePicker) -> some View {
        ZStack {
            palette.scrim
                .ignoresSafeArea()
                .onTapGesture(perform: dismissPicker)

            VStack(spacing: 0) {
                HStack {
                    Text(picker.title)
                        .font(LumenoteFont.headline(.bold))
                    Spacer()
                    Button(action: dismissPicker) {
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

                popupList(for: picker)
            }
            .frame(maxWidth: 360)
            // Fixed popup height prevents the card (and surrounding layout) from resizing
            // as the list content or selection changes.
            .frame(height: 420)
            .lumenotePopup()
            .padding(.horizontal, LumenoteSpacing.popupInset)
        }
    }

    @ViewBuilder
    private func popupList(for picker: ActivePicker) -> some View {
        switch picker {
        case .tonic:
            optionList(
                rows: CircleOfFifthsModel.Tonic.allCases.map { tonic in
                    SelectionRow(
                        id: tonic.rawValue,
                        label: tonic.displayName,
                        subtitle: nil,
                        isObscure: tonic.isObscure,
                        isSelected: model.selectedTonic == tonic
                    ) {
                        model.selectedTonic = tonic
                        dismissPicker()
                    }
                }
            )
        case .mode:
            optionList(
                rows: CircleOfFifthsModel.MusicalMode.allCases.map { mode in
                    SelectionRow(
                        id: mode.rawValue,
                        label: mode.displayName,
                        subtitle: mode.characterSummary,
                        isObscure: false,
                        isSelected: model.selectedMode == mode
                    ) {
                        model.selectedMode = mode
                        dismissPicker()
                    }
                }
            )
        }
    }

    private func optionList(rows: [SelectionRow]) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(rows) { row in
                        Button {
                            row.action()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: LumenoteSpacing.xxs) {
                                    Text(row.label)
                                        .font(LumenoteFont.body(.semibold))
                                        .foregroundStyle(.primary)
                                    if let subtitle = row.subtitle {
                                        Text(subtitle)
                                            .font(LumenoteFont.caption(.medium))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer(minLength: 0)
                                if row.isSelected {
                                    Image(systemName: "checkmark")
                                        .font(LumenoteFont.rounded(size: 14, weight: .bold))
                                        .foregroundStyle(.primary)
                                }
                            }
                            .padding(.horizontal, LumenoteSpacing.xxxl)
                            .padding(.vertical, LumenoteSpacing.xl)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(rowBackground(row))
                        }
                        .buttonStyle(.plain)
                        .id(row.id)
                    }
                }
            }
            .onAppear {
                scrollToSelected(in: rows, proxy: proxy, animated: false)
            }
            .onChange(of: rows.first(where: \.isSelected)?.id) { _, newValue in
                guard let newValue else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    private func scrollToSelected(
        in rows: [SelectionRow],
        proxy: ScrollViewProxy,
        animated: Bool
    ) {
        guard let selected = rows.first(where: \.isSelected) else { return }
        if animated {
            withAnimation(.easeInOut(duration: 0.2)) {
                proxy.scrollTo(selected.id, anchor: .center)
            }
        } else {
            // Defer one run-loop turn so LazyVStack has measured the selected row.
            DispatchQueue.main.async {
                proxy.scrollTo(selected.id, anchor: .center)
            }
        }
    }

    private func rowBackground(_ row: SelectionRow) -> Color {
        if row.isSelected {
            return palette.highlight
        }
        if row.isObscure {
            return palette.obscureRow
        }
        return palette.popupBackground
    }
}

private struct SelectionRow: Identifiable {
    let id: String
    let label: String
    let subtitle: String?
    let isObscure: Bool
    let isSelected: Bool
    let action: () -> Void
}

#Preview {
    CircleOfFifthsView()
        .lumenotePalette()
}
