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
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Gallery", systemImage: "photo.on.rectangle.angled")
                }
                .tag(0)

            TimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                }
                .tag(1)

            MilestonesView()
                .tabItem {
                    Label("Milestones", systemImage: "star.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(Brand.primary)
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewSampleData.container)
}
