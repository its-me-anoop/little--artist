//
//  HomeView.swift
//  Little Artist
//
//  The main screen showing the child profile slider and their artwork gallery.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI
import SwiftData

/// The primary view displayed after onboarding.
///
/// Shows a horizontal ``ChildSliderView`` for selecting a child profile,
/// the child's ``ArtworkGalleryView`` (or an appropriate empty state),
/// and a floating action button for capturing new artwork.
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Child.createdAt) private var children: [Child]
    @State private var selectedChild: Child?
    @State private var showAddChild = false
    @State private var showAddArtwork = false

    private var filteredArtworks: [Artwork] {
        guard let child = selectedChild else { return [] }
        return (child.artworks ?? []).sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Child profile slider
                ChildSliderView(
                    children: children,
                    selectedChild: $selectedChild,
                    onAddChild: { showAddChild = true }
                )
                .padding(.top, 8)

                Divider()
                    .padding(.top, 12)

                // Art gallery or empty state
                if children.isEmpty {
                    NoChildrenView(onAddChild: { showAddChild = true })
                } else if filteredArtworks.isEmpty {
                    NoArtworkView()
                } else {
                    ArtworkGalleryView(artworks: filteredArtworks)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if selectedChild != nil {
                    AddArtworkButton(action: { showAddArtwork = true })
                }
            }
            .navigationTitle("Little Artist")
            .sheet(isPresented: $showAddChild) {
                AddChildView()
            }
            .sheet(isPresented: $showAddArtwork) {
                if let selectedChild {
                    AddArtworkView(child: selectedChild)
                }
            }
            .onAppear {
                if selectedChild == nil {
                    selectedChild = children.first
                }
            }
            .onChange(of: children.count) {
                if selectedChild == nil {
                    selectedChild = children.first
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Empty State") {
    HomeView()
        .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
}

#Preview("With Data") {
    HomeView()
        .modelContainer(PreviewSampleData.container)
}
