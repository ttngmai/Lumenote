//

import SwiftUI

struct CircleOfFifthsRingView: View {
    @Bindable var model: CircleOfFifthsModel

    @State private var dragRotationDegrees: Double = 0
    @State private var dragStartAngle: Double?
    @State private var rotationAtDragStart: Double = 0

    private let majorColor = Color(red: 0xE9 / 255, green: 0x5D / 255, blue: 0x5D / 255)
    private let minorColor = Color(red: 0x4F / 255, green: 0x81 / 255, blue: 0xEE / 255)
    private let diminishedColor = Color(red: 0x9A / 255, green: 0x64 / 255, blue: 0xDB / 255)
    private let chromaticFill = Color(red: 0.86, green: 0.86, blue: 0.86)
    private let ringStroke = Color(red: 0.15, green: 0.15, blue: 0.15)

    private var displayedRotationDegrees: Double {
        model.tonicAlignmentRotationDegrees + dragRotationDegrees
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                ZStack {
                    Canvas { context, _ in
                        drawRings(context: context, center: center, size: size)
                    }

                    noteLabels(center: center, size: size)
                    degreeLabels(center: center, size: size)
                    centerHub(size: size)
                }
                .rotationEffect(.degrees(displayedRotationDegrees))
                .gesture(rotationDragGesture(center: center))

                fixedTonicPointer(center: center, size: size)
                rotationAffordances(center: center, size: size)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .animation(
                dragStartAngle == nil
                    ? .spring(response: 0.45, dampingFraction: 0.82)
                    : nil,
                value: model.selectedTonic
            )
            .animation(
                dragStartAngle == nil
                    ? .spring(response: 0.45, dampingFraction: 0.82)
                    : nil,
                value: model.selectedMode
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHint("원을 드래그하여 토닉을 변경합니다.")
    }

    // MARK: - Drawing

    private func drawRings(context: GraphicsContext, center: CGPoint, size: CGFloat) {
        let noteOuter = size * 0.48
        let noteInner = size * 0.30
        let degreeOuter = noteInner
        let degreeInner = size * 0.16

        // Note ring wedges — diatonic sectors tinted by chord quality.
        for position in 1...12 {
            let color: Color
            if let quality = model.chordQuality(at: position) {
                switch quality {
                case .major: color = majorColor
                case .minor: color = minorColor
                case .diminished: color = diminishedColor
                }
            } else {
                color = chromaticFill
            }
            fillSector(
                context: context,
                center: center,
                inner: noteInner,
                outer: noteOuter,
                clockPosition: position,
                color: color
            )
        }

        // Degree ring background
        var degreeRing = Path()
        degreeRing.addArc(
            center: center,
            radius: (degreeOuter + degreeInner) / 2,
            startAngle: .degrees(0),
            endAngle: .degrees(360),
            clockwise: false
        )
        context.stroke(
            degreeRing,
            with: .color(Color(red: 0.96, green: 0.96, blue: 0.94)),
            style: StrokeStyle(lineWidth: degreeOuter - degreeInner)
        )

        // Separators for all 12 wedges
        for position in 1...12 {
            let angle = angleForLeadingEdge(of: position)
            var line = Path()
            line.move(to: point(center: center, radius: degreeInner, angle: angle))
            line.addLine(to: point(center: center, radius: noteOuter, angle: angle))
            context.stroke(line, with: .color(ringStroke.opacity(0.35)), lineWidth: 1)
        }

        // Ring outlines
        for radius in [noteOuter, noteInner, degreeInner] {
            var circle = Path()
            circle.addEllipse(
                in: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
            )
            context.stroke(
                circle,
                with: .color(ringStroke),
                lineWidth: radius == noteOuter ? 2.5 : 1.5
            )
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
        let radius = size * 0.39
        return ForEach(1...12, id: \.self) { position in
            let name = model.noteNames[position].map(CircleOfFifthsModel.Tonic.formatNoteName) ?? ""
            let isActive = model.activePositionSet.contains(position)
            Text(name)
                .font(.system(size: size * 0.055, weight: .heavy, design: .rounded))
                .foregroundStyle(isActive ? Color.white : Color.secondary)
                .shadow(color: isActive ? .black.opacity(0.25) : .clear, radius: 1, y: 0.5)
                .rotationEffect(.degrees(-displayedRotationDegrees))
                .position(point(center: center, radius: radius, angle: angleForCenter(of: position)))
        }
    }

    private func degreeLabels(center: CGPoint, size: CGFloat) -> some View {
        let radius = size * 0.23
        return ForEach(Array(model.degreeLabels.keys.sorted()), id: \.self) { position in
            if let label = model.degreeLabels[position] {
                Text(label)
                    .font(.system(size: size * 0.04, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .rotationEffect(.degrees(-displayedRotationDegrees))
                    .position(point(center: center, radius: radius, angle: angleForCenter(of: position)))
            }
        }
    }

    private func centerHub(size: CGFloat) -> some View {
        VStack(spacing: 2) {
            Text(model.selectedTonic.displayName)
                .font(.system(size: size * 0.07, weight: .heavy, design: .rounded))
            Text(model.selectedMode.shortName)
                .font(.system(size: size * 0.032, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .rotationEffect(.degrees(-displayedRotationDegrees))
    }

    /// Fixed pointer at 12 o'clock on the circle boundary (does not rotate with the ring).
    private func fixedTonicPointer(center: CGPoint, size: CGFloat) -> some View {
        let tip = CGPoint(x: center.x, y: center.y - size * 0.48)
        return Image(systemName: "arrowtriangle.down.fill")
            .font(.system(size: size * 0.055))
            .foregroundStyle(Color.primary)
            .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
            .position(tip)
            .accessibilityLabel("토닉 포인터")
    }

    /// Visual cue that the circle can be rotated.
    private func rotationAffordances(center: CGPoint, size: CGFloat) -> some View {
        let radius = size * 0.52
        return ZStack {
            Image(systemName: "chevron.left")
                .font(.system(size: size * 0.035, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .position(point(center: center, radius: radius, angle: .degrees(-125)))

            Image(systemName: "chevron.right")
                .font(.system(size: size * 0.035, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .position(point(center: center, radius: radius, angle: .degrees(-55)))

            // Curved hint arcs near 12 o'clock.
            Circle()
                .trim(from: 0.88, to: 0.97)
                .stroke(Color.secondary.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(-90))
                .position(center)

            Circle()
                .trim(from: 0.03, to: 0.12)
                .stroke(Color.secondary.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(-90))
                .position(center)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Drag rotation

    private func rotationDragGesture(center: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                let angle = atan2(
                    value.location.y - center.y,
                    value.location.x - center.x
                )
                if dragStartAngle == nil {
                    dragStartAngle = angle
                    rotationAtDragStart = displayedRotationDegrees
                }
                guard let start = dragStartAngle else { return }

                var delta = (angle - start) * 180 / .pi
                // Keep delta continuous across the ±π wrap.
                while delta > 180 { delta -= 360 }
                while delta < -180 { delta += 360 }

                let newDisplayed = rotationAtDragStart + delta
                let position = CircleOfFifthsModel.lydianStartPosition(forRotationDegrees: newDisplayed)
                model.selectTonic(forLydianStart: position)
                dragRotationDegrees = newDisplayed - model.tonicAlignmentRotationDegrees
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.84)) {
                    dragRotationDegrees = 0
                }
                dragStartAngle = nil
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
