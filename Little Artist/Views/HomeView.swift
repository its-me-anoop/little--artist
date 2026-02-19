//
//  HomeView.swift
//  Little Artist
//
//  The main screen showing child filter chips and their artwork gallery.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI
import SwiftData

/// The primary view displayed as the Gallery tab.
///
/// Shows a horizontal child filter chip bar, the ``ArtworkGalleryView``
/// (or an appropriate empty state), and a floating action button for
/// capturing new artwork.
struct HomeView: View {
    @Query(sort: \Child.createdAt) private var children: [Child]
    @State private var selectedChild: Child?
    @State private var showAddChild = false
    @State private var showAddArtwork = false
    @State private var editingChild: Child?

    private var filteredArtworks: [Artwork] {
        if let child = selectedChild {
            return (child.artworks ?? []).sorted { $0.createdAt > $1.createdAt }
        }
        // "All" selected — return all children's artworks
        return children.flatMap { $0.artworks ?? [] }.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Child filter chips
                if !children.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // "All" chip
                            Button {
                                withAnimation(.snappy) {
                                    selectedChild = nil
                                }
                            } label: {
                                Text("All")
                                    .font(Brand.caption2Font.weight(.medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedChild == nil ? Brand.primary : Color(.tertiarySystemFill))
                                    .foregroundStyle(selectedChild == nil ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)

                            ForEach(children) { child in
                                ChildFilterChipView(
                                    child: child,
                                    isSelected: selectedChild?.persistentModelID == child.persistentModelID
                                ) {
                                    withAnimation(.snappy) {
                                        if selectedChild?.persistentModelID == child.persistentModelID {
                                            selectedChild = nil
                                        } else {
                                            selectedChild = child
                                        }
                                    }
                                }
                            }

                            // Add child chip
                            Button { showAddChild = true } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("Add")
                                        .font(Brand.caption2Font.weight(.medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.tertiarySystemFill))
                                .foregroundStyle(Brand.primary)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, Brand.screenPadding)
                        .padding(.vertical, 8)
                    }
                }

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
                if !children.isEmpty {
                    AddArtworkButton(action: { showAddArtwork = true })
                }
            }
            .navigationTitle("Gallery")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SearchView()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
            .sheet(isPresented: $showAddChild) {
                AddChildView()
            }
            .sheet(isPresented: $showAddArtwork) {
                if let child = selectedChild ?? children.first {
                    AddArtworkView(child: child)
                }
            }
            .sheet(item: $editingChild) { child in
                EditChildView(child: child) {
                    if selectedChild?.persistentModelID == child.persistentModelID {
                        selectedChild = nil
                    }
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
