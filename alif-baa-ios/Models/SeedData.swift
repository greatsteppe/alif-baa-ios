//
//  SeedData.swift
//  alif-baa-ios
//
//  First-launch seed: 28 letters, 8 lessons (§4.1), positional forms, and the
//  initial content library (§4.4).
//
//  NOTE (§7.1 — where humans are needed): Arabic transliterations, translations,
//  and library texts below need verification by a native speaker before release.
//

import Foundation
import SwiftData

enum SeedData {

    // id, arabic, nameAr, nameEn, transliteration
    static let letters: [(Int, String, String, String, String)] = [
        (1, "ا", "ألف", "Alif", "ā"),
        (2, "ب", "باء", "Ba", "b"),
        (3, "ت", "تاء", "Ta", "t"),
        (4, "ث", "ثاء", "Tha", "th"),
        (5, "ج", "جيم", "Jeem", "j"),
        (6, "ح", "حاء", "Ha", "ḥ"),
        (7, "خ", "خاء", "Kho", "kh"),
        (8, "د", "دال", "Dal", "d"),
        (9, "ذ", "ذال", "Dhal", "dh"),
        (10, "ر", "راء", "Ro", "r"),
        (11, "ز", "زاي", "Za", "z"),
        (12, "س", "سين", "Seen", "s"),
        (13, "ش", "شين", "Sheen", "sh"),
        (14, "ص", "صاد", "Sod", "ṣ"),
        (15, "ض", "ضاد", "Dod", "ḍ"),
        (16, "ط", "طاء", "To", "ṭ"),
        (17, "ظ", "ظاء", "Dho", "ẓ"),
        (18, "ع", "عين", "'Ain", "ʿ"),
        (19, "غ", "غين", "Ghoin", "gh"),
        (20, "ف", "فاء", "Fa", "f"),
        (21, "ق", "قاف", "Qof", "q"),
        (22, "ك", "كاف", "Kaf", "k"),
        (23, "ل", "لام", "Lam", "l"),
        (24, "م", "ميم", "Meem", "m"),
        (25, "ن", "نون", "Noon", "n"),
        (26, "ه", "هاء", "Ha", "h"),
        (27, "و", "واو", "Waw", "w"),
        (28, "ي", "ياء", "Ya", "y"),
    ]

    // The 8 letter-group lessons (§4.1).
    static let lessons: [(Int, String, [Int])] = [
        (1, "Alif Ba Ta Tha", [1, 2, 3, 4]),
        (2, "Jeem Ha Kho", [5, 6, 7]),
        (3, "Dal Dhal Ro Za", [8, 9, 10, 11]),
        (4, "Seen Sheen Sod Dod", [12, 13, 14, 15]),
        (5, "To Dho 'Ain Ghoin", [16, 17, 18, 19]),
        (6, "Fa Qof Kaf", [20, 21, 22]),
        (7, "Lam Meem Noon", [23, 24, 25]),
        (8, "Ha Waw Ya", [26, 27, 28]),
    ]

    /// Letters that do not join to the following letter.
    private static let nonConnectors: Set<Int> = [1, 8, 9, 10, 11, 27]

    private static let tatweel = "\u{0640}"

    static func forms(for letterId: Int, arabic: String) -> [(LetterPosition, String)] {
        let connects = !nonConnectors.contains(letterId)
        return [
            (.isolated, arabic),
            (.initial, connects ? arabic + tatweel : arabic),
            (.medial, connects ? tatweel + arabic + tatweel : tatweel + arabic),
            (.final, tatweel + arabic),
        ]
    }

    // MARK: - Library (§4.4)

    static func libraryWords() -> [Word] {
        [
            Word(
                id: "ayah-fatihah",
                arabic: """
                بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
                الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ
                الرَّحْمَٰنِ الرَّحِيمِ
                مَالِكِ يَوْمِ الدِّينِ
                إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ
                اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ
                صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ
                """,
                transliteration: "Bismi-llāhi r-raḥmāni r-raḥīm…",
                translationEn: "Surah Al-Fatihah — the seven oft-repeated verses that open the Quran.",
                translationRu: "Сура «Аль-Фатиха» — семь часто повторяемых аятов, открывающих Коран.",
                translationKz: "«Әл-Фатиха» сүресі — Құранды ашатын жеті қайталанатын аят.",
                audioFile: "fatihah.m4a",
                level: 1,
                category: "ayah",
                titleEn: "The Seven Oft-Repeated",
                requiredLesson: 1
            ),
            Word(
                id: "ayah-ikhlas",
                arabic: """
                قُلْ هُوَ اللَّهُ أَحَدٌ
                اللَّهُ الصَّمَدُ
                لَمْ يَلِدْ وَلَمْ يُولَدْ
                وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ
                """,
                transliteration: "Qul huwa-llāhu aḥad…",
                translationEn: "Surah Al-Ikhlas — the declaration of pure monotheism.",
                translationRu: "Сура «Аль-Ихлас» — провозглашение чистого единобожия.",
                translationKz: "«Әл-Ихлас» сүресі — таза таухидтің жариялануы.",
                audioFile: "ikhlas.m4a",
                level: 2,
                category: "ayah",
                titleEn: "Al-Ikhlas (Sincerity)",
                requiredLesson: 3
            ),
            Word(
                id: "ayah-nas",
                arabic: """
                قُلْ أَعُوذُ بِرَبِّ النَّاسِ
                مَلِكِ النَّاسِ
                إِلَٰهِ النَّاسِ
                مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ
                الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ
                مِنَ الْجِنَّةِ وَالنَّاسِ
                """,
                transliteration: "Qul aʿūdhu bi-rabbi n-nās…",
                translationEn: "Surah An-Nas — seeking refuge with the Lord of mankind.",
                translationRu: "Сура «Ан-Нас» — прибегание к защите Господа людей.",
                translationKz: "«Ән-Нас» сүресі — адамдардың Раббысынан пана тілеу.",
                audioFile: "nas.m4a",
                level: 2,
                category: "ayah",
                titleEn: "An-Nas (Mankind)",
                requiredLesson: 5
            ),
            Word(
                id: "edu-alphabet-song",
                arabic: "ا ب ت ث ج ح خ د ذ ر ز س ش ص ض ط ظ ع غ ف ق ك ل م ن ه و ي",
                transliteration: "alif, ba, ta, tha…",
                translationEn: "All 28 letters in order — tap any letter on the Alphabet tab to hear it.",
                translationRu: "Все 28 букв по порядку — нажмите на букву во вкладке «Алфавит», чтобы услышать её.",
                translationKz: "Барлық 28 әріп ретімен — әріпті есту үшін «Әліпби» қойындысында оны басыңыз.",
                audioFile: "alphabet-song.m4a",
                level: 1,
                category: "educational",
                titleEn: "Alphabet Song",
                requiredLesson: 0
            ),
            Word(
                id: "article-learning-to-read",
                arabic: "",
                transliteration: "",
                translationEn: "Why the Arabic script works the way it does.",
                translationRu: "Почему арабское письмо устроено именно так.",
                translationKz: "Араб жазуы неге дәл осылай құрылған.",
                audioFile: "",
                level: 1,
                category: "article",
                titleEn: "Learning to read Arabic",
                requiredLesson: 0,
                textBody: """
                Arabic is written right-to-left, and most letters change shape depending on where \
                they sit in a word: isolated, initial, medial, or final. That sounds intimidating, \
                but the changes follow a small set of patterns — once you know a letter's skeleton, \
                you can recognize all four of its forms.

                Everyday Arabic text also omits the short vowels (harakat). Learners' texts and the \
                Quran include them as small marks above or below the letters: Fatha (a), Damma (u), \
                and Kasra (i). Alif Baa teaches you the letters first, then layers the harakat on \
                top — exactly the order this app's lessons follow.
                """
            ),
            Word(
                id: "article-harakat",
                arabic: "بَ بُ بِ",
                transliteration: "ba · bu · bi",
                translationEn: "The three short vowels and how they sound.",
                translationRu: "Три краткие гласные и как они звучат.",
                translationKz: "Үш қысқа дауысты дыбыс және олардың айтылуы.",
                audioFile: "",
                level: 1,
                category: "article",
                titleEn: "The short vowels (harakat)",
                requiredLesson: 1,
                textBody: """
                A harakat is a small mark that gives a consonant its vowel. Fatha — a slanted dash \
                above the letter — adds "a". Damma — a small waw above — adds "u". Kasra — a dash \
                below — adds "i". So the letter Ba (ب) becomes ba (بَ), bu (بُ), or bi (بِ).

                The Quran is fully vowelled, which is why learning the harakat right after the \
                letters puts reading within reach so quickly.
                """
            ),
        ]
    }

    // MARK: - Seeding

    /// Inserts the seed content on first launch. Idempotent.
    static func seedIfNeeded(context: ModelContext) {
        let letterCount = (try? context.fetchCount(FetchDescriptor<Letter>())) ?? 0
        guard letterCount == 0 else { return }

        let references = ReferenceStrokeStore.loadRaw()

        for (id, arabic, nameAr, nameEn, translit) in letters {
            context.insert(Letter(
                id: id, arabic: arabic, nameAr: nameAr, nameEn: nameEn,
                transliteration: translit, audioFile: "letter-\(id).m4a"
            ))
            for (position, display) in forms(for: id, arabic: arabic) {
                let strokeJSON = position == .isolated ? (references[arabic] ?? "") : ""
                context.insert(LetterForm(
                    id: "\(id)-\(position.rawValue)",
                    letterId: id,
                    position: position.rawValue,
                    unicodeChar: display,
                    strokeDataJSON: strokeJSON
                ))
            }
        }

        for (num, title, letterIds) in lessons {
            // Lessons unlock sequentially; Lesson 1 starts unlocked (§4.1).
            context.insert(Lesson(id: num, num: num, title: title, letterIds: letterIds, isUnlocked: num == 1))
        }

        for word in libraryWords() {
            context.insert(word)
        }

        try? context.save()
    }
}
