//

import Foundation

/// Interactive interval explorer: root pitch + semitone distance on a one-octave ruler.
///
/// The ruler visualizes **pitch distance** (semitones / whole tones).
/// Interval names are derived from root and target **spellings** (letter + accidental),
/// so enharmonic pairs such as minor 2nd vs augmented unison follow `accidentalPreference`.
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

    /// Sharp (♯) or flat (♭) spelling for chromatic notes and spelling-aware interval names.
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

    /// Korean interval name from root/target spellings.
    var intervalName: String {
        Self.koreanIntervalName(
            root: rootSpelling,
            target: targetSpelling,
            semitones: semitoneDistance
        )
    }

    /// English interval name from root/target spellings.
    var intervalNameEnglish: String {
        Self.englishIntervalName(
            root: rootSpelling,
            target: targetSpelling,
            semitones: semitoneDistance
        )
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

    // MARK: - Internal spellings

    private var rootSpelling: String {
        Self.spelling(forPitchClass: rootPitchClass, preference: accidentalPreference)
    }

    private var targetSpelling: String {
        if semitoneDistance == 12 {
            return rootSpelling
        }
        let pc = (rootPitchClass + semitoneDistance) % 12
        return Self.spelling(forPitchClass: pc, preference: accidentalPreference)
    }

    // MARK: - Tables

    private static let chromaticSharp: [String] = [
        "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
    ]

    private static let chromaticFlat: [String] = [
        "C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"
    ]

    /// Major/perfect reference semitones for diatonic numbers 1…8.
    private static let referenceSemitones: [Int] = [0, 0, 2, 4, 5, 7, 9, 11, 12]

    private static let perfectIntervalNumbers: Set<Int> = [1, 4, 5, 8]

    private static let letterIndices: [Character: Int] = [
        "C": 0, "D": 1, "E": 2, "F": 3, "G": 4, "A": 5, "B": 6
    ]

    /// Fallback when spelling-based naming cannot resolve (should not occur for chromatic tables).
    private static let fallbackIntervalNames: [String] = [
        "완전1도",
        "단2도",
        "장2도",
        "단3도",
        "장3도",
        "완전4도",
        "증4도",
        "완전5도",
        "단6도",
        "장6도",
        "단7도",
        "장7도",
        "완전8도",
    ]

    private static let fallbackIntervalNamesEnglish: [String] = [
        "Perfect Unison",
        "Minor 2nd",
        "Major 2nd",
        "Minor 3rd",
        "Major 3rd",
        "Perfect 4th",
        "Augmented 4th",
        "Perfect 5th",
        "Minor 6th",
        "Major 6th",
        "Minor 7th",
        "Major 7th",
        "Perfect Octave",
    ]

    // MARK: - Spelling-aware interval naming

    private static func koreanIntervalName(root: String, target: String, semitones: Int) -> String {
        guard let number = diatonicNumber(root: root, target: target),
              let offset = qualityOffset(intervalNumber: number, semitones: semitones),
              let name = koreanName(intervalNumber: number, offset: offset)
        else {
            return fallbackIntervalNames[clampDistance(semitones)]
        }
        return name
    }

    private static func englishIntervalName(root: String, target: String, semitones: Int) -> String {
        guard let number = diatonicNumber(root: root, target: target),
              let offset = qualityOffset(intervalNumber: number, semitones: semitones),
              let name = englishName(intervalNumber: number, offset: offset)
        else {
            return fallbackIntervalNamesEnglish[clampDistance(semitones)]
        }
        return name
    }

    private static func diatonicNumber(root: String, target: String) -> Int? {
        guard let rootLetter = letterIndex(of: root),
              let targetLetter = letterIndex(of: target)
        else { return nil }
        let steps = (targetLetter - rootLetter + 7) % 7
        return steps + 1
    }

    private static func qualityOffset(intervalNumber: Int, semitones: Int) -> Int? {
        guard intervalNumber >= 1, intervalNumber <= 8 else { return nil }
        return semitones - referenceSemitones[intervalNumber]
    }

    private static func koreanName(intervalNumber: Int, offset: Int) -> String? {
        if perfectIntervalNumbers.contains(intervalNumber) {
            switch offset {
            case -1 where intervalNumber != 1:
                return "감\(intervalNumber)도"
            case 0:
                switch intervalNumber {
                case 1: return "완전1도"
                case 8: return "완전8도"
                default: return "완전\(intervalNumber)도"
                }
            case 1:
                if intervalNumber == 8 { return "증7도" }
                return "증\(intervalNumber)도"
            default:
                return nil
            }
        }

        switch offset {
        case -2: return "감\(intervalNumber)도"
        case -1: return "단\(intervalNumber)도"
        case 0: return "장\(intervalNumber)도"
        case 1: return "증\(intervalNumber)도"
        default: return nil
        }
    }

    private static func englishName(intervalNumber: Int, offset: Int) -> String? {
        let ordinal = englishOrdinal(intervalNumber: intervalNumber)

        if perfectIntervalNumbers.contains(intervalNumber) {
            switch offset {
            case -1 where intervalNumber != 1:
                return "Diminished \(ordinal)"
            case 0:
                switch intervalNumber {
                case 1: return "Perfect Unison"
                case 8: return "Perfect Octave"
                default: return "Perfect \(ordinal)"
                }
            case 1:
                if intervalNumber == 8 { return "Augmented 7th" }
                return "Augmented \(ordinal)"
            default:
                return nil
            }
        }

        switch offset {
        case -2: return "Diminished \(ordinal)"
        case -1: return "Minor \(ordinal)"
        case 0: return "Major \(ordinal)"
        case 1: return "Augmented \(ordinal)"
        default: return nil
        }
    }

    private static func englishOrdinal(intervalNumber: Int) -> String {
        switch intervalNumber {
        case 1: return "Unison"
        case 2: return "2nd"
        case 3: return "3rd"
        case 4: return "4th"
        case 5: return "5th"
        case 6: return "6th"
        case 7: return "7th"
        case 8: return "Octave"
        default: return "\(intervalNumber)th"
        }
    }

    private static func letterIndex(of spelling: String) -> Int? {
        guard let first = spelling.first else { return nil }
        return letterIndices[first]
    }

    // MARK: - Helpers

    static func spelling(forPitchClass pc: Int, preference: AccidentalPreference) -> String {
        let table = preference == .sharp ? chromaticSharp : chromaticFlat
        return table[clampPitchClass(pc)]
    }

    static func displayName(
        forPitchClass pc: Int,
        preference: AccidentalPreference
    ) -> String {
        formatNoteName(spelling(forPitchClass: pc, preference: preference))
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
