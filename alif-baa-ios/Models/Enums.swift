//
//  Enums.swift
//  alif-baa-ios
//
//  Domain choices surfaced by onboarding (§3.2) and the harakat (§4.2 D).
//

import Foundation

/// Onboarding step 1 — "What is your Arabic reading level?" (§3.2).
enum ReadingLevel: String, CaseIterable, Identifiable {
    case beginner
    case knowAlphabet
    case canRead
    case knowTajweed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beginner: return "A beginner"
        case .knowAlphabet: return "I know the alphabet"
        case .canRead: return "I can read"
        case .knowTajweed: return "I know tajweed"
        }
    }

    var hint: String {
        switch self {
        case .beginner: return "Starting from zero"
        case .knowAlphabet: return "Ready to read words"
        case .canRead: return "Want to strengthen fluency"
        case .knowTajweed: return "Polishing recitation rules"
        }
    }

    /// Progress meter shown on the option card (25 / 50 / 75 / 100%).
    var meter: Double {
        switch self {
        case .beginner: return 0.25
        case .knowAlphabet: return 0.5
        case .canRead: return 0.75
        case .knowTajweed: return 1.0
        }
    }

    /// Non-beginners fast-forward: all letter lessons unlock as review (§4.3, MVP-partial).
    var unlocksAllLessons: Bool { self != .beginner }
}

/// Onboarding step 2 — "What program do you prefer?" (§3.2).
enum ProgramChoice: String, CaseIterable, Identifiable {
    case fast
    case thorough
    case straightToReading

    var id: String { rawValue }

    var badge: String {
        switch self {
        case .fast: return "F"
        case .thorough: return "T"
        case .straightToReading: return "S"
        }
    }

    var title: String {
        switch self {
        case .fast: return "Fast"
        case .thorough: return "Thorough"
        case .straightToReading: return "Go straight to reading"
        }
    }

    var subtitle: String {
        switch self {
        case .fast:
            return "Alphabet without revision lessons — the quickest route through the 28 letters"
        case .thorough:
            return "Includes revision lessons that re-test earlier letter groups via SRS before advancing"
        case .straightToReading:
            return "Skips letter-form drilling; only appropriate for learners who already know the alphabet"
        }
    }

    /// "Go straight to reading" is gated to non-beginner reading levels (§3.2, §4.3).
    func isAvailable(for level: ReadingLevel?) -> Bool {
        self != .straightToReading || (level.map { $0 != .beginner } ?? false)
    }
}

/// The three short vowels (§4.2 D).
enum Harakat: String, CaseIterable, Identifiable {
    case fatha
    case damma
    case kasra

    var id: String { rawValue }

    var mark: String {
        switch self {
        case .fatha: return "\u{064E}"   // َ
        case .damma: return "\u{064F}"   // ُ
        case .kasra: return "\u{0650}"   // ِ
        }
    }

    var name: String {
        switch self {
        case .fatha: return "Fatha"
        case .damma: return "Damma"
        case .kasra: return "Kasra"
        }
    }

    var vowelSound: String {
        switch self {
        case .fatha: return "a"
        case .damma: return "u"
        case .kasra: return "i"
        }
    }

    /// Placeholder-tone pitch shift until real recordings ship (§4.6).
    var toneMultiplier: Double {
        switch self {
        case .fatha: return 1.0
        case .damma: return 1.26
        case .kasra: return 0.84
        }
    }
}

/// Item learning status derived from SRS state (§5.3).
enum LearningStatus {
    case notStarted   // ○
    case inProgress   // ◑  seen, but < 80% correct
    case learned      // ●  ≥ 80% correct
    case mastered     // ★  reviewed across 1 → 7 → 30 days
}

/// Letter positional forms (§5.4).
enum LetterPosition: String, CaseIterable {
    case isolated, initial, medial, final
}
