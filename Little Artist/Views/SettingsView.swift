//
//  SettingsView.swift
//  Little Artist
//
//  App settings with children management, preferences,
//  data management, and about section.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query(sort: \Child.createdAt) private var children: [Child]

    var body: some View {
        NavigationStack {
            Text("Settings coming soon")
                .font(Brand.bodyFont)
                .foregroundStyle(.secondary)
                .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewSampleData.container)
}
