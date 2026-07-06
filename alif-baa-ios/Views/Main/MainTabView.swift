//
//  MainTabView.swift
//  alif-baa-ios
//
//  Three-tab main app: Alphabet / Content / Settings (§3.1).
//

import SwiftUI

struct MainTabView: View {
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            AlphabetView(tabSelection: $selection)
                .tabItem { Label("Alphabet", systemImage: "character.book.closed") }
                .tag(0)

            ContentLibraryView()
                .tabItem { Label("Content", systemImage: "books.vertical") }
                .tag(1)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(2)
        }
        .tint(AB.primary)
    }
}
