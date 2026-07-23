//

import SwiftUI

struct CircleOfFifthsView: View {
    @State private var model = CircleOfFifthsModel()
    @State private var activePicker: ActivePicker?

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
                            selectors(stacked: true)
                        }
                        .frame(width: min(280, geo.size.width * 0.32))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            circleSection
                            selectors(stacked: false)
                        }
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
            colors: [
                Color(red: 0.97, green: 0.96, blue: 0.93),
                Color(red: 0.92, green: 0.94, blue: 0.96)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var circleSection: some View {
        VStack(spacing: 12) {
            CircleOfFifthsRingView(model: model)
                .frame(maxWidth: 520)
                .padding(.horizontal, 4)

            legend
        }
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(color: Color(red: 0xE9 / 255, green: 0x5D / 255, blue: 0x5D / 255), title: "Major")
            legendItem(color: Color(red: 0x4F / 255, green: 0x81 / 255, blue: 0xEE / 255), title: "Minor")
            legendItem(color: Color(red: 0x9A / 255, green: 0x64 / 255, blue: 0xDB / 255), title: "Dim")
            legendItem(color: Color(red: 0.86, green: 0.86, blue: 0.86), title: "Non-diatonic")
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

            scaleNotesTable
        }
        // Keep selector chrome height stable so the circle never jumps when a popup opens.
        .frame(maxWidth: .infinity)
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
                            .fill(Color.black.opacity(0.08))
                            .frame(width: 1)
                            .padding(.vertical, 4)
                    }

                    VStack(spacing: 6) {
                        Text(tone.degree)
                            .font(.system(.caption2, design: .rounded).weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(tone.note)
                            .font(.system(.body, design: .rounded).weight(index == 0 ? .bold : .semibold))
                            .foregroundStyle(.primary)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.75), lineWidth: 1.5)
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
            .background(Color.white.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isActive ? Color.black : Color.black.opacity(0.75), lineWidth: isActive ? 2.5 : 1.5)
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
            Color.black.opacity(0.28)
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
                .background(Color.black)
                .foregroundStyle(.white)

                popupList(for: picker)
            }
            .frame(maxWidth: 360)
            // Fixed popup height prevents the card (and surrounding layout) from resizing
            // as the list content or selection changes.
            .frame(height: 420)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.85), lineWidth: 2)
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
                                Text(row.label)
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                    .foregroundStyle(.primary)
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
            return Color(red: 1.0, green: 0.88, blue: 0.65)
        }
        if row.isObscure {
            return Color(red: 0.91, green: 0.91, blue: 0.91)
        }
        return Color.white
    }
}

private struct SelectionRow: Identifiable {
    let id: String
    let label: String
    let isObscure: Bool
    let isSelected: Bool
    let action: () -> Void
}

#Preview {
    CircleOfFifthsView()
}
