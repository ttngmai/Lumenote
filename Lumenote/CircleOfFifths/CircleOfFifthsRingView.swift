//

import SwiftUI

struct CircleOfFifthsRingView: View {
    @Bindable var model: CircleOfFifthsModel

    @State private var ringRotationDegrees: Double = 0
    @State private var dragRotationDegrees: Double = 0
    @State private var dragStartAngle: Double?
    @State private var rotationAtDragStart: Double = 0

    private let majorColor = Color(red: 0xE9 / 255, green: 0x5D / 255, blue: 0x5D / 255)
    private let minorColor = Color(red: 0x4F / 255, green: 0x81 / 255, blue: 0xEE / 255)
    private let diminishedColor = Color(red: 0x9A / 255, green: 0x64 / 255, blue: 0xDB / 255)
    private let chromaticFill = Color(red: 0.86, green: 0.86, blue: 0.86)
    private let relativeFill = Color(red: 0.94, green: 0.94, blue: 0.95)
    private let ringStroke = Color(red: 0.15, green: 0.15, blue: 0.15)

    /// Base outer radius of the degree ring (outermost).
    private let outerRadiusRatio: CGFloat = 0.48
    /// Note ring (middle) — thickest band.
    private let noteOuterRatio: CGFloat = 0.41
    private let noteInnerRatio: CGFloat = 0.265
    /// Relative-key ring (innermost).
    private let relativeInnerRatio: CGFloat = 0.175
    /// How much the 12 o'clock tonic wedge is scaled up (radial + slight angular overlap).
    private let raisedScale: CGFloat = 1.05
    private let raisedAngularPadDegrees: Double = 2.5

    /// Continuous ring rotation. Avoids C (0°) ↔ F (−330°) long-way animation.
    private var displayedRotationDegrees: Double {
        ringRotationDegrees + dragRotationDegrees
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                // Base rings (equal wedges).
                Canvas { context, _ in
                    drawBaseRings(context: context, center: center, size: size)
                }

                // Raised 12 o'clock wedge drawn above neighbors with a drop shadow.
                RaisedTonicWedgeView(
                    noteColor: noteColor(forScreenClock: 12),
                    relativeFill: relativeFill,
                    ringStroke: ringStroke,
                    outerRadiusRatio: outerRadiusRatio,
                    noteOuterRatio: noteOuterRatio,
                    noteInnerRatio: noteInnerRatio,
                    relativeInnerRatio: relativeInnerRatio,
                    raisedScale: raisedScale,
                    angularPadDegrees: raisedAngularPadDegrees
                )

                // Rotating labels.
                ZStack {
                    noteLabels(center: center, size: size)
                    relativeMinorLabels(center: center, size: size)
                    degreeLabels(center: center, size: size)
                }
                .rotationEffect(.degrees(displayedRotationDegrees))

                centerHub(size: size)
                rotationAffordances(center: center, size: size)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Circle().scale(1.12))
            .gesture(rotationDragGesture(center: center))
            .onAppear {
                ringRotationDegrees = canonicalRotationDegrees(for: model.tonicArrowPosition)
            }
            .onChange(of: model.selectedTonic) { _, _ in
                // Picker / external tonic changes: take the shortest arc (fixes C ↔ F spin).
                guard dragStartAngle == nil else { return }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    ringRotationDegrees += shortestRotationDelta(
                        from: ringRotationDegrees,
                        to: canonicalRotationDegrees(for: model.tonicArrowPosition)
                    )
                }
            }
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

    // MARK: - Base rings

    private func drawBaseRings(context: GraphicsContext, center: CGPoint, size: CGFloat) {
        let radii = ringRadii(size: size, scale: 1)

        // Outer → inner: degree, note, relative. Skip position 12; raised overlay redraws it.
        for position in 1...12 where position != 12 {
            let color = noteColor(forScreenClock: position)

            // Degree ring (outermost) — same fill as the related note cell.
            fillSector(
                context: context,
                center: center,
                inner: radii.degreeInner,
                outer: radii.degreeOuter,
                clockPosition: position,
                color: color,
                angularPad: 0
            )

            // Note ring (middle, thickest)
            fillSector(
                context: context,
                center: center,
                inner: radii.noteInner,
                outer: radii.noteOuter,
                clockPosition: position,
                color: color,
                angularPad: 0
            )

            // Relative-key ring (innermost)
            fillSector(
                context: context,
                center: center,
                inner: radii.relativeInner,
                outer: radii.relativeOuter,
                clockPosition: position,
                color: relativeFill,
                angularPad: 0
            )
        }

        // Separators (all 12; raised wedge covers the top pair)
        for position in 1...12 {
            let angle = angleForLeadingEdge(of: position)
            var line = Path()
            line.move(to: point(center: center, radius: radii.relativeInner, angle: angle))
            line.addLine(to: point(center: center, radius: radii.degreeOuter, angle: angle))
            context.stroke(line, with: .color(ringStroke.opacity(0.3)), lineWidth: 0.8)
        }

        // Ring outlines
        for radius in [radii.degreeOuter, radii.noteOuter, radii.noteInner, radii.relativeInner] {
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
                lineWidth: radius == radii.degreeOuter ? 1.8 : 1.1
            )
        }
    }

    // MARK: - Labels

    private func noteLabels(center: CGPoint, size: CGFloat) -> some View {
        // Midpoint of the note ring (thickest / middle band).
        let baseRadius = size * ((noteOuterRatio + noteInnerRatio) / 2)
        return ForEach(1...12, id: \.self) { position in
            let name = model.noteNames[position].map(CircleOfFifthsModel.Tonic.formatNoteName) ?? ""
            let isActive = model.activePositionSet.contains(position)
            let isTonic = position == model.tonicArrowPosition
            let radius = isTonic ? baseRadius * raisedScale : baseRadius
            Text(name)
                .font(.system(
                    size: size * (isTonic ? 0.055 : 0.048),
                    weight: .heavy,
                    design: .rounded
                ))
                .foregroundStyle(isActive ? Color.white : Color.secondary)
                .shadow(color: isActive ? .black.opacity(0.22) : .clear, radius: 1, y: 0.5)
                .rotationEffect(.degrees(-displayedRotationDegrees))
                .position(point(center: center, radius: radius, angle: angleForCenter(of: position)))
                .zIndex(isTonic ? 1 : 0)
        }
    }

    private func relativeMinorLabels(center: CGPoint, size: CGFloat) -> some View {
        // Midpoint of the relative-key ring (innermost).
        let baseRadius = size * ((noteInnerRatio + relativeInnerRatio) / 2)
        let names = model.relativeMinorNames
        return ForEach(1...12, id: \.self) { position in
            let raw = names[position] ?? ""
            let label = CircleOfFifthsModel.Tonic.formatNoteName(raw) + "m"
            let isActive = model.activePositionSet.contains(position)
            let isTonic = position == model.tonicArrowPosition
            let radius = isTonic ? baseRadius * raisedScale : baseRadius
            Text(label)
                .font(.system(
                    size: size * (isTonic ? 0.032 : 0.028),
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundStyle(isActive ? Color.primary.opacity(0.85) : Color.secondary.opacity(0.55))
                .rotationEffect(.degrees(-displayedRotationDegrees))
                .position(point(center: center, radius: radius, angle: angleForCenter(of: position)))
                .zIndex(isTonic ? 1 : 0)
        }
    }

    private func degreeLabels(center: CGPoint, size: CGFloat) -> some View {
        // Midpoint of the degree ring (outermost).
        let baseRadius = size * ((outerRadiusRatio + noteOuterRatio) / 2)
        return ForEach(Array(model.degreeLabels.keys.sorted()), id: \.self) { position in
            if let label = model.degreeLabels[position] {
                let isActive = model.activePositionSet.contains(position)
                let isTonic = position == model.tonicArrowPosition
                let radius = isTonic ? baseRadius * raisedScale : baseRadius
                Text(label)
                    .font(.system(
                        size: size * (isTonic ? 0.04 : 0.036),
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundStyle(isActive ? Color.white : Color.secondary)
                    .shadow(color: isActive ? .black.opacity(0.22) : .clear, radius: 1, y: 0.5)
                    .rotationEffect(.degrees(-displayedRotationDegrees))
                    .position(point(center: center, radius: radius, angle: angleForCenter(of: position)))
                    .zIndex(isTonic ? 1 : 0)
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

    // MARK: - Rotation affordances

    private func rotationAffordances(center: CGPoint, size: CGFloat) -> some View {
        let radius = size * 0.52
        let gStart = -72.0
        let gEnd = -48.0
        let fStart = -108.0
        let fEnd = -132.0

        return ZStack {
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

    private func arrowHead(
        center: CGPoint,
        radius: CGFloat,
        tangentDegrees: Double,
        pointingClockwise: Bool,
        size: CGFloat
    ) -> some View {
        let tip = point(center: center, radius: radius, angle: .degrees(tangentDegrees))
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

                // Keep ringRotation on a continuous snapped angle so C↔F never jumps by 330°.
                let snappedRing = ringRotationDegrees + shortestRotationDelta(
                    from: ringRotationDegrees,
                    to: canonicalRotationDegrees(for: position)
                )
                ringRotationDegrees = snappedRing
                dragRotationDegrees = newDisplayed - snappedRing
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.84)) {
                    dragRotationDegrees = 0
                }
                dragStartAngle = nil
            }
    }

    /// Canonical alignment for a clock position in (−360, 0] (C/B♯ → 0, G → −30, …, F → −330).
    private func canonicalRotationDegrees(for lydianStartPosition: Int) -> Double {
        -Double(lydianStartPosition % 12) * 30.0
    }

    /// Shortest signed delta on the circle from `from` toward an angle equivalent to `to`.
    private func shortestRotationDelta(from: Double, to: Double) -> Double {
        let fromN = normalizedDegrees(from)
        let toN = normalizedDegrees(to)
        var delta = toN - fromN
        if delta > 180 { delta -= 360 }
        if delta <= -180 { delta += 360 }
        return delta
    }

    private func normalizedDegrees(_ degrees: Double) -> Double {
        var value = degrees.truncatingRemainder(dividingBy: 360)
        if value < 0 { value += 360 }
        return value
    }

    // MARK: - Drawing helpers

    private struct RingRadii {
        /// Outermost: degree labels.
        var degreeOuter: CGFloat
        var degreeInner: CGFloat
        /// Middle (thickest): note names.
        var noteOuter: CGFloat
        var noteInner: CGFloat
        /// Innermost: relative keys.
        var relativeOuter: CGFloat
        var relativeInner: CGFloat
    }

    private func ringRadii(size: CGFloat, scale: CGFloat) -> RingRadii {
        RingRadii(
            degreeOuter: size * outerRadiusRatio * scale,
            degreeInner: size * noteOuterRatio * scale,
            noteOuter: size * noteOuterRatio * scale,
            noteInner: size * noteInnerRatio * scale,
            relativeOuter: size * noteInnerRatio * scale,
            relativeInner: size * relativeInnerRatio * scale
        )
    }

    private func noteColor(forScreenClock position: Int) -> Color {
        if let quality = model.screenChordQuality(atScreenClock: position) {
            switch quality {
            case .major: return majorColor
            case .minor: return minorColor
            case .diminished: return diminishedColor
            }
        }
        return chromaticFill
    }

    private func fillSector(
        context: GraphicsContext,
        center: CGPoint,
        inner: CGFloat,
        outer: CGFloat,
        clockPosition: Int,
        color: Color,
        angularPad: Double
    ) {
        let startAngle = angleForLeadingEdge(of: clockPosition) - .degrees(angularPad)
        let endAngle = angleForLeadingEdge(of: CircleOfFifthsModel.normalizedClock(clockPosition + 1))
            + .degrees(angularPad)
        var path = Path()
        path.addArc(center: center, radius: outer, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: inner, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        context.fill(path, with: .color(color))
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

// MARK: - Raised tonic wedge

private struct RaisedTonicWedgeView: View {
    let noteColor: Color
    let relativeFill: Color
    let ringStroke: Color
    let outerRadiusRatio: CGFloat
    let noteOuterRatio: CGFloat
    let noteInnerRatio: CGFloat
    let relativeInnerRatio: CGFloat
    let raisedScale: CGFloat
    let angularPadDegrees: Double

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                // Soft contact shadow.
                AnnularSector(
                    clockPosition: 12,
                    innerRatio: relativeInnerRatio * raisedScale,
                    outerRatio: outerRadiusRatio * raisedScale,
                    angularPadDegrees: angularPadDegrees
                )
                .fill(Color.black.opacity(0.2))
                .offset(y: size * 0.01)
                .blur(radius: size * 0.014)

                // Outer → inner: degree, note, relative (degree shares note color).
                band(
                    innerRatio: noteOuterRatio * raisedScale,
                    outerRatio: outerRadiusRatio * raisedScale,
                    fill: noteColor,
                    strokeWidth: 1.6
                )
                band(
                    innerRatio: noteInnerRatio * raisedScale,
                    outerRatio: noteOuterRatio * raisedScale,
                    fill: noteColor,
                    strokeWidth: 1.1
                )
                band(
                    innerRatio: relativeInnerRatio * raisedScale,
                    outerRatio: noteInnerRatio * raisedScale,
                    fill: relativeFill,
                    strokeWidth: 1.0
                )
            }
            .shadow(color: .black.opacity(0.1), radius: size * 0.02, x: 0, y: size * 0.012)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
    }

    private func band(
        innerRatio: CGFloat,
        outerRatio: CGFloat,
        fill: Color,
        strokeWidth: CGFloat
    ) -> some View {
        let shape = AnnularSector(
            clockPosition: 12,
            innerRatio: innerRatio,
            outerRatio: outerRatio,
            angularPadDegrees: angularPadDegrees
        )
        return shape
            .fill(fill)
            .overlay(shape.stroke(ringStroke, lineWidth: strokeWidth))
    }
}

private struct AnnularSector: Shape {
    var clockPosition: Int
    var innerRatio: CGFloat
    var outerRatio: CGFloat
    var angularPadDegrees: Double

    func path(in rect: CGRect) -> Path {
        let size = min(rect.width, rect.height)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let inner = size * innerRatio
        let outer = size * outerRatio

        let leading = Double(clockPosition) * 30.0 - 15.0 - 90.0 - angularPadDegrees
        let trailing = Double(CircleOfFifthsModel.normalizedClock(clockPosition + 1)) * 30.0 - 15.0 - 90.0
            + angularPadDegrees

        var path = Path()
        path.addArc(
            center: center,
            radius: outer,
            startAngle: .degrees(leading),
            endAngle: .degrees(trailing),
            clockwise: false
        )
        path.addArc(
            center: center,
            radius: inner,
            startAngle: .degrees(trailing),
            endAngle: .degrees(leading),
            clockwise: true
        )
        path.closeSubpath()
        return path
    }
}

#Preview {
    CircleOfFifthsRingView(model: CircleOfFifthsModel())
        .padding()
}
