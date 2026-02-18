//
//  ContentView.swift
//  Little Artist
//
//  Root view displayed after onboarding. Wraps the main ``HomeView``.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI
import SwiftData

/// The root content view displayed after onboarding is complete.
struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewSampleData.container)
}
