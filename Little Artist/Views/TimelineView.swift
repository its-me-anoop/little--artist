//
//  TimelineView.swift
//  Little Artist
//
//  Chronological feed of all artworks with sticky month headers
//  and a vertical timeline spine visualization.
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    @Query(sort: \Artwork.createdAt, order: .reverse) private var artworks: [Artwork]

    var body: some View {
        NavigationStack {
            Text("Timeline coming soon")
                .font(Brand.bodyFont)
                .foregroundStyle(.secondary)
                .navigationTitle("Timeline")
        }
    }
}

#Preview {
    TimelineView()
        .modelContainer(PreviewSampleData.container)
}
