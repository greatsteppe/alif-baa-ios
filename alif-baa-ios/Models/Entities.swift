//
//  Entities.swift
//  alif-baa-ios
//
//  SwiftData model per PRD §5.4. 100% local — no server, no account (§5).
//

import Foundation
import SwiftData

/// A letter of the alphabet.
@Model
final class Letter {
    @Attribute(.unique) var id: Int
    var arabic: String
    var nameAr: String
    var nameEn: String
    var transliteration: String
    var audioFile: String

    init(id: Int, arabic: String, nameAr: String, nameEn: String, transliteration: String, audioFile: String) {
        self.id = id
        self.arabic = arabic
        self.nameAr = nameAr
        self.nameEn = nameEn
        self.transliteration = transliteration
        self.audioFile = audioFile
    }
}

/// One of the four positional forms of a letter, plus reference strokes for tracing.
@Model
final class LetterForm {
    @Attribute(.unique) var id: String   // e.g. "1-isolated"
    var letterId: Int
    var position: String                 // isolated / initial / medial / final
    var unicodeChar: String              // display string (uses tatweel joiners for joined forms)
    var strokeDataJSON: String           // reference strokes, unit-square coordinates

    init(id: String, letterId: Int, position: String, unicodeChar: String, strokeDataJSON: String = "") {
        self.id = id
        self.letterId = letterId
        self.position = position
        self.unicodeChar = unicodeChar
        self.strokeDataJSON = strokeDataJSON
    }
}

/// One of the 8 letter-group lessons (§4.1).
@Model
final class Lesson {
    @Attribute(.unique) var id: Int
    var num: Int
    var title: String
    var letterIds: [Int]
    var isUnlocked: Bool
    var isComplete: Bool

    init(id: Int, num: Int, title: String, letterIds: [Int], isUnlocked: Bool = false, isComplete: Bool = false) {
        self.id = id
        self.num = num
        self.title = title
        self.letterIds = letterIds
        self.isUnlocked = isUnlocked
        self.isComplete = isComplete
    }
}

/// Library / reading content (§4.4). Ayahs, educational items, and short articles.
@Model
final class Word {
    @Attribute(.unique) var id: String
    var arabic: String
    var transliteration: String
    var translationEn: String
    var translationRu: String
    var translationKz: String
    var audioFile: String
    var level: Int
    // Library presentation (beyond the PRD's minimal Word fields)
    var category: String                 // ayah / educational / article
    var titleEn: String
    var requiredLesson: Int              // lesson num that must be complete to unlock; 0 = always
    var textBody: String                 // long-form body for articles ("" otherwise)

    init(id: String, arabic: String, transliteration: String,
         translationEn: String, translationRu: String, translationKz: String,
         audioFile: String, level: Int, category: String, titleEn: String,
         requiredLesson: Int = 0, textBody: String = "") {
        self.id = id
        self.arabic = arabic
        self.transliteration = transliteration
        self.translationEn = translationEn
        self.translationRu = translationRu
        self.translationKz = translationKz
        self.audioFile = audioFile
        self.level = level
        self.category = category
        self.titleEn = titleEn
        self.requiredLesson = requiredLesson
        self.textBody = textBody
    }

    /// Translation matching the current UI language (EN / RU / KZ, §1.5).
    var localizedTranslation: String {
        switch Locale.current.language.languageCode?.identifier {
        case "ru": return translationRu
        case "kk": return translationKz
        default: return translationEn
        }
    }
}

/// SM-2 spaced-repetition state per item (§5.3, §5.4).
@Model
final class UserProgress {
    @Attribute(.unique) var key: String  // "\(itemType):\(itemId)"
    var itemType: String                 // letter / vowelledLetter / word
    var itemId: String
    var interval: Int                    // days
    var repetition: Int
    var easeFactor: Double
    var nextReviewAt: Date?
    var correctCount: Int
    var wrongCount: Int

    init(itemType: String, itemId: String) {
        self.key = "\(itemType):\(itemId)"
        self.itemType = itemType
        self.itemId = itemId
        self.interval = 0
        self.repetition = 0
        self.easeFactor = 2.5
        self.nextReviewAt = nil
        self.correctCount = 0
        self.wrongCount = 0
    }
}

/// Onboarding choices + toggles (§4.5, §5.4). Single row.
@Model
final class UserSettings {
    @Attribute(.unique) var id: Int
    var readingLevel: String
    var programPref: String
    var soundEffects: Bool
    var dailyReminder: Bool
    var darkModePreview: Bool
    var onboardingComplete: Bool

    init() {
        self.id = 1
        self.readingLevel = ""
        self.programPref = ""
        self.soundEffects = true
        self.dailyReminder = false
        self.darkModePreview = false
        self.onboardingComplete = false
    }
}
