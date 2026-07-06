//
//  SRSService.swift
//  alif-baa-ios
//
//  SM-2 spaced repetition, as in Anki (§5.3). Drives retention tracking now and
//  the "Thorough" program's revision lessons on the v1.x roadmap (§4.3).
//

import Foundation
import SwiftData

enum SRSService {

    /// Applies an SM-2 review to an item. `quality` is 0–5; below 3 is a failure.
    static func processAnswer(_ progress: UserProgress, quality: Int, now: Date = .now) {
        let q = max(0, min(5, quality))

        if q >= 3 {
            progress.correctCount += 1
            progress.easeFactor = max(
                1.3,
                progress.easeFactor + (0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02))
            )
            progress.repetition += 1
            switch progress.repetition {
            case 1: progress.interval = 1
            case 2: progress.interval = 6
            default: progress.interval = Int((Double(progress.interval) * progress.easeFactor).rounded())
            }
        } else {
            // Failure resets the streak; the item is relearned from a 1-day interval.
            progress.wrongCount += 1
            progress.repetition = 0
            progress.interval = 1
        }

        progress.nextReviewAt = Calendar.current.date(byAdding: .day, value: progress.interval, to: now)
    }

    static func isDue(_ progress: UserProgress, now: Date = .now) -> Bool {
        guard let next = progress.nextReviewAt else { return true }
        return next <= now
    }

    /// Status per §5.3: ○ not started, ◑ in progress (< 80%), ● learned (≥ 80%),
    /// ★ mastered (reviewed out to the 30-day interval).
    static func status(of progress: UserProgress?) -> LearningStatus {
        guard let progress, progress.correctCount + progress.wrongCount > 0 else { return .notStarted }
        if progress.interval >= 30 { return .mastered }
        let total = progress.correctCount + progress.wrongCount
        let accuracy = Double(progress.correctCount) / Double(total)
        return accuracy >= 0.8 ? .learned : .inProgress
    }

    // MARK: - Persistence helpers

    static func fetchOrCreate(context: ModelContext, itemType: String, itemId: String) -> UserProgress {
        let key = "\(itemType):\(itemId)"
        let descriptor = FetchDescriptor<UserProgress>(predicate: #Predicate { $0.key == key })
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let progress = UserProgress(itemType: itemType, itemId: itemId)
        context.insert(progress)
        return progress
    }

    /// Records one answer for an item and saves.
    static func record(context: ModelContext, itemType: String, itemId: String, quality: Int) {
        let progress = fetchOrCreate(context: context, itemType: itemType, itemId: itemId)
        processAnswer(progress, quality: quality)
        try? context.save()
    }
}
