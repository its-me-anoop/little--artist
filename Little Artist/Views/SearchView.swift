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

    @State private var searchText = ""
    @State private var selectedChildIDs: Set<PersistentIdentifier> = []
    @State private var showFavoritesOnly = false
    @AppStorage("recentSearches") private var recentSearchesData: Data = Data()

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

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

        // Text search
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            results = results.filter { artwork in
                artwork.title.lowercased().contains(query) ||
                artwork.caption.lowercased().contains(query)
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
                                            .font(Brand.caption2Font)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color(.tertiarySystemFill))
                                            .clipShape(Capsule())
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
                                        .font(Brand.caption2Font.weight(.medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(showFavoritesOnly ? Brand.dustyRose : Color(.tertiarySystemFill))
                                .foregroundStyle(showFavoritesOnly ? .white : .primary)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, Brand.screenPadding)
                    }
                }

                // Results
                if !searchText.isEmpty || !selectedChildIDs.isEmpty || showFavoritesOnly {
                    Text("Results (\(filteredArtworks.count))")
                        .font(Brand.caption2Font.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Brand.screenPadding)

                    if filteredArtworks.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40, design: .rounded))
                                .foregroundStyle(Brand.primary.opacity(0.4))
                            Text("No artwork found")
                                .font(Brand.subheadlineFont.weight(.medium))
                            Text("Try a different search or adjust filters")
                                .font(Brand.caption2Font)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(filteredArtworks) { artwork in
                                NavigationLink {
                                    ArtworkDetailView(artwork: artwork)
                                } label: {
                                    ArtworkThumbnailView(artwork: artwork)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Brand.screenPadding)
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
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
    .modelContainer(PreviewSampleData.container)
}
