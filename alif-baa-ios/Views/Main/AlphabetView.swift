//
//  AlphabetView.swift
//  alif-baa-ios
//
//  The Alphabet tab (§3.1): 8 lesson rows with play / check / lock status icons.
//  Lessons unlock sequentially (§4.1).
//

import SwiftUI
import SwiftData

struct AlphabetView: View {
    @Binding var tabSelection: Int

    @Query(sort: \Lesson.num) private var lessons: [Lesson]
    @Query private var letters: [Letter]
    @State private var activeLesson: Lesson?

    private var lettersById: [Int: Letter] {
        Dictionary(uniqueKeysWithValues: letters.map { ($0.id, $0) })
    }

    private var completedCount: Int { lessons.filter(\.isComplete).count }

    var body: some View {
        ZStack {
            AB.cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Alphabet")
                            .font(.system(size: AB.screenTitle, weight: .bold))
                            .foregroundStyle(AB.darkest)
                        Text("\(completedCount) of \(lessons.count) lessons completed")
                            .font(.system(size: AB.small))
                            .foregroundStyle(AB.neutral400)
                    }
                    .padding(.top, 12)

                    LazyVStack(spacing: 14) {
                        ForEach(lessons) { lesson in
                            LessonRow(
                                lesson: lesson,
                                arabicLetters: lesson.letterIds.compactMap { lettersById[$0]?.arabic }
                            ) {
                                activeLesson = lesson
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .fullScreenCover(item: $activeLesson) { lesson in
            LessonPlayerView(lesson: lesson) { next in
                activeLesson = next
            } onOpenLibrary: {
                activeLesson = nil
                tabSelection = 1
            }
            // Fresh engine state when "Next lesson" swaps the presented item.
            .id(lesson.id)
        }
    }
}

private struct LessonRow: View {
    let lesson: Lesson
    let arabicLetters: [String]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                statusIcon

                VStack(alignment: .leading, spacing: 3) {
                    Text("Lesson \(lesson.num)")
                        .font(.system(size: AB.caption, weight: .medium))
                        .foregroundStyle(lesson.isUnlocked ? AB.sage : AB.neutral400)
                        .textCase(.uppercase)
                    Text(LocalizedStringKey(lesson.title))
                        .font(.system(size: AB.body, weight: .semibold))
                        .foregroundStyle(lesson.isUnlocked ? AB.darkest : AB.neutral400)
                }

                Spacer()

                ArabicText(
                    text: arabicLetters.joined(separator: " "),
                    size: AB.h3,
                    color: lesson.isUnlocked ? AB.primary : AB.neutral400
                )
            }
            .padding(18)
            .background(AB.surface)
            .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
            .shadow(color: AB.cardShadow, radius: 15, x: 0, y: 4)
            .opacity(lesson.isUnlocked ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!lesson.isUnlocked)
        .accessibilityLabel(lesson.isUnlocked ? "Lesson \(lesson.num): \(lesson.title)" : "Lesson \(lesson.num) locked")
    }

    @ViewBuilder
    private var statusIcon: some View {
        if lesson.isComplete {
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AB.pine)
                .frame(width: 40, height: 40)
                .background(AB.mint)
                .clipShape(Circle())
        } else if lesson.isUnlocked {
            Image(systemName: "play.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(AB.primary)
                .clipShape(Circle())
        } else {
            Image(systemName: "lock.fill")
                .font(.system(size: 15))
                .foregroundStyle(AB.neutral400)
                .frame(width: 40, height: 40)
                .background(AB.neutral300.opacity(0.5))
                .clipShape(Circle())
        }
    }
}
