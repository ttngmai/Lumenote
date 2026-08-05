//

import Foundation

/// Interactive interval explorer: root pitch + semitone distance on a one-octave ruler.
///
/// The ruler visualizes **pitch distance** (semitones / whole tones).
/// Interval *names* here are a simple semitone→name lookup for learning;
/// enharmonic spelling (e.g. minor 3rd vs augmented 2nd) is deferred.
@Observable
final class IntervalModel {
    /// Pitch class of the root note, 0…11 (C = 0).
    var rootPitchClass: Int = 0 {
        didSet {
            let clamped = Self.clampPitchClass(rootPitchClass)
            if clamped != rootPitchClass { rootPitchClass = clamped }
        }
    }

    /// Semitone distance from root to target, 0…12 (one octave).
    var semitoneDistance: Int = 4 {
        didSet {
            let clamped = Self.clampDistance(semitoneDistance)
            if clamped != semitoneDistance { semitoneDistance = clamped }
        }
    }

    // MARK: - Derived

    var rootDisplayName: String {
        Self.displayName(forPitchClass: rootPitchClass)
    }

    /// Target note name. Distance 12 reuses the root spelling (octave).
    var targetDisplayName: String {
        if semitoneDistance == 12 {
            return rootDisplayName
        }
        let pc = (rootPitchClass + semitoneDistance) % 12
        return Self.displayName(forPitchClass: pc)
    }

    /// Whole-tone equivalent of the current semitone distance.
    var wholeTones: Double {
        Double(semitoneDistance) / 2.0
    }

    /// Korean interval name from semitone count only (not letter spelling).
    var intervalName: String {
        Self.intervalNames[semitoneDistance]
    }

    var distanceDescription: String {
        "\(semitoneDistance)반음 · \(Self.formatWholeTones(wholeTones))온음"
    }

    /// All selectable roots for the picker (sharp-preferring chromatic).
    static var rootOptions: [(pitchClass: Int, displayName: String)] {
        (0..<12).map { ($0, displayName(forPitchClass: $0)) }
    }

    // MARK: - Tables

    /// ASCII chromatic spellings, sharp-preferring (MVP; no flat enharmonics).
    private static let chromaticASCII: [String] = [
        "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
    ]

    /// Semitone index 0…12 → Korean interval name.
    private static let intervalNames: [String] = [
        "완전1도",
        "단2도",
        "장2도",
        "단3도",
        "장3도",
        "완전4도",
        "증4도·감5도",
        "완전5도",
        "단6도",
        "장6도",
        "단7도",
        "장7도",
        "완전8도",
    ]

    // MARK: - Helpers

    static func displayName(forPitchClass pc: Int) -> String {
        formatNoteName(chromaticASCII[clampPitchClass(pc)])
    }

    static func formatNoteName(_ name: String) -> String {
        if name.hasSuffix("##") {
            return String(name.dropLast(2)) + "𝄪"
        }
        if name.hasSuffix("#") {
            return String(name.dropLast()) + "♯"
        }
        if name.hasSuffix("bb") {
            return String(name.dropLast(2)) + "𝄫"
        }
        if name.hasSuffix("b") {
            return String(name.dropLast()) + "♭"
        }
        return name
    }

    static func formatWholeTones(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }

    static func clampPitchClass(_ value: Int) -> Int {
        var v = value % 12
        if v < 0 { v += 12 }
        return v
    }

    static func clampDistance(_ value: Int) -> Int {
        min(12, max(0, value))
    }
}
