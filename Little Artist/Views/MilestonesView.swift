//
//  MilestonesView.swift
//  Little Artist
//
//  Statistics dashboard with achievement badges, capture streaks,
//  and per-child artwork breakdowns.
//

import SwiftUI
import SwiftData

struct MilestonesView: View {
    @Query private var children: [Child]
    @Query private var artworks: [Artwork]

    var body: some View {
        NavigationStack {
            Text("Milestones coming soon")
                .font(Brand.bodyFont)
                .foregroundStyle(.secondary)
                .navigationTitle("Milestones")
        }
    }
}

#Preview {
    MilestonesView()
        .modelContainer(PreviewSampleData.container)
}
