//
//  AlifBaaApp.swift
//  alif-baa-ios
//
//  Alif Baa — learn to read and write the Arabic alphabet, from zero.
//  100% offline: no server, no account, no analytics (§5, §5.5).
//

import SwiftUI
import SwiftData

@main
struct AlifBaaApp: App {

    let container: ModelContainer

    init() {
        AB.registerBundledFonts()

        let schema = Schema([
            Letter.self,
            LetterForm.self,
            Lesson.self,
            Word.self,
            UserProgress.self,
            UserSettings.self,
        ])
        // UI tests run against a throwaway in-memory store for deterministic state.
        let isUITest = ProcessInfo.processInfo.arguments.contains("-uitest")
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITest)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        SeedData.seedIfNeeded(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
