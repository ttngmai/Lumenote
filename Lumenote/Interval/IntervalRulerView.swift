//

import SwiftUI
import UIKit

/// One-octave chromatic ruler: thick ticks = whole tones, thin = semitones.
/// Drag the target marker to change semitone distance; labels show both units.
struct IntervalRulerView: View {
    @Binding var semitoneDistance: Int
    @Environment(\.appPalette) private var palette

    private let maxSemitones = 12
    private let unitLabelWidth: CGFloat = 36

    var body: some View {
        GeometryReader { geo in
            let trackWidth = max(geo.size.width - unitLabelWidth, 1)
            let step = trackWidth / CGFloat(maxSemitones)
            let selectedWidth = step * CGFloat(semitoneDistance)

            ZStack(alignment: .topLeading) {
                // Dim full track
                Capsule()
                    .fill(palette.ringStroke.opacity(0.18))
                    .frame(width: trackWidth, height: 10)
                    .offset(y: trackCenterY - 5)

                // Selected span
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                palette.emphasisStroke.opacity(0.55),
                                palette.emphasisFill
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(selectedWidth, 0), height: 10)
                    .offset(y: trackCenterY - 5)

                ticks(step: step)

                // Root marker (fixed at 0)
                markerDot()
                    .offset(x: -9, y: trackCenterY - 9)

                // Target marker
                markerDot()
                    .offset(x: step * CGFloat(semitoneDistance) - 9, y: trackCenterY - 9)

                // Unit captions
                Text("온음")
                    .font(LumenoteFont.caption2(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: unitLabelWidth, alignment: .leading)
                    .offset(x: trackWidth + 4, y: trackCenterY + 18)

                Text("반음")
                    .font(LumenoteFont.caption2(.medium))
                    .foregroundStyle(.secondary)
                    .frame(width: unitLabelWidth, alignment: .leading)
                    .offset(x: trackWidth + 4, y: trackCenterY + 38)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .contentShape(Rectangle())
            .gesture(dragGesture(step: step, trackWidth: trackWidth))
        }
        .frame(height: 108)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("음정 자")
        .accessibilityValue("\(semitoneDistance)반음")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                updateDistance(semitoneDistance + 1)
            case .decrement:
                updateDistance(semitoneDistance - 1)
            @unknown default:
                break
            }
        }
    }

    private var trackCenterY: CGFloat { 28 }

    private func ticks(step: CGFloat) -> some View {
        ForEach(0...maxSemitones, id: \.self) { i in
            let x = step * CGFloat(i)
            let isWhole = i % 2 == 0
            let inRange = i <= semitoneDistance

            Capsule()
                .fill(inRange ? palette.ringStroke : palette.ringStroke.opacity(0.35))
                .frame(width: isWhole ? 2.5 : 1.2, height: isWhole ? 22 : 14)
                .offset(
                    x: x - (isWhole ? 1.25 : 0.6),
                    y: trackCenterY - (isWhole ? 11 : 7)
                )

            if isWhole {
                Text(IntervalModel.formatWholeTones(Double(i) / 2.0))
                    .font(LumenoteFont.caption2(.semibold))
                    .foregroundStyle(inRange ? Color.primary : Color.secondary.opacity(0.55))
                    .position(x: x, y: trackCenterY + 28)
            }

            Text("\(i)")
                .font(LumenoteFont.caption2(.medium))
                .foregroundStyle(inRange ? Color.secondary : Color.secondary.opacity(0.4))
                .position(x: x, y: trackCenterY + 48)
        }
    }

    private func markerDot() -> some View {
        Circle()
            .fill(palette.emphasisStroke)
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(0.85), lineWidth: 1.5)
            )
            .frame(width: 18, height: 18)
            .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
    }

    private func dragGesture(step: CGFloat, trackWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let x = min(max(value.location.x, 0), trackWidth)
                let raw = Int((x / step).rounded())
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

#Preview {
    @Previewable @State var distance = 4
    IntervalRulerView(semitoneDistance: $distance)
        .padding()
        .lumenotePalette()
}
