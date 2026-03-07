//
//  SearchView.swift
//  Little Artist
//
//  Full-text search across artwork titles and captions with
//  child filter chips and recent search history.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Query(sort: \Artwork.createdAt, order: .reverse) private var allArtworks: [Artwork]
    @Query(sort: \Child.createdAt) private var children: [Child]
    @Query(sort: \Tag.name) private var allTags: [Tag]

    @State private var searchText = ""
    @State private var selectedChildIDs: Set<PersistentIdentifier> = []
    @State private var selectedTagIDs: Set<PersistentIdentifier> = []
    @State private var showFavoritesOnly = false
    @AppStorage("recentSearches") private var recentSearchesData: Data = Data()

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var availableWidth: CGFloat = 390

    private var recentSearches: [String] {
        (try? JSONDecoder().decode([String].self, from: recentSearchesData)) ?? []
    }

    private func saveSearch(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var searches = recentSearches.filter { $0 != trimmed }
        searches.insert(trimmed, at: 0)
        if searches.count > 10 { searches = Array(searches.prefix(10)) }
        recentSearchesData = (try? JSONEncoder().encode(searches)) ?? Data()
    }

    private var filteredArtworks: [Artwork] {
        var results = allArtworks

        // Child filter
        if !selectedChildIDs.isEmpty {
            results = results.filter { artwork in
                guard let child = artwork.child else { return false }
                return selectedChildIDs.contains(child.persistentModelID)
            }
        }

        // Favorites filter
        if showFavoritesOnly {
            results = results.filter(\.isFavorited)
        }

        // Tag filter
        if !selectedTagIDs.isEmpty {
            results = results.filter { artwork in
                guard let tags = artwork.tags else { return false }
                return tags.contains { selectedTagIDs.contains($0.persistentModelID) }
            }
        }

        // Text search
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            results = results.filter { artwork in
                artwork.title.lowercased().contains(query) ||
                artwork.caption.lowercased().contains(query) ||
                artwork.tags?.contains { $0.name.lowercased().contains(query) } == true
            }
        }

        return results
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // Recent searches (shown when search is empty)
                if searchText.isEmpty && !recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Searches")
                            .font(Brand.caption2Font.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, Brand.screenPadding)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recentSearches, id: \.self) { term in
                                    Button {
                                        searchText = term
                                    } label: {
                                            Text(term)
                                                .font(Brand.captionFont.bold())
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(Brand.glass.gradient)
                                                .foregroundStyle(Brand.charcoal)
                                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                        .stroke(Brand.glassStroke, lineWidth: 1.5)
                                                )
                                                .crayonStyle()
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, Brand.screenPadding)
                        }
                    }
                }

                // Filter chips
                VStack(alignment: .leading, spacing: 8) {
                    Text("Filter By")
                        .font(Brand.caption2Font.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Brand.screenPadding)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(children) { child in
                                ChildFilterChipView(
                                    child: child,
                                    isSelected: selectedChildIDs.contains(child.persistentModelID)
                                ) {
                                    withAnimation(.snappy) {
                                        if selectedChildIDs.contains(child.persistentModelID) {
                                            selectedChildIDs.remove(child.persistentModelID)
                                        } else {
                                            selectedChildIDs.insert(child.persistentModelID)
                                        }
                                    }
                                }
                            }

                            Button {
                                withAnimation(.snappy) {
                                    showFavoritesOnly.toggle()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                                        .font(.system(size: 11))
                                Text("Starred")
                                    .font(Brand.captionFont.bold())
                                    .crayonStyle()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(showFavoritesOnly ? Brand.dustyRose.gradient : Brand.glass.gradient)
                            .foregroundStyle(showFavoritesOnly ? .white : Brand.charcoal)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(showFavoritesOnly ? Brand.glassStrokeSoft : Brand.glassStroke, lineWidth: 2)
                            )
                            .shadow(color: showFavoritesOnly ? Brand.dustyRose.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, Brand.screenPadding)
                    }
                }

                // Tag filter chips
                if !allTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(allTags) { tag in
                                TagChipView(
                                    name: tag.name,
                                    isSelected: selectedTagIDs.contains(tag.persistentModelID)
                                ) {
                                    withAnimation(.snappy) {
                                        if selectedTagIDs.contains(tag.persistentModelID) {
                                            selectedTagIDs.remove(tag.persistentModelID)
                                        } else {
                                            selectedTagIDs.insert(tag.persistentModelID)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Brand.screenPadding)
                    }
                }

                // Results
                if !searchText.isEmpty || !selectedChildIDs.isEmpty || showFavoritesOnly || !selectedTagIDs.isEmpty {
                    Text("Results (\(filteredArtworks.count))")
                        .font(Brand.caption2Font.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Brand.screenPadding)

                    if filteredArtworks.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40, design: .rounded))
                                .foregroundStyle(Brand.primary.opacity(0.4))
                            Text("No artwork found")
                                .font(Brand.title3Font.bold())
                                .foregroundStyle(Brand.charcoal)
                            Text("Try a different search or adjust filters")
                                .font(Brand.captionFont)
                                .foregroundStyle(Brand.warmGray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .fill(Brand.glass)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(Brand.glassStroke, lineWidth: 2)
                        )
                        .brandCardShadow()
                        .padding(.horizontal, Brand.screenPadding)
                        .padding(.top, 40)
                    } else {
                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible(), spacing: 12),
                                count: Brand.Adaptive.searchColumns(for: availableWidth)
                            ),
                            spacing: 12
                        ) {
                            ForEach(filteredArtworks) { artwork in
                                NavigationLink {
                                    ArtworkDetailView(artwork: artwork)
                                } label: {
                                    ArtworkThumbnailView(artwork: artwork)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Brand.Adaptive.screenPadding(for: sizeClass))
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search artwork...")
        .onSubmit(of: .search) {
            saveSearch(searchText)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(
            GeometryReader { geo in
                BrandAppBackground()
                    .ignoresSafeArea()
                    .onAppear { availableWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, newWidth in availableWidth = newWidth }
            }
        )
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
    .modelContainer(PreviewSampleData.container)
}
