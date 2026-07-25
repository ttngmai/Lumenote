//

import SwiftUI

/// Treble staff showing how the current key signature is written.
/// Clef and staff geometry are fixed; only accidentals change with the key.
struct KeySignatureStaffView: View {
    let accidentals: [CircleOfFifthsModel.KeySignatureAccidental]
    /// Distance between two adjacent staff lines.
    let staffSpace: CGFloat
    let lineColor: Color

    /// Always reserve seven accidental slots so sharp/flat keys don't resize the staff.
    private let accidentalSlotCount = 7

    private var staffHeight: CGFloat { staffSpace * 4 }
    private var clefWidth: CGFloat { staffSpace * 2.8 }
    private var accidentalSpacing: CGFloat { staffSpace * 0.95 }
    private var trailingPad: CGFloat { staffSpace * 0.7 }
    private var staffWidth: CGFloat {
        clefWidth + CGFloat(accidentalSlotCount) * accidentalSpacing + trailingPad
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            staffLines
            clef

            ForEach(accidentals) { accidental in
                Text(accidental.symbol)
                    .font(.system(size: staffSpace * 2.1, weight: .semibold))
                    .foregroundStyle(lineColor)
                    .fixedSize()
                    .position(
                        x: clefWidth + (CGFloat(accidental.order) + 0.5) * accidentalSpacing,
                        y: y(forStaffStep: accidental.staffStep)
                    )
            }
        }
        .frame(width: staffWidth, height: staffHeight)
        .accessibilityHidden(true)
    }

    private var staffLines: some View {
        Canvas { context, size in
            for line in 0..<5 {
                let y = CGFloat(line) * staffSpace
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: max(0.6, staffSpace * 0.09))
            }
        }
        .frame(width: staffWidth, height: staffHeight)
    }

    /// Unicode G clef. Ink height varies by font, so the box is capped to keep it
    /// from swamping the hub; adjust the multiplier to taste.
    private var clef: some View {
        Text("𝄞")
            .font(.system(size: staffSpace * 7))
            .minimumScaleFactor(0.3)
            .lineLimit(1)
            .foregroundStyle(lineColor)
            .frame(width: clefWidth, height: staffSpace * 7)
            .position(x: clefWidth / 2, y: staffHeight / 2)
    }

    /// Bottom staff line is step 0; each step is half a staff space.
    private func y(forStaffStep step: Int) -> CGFloat {
        staffHeight - CGFloat(step) * staffSpace / 2
    }
}

#Preview {
    let model = CircleOfFifthsModel()
    return VStack(spacing: 24) {
        KeySignatureStaffView(
            accidentals: model.keySignatureAccidentals,
            staffSpace: 10,
            lineColor: .primary
        )
    }
    .padding(40)
}
