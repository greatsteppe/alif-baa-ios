//
//  OnboardingView.swift
//  alif-baa-ios
//
//  Two-step onboarding (§3.2): reading level with progress meters, then program
//  with lettered badges. Proceed stays disabled until a choice is made.
//

import SwiftUI

struct OnboardingFlowView: View {
    let onComplete: (ReadingLevel, ProgramChoice) -> Void

    @State private var step = 1
    @State private var selectedLevel: ReadingLevel?
    @State private var selectedProgram: ProgramChoice?

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if step == 1 {
                        levelStep
                    } else {
                        programStep
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }

            proceedButton
        }
    }

    // MARK: - Chrome

    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                if step == 2 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { step = 1 }
                    } label: {
                        Image(systemName: "arrow.backward")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(AB.pine)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Back")
                }
                Spacer()
            }
            .frame(height: 44)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AB.neutral300.opacity(0.5))
                    Capsule()
                        .fill(AB.primary)
                        .frame(width: geo.size.width * (step == 1 ? 0.5 : 1))
                        .animation(.easeInOut(duration: 0.3), value: step)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 24)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    private var proceedButton: some View {
        Button("Proceed") {
            if step == 1 {
                // A newly gated program choice must not survive a level change (§3.2).
                if let program = selectedProgram, let level = selectedLevel,
                   !program.isAvailable(for: level) {
                    selectedProgram = nil
                }
                withAnimation(.easeInOut(duration: 0.25)) { step = 2 }
            } else if let level = selectedLevel, let program = selectedProgram {
                onComplete(level, program)
            }
        }
        .buttonStyle(PillButtonStyle())
        .disabled(step == 1 ? selectedLevel == nil : selectedProgram == nil)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    // MARK: - Step 1: Reading level

    private var levelStep: some View {
        Group {
            VStack(alignment: .leading, spacing: 12) {
                ArabicText(text: "السَّلَامُ عَلَيْكُمْ", size: AB.h2, semiBold: true, color: AB.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .environment(\.layoutDirection, .leftToRight)
                Text("What is your Arabic reading level?")
                    .font(.system(size: AB.screenTitle, weight: .bold))
                    .foregroundStyle(AB.darkest)
            }

            VStack(spacing: 14) {
                ForEach(ReadingLevel.allCases) { level in
                    LevelOptionCard(level: level, isSelected: selectedLevel == level) {
                        selectedLevel = level
                    }
                }
            }
        }
    }

    // MARK: - Step 2: Program

    private var programStep: some View {
        Group {
            Text("What program do you prefer?")
                .font(.system(size: AB.screenTitle, weight: .bold))
                .foregroundStyle(AB.darkest)

            VStack(spacing: 14) {
                ForEach(ProgramChoice.allCases) { program in
                    ProgramOptionCard(
                        program: program,
                        isSelected: selectedProgram == program,
                        isAvailable: program.isAvailable(for: selectedLevel)
                    ) {
                        selectedProgram = program
                    }
                }
            }
        }
    }
}

// MARK: - Option cards

private struct LevelOptionCard: View {
    let level: ReadingLevel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey(level.title))
                            .font(.system(size: AB.body, weight: .semibold))
                            .foregroundStyle(AB.darkest)
                        Text(LocalizedStringKey(level.hint))
                            .font(.system(size: AB.small))
                            .foregroundStyle(AB.neutral400)
                    }
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? AB.primary : AB.neutral300)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AB.neutral300.opacity(0.4))
                        Capsule()
                            .fill(isSelected ? AB.primary : AB.mint)
                            .frame(width: geo.size.width * level.meter)
                    }
                }
                .frame(height: 6)
            }
            .padding(18)
            .background(isSelected ? AB.mintPale : AB.surface)
            .clipShape(RoundedRectangle(cornerRadius: AB.radiusCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AB.radiusCard, style: .continuous)
                    .strokeBorder(isSelected ? AB.primary : AB.neutral300.opacity(0.6), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: AB.cardShadow, radius: 15, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private struct ProgramOptionCard: View {
    let program: ProgramChoice
    let isSelected: Bool
    let isAvailable: Bool
    let onTap: () -> Void

    private var badgeColor: Color {
        switch program {
        case .fast: return AB.saffron
        case .thorough: return AB.primary
        case .straightToReading: return AB.sage
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Text(program.badge)
                    .font(.system(size: AB.h3, weight: .bold))
                    .foregroundStyle(program == .fast ? AB.darkest : .white)
                    .frame(width: 44, height: 44)
                    .background(badgeColor)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(program.title))
                        .font(.system(size: AB.body, weight: .semibold))
                        .foregroundStyle(AB.darkest)
                    Text(LocalizedStringKey(program.subtitle))
                        .font(.system(size: AB.small))
                        .foregroundStyle(AB.neutral400)
                        .fixedSize(horizontal: false, vertical: true)
                    if !isAvailable {
                        Label("Available for learners who already know the alphabet", systemImage: "lock.fill")
                            .font(.system(size: AB.caption))
                            .foregroundStyle(AB.amberDark)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? AB.primary : AB.neutral300)
            }
            .padding(18)
            .background(isSelected ? AB.mintPale : AB.surface)
            .clipShape(RoundedRectangle(cornerRadius: AB.radiusCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AB.radiusCard, style: .continuous)
                    .strokeBorder(isSelected ? AB.primary : AB.neutral300.opacity(0.6), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: AB.cardShadow, radius: 15, x: 0, y: 4)
            .opacity(isAvailable ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
    }
}
