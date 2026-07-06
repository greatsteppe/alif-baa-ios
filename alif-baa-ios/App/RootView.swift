//
//  RootView.swift
//  alif-baa-ios
//
//  Routes the one continuous flow of the prototype (§3): onboarding →
//  configuring transition → three-tab main app.
//

import SwiftUI
import SwiftData

struct RootView: View {

    private enum Phase {
        case onboarding
        case configuring
        case main
    }

    @Environment(\.modelContext) private var context
    @Query private var settingsList: [UserSettings]
    @State private var phase: Phase?

    private var settings: UserSettings? { settingsList.first }

    var body: some View {
        ZStack {
            AB.cream.ignoresSafeArea()

            switch phase {
            case .onboarding:
                OnboardingFlowView { level, program in
                    completeOnboarding(level: level, program: program)
                }
                .transition(.opacity)
            case .configuring:
                ConfiguringView {
                    withAnimation(.easeInOut(duration: 0.35)) { phase = .main }
                }
                .transition(.opacity)
            case .main:
                MainTabView()
                    .transition(.opacity)
            case nil:
                Color.clear
            }
        }
        .preferredColorScheme(settings?.darkModePreview == true ? .dark : .light)
        .onAppear {
            if phase == nil {
                phase = settings?.onboardingComplete == true ? .main : .onboarding
            }
        }
    }

    private func completeOnboarding(level: ReadingLevel, program: ProgramChoice) {
        let userSettings = settings ?? {
            let created = UserSettings()
            context.insert(created)
            return created
        }()

        userSettings.readingLevel = level.rawValue
        userSettings.programPref = program.rawValue
        userSettings.onboardingComplete = true

        // Non-beginner levels fast-forward: letter lessons open up as review (§4.3).
        if level.unlocksAllLessons {
            let lessons = (try? context.fetch(FetchDescriptor<Lesson>())) ?? []
            for lesson in lessons { lesson.isUnlocked = true }
        }
        try? context.save()

        withAnimation(.easeInOut(duration: 0.35)) { phase = .configuring }
    }
}

/// Bouncing-dots loader shown for ~1.6 s after onboarding (§3.1).
struct ConfiguringView: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            BouncingDotsLoader()
            Text("Configuring your program")
                .font(.system(size: AB.small))
                .foregroundStyle(AB.neutral400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            try? await Task.sleep(for: .seconds(1.6))
            onDone()
        }
    }
}
