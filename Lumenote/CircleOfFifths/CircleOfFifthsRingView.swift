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
    private let relativeFill = Color(red: 0.94, green: 0.94, blue: 0.95)
    private let degreeFill = Color(red: 0.96, green: 0.96, blue: 0.94)
    private let ringStroke = Color(red: 0.15, green: 0.15, blue: 0.15)

    /// Outer radius of the note (major) ring, used by the fixed tonic pointer.
    private let outerRadiusRatio: CGFloat = 0.48

    private var displayedRotationDegrees: Double {
        model.tonicAlignmentRotationDegrees + dragRotationDegrees
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                // Fixed layer: quality colors and ring chrome stay pinned to the screen.
                Canvas { context, _ in
                    drawFixedRings(context: context, center: center, size: size)
                }

                // Rotating layer: note / relative / degree labels orbit with the tonic.
                ZStack {
                    noteLabels(center: center, size: size)
                    relativeMinorLabels(center: center, size: size)
                    degreeLabels(center: center, size: size)
                }
                .rotationEffect(.degrees(displayedRotationDegrees))

                centerHub(size: size)
                fixedTonicPointer(center: center, size: size)
                rotationAffordances(center: center, size: size)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Circle().scale(1.08))
            .gesture(rotationDragGesture(center: center))
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
        .accessibilityHint("원을 드래그하여 토닉을 변경합니다. 시계 방향은 완전5도, 반시계 방향은 완전4도입니다.")
    }

    // MARK: - Fixed ring drawing

    private func drawFixedRings(context: GraphicsContext, center: CGPoint, size: CGFloat) {
        let noteOuter = size * outerRadiusRatio
        let noteInner = size * 0.385
        let relativeOuter = noteInner
        let relativeInner = size * 0.295
        let degreeOuter = relativeInner
        let degreeInner = size * 0.175

        // Note ring — screen-fixed Major / Minor / Dim / chromatic wedges.
        for position in 1...12 {
            let color: Color
            if let quality = model.screenChordQuality(atScreenClock: position) {
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

        // Relative-key ring background
        for position in 1...12 {
            fillSector(
                context: context,
                center: center,
                inner: relativeInner,
                outer: relativeOuter,
                clockPosition: position,
                color: relativeFill
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
            with: .color(degreeFill),
            style: StrokeStyle(lineWidth: degreeOuter - degreeInner)
        )

        // Separators
        for position in 1...12 {
            let angle = angleForLeadingEdge(of: position)
            var line = Path()
            line.move(to: point(center: center, radius: degreeInner, angle: angle))
            line.addLine(to: point(center: center, radius: noteOuter, angle: angle))
            context.stroke(line, with: .color(ringStroke.opacity(0.3)), lineWidth: 0.8)
        }

        // Ring outlines (thinner)
        for radius in [noteOuter, noteInner, relativeInner, degreeInner] {
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
                lineWidth: radius == noteOuter ? 1.8 : 1.1
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

    // MARK: - Rotating labels

    private func noteLabels(center: CGPoint, size: CGFloat) -> some View {
        let radius = size * 0.432
        return ForEach(1...12, id: \.self) { position in
            let name = model.noteNames[position].map(CircleOfFifthsModel.Tonic.formatNoteName) ?? ""
            let isActive = model.activePositionSet.contains(position)
            Text(name)
                .font(.system(size: size * 0.048, weight: .heavy, design: .rounded))
                .foregroundStyle(isActive ? Color.white : Color.secondary)
                .shadow(color: isActive ? .black.opacity(0.22) : .clear, radius: 1, y: 0.5)
                .rotationEffect(.degrees(-displayedRotationDegrees))
                .position(point(center: center, radius: radius, angle: angleForCenter(of: position)))
        }
    }

    private func relativeMinorLabels(center: CGPoint, size: CGFloat) -> some View {
        let radius = size * 0.34
        let names = model.relativeMinorNames
        return ForEach(1...12, id: \.self) { position in
            let raw = names[position] ?? ""
            let label = CircleOfFifthsModel.Tonic.formatNoteName(raw) + "m"
            let isActive = model.activePositionSet.contains(position)
            Text(label)
                .font(.system(size: size * 0.028, weight: .bold, design: .rounded))
                .foregroundStyle(isActive ? Color.primary.opacity(0.85) : Color.secondary.opacity(0.55))
                .rotationEffect(.degrees(-displayedRotationDegrees))
                .position(point(center: center, radius: radius, angle: angleForCenter(of: position)))
        }
    }

    private func degreeLabels(center: CGPoint, size: CGFloat) -> some View {
        let radius = size * 0.235
        return ForEach(Array(model.degreeLabels.keys.sorted()), id: \.self) { position in
            if let label = model.degreeLabels[position] {
                Text(label)
                    .font(.system(size: size * 0.036, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .rotationEffect(.degrees(-displayedRotationDegrees))
                    .position(point(center: center, radius: radius, angle: angleForCenter(of: position)))
            }
        }
    }

    private func centerHub(size: CGFloat) -> some View {
        VStack(spacing: 2) {
            Text(model.selectedTonic.displayName)
                .font(.system(size: size * 0.065, weight: .heavy, design: .rounded))
            Text(model.selectedMode.shortName)
                .font(.system(size: size * 0.03, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    /// Fixed pointer at 12 o'clock on the circle boundary.
    private func fixedTonicPointer(center: CGPoint, size: CGFloat) -> some View {
        let tip = CGPoint(x: center.x, y: center.y - size * outerRadiusRatio)
        return Image(systemName: "arrowtriangle.down.fill")
            .font(.system(size: size * 0.05))
            .foregroundStyle(Color.primary)
            .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
            .position(tip)
            .accessibilityLabel("토닉 포인터")
    }

    // MARK: - Rotation affordances

    /// Short curved arrows over the F / G wedges (flanking the 12 o'clock tonic).
    ///
    /// Note: with our angle convention (increasing degrees = clockwise on screen),
    /// `Path.addArc(..., clockwise: false)` draws the short clockwise sweep —
    /// the same convention used by `fillSector`. Using the opposite flag draws
    /// the long way around the circle.
    private func rotationAffordances(center: CGPoint, size: CGFloat) -> some View {
        let radius = size * 0.52
        // G wedge (screen position 1): leading −75° … trailing −45°, center −60°.
        // F wedge (screen position 11): leading −135° … trailing −105°, center −120°.
        let gStart = -72.0
        let gEnd = -48.0
        let fStart = -108.0
        let fEnd = -132.0

        return ZStack {
            // Clockwise over G → perfect fifths
            directionalArc(
                center: center,
                radius: radius,
                startDegrees: gStart,
                endDegrees: gEnd,
                clockwise: false,
                lineWidth: size * 0.0055
            )
            arrowHead(
                center: center,
                radius: radius,
                tangentDegrees: gEnd,
                pointingClockwise: true,
                size: size * 0.024
            )
            Text("완전5도")
                .font(.system(size: size * 0.022, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .position(point(center: center, radius: radius + size * 0.038, angle: .degrees(-60)))

            // Counter-clockwise over F → perfect fourths
            directionalArc(
                center: center,
                radius: radius,
                startDegrees: fStart,
                endDegrees: fEnd,
                clockwise: true,
                lineWidth: size * 0.0055
            )
            arrowHead(
                center: center,
                radius: radius,
                tangentDegrees: fEnd,
                pointingClockwise: false,
                size: size * 0.024
            )
            Text("완전4도")
                .font(.system(size: size * 0.022, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .position(point(center: center, radius: radius + size * 0.038, angle: .degrees(-120)))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func directionalArc(
        center: CGPoint,
        radius: CGFloat,
        startDegrees: Double,
        endDegrees: Double,
        clockwise: Bool,
        lineWidth: CGFloat
    ) -> some View {
        Path { path in
            path.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(startDegrees),
                endAngle: .degrees(endDegrees),
                clockwise: clockwise
            )
        }
        .stroke(Color.secondary.opacity(0.55), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
    }

    /// Triangle tip aligned with the arc tangent at `tangentDegrees`.
    private func arrowHead(
        center: CGPoint,
        radius: CGFloat,
        tangentDegrees: Double,
        pointingClockwise: Bool,
        size: CGFloat
    ) -> some View {
        // Tangent for a circle: angle of radius + 90° (CW) or −90° (CCW).
        let tipAngle = Angle.degrees(tangentDegrees)
        let tip = point(center: center, radius: radius, angle: tipAngle)
        let rotation = tangentDegrees + (pointingClockwise ? 90 : -90)

        return Image(systemName: "arrowtriangle.right.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(Color.secondary.opacity(0.75))
            .rotationEffect(.degrees(rotation))
            .position(tip)
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

    private func angleForLeadingEdge(of clockPosition: Int) -> Angle {
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
