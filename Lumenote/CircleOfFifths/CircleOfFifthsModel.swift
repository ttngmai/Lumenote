//

import Foundation
import SwiftUI

/// Interactive Circle of Fifths model, based on Rand Scullard's design:
/// https://randscullard.com/CircleOfFifths/
@Observable
final class CircleOfFifthsModel {
    var selectedTonic: Tonic = .c
    var selectedMode: MusicalMode = .ionian

    /// Clock positions 1…12 → note names for the current tonic/mode.
    var noteNames: [Int: String] {
        let signature = Self.keySignatures[keySignatureIndex] ?? Self.keySignatures[0]!
        var result: [Int: String] = [:]
        for position in 1...12 {
            result[position] = signature[position - 1]
        }
        return result
    }

    /// Seven consecutive active (diatonic) clock positions, in clockwise order.
    var activePositions: [Int] {
        let start = selectedTonic.lydianStartPosition + selectedMode.offset
        return (0..<7).map { Self.normalizedClock(start + $0) }
    }

    var activePositionSet: Set<Int> {
        Set(activePositions)
    }

    /// Clock position → Roman-numeral degree label (only for active notes).
    var degreeLabels: [Int: String] {
        var degrees = Self.lydianDegrees
        for _ in 0..<abs(selectedMode.offset) {
            if let last = degrees.popLast() {
                degrees.insert(last, at: 0)
            }
        }

        var result: [Int: String] = [:]
        for (ordinal, position) in activePositions.enumerated() {
            result[position] = Self.makeDegreeSymbol(degree: degrees[ordinal], ordinal: ordinal)
        }
        return result
    }

    /// Clock position of the tonic arrow.
    var tonicArrowPosition: Int {
        selectedTonic.lydianStartPosition
    }

    /// Where the Major/Minor/Dim chord-ring segment begins.
    var chordRingStartPosition: Int {
        Self.normalizedClock(selectedTonic.lydianStartPosition + selectedMode.offset)
    }

    var keySignatureIndex: Int {
        selectedTonic.lydianSignature + selectedMode.offset
    }

    var sharpsOrFlatsDescription: String {
        let index = keySignatureIndex
        if index == 0 {
            return "조표 없음"
        } else if index > 0 {
            return "♯ \(index)개"
        } else {
            return "♭ \(abs(index))개"
        }
    }

    var selectedKeyTitle: String {
        "\(selectedTonic.displayName) \(selectedMode.shortName)"
    }

    /// Scale notes in ascending order from the tonic.
    var diatonicScaleNotes: [String] {
        let names = noteNames
        let pitchClasses: [(pc: Int, name: String)] = activePositionSet.compactMap { position in
            guard let name = names[position], let pc = Self.pitchClass(of: name) else {
                return nil
            }
            return (pc, name)
        }

        guard let tonicPC = Self.pitchClass(of: selectedTonic.rawValue) else {
            return pitchClasses.map { Tonic.formatNoteName($0.name) }
        }

        return pitchClasses
            .sorted { lhs, rhs in
                let l = (lhs.pc - tonicPC + 12) % 12
                let r = (rhs.pc - tonicPC + 12) % 12
                return l < r
            }
            .map { Tonic.formatNoteName($0.name) }
    }

    // MARK: - Types

    enum Tonic: String, CaseIterable, Identifiable {
        case bSharp = "B#"
        case eSharp = "E#"
        case aSharp = "A#"
        case dSharp = "D#"
        case gSharp = "G#"
        case cSharp = "C#"
        case fSharp = "F#"
        case b = "B"
        case e = "E"
        case a = "A"
        case d = "D"
        case g = "G"
        case c = "C"
        case f = "F"
        case bFlat = "Bb"
        case eFlat = "Eb"
        case aFlat = "Ab"
        case dFlat = "Db"
        case gFlat = "Gb"
        case cFlat = "Cb"
        case fFlat = "Fb"

        var id: String { rawValue }

        var displayName: String {
            Self.formatNoteName(rawValue)
        }

        /// Rare tonics shown gray in the original table.
        var isObscure: Bool {
            switch self {
            case .bSharp, .eSharp, .aSharp, .dSharp, .gSharp, .fFlat:
                return true
            default:
                return false
            }
        }

        /// Clock position where Lydian of this tonic begins.
        var lydianStartPosition: Int {
            switch self {
            case .bSharp: return 12
            case .eSharp: return 11
            case .aSharp: return 10
            case .dSharp: return 9
            case .gSharp: return 8
            case .cSharp: return 7
            case .fSharp: return 6
            case .b: return 5
            case .e: return 4
            case .a: return 3
            case .d: return 2
            case .g: return 1
            case .c: return 12
            case .f: return 11
            case .bFlat: return 10
            case .eFlat: return 9
            case .aFlat: return 8
            case .dFlat: return 7
            case .gFlat: return 6
            case .cFlat: return 5
            case .fFlat: return 4
            }
        }

        /// Key-signature index for this tonic in Lydian.
        var lydianSignature: Int {
            switch self {
            case .bSharp: return 13
            case .eSharp: return 12
            case .aSharp: return 11
            case .dSharp: return 10
            case .gSharp: return 9
            case .cSharp: return 8
            case .fSharp: return 7
            case .b: return 6
            case .e: return 5
            case .a: return 4
            case .d: return 3
            case .g: return 2
            case .c: return 1
            case .f: return 0
            case .bFlat: return -1
            case .eFlat: return -2
            case .aFlat: return -3
            case .dFlat: return -4
            case .gFlat: return -5
            case .cFlat: return -6
            case .fFlat: return -7
            }
        }

        static func formatNoteName(_ name: String) -> String {
            if name.hasSuffix("##") {
                return String(name.dropLast(2)) + "𝄪"
            }
            if name.hasSuffix("bb") {
                return String(name.dropLast(2)) + "𝄫"
            }
            if name.hasSuffix("#") {
                return String(name.dropLast()) + "♯"
            }
            if name.hasSuffix("b") {
                return String(name.dropLast()) + "♭"
            }
            return name
        }
    }

    enum MusicalMode: String, CaseIterable, Identifiable {
        case lydian
        case ionian
        case mixolydian
        case dorian
        case aeolian
        case phrygian
        case locrian

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .lydian: return "Lydian"
            case .ionian: return "Major / Ionian"
            case .mixolydian: return "Mixolydian"
            case .dorian: return "Dorian"
            case .aeolian: return "N. Minor / Aeolian"
            case .phrygian: return "Phrygian"
            case .locrian: return "Locrian"
            }
        }

        var shortName: String {
            switch self {
            case .lydian: return "Lydian"
            case .ionian: return "Major"
            case .mixolydian: return "Mixolydian"
            case .dorian: return "Dorian"
            case .aeolian: return "Minor"
            case .phrygian: return "Phrygian"
            case .locrian: return "Locrian"
            }
        }

        /// Steps counterclockwise from Lydian.
        var offset: Int {
            switch self {
            case .lydian: return 0
            case .ionian: return -1
            case .mixolydian: return -2
            case .dorian: return -3
            case .aeolian: return -4
            case .phrygian: return -5
            case .locrian: return -6
            }
        }
    }

    enum ChordQuality {
        case major
        case minor
        case diminished

        static func quality(forOrdinal ordinal: Int) -> ChordQuality {
            switch ordinal {
            case 0, 1, 2: return .major
            case 3, 4, 5: return .minor
            default: return .diminished
            }
        }
    }

    // MARK: - Tables from CircleOfFifths.js

    /// Scale degrees for Lydian around the circle (clockwise from start).
    private static let lydianDegrees = [1, 5, 2, 6, 3, 7, 4]

    /// Key-signature index → note names at clock positions 1…12.
    private static let keySignatures: [Int: [String]] = [
        -13: ["Abb", "Ebb", "Bbb", "Fb", "Cb", "Gb", "Db", "Ab", "Eb", "Cbb", "Gbb", "Dbb"],
        -12: ["Abb", "Ebb", "Bbb", "Fb", "Cb", "Gb", "Db", "Ab", "Eb", "Bb", "Gbb", "Dbb"],
        -11: ["Abb", "Ebb", "Bbb", "Fb", "Cb", "Gb", "Db", "Ab", "Eb", "Bb", "F", "Dbb"],
        -10: ["Abb", "Ebb", "Bbb", "Fb", "Cb", "Gb", "Db", "Ab", "Eb", "Bb", "F", "C"],
        -9: ["G", "Ebb", "Bbb", "Fb", "Cb", "Gb", "Db", "Ab", "Eb", "Bb", "F", "C"],
        -8: ["G", "D", "Bbb", "Fb", "Cb", "Gb", "Db", "Ab", "Eb", "Bb", "F", "C"],
        -7: ["G", "D", "A", "Fb", "Cb", "Gb", "Db", "Ab", "Eb", "Bb", "F", "C"],
        -6: ["G", "D", "A", "E", "Cb", "Gb", "Db", "Ab", "Eb", "Bb", "F", "C"],
        -5: ["G", "D", "A", "E", "B", "Gb", "Db", "Ab", "Eb", "Bb", "F", "C"],
        -4: ["G", "D", "A", "E", "B", "F#", "Db", "Ab", "Eb", "Bb", "F", "C"],
        -3: ["G", "D", "A", "E", "B", "F#", "Db", "Ab", "Eb", "Bb", "F", "C"],
        -2: ["G", "D", "A", "E", "B", "F#", "Db", "Ab", "Eb", "Bb", "F", "C"],
        -1: ["G", "D", "A", "E", "B", "F#", "Db", "Ab", "Eb", "Bb", "F", "C"],
        0: ["G", "D", "A", "E", "B", "F#", "Db", "Ab", "Eb", "Bb", "F", "C"],
        1: ["G", "D", "A", "E", "B", "F#", "Db", "Ab", "Eb", "Bb", "F", "C"],
        2: ["G", "D", "A", "E", "B", "F#", "C#", "Ab", "Eb", "Bb", "F", "C"],
        3: ["G", "D", "A", "E", "B", "F#", "C#", "G#", "Eb", "Bb", "F", "C"],
        4: ["G", "D", "A", "E", "B", "F#", "C#", "G#", "D#", "Bb", "F", "C"],
        5: ["G", "D", "A", "E", "B", "F#", "C#", "G#", "D#", "A#", "F", "C"],
        6: ["G", "D", "A", "E", "B", "F#", "C#", "G#", "D#", "A#", "E#", "C"],
        7: ["G", "D", "A", "E", "B", "F#", "C#", "G#", "D#", "A#", "E#", "B#"],
        8: ["F##", "D", "A", "E", "B", "F#", "C#", "G#", "D#", "A#", "E#", "B#"],
        9: ["F##", "C##", "A", "E", "B", "F#", "C#", "G#", "D#", "A#", "E#", "B#"],
        10: ["F##", "C##", "G##", "E", "B", "F#", "C#", "G#", "D#", "A#", "E#", "B#"],
        11: ["F##", "C##", "G##", "D##", "B", "F#", "C#", "G#", "D#", "A#", "E#", "B#"],
        12: ["F##", "C##", "G##", "D##", "A##", "F#", "C#", "G#", "D#", "A#", "E#", "B#"],
        13: ["F##", "C##", "G##", "D##", "A##", "E##", "C#", "G#", "D#", "A#", "E#", "B#"]
    ]

    static func normalizedClock(_ position: Int) -> Int {
        var clock = position
        while clock < 1 { clock += 12 }
        while clock > 12 { clock -= 12 }
        return clock
    }

    private static func makeDegreeSymbol(degree: Int, ordinal: Int) -> String {
        let romans = ["i", "ii", "iii", "iv", "v", "vi", "vii"]
        guard degree >= 1, degree <= 7 else { return "" }
        let roman = romans[degree - 1]
        switch ChordQuality.quality(forOrdinal: ordinal) {
        case .major:
            return roman.uppercased()
        case .diminished:
            return roman + "°"
        case .minor:
            return roman
        }
    }

    private static func pitchClass(of name: String) -> Int? {
        let letterMap: [Character: Int] = [
            "C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11
        ]
        guard let first = name.first, let base = letterMap[first] else { return nil }
        var pc = base
        let accidentals = String(name.dropFirst())
        if accidentals.hasSuffix("##") {
            pc += 2
        } else if accidentals.hasSuffix("bb") {
            pc -= 2
        } else if accidentals.hasSuffix("#") {
            pc += 1
        } else if accidentals.hasSuffix("b") {
            pc -= 1
        }
        return (pc % 12 + 12) % 12
    }
}
