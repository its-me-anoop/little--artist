//
//  HomeView.swift
//  Little Artist
//
//  The main screen showing child filter chips and their artwork gallery.
//
//  Created by Anoop Jose on 13/02/2026.
//

import CloudKit
import SwiftUI
import SwiftData

/// The primary view displayed as the Gallery tab.
///
/// Shows a horizontal child filter chip bar, the ``ArtworkGalleryView``
/// (or an appropriate empty state), and a floating action button for
/// capturing new artwork.
struct HomeView: View {
    @Query(sort: \Child.createdAt) private var children: [Child]
    @Query private var allArtworks: [Artwork]

    @Environment(\.horizontalSizeClass) private var sizeClass

    private let sharingService = CloudKitSharingService.shared

    @AppStorage("hasSeenFirstArtworkUpsell") private var hasSeenUpsell = false

    @State private var selectedChild: Child?
    @State private var selectedArtwork: Artwork?
    @State private var showAddChild = false
    @State private var showAddArtwork = false
    @State private var editingChild: Child?
    @State private var paywallReason: PaywallView.LimitReason?
    @State private var artworkCountBeforeSheet = 0
    @State private var showPremiumUpsell = false

    /// Artworks created on this day in previous years.
    private var memoriesArtworks: [(artwork: Artwork, yearsAgo: Int)] {
        let calendar = Calendar.current
        let today = calendar.dateComponents([.month, .day], from: Date.now)
        guard let todayMonth = today.month, let todayDay = today.day else { return [] }

        var results: [(artwork: Artwork, yearsAgo: Int)] = []
        for artwork in allArtworks {
            let components = calendar.dateComponents([.year, .month, .day], from: artwork.createdAt)
            if components.month == todayMonth && components.day == todayDay {
                let yearsAgo = (calendar.component(.year, from: Date.now)) - (components.year ?? 0)
                if yearsAgo >= 1 {
                    results.append((artwork: artwork, yearsAgo: yearsAgo))
                }
            }
        }
        return results.sorted { $0.yearsAgo < $1.yearsAgo }
    }

    private var filteredArtworks: [Artwork] {
        if let child = selectedChild {
            return (child.artworks ?? []).sorted { $0.createdAt > $1.createdAt }
        }
        // "All" selected — return all children's artworks
        return children.flatMap { $0.artworks ?? [] }.sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Master Header

    private var masterHeader: some View {
        VStack(spacing: 0) {
            // Child filter chips
            if !children.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // "All" chip
                        Button {
                            HapticService.selection()
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
                                HapticService.selection()
                                withAnimation(.snappy) {
                                    if selectedChild?.persistentModelID == child.persistentModelID {
                                        selectedChild = nil
                                    } else {
                                        selectedChild = child
                                    }
                                }
                            }
                            .overlay(alignment: .topTrailing) {
                                if sharingService.isInitialised {
                                    SharedBadgeView(
                                        participantCount: sharingService.existingShare(for: child)?.participants.count ?? 0,
                                        isShared: sharingService.isShared(child)
                                    )
                                    .offset(x: 6, y: -6)
                                }
                            }
                        }

                        // Add child chip
                        Button {
                            if PremiumManager.canAddChild(currentCount: children.count) {
                                showAddChild = true
                            } else {
                                paywallReason = .children
                            }
                        } label: {
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
                    .padding(.horizontal, Brand.Adaptive.screenPadding(for: sizeClass))
                    .padding(.vertical, 8)
                }
            }

            // On This Day memories
            if !memoriesArtworks.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(Brand.primary)
                        Text("On This Day")
                            .font(Brand.headlineFont)
                            .foregroundStyle(Brand.charcoal)
                    }
                    .padding(.horizontal, Brand.Adaptive.screenPadding(for: sizeClass))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(memoriesArtworks, id: \.artwork.persistentModelID) { memory in
                                if sizeClass == .regular {
                                    Button {
                                        selectedArtwork = memory.artwork
                                    } label: {
                                        MemoryCardView(
                                            artwork: memory.artwork,
                                            yearsAgo: memory.yearsAgo,
                                            cardWidth: 200
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    NavigationLink {
                                        ArtworkDetailView(artwork: memory.artwork)
                                    } label: {
                                        MemoryCardView(
                                            artwork: memory.artwork,
                                            yearsAgo: memory.yearsAgo,
                                            cardWidth: 160
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, Brand.Adaptive.screenPadding(for: sizeClass))
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Detail Placeholder

    private var detailPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.tap")
                .font(.system(size: 48, design: .rounded))
                .foregroundStyle(Brand.primary.opacity(0.3))
            Text("Select an artwork")
                .font(Brand.title3Font)
                .foregroundStyle(Brand.warmGray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if sizeClass == .regular {
                    // iPad: master-detail split
                    HStack(spacing: 0) {
                        // Master pane
                        VStack(spacing: 0) {
                            masterHeader

                            if children.isEmpty {
                                NoChildrenView(onAddChild: { showAddChild = true })
                            } else if filteredArtworks.isEmpty {
                                NoArtworkView()
                            } else {
                                ArtworkGalleryView(
                                    artworks: filteredArtworks,
                                    onSelect: { artwork in
                                        withAnimation(.snappy) {
                                            selectedArtwork = artwork
                                        }
                                    },
                                    selectedArtworkID: selectedArtwork?.persistentModelID
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)

                        Divider()

                        // Detail pane
                        Group {
                            if let selectedArtwork {
                                ArtworkDetailView(
                                    artwork: selectedArtwork,
                                    onDelete: {
                                        self.selectedArtwork = nil
                                    }
                                )
                                .id(selectedArtwork.persistentModelID)
                            } else {
                                detailPlaceholder
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    // iPhone: single-column
                    VStack(spacing: 0) {
                        masterHeader

                        if children.isEmpty {
                            NoChildrenView(onAddChild: { showAddChild = true })
                        } else if filteredArtworks.isEmpty {
                            NoArtworkView()
                        } else {
                            ArtworkGalleryView(artworks: filteredArtworks)
                        }
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if !children.isEmpty {
                    AddArtworkButton(action: {
                        if PremiumManager.canAddArtwork(currentCount: allArtworks.count) {
                            artworkCountBeforeSheet = allArtworks.count
                            showAddArtwork = true
                        } else {
                            paywallReason = .artworks
                        }
                    })
                }
            }
            .navigationTitle("Gallery")
            .toolbar {
                if let selectedChild {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            ArtworkComparisonView(child: selectedChild)
                        } label: {
                            Image(systemName: "rectangle.split.2x1")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddChild) {
                AddChildView()
            }
            .sheet(isPresented: $showAddArtwork, onDismiss: {
                if artworkCountBeforeSheet == 0
                    && allArtworks.count > artworkCountBeforeSheet
                    && !PremiumManager.isPremium
                    && !hasSeenUpsell
                {
                    hasSeenUpsell = true
                    showPremiumUpsell = true
                }
            }) {
                if let child = selectedChild ?? children.first {
                    AddArtworkView(child: child)
                        .adaptiveSheetSizing(sizeClass: sizeClass)
                }
            }
            .sheet(isPresented: $showPremiumUpsell) {
                PremiumUpsellView()
            }
            .sheet(item: $editingChild) { child in
                EditChildView(child: child) {
                    if selectedChild?.persistentModelID == child.persistentModelID {
                        selectedChild = nil
                    }
                }
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
            .onChange(of: selectedChild) { _, _ in
                // Clear stale selection when child filter changes
                if let selectedArtwork, !filteredArtworks.contains(where: { $0.persistentModelID == selectedArtwork.persistentModelID }) {
                    self.selectedArtwork = nil
                }
            }
            .onAppear {
                if UserDefaults.standard.bool(forKey: "notificationsEnabled") {
                    NotificationService.scheduleAll(artworks: allArtworks)
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
