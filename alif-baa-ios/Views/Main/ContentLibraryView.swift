//
//  ContentLibraryView.swift
//  alif-baa-ios
//
//  The Content tab (§4.4): a grouped library — Quranic Ayahs, Educational,
//  Short Articles. Completing lessons surfaces new items.
//

import SwiftUI
import SwiftData

struct ContentLibraryView: View {
    @Query(sort: \Word.level) private var words: [Word]
    @Query private var lessons: [Lesson]

    private let sections: [(category: String, title: String)] = [
        ("ayah", "Quranic Ayahs"),
        ("educational", "Educational"),
        ("article", "Short Articles"),
    ]

    private func isUnlocked(_ word: Word) -> Bool {
        guard word.requiredLesson > 0 else { return true }
        return lessons.first { $0.num == word.requiredLesson }?.isComplete == true
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AB.cream.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Content")
                            .font(.system(size: AB.screenTitle, weight: .bold))
                            .foregroundStyle(AB.darkest)
                            .padding(.top, 12)

                        ForEach(sections, id: \.category) { section in
                            let items = words.filter { $0.category == section.category }
                            if !items.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(LocalizedStringKey(section.title))
                                        .font(.system(size: AB.h3, weight: .bold))
                                        .foregroundStyle(AB.sage)

                                    ForEach(items) { word in
                                        if isUnlocked(word) {
                                            NavigationLink {
                                                WordDetailView(word: word)
                                            } label: {
                                                LibraryRow(word: word, locked: false)
                                            }
                                            .buttonStyle(.plain)
                                        } else {
                                            LibraryRow(word: word, locked: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct LibraryRow: View {
    let word: Word
    let locked: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: locked ? "lock.fill" : iconName)
                .font(.system(size: 17))
                .foregroundStyle(locked ? AB.neutral400 : AB.primary)
                .frame(width: 40, height: 40)
                .background(locked ? AB.neutral300.opacity(0.5) : AB.mintPale)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(word.titleEn))
                    .font(.system(size: AB.body, weight: .semibold))
                    .foregroundStyle(locked ? AB.neutral400 : AB.darkest)
                if locked {
                    Text("Complete Lesson \(word.requiredLesson) to unlock")
                        .font(.system(size: AB.caption))
                        .foregroundStyle(AB.neutral400)
                } else {
                    Text(word.localizedTranslation)
                        .font(.system(size: AB.caption))
                        .foregroundStyle(AB.neutral400)
                        .lineLimit(2)
                }
            }
            Spacer()
            if !locked {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AB.neutral300)
            }
        }
        .padding(16)
        .background(AB.surface)
        .clipShape(RoundedRectangle(cornerRadius: AB.radiusCard, style: .continuous))
        .shadow(color: AB.cardShadow, radius: 15, x: 0, y: 4)
        .opacity(locked ? 0.6 : 1)
    }

    private var iconName: String {
        switch word.category {
        case "ayah": return "book.closed"
        case "educational": return "music.note"
        default: return "doc.text"
        }
    }
}

struct WordDetailView: View {
    let word: Word

    var body: some View {
        ZStack {
            AB.cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(LocalizedStringKey(word.titleEn))
                        .font(.system(size: AB.screenTitle, weight: .bold))
                        .foregroundStyle(AB.darkest)

                    if !word.arabic.isEmpty {
                        VStack(spacing: 16) {
                            ArabicText(text: word.arabic, size: 30)
                                .lineSpacing(14)
                                .frame(maxWidth: .infinity)

                            if !word.transliteration.isEmpty {
                                Text(word.transliteration)
                                    .font(.system(size: AB.small).italic())
                                    .foregroundStyle(AB.neutral400)
                            }

                            if !word.audioFile.isEmpty {
                                Button {
                                    AudioService.shared.playWord(word)
                                } label: {
                                    Label("Listen", systemImage: "play.fill")
                                        .font(.system(size: AB.small, weight: .semibold))
                                        .foregroundStyle(AB.darkest)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(AB.saffron)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .abCard()
                    }

                    Text(word.localizedTranslation)
                        .font(.system(size: AB.body))
                        .foregroundStyle(AB.darkest)

                    if !word.textBody.isEmpty {
                        Text(LocalizedStringKey(word.textBody))
                            .font(.system(size: AB.body))
                            .foregroundStyle(AB.darkest)
                            .lineSpacing(5)
                    }
                }
                .padding(24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .tint(AB.primary)
    }
}
