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
    @Query private var allArtworks: [Artwork]

    @Environment(\.horizontalSizeClass) private var sizeClass

    private let syncService = FirestoreSyncService.shared
    private var store: StoreKitManager { StoreKitManager.shared }

    @Binding var selectedChildID: PersistentIdentifier?
    @State private var selectedArtwork: Artwork?
    @State private var showAddChild = false
    @State private var editingChild: Child?
    @State private var paywallReason: PaywallView.LimitReason?

    private var selectedChild: Child? {
        guard let selectedChildID else { return nil }
        return children.first { $0.persistentModelID == selectedChildID }
    }

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
        if let selectedChildID {
            return allArtworks
                .filter { $0.child?.persistentModelID == selectedChildID }
                .sorted { $0.createdAt > $1.createdAt }
        }

        return allArtworks.sorted { $0.createdAt > $1.createdAt }
    }

    private var paywallPresented: Binding<PaywallView.LimitReason?> {
        Binding(
            get: { store.isPremium ? nil : paywallReason },
            set: { paywallReason = $0 }
        )
    }

    // MARK: - Master Header

    private var selectedChildMenuTitle: String {
        selectedChild?.name ?? "All Children"
    }

    private var selectedChildArtworkCountLabel: String {
        let count = filteredArtworks.count
        return "\(count) \(count == 1 ? "piece" : "pieces")"
    }

    @ViewBuilder
    private var selectedChildMenuAvatar: some View {
        if let selectedChild {
            Circle()
                .fill(Color(hex: selectedChild.avatarColor))
                .frame(width: 28, height: 28)
                .overlay {
                    if let data = selectedChild.avatarImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                    } else {
                        Text(String(selectedChild.name.prefix(1)).uppercased())
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
        } else {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Brand.primary)
                .frame(width: 28, height: 28)
                .glassEffect(.regular.tint(Brand.primary.opacity(0.16)), in: .circle)
        }
    }

    private var childSelectionMenu: some View {
        Menu {
            Button {
                HapticService.selection()
                withAnimation(.snappy) {
                    selectedChildID = nil
                }
            } label: {
                Label("All Children", systemImage: selectedChild == nil ? "checkmark" : "person.3.sequence.fill")
            }

            if !children.isEmpty {
                Divider()
            }

            ForEach(children) { child in
                Button {
                    HapticService.selection()
                    withAnimation(.snappy) {
                        selectedChildID = child.persistentModelID
                    }
                } label: {
                    Label(child.name, systemImage: selectedChildID == child.persistentModelID ? "checkmark" : "figure.child")
                }
            }

            Divider()

            Button {
                if PremiumManager.canAddChild(currentCount: children.count) {
                    showAddChild = true
                } else {
                    paywallReason = .children
                }
            } label: {
                Label("Add Child", systemImage: "plus")
            }
        } label: {
            HStack(spacing: 12) {
                selectedChildMenuAvatar

                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedChildMenuTitle)
                        .font(Brand.subheadlineFont.weight(.semibold))
                        .foregroundStyle(Brand.charcoal)
                        .lineLimit(1)

                    Text(selectedChildArtworkCountLabel)
                        .font(Brand.caption2Font)
                        .foregroundStyle(Brand.warmGray)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                if let selectedChild, selectedChild.isShared {
                    Image(systemName: "person.2.badge.gearshape.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Brand.primary)
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Brand.warmGray)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .menuStyle(.button)
        .buttonStyle(.glass)
        .tint(Brand.primary)
        .accessibilityLabel("Child filter, \(selectedChildMenuTitle)")
    }

    private var masterHeader: some View {
        VStack(spacing: 0) {
            artlingHeader

            if !children.isEmpty {
                GlassEffectContainer(spacing: 14) {
                    HStack(spacing: 12) {
                        childSelectionMenu
                    }
                    .padding(.horizontal, Brand.Adaptive.screenPadding(for: sizeClass))
                    .padding(.vertical, 10)
                }
            }
        }
    }

    private var artlingHeader: some View {
        HStack(spacing: 12) {
            Image("LaunchFox")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)

            Text("Artling")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Brand.Adaptive.screenPadding(for: sizeClass))
        .padding(.top, 8)
        .padding(.bottom, children.isEmpty ? 16 : 12)
    }

    private var onThisDaySection: some View {
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
        .background(Brand.backgroundBase)
    }

    private var galleryScreen: some View {
        Group {
            if children.isEmpty {
                NoChildrenView(onAddChild: { showAddChild = true })
            } else if filteredArtworks.isEmpty {
                NoArtworkView()
            } else {
                ArtworkGalleryView(
                    artworks: filteredArtworks,
                    headerContent: AnyView(artlingHeader),
                    topContent: memoriesArtworks.isEmpty ? nil : AnyView(onThisDaySection),
                    pinsControlsToTop: false,
                    usesToolbarControls: true
                )
            }
        }
    }

    private var compactGalleryScreen: some View {
        Group {
            if children.isEmpty {
                NoChildrenView(onAddChild: { showAddChild = true })
            } else if filteredArtworks.isEmpty {
                NoArtworkView()
            } else {
                ArtworkGalleryView(
                    artworks: filteredArtworks,
                    headerContent: AnyView(EmptyView()),
                    topContent: memoriesArtworks.isEmpty ? nil : AnyView(onThisDaySection),
                    pinsControlsToTop: false,
                    usesToolbarControls: true
                )
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if sizeClass == .regular {
            // iPad: master-detail split
            HStack(spacing: 0) {
                // Master pane
                VStack(spacing: 0) {
                    masterHeader
                        .zIndex(1)

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
                            selectedArtworkID: selectedArtwork?.persistentModelID,
                            headerContent: AnyView(EmptyView()),
                            topContent: memoriesArtworks.isEmpty ? nil : AnyView(onThisDaySection)
                        )
                        .clipped()
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
            compactGalleryScreen
        }
    }

    // MARK: - Body

    var body: some View {
        mainContent
            .navigationTitle("Artling")
            .navigationBarTitleDisplayMode(.large)
            .background(BrandAppBackground())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image("LaunchFox")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                        .accessibilityHidden(true)
                }

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
            .sheet(item: $editingChild) { child in
                EditChildView(child: child) {
                    if selectedChildID == child.persistentModelID {
                        selectedChildID = nil
                    }
                }
            }
            .sheet(item: paywallPresented) { reason in
                PaywallView(reason: reason)
            }
            .onChange(of: selectedChildID) { _, _ in
                // Clear stale selection when child filter changes
                if let selectedArtwork, !filteredArtworks.contains(where: { $0.persistentModelID == selectedArtwork.persistentModelID }) {
                    self.selectedArtwork = nil
                }
            }
            .onChange(of: store.isPremium) { _, isPremium in
                guard isPremium else { return }
                paywallReason = nil
            }
            .onAppear {
                if UserDefaults.standard.bool(forKey: "notificationsEnabled") {
                    NotificationService.scheduleAll(artworks: allArtworks)
                }
            }
    }
}

// MARK: - Previews

#Preview("Empty State") {
    HomeView(selectedChildID: .constant(nil))
        .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
}

#Preview("With Data") {
    HomeView(selectedChildID: .constant(nil))
        .modelContainer(PreviewSampleData.container)
}
