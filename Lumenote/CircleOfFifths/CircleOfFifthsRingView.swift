//

import SwiftUI

struct CircleOfFifthsRingView: View {
    let model: CircleOfFifthsModel

    private let majorColor = Color(red: 0.78, green: 0.22, blue: 0.22)
    private let minorColor = Color(red: 0.22, green: 0.42, blue: 0.72)
    private let diminishedColor = Color(red: 0.45, green: 0.32, blue: 0.58)
    private let diatonicFill = Color.white
    private let chromaticFill = Color(red: 0.86, green: 0.86, blue: 0.86)
    private let ringStroke = Color(red: 0.15, green: 0.15, blue: 0.15)

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                Canvas { context, _ in
                    drawRings(context: context, center: center, size: size)
                }

                noteLabels(center: center, size: size)
                degreeLabels(center: center, size: size)
                chordQualityLabels(center: center, size: size)
                tonicArrow(center: center, size: size)
                centerHub(size: size)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: model.selectedTonic)
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: model.selectedMode)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Drawing

    private func drawRings(context: GraphicsContext, center: CGPoint, size: CGFloat) {
        let outer = size * 0.48
        let chordInner = size * 0.40
        let noteOuter = chordInner
        let noteInner = size * 0.28
        let degreeOuter = noteInner
        let degreeInner = size * 0.16

        // Chord ring background (inactive arc)
        var fullChord = Path()
        fullChord.addArc(center: center, radius: (outer + chordInner) / 2, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        context.stroke(fullChord, with: .color(Color(red: 0.92, green: 0.92, blue: 0.92)), style: StrokeStyle(lineWidth: outer - chordInner))

        // Chord quality segments over the 7 active positions
        let start = model.chordRingStartPosition
        for ordinal in 0..<7 {
            let position = CircleOfFifthsModel.normalizedClock(start + ordinal)
            let quality = CircleOfFifthsModel.ChordQuality.quality(forOrdinal: ordinal)
            let color: Color
            switch quality {
            case .major: color = majorColor
            case .minor: color = minorColor
            case .diminished: color = diminishedColor
            }
            fillSector(
                context: context,
                center: center,
                inner: chordInner,
                outer: outer,
                clockPosition: position,
                color: color.opacity(0.92)
            )
        }

        // Note ring wedges
        for position in 1...12 {
            let isActive = model.activePositionSet.contains(position)
            fillSector(
                context: context,
                center: center,
                inner: noteInner,
                outer: noteOuter,
                clockPosition: position,
                color: isActive ? diatonicFill : chromaticFill
            )
        }

        // Degree ring background
        var degreeRing = Path()
        degreeRing.addArc(center: center, radius: (degreeOuter + degreeInner) / 2, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        context.stroke(degreeRing, with: .color(Color(red: 0.96, green: 0.96, blue: 0.94)), style: StrokeStyle(lineWidth: degreeOuter - degreeInner))

        // Separators for all 12 wedges
        for position in 1...12 {
            let angle = angleForLeadingEdge(of: position)
            var line = Path()
            line.move(to: point(center: center, radius: degreeInner, angle: angle))
            line.addLine(to: point(center: center, radius: outer, angle: angle))
            context.stroke(line, with: .color(ringStroke.opacity(0.35)), lineWidth: 1)
        }

        // Ring outlines
        for radius in [outer, chordInner, noteInner, degreeInner] {
            var circle = Path()
            circle.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            context.stroke(circle, with: .color(ringStroke), lineWidth: radius == outer ? 2.5 : 1.5)
        }
    }

    private func fillSector(
        context: GraphicsContext,
        center: CGPoint,
        inner: CGFloat,
        outer: CGFloat,
        clockPosition: Int,
        color: Color
    ) {
        let startAngle = angleForLeadingEdge(of: clockPosition)
        let endAngle = angleForLeadingEdge(of: CircleOfFifthsModel.normalizedClock(clockPosition + 1))
        var path = Path()
        path.addArc(center: center, radius: outer, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: inner, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        context.fill(path, with: .color(color))
    }

    // MARK: - Labels

    private func noteLabels(center: CGPoint, size: CGFloat) -> some View {
        let radius = size * 0.34
        return ForEach(1...12, id: \.self) { position in
            let name = model.noteNames[position].map(CircleOfFifthsModel.Tonic.formatNoteName) ?? ""
            let isActive = model.activePositionSet.contains(position)
            Text(name)
                .font(.system(size: size * 0.055, weight: .heavy, design: .rounded))
                .foregroundStyle(isActive ? Color.primary : Color.secondary)
                .position(point(center: center, radius: radius, angle: angleForCenter(of: position)))
        }
    }

    private func degreeLabels(center: CGPoint, size: CGFloat) -> some View {
        let radius = size * 0.22
        return ForEach(Array(model.degreeLabels.keys.sorted()), id: \.self) { position in
            if let label = model.degreeLabels[position] {
                Text(label)
                    .font(.system(size: size * 0.04, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .position(point(center: center, radius: radius, angle: angleForCenter(of: position)))
            }
        }
    }

    private func chordQualityLabels(center: CGPoint, size: CGFloat) -> some View {
        let radius = size * 0.44
        let start = model.chordRingStartPosition
        // Place labels at the middle of each quality group (3 major, 3 minor, 1 dim).
        let groups: [(ordinals: [Int], title: String)] = [
            ([0, 1, 2], "Major"),
            ([3, 4, 5], "Minor"),
            ([6], "Dim")
        ]

        return ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
            let midOrdinal = Double(group.ordinals.reduce(0, +)) / Double(group.ordinals.count)
            let clockPosition = Double(start) + midOrdinal
            let angle = Angle.degrees(clockPosition * 30.0 - 90)
            Text(group.title)
                .font(.system(size: size * 0.028, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                .position(point(center: center, radius: radius, angle: angle))
        }
    }

    private func tonicArrow(center: CGPoint, size: CGFloat) -> some View {
        let radius = size * 0.125
        let angle = angleForCenter(of: model.tonicArrowPosition)
        let tip = point(center: center, radius: radius, angle: angle)

        return Image(systemName: "arrowtriangle.up.fill")
            .font(.system(size: size * 0.045))
            .foregroundStyle(Color.primary)
            .rotationEffect(angle + .degrees(90))
            .position(tip)
    }

    private func centerHub(size: CGFloat) -> some View {
        VStack(spacing: 2) {
            Text(model.selectedTonic.displayName)
                .font(.system(size: size * 0.07, weight: .heavy, design: .rounded))
            Text(model.selectedMode.shortName)
                .font(.system(size: size * 0.032, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Geometry helpers

    /// Leading edge angle for a clock wedge (clockwise from 12 o'clock).
    /// Position 12 is at top; position 1 is one step clockwise.
    private func angleForLeadingEdge(of clockPosition: Int) -> Angle {
        // Center of position N is at N * 30°, so leading edge is at (N - 0.5) * 30°.
        // In SwiftUI, 0° is right (3 o'clock), so convert from clock degrees.
        let clockDegrees = Double(clockPosition) * 30.0 - 15.0
        return .degrees(clockDegrees - 90)
    }

    private func angleForCenter(of clockPosition: Int) -> Angle {
        let clockDegrees = Double(clockPosition) * 30.0
        return .degrees(clockDegrees - 90)
    }

    private func point(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(
            x: center.x + radius * CGFloat(cos(angle.radians)),
            y: center.y + radius * CGFloat(sin(angle.radians))
        )
    }
}

#Preview {
    CircleOfFifthsRingView(model: CircleOfFifthsModel())
        .padding()
}
