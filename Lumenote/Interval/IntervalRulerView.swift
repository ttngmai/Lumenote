//

import SwiftUI
import UIKit

/// One-octave chromatic ruler with horizontally scrollable columns on narrow screens.
/// Expands to fill available width on iPad / landscape when space allows.
/// Each semitone column shows ticks, labels, and a target-note button.
struct IntervalRulerView: View {
    @Binding var semitoneDistance: Int
    let targetOptions: [(distance: Int, displayName: String)]

    @Environment(\.appPalette) private var palette

    private let maxSemitones = 12
    private let minColumnWidth: CGFloat = 44
    private let trackHeight: CGFloat = 8
    private let pinSize: CGFloat = 16

    @State private var scrollPosition: Int?

    var body: some View {
        GeometryReader { geo in
            let horizontalPadding = LumenoteSpacing.xs * 2
            let availableWidth = max(geo.size.width - horizontalPadding, 1)
            let columnWidth = max(
                minColumnWidth,
                availableWidth / CGFloat(maxSemitones + 1)
            )
            let contentWidth = columnWidth * CGFloat(maxSemitones + 1)
            let fitsInScreen = contentWidth <= availableWidth + 0.5

            ScrollView(.horizontal, showsIndicators: false) {
                rulerContent(columnWidth: columnWidth)
                    .frame(width: contentWidth, alignment: .leading)
                    .padding(.horizontal, LumenoteSpacing.xs)
            }
            .scrollDisabled(fitsInScreen)
            .scrollPosition(id: $scrollPosition, anchor: .center)
        }
        .frame(height: rulerHeight)
        .onAppear {
            if scrollPosition == nil {
                scrollPosition = semitoneDistance
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("음정 자")
    }

    private func rulerContent(columnWidth: CGFloat) -> some View {
        let trackWidth = columnWidth * CGFloat(maxSemitones)
        let leadingInset = columnWidth / 2
        let trackY = trackCenterY

        return ZStack(alignment: .topLeading) {
            // Dim full track
            Capsule()
                .fill(palette.divider)
                .frame(width: trackWidth, height: trackHeight)
                .offset(x: leadingInset, y: trackY - trackHeight / 2)

            // Selected span — blue → purple
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [palette.minor, palette.diminished],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(
                    width: max(columnWidth * CGFloat(semitoneDistance), 0),
                    height: trackHeight
                )
                .offset(x: leadingInset, y: trackY - trackHeight / 2)
                .animation(.easeOut(duration: 0.2), value: semitoneDistance)

            ticks(columnWidth: columnWidth, leadingInset: leadingInset)

            // Root pin (blue, fixed at 0)
            pin(color: palette.minor)
                .offset(
                    x: leadingInset - pinSize / 2,
                    y: trackY - pinSize - 2
                )

            // Target pin (purple)
            pin(color: palette.diminished)
                .offset(
                    x: leadingInset + columnWidth * CGFloat(semitoneDistance) - pinSize / 2,
                    y: trackY - pinSize - 2
                )
                .animation(.easeOut(duration: 0.2), value: semitoneDistance)

            noteButtons(columnWidth: columnWidth, leadingInset: leadingInset)

            // Drag only on the track band to avoid fighting horizontal scroll.
            Color.clear
                .frame(width: trackWidth, height: 36)
                .offset(x: leadingInset, y: trackY - 18)
                .contentShape(Rectangle())
                .gesture(
                    dragGesture(
                        columnWidth: columnWidth,
                        trackWidth: trackWidth
                    )
                )
        }
        .frame(height: rulerHeight, alignment: .topLeading)
    }

    private var trackCenterY: CGFloat { 42 }
    private var rulerHeight: CGFloat { 138 }

    private func ticks(columnWidth: CGFloat, leadingInset: CGFloat) -> some View {
        ForEach(0...maxSemitones, id: \.self) { i in
            let x = leadingInset + columnWidth * CGFloat(i)
            let isWhole = i % 2 == 0
            let inRange = i <= semitoneDistance
            let isSelectedTick = i == semitoneDistance
            let tickHeight: CGFloat = isWhole ? 18 : 12

            Capsule()
                .fill(inRange ? Color.secondary.opacity(0.55) : Color.secondary.opacity(0.25))
                .frame(width: isWhole ? 1.5 : 1, height: tickHeight)
                .offset(x: x - (isWhole ? 0.75 : 0.5), y: trackCenterY - tickHeight / 2)

            // Semitone label (above)
            Text("\(i)")
                .font(LumenoteFont.caption2(isSelectedTick ? .bold : .medium))
                .foregroundStyle(
                    isSelectedTick
                        ? palette.minor
                        : (inRange ? Color.secondary : Color.secondary.opacity(0.35))
                )
                .position(x: x, y: trackCenterY - 26)

            // Whole-tone label (below)
            Text(IntervalModel.formatWholeTones(Double(i) / 2.0))
                .font(LumenoteFont.caption2(isSelectedTick ? .bold : .semibold))
                .foregroundStyle(
                    isSelectedTick
                        ? palette.diminished
                        : (inRange ? Color.primary.opacity(0.75) : Color.secondary.opacity(0.4))
                )
                .position(x: x, y: trackCenterY + 24)
        }
    }

    private func noteButtons(columnWidth: CGFloat, leadingInset: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(targetOptions, id: \.distance) { option in
                let selected = semitoneDistance == option.distance
                Button {
                    semitoneDistance = option.distance
                } label: {
                    Text(option.displayName)
                        .font(LumenoteFont.caption2(selected ? .bold : .semibold))
                        .foregroundStyle(selected ? palette.emphasisStroke : Color.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: columnWidth, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: LumenoteRadius.softRow, style: .continuous)
                                .fill(selected ? palette.highlight : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: LumenoteRadius.softRow, style: .continuous)
                                .strokeBorder(
                                    selected ? palette.emphasisStroke.opacity(0.55) : Color.clear,
                                    lineWidth: LumenoteStroke.hairline
                                )
                        )
                }
                .buttonStyle(.plain)
                .id(option.distance)
                .accessibilityLabel(option.displayName)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .offset(x: leadingInset - columnWidth / 2, y: trackCenterY + 40)
    }

    private func pin(color: Color) -> some View {
        IntervalPinShape()
            .fill(color)
            .overlay(
                IntervalPinShape()
                    .strokeBorder(Color.white.opacity(0.9), lineWidth: 1.5)
            )
            .frame(width: pinSize, height: pinSize + 4)
            .shadow(color: .black.opacity(0.16), radius: 2, y: 1)
    }

    private func dragGesture(
        columnWidth: CGFloat,
        trackWidth: CGFloat
    ) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let x = min(max(value.location.x, 0), trackWidth)
                let raw = Int((x / columnWidth).rounded())
                updateDistance(raw)
            }
    }

    private func updateDistance(_ newValue: Int) {
        let clamped = IntervalModel.clampDistance(newValue)
        guard clamped != semitoneDistance else { return }
        semitoneDistance = clamped
        triggerHaptic(for: clamped)
    }

    private func triggerHaptic(for distance: Int) {
        let style: UIImpactFeedbackGenerator.FeedbackStyle =
            (distance == 5 || distance == 7 || distance == 12) ? .medium : .light
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred(intensity: style == .medium ? 0.9 : 0.6)
    }
}

/// Map-pin / teardrop shape pointing downward onto the track.
private struct IntervalPinShape: Shape, InsettableShape {
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let radius = min(r.width, r.height * 0.72) / 2
        let center = CGPoint(x: r.midX, y: r.minY + radius)
        let tip = CGPoint(x: r.midX, y: r.maxY)

        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(150),
            endAngle: .degrees(30),
            clockwise: true
        )
        path.addLine(to: tip)
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> IntervalPinShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

#Preview {
    @Previewable @State var distance = 4
    let options = (0...12).map { ($0, "C") }
    IntervalRulerView(semitoneDistance: $distance, targetOptions: options)
        .padding()
        .lumenotePalette()
}
