//
//  Components.swift
//  alif-baa-ios
//
//  Shared UI: pill CTAs, cards, feedback banners, bouncing-dot loader (§2.3).
//

import SwiftUI

// MARK: - Buttons

/// 50px-radius pill CTA in brand green; gray when disabled.
struct PillButtonStyle: ButtonStyle {
    var background: Color = AB.primary
    var foreground: Color = .white
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: AB.body, weight: .semibold))
            .foregroundStyle(isEnabled ? foreground : AB.neutral400)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isEnabled ? background : AB.neutral300)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Cards

struct CardModifier: ViewModifier {
    var radius: CGFloat = AB.radiusCard
    func body(content: Content) -> some View {
        content
            .background(AB.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: AB.cardShadow, radius: 15, x: 0, y: 4)
    }
}

extension View {
    func abCard(radius: CGFloat = AB.radiusCard) -> some View {
        modifier(CardModifier(radius: radius))
    }
}

// MARK: - Progress bar

/// Saffron exercise progress bar (§4.2).
struct SaffronProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(AB.neutral300.opacity(0.5))
                Capsule()
                    .fill(AB.saffron)
                    .frame(width: max(8, geo.size.width * progress))
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Bouncing dots loader

/// Three bouncing dots — green, mint, saffron (§2.3).
struct BouncingDotsLoader: View {
    @State private var bounce = false
    private let colors: [Color] = [AB.primary, AB.mint, AB.saffron]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(colors[i])
                    .frame(width: 16, height: 16)
                    .offset(y: bounce ? -12 : 4)
                    .animation(
                        .easeInOut(duration: 0.45)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.15),
                        value: bounce
                    )
            }
        }
        .onAppear { bounce = true }
        .accessibilityHidden(true)
    }
}

// MARK: - Feedback banner

enum FeedbackKind: Equatable {
    case correct(praise: String)
    case wrong(correctAnswer: String?)
}

/// Bottom feedback banner — mint for correct, blush-red for wrong (§2.3, §4.2).
struct FeedbackBanner: View {
    let kind: FeedbackKind
    var proceedTitle: LocalizedStringKey = "Proceed"
    let onProceed: () -> Void

    private var isCorrect: Bool {
        if case .correct = kind { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(isCorrect ? AB.primary : AB.error)
                VStack(alignment: .leading, spacing: 2) {
                    switch kind {
                    case .correct(let praise):
                        Text(LocalizedStringKey(praise))
                            .font(.system(size: AB.h3, weight: .bold))
                            .foregroundStyle(AB.darkest)
                    case .wrong(let answer):
                        Text("Not quite")
                            .font(.system(size: AB.h3, weight: .bold))
                            .foregroundStyle(AB.error)
                        if let answer {
                            Text("The correct answer: \(answer)")
                                .font(.system(size: AB.small))
                                .foregroundStyle(AB.darkest)
                        } else {
                            Text("Follow the outline and try again")
                                .font(.system(size: AB.small))
                                .foregroundStyle(AB.darkest)
                        }
                    }
                }
                Spacer()
            }
            Button(proceedTitle) { onProceed() }
                .buttonStyle(PillButtonStyle(background: isCorrect ? AB.primary : AB.error))
        }
        .padding(20)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: AB.radiusCard,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: AB.radiusCard
            )
            .fill(isCorrect ? AB.mint.opacity(0.35) : AB.error.opacity(0.12))
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: AB.radiusCard,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: AB.radiusCard
                )
                .fill(AB.cream)
            )
        )
        .overlay(alignment: .top) {
            UnevenRoundedRectangle(
                topLeadingRadius: AB.radiusCard,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: AB.radiusCard
            )
            .strokeBorder(isCorrect ? AB.mint : AB.error.opacity(0.4), lineWidth: 1.5)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    static let praises = ["Well done!", "Awesome!", "Great job!", "Excellent!", "Keep it up!"]

    static func randomPraise() -> String {
        praises.randomElement() ?? "Well done!"
    }
}

// MARK: - Letter chip

struct LetterChip: View {
    let arabic: String
    var highlighted: Bool = true

    var body: some View {
        ArabicText(text: arabic, size: AB.h2, color: highlighted ? AB.primary : AB.neutral400)
            .frame(width: 56, height: 64)
            .background(highlighted ? AB.mint.opacity(0.25) : AB.neutral300.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: AB.radiusSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AB.radiusSmall, style: .continuous)
                    .strokeBorder(highlighted ? AB.mint : AB.neutral300, lineWidth: 1.5)
            )
    }
}

// MARK: - Toast

struct ToastView: View {
    let message: LocalizedStringKey

    var body: some View {
        Text(message)
            .font(.system(size: AB.small, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AB.pine.opacity(0.95))
            .clipShape(Capsule())
            .shadow(color: AB.cardShadow, radius: 10, y: 4)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
