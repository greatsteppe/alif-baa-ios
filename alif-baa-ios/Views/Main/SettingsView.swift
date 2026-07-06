//
//  SettingsView.swift
//  alif-baa-ios
//
//  The Settings tab (§4.5): toggles, Reset Progress with confirmation toast,
//  About + version.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [UserSettings]
    @State private var showResetConfirm = false
    @State private var showToast = false

    private var settings: UserSettings? { settingsList.first }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        ZStack {
            AB.cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Settings")
                        .font(.system(size: AB.screenTitle, weight: .bold))
                        .foregroundStyle(AB.darkest)
                        .padding(.top, 12)

                    // Toggles
                    VStack(spacing: 0) {
                        toggleRow(
                            title: "Sound effects",
                            icon: "speaker.wave.2.fill",
                            value: binding(\.soundEffects) { AudioService.shared.soundEffectsEnabled = $0 }
                        )
                        Divider().overlay(AB.neutral300)
                        toggleRow(
                            title: "Daily reminder",
                            icon: "bell.fill",
                            value: binding(\.dailyReminder) { NotificationService.setDailyReminder(enabled: $0) }
                        )
                        Divider().overlay(AB.neutral300)
                        toggleRow(
                            title: "Dark mode (preview)",
                            icon: "moon.fill",
                            value: binding(\.darkModePreview) { _ in }
                        )
                    }
                    .abCard()

                    // Reset
                    Button {
                        showResetConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset Progress")
                                .font(.system(size: AB.body, weight: .semibold))
                            Spacer()
                        }
                        .foregroundStyle(AB.error)
                        .padding(18)
                    }
                    .abCard()

                    // About
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About Alif Baa")
                            .font(.system(size: AB.body, weight: .semibold))
                            .foregroundStyle(AB.darkest)
                        Text("Learn to read and write the Arabic alphabet, from zero. Fully offline — no account, no ads, no analytics.")
                            .font(.system(size: AB.small))
                            .foregroundStyle(AB.neutral400)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Version \(appVersion)")
                            .font(.system(size: AB.caption))
                            .foregroundStyle(AB.neutral400)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .abCard()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            if showToast {
                VStack {
                    Spacer()
                    ToastView(message: "Progress has been reset")
                        .padding(.bottom, 24)
                }
            }
        }
        .confirmationDialog(
            "Reset all progress?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset Progress", role: .destructive) { resetProgress() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All lessons return to their initial state and review history is cleared.")
        }
        .onAppear {
            AudioService.shared.soundEffectsEnabled = settings?.soundEffects ?? true
        }
    }

    private func toggleRow(title: LocalizedStringKey, icon: String, value: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(AB.primary)
                .frame(width: 32)
            Toggle(title, isOn: value)
                .font(.system(size: AB.body))
                .foregroundStyle(AB.darkest)
                .tint(AB.primary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    /// Binding into the UserSettings row with a side effect on change.
    private func binding(
        _ keyPath: ReferenceWritableKeyPath<UserSettings, Bool>,
        onChange: @escaping (Bool) -> Void
    ) -> Binding<Bool> {
        Binding(
            get: { settings?[keyPath: keyPath] ?? (keyPath == \.soundEffects) },
            set: { newValue in
                guard let settings else { return }
                settings[keyPath: keyPath] = newValue
                try? context.save()
                onChange(newValue)
            }
        )
    }

    /// Returns lessons to their initial locked/unlocked state and clears SRS history (§4.5).
    private func resetProgress() {
        let lessons = (try? context.fetch(FetchDescriptor<Lesson>())) ?? []
        let level = ReadingLevel(rawValue: settings?.readingLevel ?? "") ?? .beginner
        for lesson in lessons {
            lesson.isComplete = false
            lesson.isUnlocked = level.unlocksAllLessons || lesson.num == 1
        }
        try? context.delete(model: UserProgress.self)
        try? context.save()

        withAnimation { showToast = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { showToast = false }
        }
    }
}
