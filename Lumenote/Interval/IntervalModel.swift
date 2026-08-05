//

import Foundation

/// Interactive interval explorer: root pitch + semitone distance on a one-octave ruler.
///
/// The ruler visualizes **pitch distance** (semitones / whole tones).
/// Interval names follow semitone count; at the tritone (6 semitones) the
/// aug-4th / dim-5th spelling follows `accidentalPreference`.
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

    /// Sharp (♯) or flat (♭) spelling for chromatic notes and the tritone interval name.
    var accidentalPreference: AccidentalPreference = .sharp

    // MARK: - Derived

    var rootDisplayName: String {
        Self.displayName(forPitchClass: rootPitchClass, preference: accidentalPreference)
    }

    /// Target note name. Distance 12 reuses the root spelling (octave).
    var targetDisplayName: String {
        if semitoneDistance == 12 {
            return rootDisplayName
        }
        let pc = (rootPitchClass + semitoneDistance) % 12
        return Self.displayName(forPitchClass: pc, preference: accidentalPreference)
    }

    /// Whole-tone equivalent of the current semitone distance.
    var wholeTones: Double {
        Double(semitoneDistance) / 2.0
    }

    /// Korean interval name; tritone splits into 증4도 vs 감5도 by preference.
    var intervalName: String {
        if semitoneDistance == Self.tritoneDistance {
            return accidentalPreference == .sharp ? "증4도" : "감5도"
        }
        return Self.intervalNames[semitoneDistance]
    }

    /// English interval name; tritone splits into Augmented 4th vs Diminished 5th.
    var intervalNameEnglish: String {
        if semitoneDistance == Self.tritoneDistance {
            return accidentalPreference == .sharp ? "Augmented 4th" : "Diminished 5th"
        }
        return Self.intervalNamesEnglish[semitoneDistance]
    }

    var distanceDescription: String {
        "\(Self.formatWholeTones(wholeTones))온음 · \(semitoneDistance)반음"
    }

    /// Chromatic target options for one octave starting at the root (distance 0…12).
    var targetOptions: [(distance: Int, displayName: String)] {
        (0...12).map { distance in
            let name: String
            if distance == 12 {
                name = rootDisplayName
            } else {
                let pc = (rootPitchClass + distance) % 12
                name = Self.displayName(forPitchClass: pc, preference: accidentalPreference)
            }
            return (distance, name)
        }
    }

    /// All selectable roots for the picker.
    var rootOptions: [(pitchClass: Int, displayName: String)] {
        (0..<12).map { pitchClass in
            (
                pitchClass,
                Self.displayName(forPitchClass: pitchClass, preference: accidentalPreference)
            )
        }
    }

    // MARK: - Tables

    private static let tritoneDistance = 6

    private static let chromaticSharp: [String] = [
        "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
    ]

    private static let chromaticFlat: [String] = [
        "C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"
    ]

    /// Semitone index 0…12 → Korean interval name (tritone handled separately).
    private static let intervalNames: [String] = [
        "완전1도",
        "단2도",
        "장2도",
        "단3도",
        "장3도",
        "완전4도",
        "증4도", // overridden at runtime for flat preference
        "완전5도",
        "단6도",
        "장6도",
        "단7도",
        "장7도",
        "완전8도",
    ]

    /// Semitone index 0…12 → English interval name (tritone handled separately).
    private static let intervalNamesEnglish: [String] = [
        "Perfect Unison",
        "Minor 2nd",
        "Major 2nd",
        "Minor 3rd",
        "Major 3rd",
        "Perfect 4th",
        "Augmented 4th", // overridden at runtime for flat preference
        "Perfect 5th",
        "Minor 6th",
        "Major 6th",
        "Minor 7th",
        "Major 7th",
        "Perfect Octave",
    ]

    // MARK: - Helpers

    static func displayName(
        forPitchClass pc: Int,
        preference: AccidentalPreference
    ) -> String {
        let table = preference == .sharp ? chromaticSharp : chromaticFlat
        return formatNoteName(table[clampPitchClass(pc)])
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
