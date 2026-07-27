//

import SwiftUI

struct CircleOfFifthsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(AppearanceMode.storageKey) private var appearance: AppearanceMode = .system

    @State private var model = CircleOfFifthsModel()
    @State private var activePicker: ActivePicker?
    @State private var emphasisClearToken = UUID()

    private var palette: AppPalette { AppPalette(colorScheme: colorScheme) }

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
                    HStack(alignment: .top, spacing: 20) {
                        circleSection
                        ScrollView {
                            VStack(spacing: 12) {
                                HStack {
                                    Spacer(minLength: 0)
                                    appearanceToggle
                                }
                                selectors(stacked: true)
                            }
                        }
                        .scrollIndicators(.hidden)
                        .frame(width: min(280, geo.size.width * 0.32))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            circleSection
                            selectors(stacked: false)
                        }
                    }
                    .scrollIndicators(.hidden)
                    // Sits in the empty corner beside the circle, so it costs no layout height.
                    .overlay(alignment: .topTrailing) {
                        appearanceToggle
                    }
                }
            }
            .padding(16)
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

    private var appearanceToggle: some View {
        let isDark = colorScheme == .dark
        return Button {
            appearance = isDark ? .light : .dark
        } label: {
            Image(systemName: isDark ? "sun.max.fill" : "moon.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(palette.cardBackground))
                .overlay(Circle().strokeBorder(palette.cardBorder, lineWidth: 1.2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isDark ? "라이트 모드로 전환" : "다크 모드로 전환")
    }

    private var circleSection: some View {
        VStack(spacing: 2) {
            CircleOfFifthsRingView(model: model)
                .frame(maxWidth: 520)
                .padding(.horizontal, 4)

            legend
        }
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(color: palette.major, title: "Major")
            legendItem(color: palette.minor, title: "Minor")
            legendItem(color: palette.diminished, title: "Dim")
            legendItem(color: palette.chromaticFill, title: "Non-diatonic")
        }
        .font(.system(.caption2, design: .rounded).weight(.semibold))
    }

    private func legendItem(color: Color, title: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color)
                .frame(width: 12, height: 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 0.5)
                )
            Text(title)
                .foregroundStyle(.secondary)
        }
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
        VStack(spacing: 12) {
            Group {
                if stacked {
                    VStack(spacing: 12) {
                        tonicButton
                        modeButton
                    }
                } else {
                    HStack(spacing: 12) {
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

        return VStack(alignment: .leading, spacing: 10) {
            Text("Mode Character")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(.secondary)

            Text(character.summary)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                Text("Formula")
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 2) {
                    ForEach(Array(character.formula.enumerated()), id: \.element.id) { index, tone in
                        if index > 0 {
                            Text("·")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundStyle(.secondary.opacity(0.5))
                        }

                        let isLit = model.emphasizedScaleDegrees.contains(tone.scaleDegree)
                            || (model.emphasizedScaleDegrees.isEmpty && tone.isEmphasized)

                        Button {
                            flashEmphasis(scaleDegrees: [tone.scaleDegree])
                        } label: {
                            Text(tone.symbol)
                                .font(.system(.callout, design: .rounded).weight(isLit ? .bold : .semibold))
                                .foregroundStyle(isLit ? Color.primary : Color.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(isLit ? palette.highlight : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            if character.characteristicNote != nil || character.characteristicChord != nil {
                VStack(alignment: .leading, spacing: 6) {
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
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(palette.cardBorder, lineWidth: 1.5)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("모드 캐릭터, \(character.summary)")
    }

    private func characteristicRow(
        symbol: String,
        text: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(symbol)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(palette.star)
                Text(text)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
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
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 10)

            HStack(spacing: 0) {
                ForEach(Array(model.scaleTones.enumerated()), id: \.element.id) { index, tone in
                    if index > 0 {
                        Rectangle()
                            .fill(palette.divider)
                            .frame(width: 1)
                            .padding(.vertical, 4)
                    }

                    let isLit = model.emphasizedScaleDegrees.contains(tone.scaleDegree)

                    VStack(spacing: 6) {
                        Text(tone.degree)
                            .font(.system(.caption2, design: .rounded).weight(.semibold))
                            .foregroundStyle(isLit ? Color.primary : .secondary)
                        Text(tone.note)
                            .font(.system(.body, design: .rounded).weight(index == 0 || isLit ? .bold : .semibold))
                            .foregroundStyle(.primary)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(isLit ? palette.highlight : Color.clear)
                    )
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(palette.cardBorder, lineWidth: 1.5)
        )
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
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isActive ? 180 : 0))
                }

                Text(value)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background(palette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isActive ? palette.cardBorderActive : palette.cardBorder,
                        lineWidth: isActive ? 2.5 : 1.5
                    )
            )
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
                        .font(.system(.headline, design: .rounded).weight(.bold))
                    Spacer()
                    Button(action: dismissPicker) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("닫기")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(palette.popupHeaderBackground)
                .foregroundStyle(palette.popupHeaderForeground)

                popupList(for: picker)
            }
            .frame(maxWidth: 360)
            // Fixed popup height prevents the card (and surrounding layout) from resizing
            // as the list content or selection changes.
            .frame(height: 420)
            .background(palette.popupBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(palette.cardBorder, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
            .padding(.horizontal, 28)
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
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(row.label)
                                        .font(.system(.body, design: .rounded).weight(.semibold))
                                        .foregroundStyle(.primary)
                                    if let subtitle = row.subtitle {
                                        Text(subtitle)
                                            .font(.system(.caption, design: .rounded).weight(.medium))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer(minLength: 0)
                                if row.isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.primary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
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
}
