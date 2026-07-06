//
//  DesignSystem.swift
//  alif-baa-ios
//
//  "Hafiz" design system — tokens from the Claude Design handoff (colors_and_type.css).
//

import SwiftUI
import UIKit
import CoreText

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// Design tokens (§2 of the PRD).
enum AB {
    // MARK: Colors (§2.1)
    static let primary = Color(hex: 0x006754)      // brand green
    static let pine = Color(hex: 0x15351B)         // deep green
    static let darkest = Color(hex: 0x001C18)      // primary text
    static let sage = Color(hex: 0x3F756C)         // secondary buttons, "Memorize"
    static let mint = Color(hex: 0x87D1A4)         // success, selected fills
    static let mintPale = Color(hex: 0xE2F6F8)     // card tints
    static let amberDark = Color(hex: 0xB75F08)    // exercise progress bar
    static let saffron = Color(hex: 0xFEBC2E)      // "Fast" badge, audio play buttons
    static let cream = Color(hex: 0xFBF9EF)        // app background
    static let surface = Color.white               // cards, canvases
    static let error = Color(hex: 0xBC4646)        // wrong answer feedback
    static let neutral300 = Color(hex: 0xD9D9D9)   // dividers
    static let neutral400 = Color(hex: 0x888888)   // secondary text, locked states

    static let cardShadow = Color(hex: 0x006754).opacity(0.12)

    // MARK: Type scale (§2.2)
    static let display: CGFloat = 64
    static let h1: CGFloat = 40
    static let h2: CGFloat = 32
    static let screenTitle: CGFloat = 28
    static let h3: CGFloat = 20
    static let body: CGFloat = 16
    static let small: CGFloat = 14
    static let caption: CGFloat = 12

    // MARK: Shape (§2.3)
    static let radiusSmall: CGFloat = 12
    static let radiusCard: CGFloat = 20

    // MARK: Arabic typography
    static let arabicFontName = "NotoSansArabic-Regular"
    static let arabicSemiBoldFontName = "NotoSansArabic-SemiBold"

    /// Noto Sans Arabic when bundled; graceful fallback to the system font.
    static func arabicFont(_ size: CGFloat, semiBold: Bool = false) -> Font {
        let name = semiBold ? arabicSemiBoldFontName : arabicFontName
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: semiBold ? .semibold : .regular)
    }

    /// Registers the bundled Noto Sans Arabic faces with Core Text. Call once at launch.
    static func registerBundledFonts() {
        for name in [arabicFontName, arabicSemiBoldFontName] {
            guard UIFont(name: name, size: 12) == nil,
                  let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

/// Arabic script is always rendered RTL and marked as Arabic for VoiceOver,
/// independent of the UI language (§1.5, §5.5).
struct ArabicText: View {
    let text: String
    var size: CGFloat = AB.h1
    var semiBold: Bool = false
    var color: Color = AB.darkest

    /// Marked lang="ar" so VoiceOver reads it as Arabic (§5.5).
    private var attributed: AttributedString {
        var string = AttributedString(text)
        string.languageIdentifier = "ar"
        return string
    }

    var body: some View {
        Text(attributed)
            .font(AB.arabicFont(size, semiBold: semiBold))
            .foregroundStyle(color)
            .environment(\.layoutDirection, .rightToLeft)
            .multilineTextAlignment(.center)
    }
}
