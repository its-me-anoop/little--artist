//
//  ContentView.swift
//  Little Artist
//
//  Root view displayed after onboarding. Provides a 4-tab navigation
//  shell: Gallery, Timeline, Milestones, and Settings.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI
import SwiftData

/// The root content view displayed after onboarding is complete.
struct ContentView: View {
    @State private var selectedTab: AppTab = .gallery

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Gallery", systemImage: "photo.on.rectangle.angled", value: .gallery) {
                HomeView()
            }

            Tab("Timeline", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90", value: .timeline) {
                TimelineView()
            }

            Tab("Milestones", systemImage: "star", value: .milestones) {
                MilestonesView()
            }

            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView()
            }

            Tab(value: .search, role: .search) {
                NavigationStack {
                    SearchView()
                }
            }
        }
        .tint(Brand.primary)
        .toolbarBackground(Brand.backgroundBase, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

// MARK: - Tab Identifier

enum AppTab: Hashable {
    case gallery
    case timeline
    case milestones
    case settings
    case search
}

#Preview {
    ContentView()
        .modelContainer(PreviewSampleData.container)
}
