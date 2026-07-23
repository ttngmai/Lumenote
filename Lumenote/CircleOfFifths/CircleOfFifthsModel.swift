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

    /// Clock position of the tonic (aligned to the fixed 12 o'clock pointer after rotation).
    var tonicArrowPosition: Int {
        selectedTonic.lydianStartPosition
    }

    /// Where the Major/Minor/Dim quality segment begins on the active arc.
    var chordRingStartPosition: Int {
        Self.normalizedClock(selectedTonic.lydianStartPosition + selectedMode.offset)
    }

    /// Chord quality for an active model clock position, if any.
    func chordQuality(at position: Int) -> ChordQuality? {
        guard let ordinal = activePositions.firstIndex(of: position) else { return nil }
        return ChordQuality.quality(forOrdinal: ordinal)
    }

    /// Chord quality for a fixed screen clock wedge when the tonic is pinned at 12 o'clock.
    /// Screen position 12 is the tonic; qualities depend only on the selected mode.
    func screenChordQuality(atScreenClock position: Int) -> ChordQuality? {
        let stepsFromTonic = position % 12 // 12 → 0, 1 → 1, …
        for ordinal in 0..<7 {
            let steps = Self.normalizedClock(12 + selectedMode.offset + ordinal) % 12
            if steps == stepsFromTonic {
                return ChordQuality.quality(forOrdinal: ordinal)
            }
        }
        return nil
    }

    /// Relative-minor tonic spelling for the major key whose tonic is at `position`.
    var relativeMinorNames: [Int: String] {
        var result: [Int: String] = [:]
        for position in 1...12 {
            guard let major = noteNames[position],
                  let relative = Self.relativeMinor(ofMajor: major) else { continue }
            result[position] = relative
        }
        return result
    }

    /// Rotation (degrees) that brings the selected tonic to 12 o'clock.
    var tonicAlignmentRotationDegrees: Double {
        -Double(tonicArrowPosition % 12) * 30.0
    }

    /// Select the tonic whose Lydian start matches `position`, preferring the current
    /// enharmonic spelling when possible, otherwise a non-obscure spelling.
    func selectTonic(forLydianStart position: Int) {
        let normalized = Self.normalizedClock(position)
        let matches = Tonic.allCases.filter { $0.lydianStartPosition == normalized }
        if matches.contains(selectedTonic) { return }
        if let preferred = matches.first(where: { !$0.isObscure }) {
            selectedTonic = preferred
        } else if let first = matches.first {
            selectedTonic = first
        }
    }

    /// Clock position implied by a circle rotation in degrees.
    static func lydianStartPosition(forRotationDegrees degrees: Double) -> Int {
        var steps = Int(((-degrees / 30.0).rounded())) % 12
        if steps < 0 { steps += 12 }
        return steps == 0 ? 12 : steps
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

    /// Scale tones (degree + note) in ascending order from the tonic.
    var scaleTones: [ScaleTone] {
        let names = noteNames
        let degrees = degreeLabels
        let rows: [(pc: Int, position: Int, roman: String, note: String)] = activePositions.compactMap { position in
            guard let name = names[position],
                  let roman = degrees[position],
                  let pc = Self.pitchClass(of: name) else {
                return nil
            }
            return (pc, position, roman, Tonic.formatNoteName(name))
        }

        guard let tonicPC = Self.pitchClass(of: selectedTonic.rawValue) else {
            return rows.enumerated().map { index, row in
                ScaleTone(
                    scaleDegree: index + 1,
                    degree: row.roman,
                    note: row.note,
                    clockPosition: row.position
                )
            }
        }

        return rows
            .sorted { lhs, rhs in
                let l = (lhs.pc - tonicPC + 12) % 12
                let r = (rhs.pc - tonicPC + 12) % 12
                return l < r
            }
            .enumerated()
            .map { index, row in
                ScaleTone(
                    scaleDegree: index + 1,
                    degree: row.roman,
                    note: row.note,
                    clockPosition: row.position
                )
            }
    }

    /// Scale notes in ascending order from the tonic.
    var diatonicScaleNotes: [String] {
        scaleTones.map(\.note)
    }

    /// Mode character block: one-line comparison, formula, and characteristic note/chord.
    var modeCharacter: ModeCharacter {
        let profile = selectedMode.characterProfile
        let tones = scaleTones

        func tone(atScaleDegree degree: Int) -> ScaleTone? {
            tones.first { $0.scaleDegree == degree }
        }

        let characteristicNote: ModeCharacter.Highlight?
        if let degree = profile.characteristicNoteDegree,
           let tone = tone(atScaleDegree: degree) {
            characteristicNote = ModeCharacter.Highlight(
                text: "\(tone.note)  \(profile.characteristicIntervalLabel)",
                scaleDegree: degree,
                clockPosition: tone.clockPosition
            )
        } else {
            characteristicNote = nil
        }

        let characteristicChord: ModeCharacter.Highlight?
        if let degree = profile.characteristicChordDegree,
           let tone = tone(atScaleDegree: degree) {
            let quality = chordQuality(at: tone.clockPosition).map(Self.chordQualityEnglishName) ?? ""
            let qualityPart = quality.isEmpty ? "" : " \(quality)"
            characteristicChord = ModeCharacter.Highlight(
                text: "\(tone.note)\(qualityPart) · \(tone.degree)",
                scaleDegree: degree,
                clockPosition: tone.clockPosition
            )
        } else {
            characteristicChord = nil
        }

        return ModeCharacter(
            summary: profile.summary,
            formula: profile.formula,
            characteristicNote: characteristicNote,
            characteristicChord: characteristicChord
        )
    }

    /// Model-clock positions temporarily emphasized (e.g. characteristic note tap).
    var emphasizedClockPositions: Set<Int> = []
    /// Scale degrees 1…7 temporarily emphasized in the Scale table / formula.
    var emphasizedScaleDegrees: Set<Int> = []

    func emphasize(scaleDegree: Int, clockPosition: Int) {
        emphasizedScaleDegrees = [scaleDegree]
        emphasizedClockPositions = [clockPosition]
    }

    func emphasize(scaleDegrees: Set<Int>) {
        emphasizedScaleDegrees = scaleDegrees
        emphasizedClockPositions = Set(
            scaleTones
                .filter { scaleDegrees.contains($0.scaleDegree) }
                .map(\.clockPosition)
        )
    }

    func clearEmphasis() {
        emphasizedScaleDegrees = []
        emphasizedClockPositions = []
    }

    /// Screen-clock wedge for a model-clock position when tonic is pinned at 12.
    func screenClock(forModelPosition position: Int) -> Int {
        Self.normalizedClock(position - tonicArrowPosition)
    }

    // MARK: - Types

    struct ScaleTone: Identifiable, Equatable {
        let scaleDegree: Int
        let degree: String
        let note: String
        let clockPosition: Int

        var id: String { "\(scaleDegree)-\(degree)-\(note)" }
    }

    struct ModeCharacter: Equatable {
        let summary: String
        let formula: [FormulaTone]
        let characteristicNote: Highlight?
        let characteristicChord: Highlight?

        struct FormulaTone: Identifiable, Equatable {
            let scaleDegree: Int
            let symbol: String
            let isEmphasized: Bool

            var id: Int { scaleDegree }
        }

        struct Highlight: Equatable {
            let text: String
            let scaleDegree: Int
            let clockPosition: Int
        }
    }

    struct ModeCharacterProfile {
        let summary: String
        let formula: [ModeCharacter.FormulaTone]
        /// Nil for Ionian / Aeolian (no distinctive note beyond the parent scale).
        let characteristicNoteDegree: Int?
        let characteristicIntervalLabel: String
        let characteristicChordDegree: Int?
    }

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

        /// Short subtitle for the mode picker (same as Mode Character summary).
        var characterSummary: String {
            characterProfile.summary
        }

        var characterProfile: ModeCharacterProfile {
            switch self {
            case .lydian:
                return ModeCharacterProfile(
                    summary: "메이저 + 증4도",
                    formula: Self.formula([
                        (1, "1", false), (2, "2", false), (3, "3", false),
                        (4, "♯4", true), (5, "5", false), (6, "6", false), (7, "7", false)
                    ]),
                    characteristicNoteDegree: 4,
                    characteristicIntervalLabel: "Augmented 4th",
                    characteristicChordDegree: 2
                )
            case .ionian:
                return ModeCharacterProfile(
                    summary: "일반적인 메이저",
                    formula: Self.formula([
                        (1, "1", false), (2, "2", false), (3, "3", false),
                        (4, "4", false), (5, "5", false), (6, "6", false), (7, "7", false)
                    ]),
                    characteristicNoteDegree: nil,
                    characteristicIntervalLabel: "",
                    characteristicChordDegree: nil
                )
            case .mixolydian:
                return ModeCharacterProfile(
                    summary: "메이저 + 단7도",
                    formula: Self.formula([
                        (1, "1", false), (2, "2", false), (3, "3", false),
                        (4, "4", false), (5, "5", false), (6, "6", false), (7, "♭7", true)
                    ]),
                    characteristicNoteDegree: 7,
                    characteristicIntervalLabel: "Minor 7th",
                    characteristicChordDegree: 7
                )
            case .dorian:
                return ModeCharacterProfile(
                    summary: "마이너 + 장6도",
                    formula: Self.formula([
                        (1, "1", false), (2, "2", false), (3, "♭3", true),
                        (4, "4", false), (5, "5", false), (6, "6", true), (7, "♭7", true)
                    ]),
                    characteristicNoteDegree: 6,
                    characteristicIntervalLabel: "Major 6th",
                    characteristicChordDegree: 4
                )
            case .aeolian:
                return ModeCharacterProfile(
                    summary: "일반적인 내추럴 마이너",
                    formula: Self.formula([
                        (1, "1", false), (2, "2", false), (3, "♭3", false),
                        (4, "4", false), (5, "5", false), (6, "♭6", false), (7, "♭7", false)
                    ]),
                    characteristicNoteDegree: nil,
                    characteristicIntervalLabel: "",
                    characteristicChordDegree: nil
                )
            case .phrygian:
                return ModeCharacterProfile(
                    summary: "마이너 + 단2도",
                    formula: Self.formula([
                        (1, "1", false), (2, "♭2", true), (3, "♭3", true),
                        (4, "4", false), (5, "5", false), (6, "♭6", true), (7, "♭7", true)
                    ]),
                    characteristicNoteDegree: 2,
                    characteristicIntervalLabel: "Minor 2nd",
                    characteristicChordDegree: 2
                )
            case .locrian:
                return ModeCharacterProfile(
                    summary: "마이너 + 감5도",
                    formula: Self.formula([
                        (1, "1", false), (2, "♭2", true), (3, "♭3", true),
                        (4, "4", false), (5, "♭5", true), (6, "♭6", true), (7, "♭7", true)
                    ]),
                    characteristicNoteDegree: 5,
                    characteristicIntervalLabel: "Diminished 5th",
                    characteristicChordDegree: 5
                )
            }
        }

        private static func formula(
            _ degrees: [(Int, String, Bool)]
        ) -> [ModeCharacter.FormulaTone] {
            degrees.map { ModeCharacter.FormulaTone(scaleDegree: $0.0, symbol: $0.1, isEmphasized: $0.2) }
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

    private static func chordQualityEnglishName(_ quality: ChordQuality) -> String {
        switch quality {
        case .major: return "Major"
        case .minor: return "Minor"
        case .diminished: return "Dim"
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

    /// Relative minor tonic of a major tonic note (minor 3rd below), with matching spelling.
    private static func relativeMinor(ofMajor name: String) -> String? {
        guard let majorPC = pitchClass(of: name), let first = name.first else { return nil }
        let letters: [Character] = ["C", "D", "E", "F", "G", "A", "B"]
        guard let letterIndex = letters.firstIndex(of: first) else { return nil }

        let minorLetter = letters[(letterIndex + 5) % 7] // two letters down
        let targetPC = (majorPC - 3 + 12) % 12
        let basePC = pitchClass(of: String(minorLetter)) ?? 0
        var accidental = targetPC - basePC
        if accidental > 6 { accidental -= 12 }
        if accidental < -6 { accidental += 12 }

        let suffix: String
        switch accidental {
        case 2: suffix = "##"
        case 1: suffix = "#"
        case 0: suffix = ""
        case -1: suffix = "b"
        case -2: suffix = "bb"
        default: return nil
        }
        return String(minorLetter) + suffix
    }
}
