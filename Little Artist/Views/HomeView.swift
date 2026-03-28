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
/// Shows a bento-style gallery with a child filter slider, a "Today" section
/// featuring artwork cards and memory lane, and an "Earlier this Month" grid.
struct HomeView: View {
    @Query(sort: \Child.createdAt) private var children: [Child]
    @Query private var allArtworks: [Artwork]

    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.modelContext) private var modelContext

    private var store: StoreKitManager { StoreKitManager.shared }

    @Binding var selectedChildID: PersistentIdentifier?
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

    // MARK: - Navigation Metadata

    private var selectedChildMenuTitle: String {
        selectedChild?.name ?? "All Children"
    }

    private var selectedChildArtworkCountLabel: String {
        let count = filteredArtworks.count
        return "\(count) \(count == 1 ? "piece" : "pieces")"
    }

    private var navigationTitleText: String {
        children.isEmpty ? "Artling" : selectedChildMenuTitle
    }

    private var navigationSubtitleText: String? {
        guard !children.isEmpty else { return nil }
        return selectedChildArtworkCountLabel
    }

    private func selectChild(_ childID: PersistentIdentifier?) {
        HapticService.selection()
        withAnimation(.snappy) {
            selectedChildID = childID
        }
    }

    private func showAddChildFlow() {
        if PremiumManager.canAddChild(currentCount: children.count) {
            showAddChild = true
        } else {
            paywallReason = .children
        }
    }

    // MARK: - Child Filter Binding

    /// Bridges the PersistentIdentifier binding to a Child? binding for ChildSliderView.
    private var selectedChildBinding: Binding<Child?> {
        Binding(
            get: { selectedChild },
            set: { child in
                withAnimation(.snappy) {
                    selectedChildID = child?.persistentModelID
                }
            }
        )
    }

    // MARK: - Bento Layout Helpers

    /// Artworks for the Latest bento section (up to 4).
    private var latestArtworks: [Artwork] {
        Array(filteredArtworks.prefix(4))
    }

    /// The featured (largest) artwork for the bento grid.
    private var featuredArtwork: Artwork? {
        latestArtworks.first
    }

    /// Smaller artworks for the bento grid (indices 1-3).
    private var secondaryArtworks: [Artwork] {
        guard latestArtworks.count > 1 else { return [] }
        return Array(latestArtworks.dropFirst())
    }

    /// Artworks after the Latest section for the "More" grid.
    private var earlierArtworks: [Artwork] {
        guard filteredArtworks.count > 4 else { return [] }
        return Array(filteredArtworks.dropFirst(4))
    }

    // MARK: - Latest Section Header

    private var latestSectionHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("GALLERY")
                    .font(Brand.caption2Font)
                    .fontWeight(.bold)
                    .tracking(2)
                    .foregroundStyle(Brand.warmGray)
                Text("Latest")
                    .font(Brand.displayFont)
                    .foregroundStyle(Brand.charcoal)
            }
            Spacer()
            Text(Date.now.formatted(.dateTime.month(.abbreviated).day()))
                .font(Brand.captionFont)
                .fontWeight(.bold)
                .foregroundStyle(Brand.charcoal)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Brand.surface)
                .clipShape(Capsule())
        }
    }

    // MARK: - Memory Card

    private func memoryCard(_ artwork: Artwork) -> some View {
        NavigationLink(value: artwork) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption2)
                    Text("MEMORY LANE")
                        .font(Brand.caption2Font)
                        .fontWeight(.bold)
                        .tracking(1.5)
                }
                .foregroundStyle(Brand.warmGray)

                Text("On this day...")
                    .font(Brand.headlineFont)
                    .foregroundStyle(Brand.charcoal)

                if let data = artwork.thumbnailData ?? artwork.imageData,
                   let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusImage))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.lavender.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded {
            AchievementService.markMemoryViewed(context: modelContext)
        })
    }

    // MARK: - Bento Grid

    private var bentoGrid: some View {
        let hasMemory = !memoriesArtworks.isEmpty
        let padding = Brand.Adaptive.screenPadding(for: sizeClass)

        return VStack(spacing: 12) {
            // Row 1: Featured artwork + memory/secondary card
            HStack(spacing: 12) {
                // Featured artwork (largest card)
                if let featured = featuredArtwork {
                    NavigationLink(value: featured) {
                        BentoArtworkCardView(
                            artwork: featured,
                            rotation: -1
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Right column: Memory card or secondary artwork
                VStack(spacing: 12) {
                    if hasMemory {
                        memoryCard(memoriesArtworks[0].artwork)
                    }

                    if let second = secondaryArtworks.first {
                        NavigationLink(value: second) {
                            BentoArtworkCardView(
                                artwork: second,
                                rotation: hasMemory ? 1.5 : 2
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Row 2: Two smaller cards
            if secondaryArtworks.count > 1 {
                HStack(spacing: 12) {
                    ForEach(Array(secondaryArtworks.dropFirst().enumerated()), id: \.element.persistentModelID) { index, artwork in
                        NavigationLink(value: artwork) {
                            BentoArtworkCardView(
                                artwork: artwork,
                                rotation: index.isMultiple(of: 2) ? -1.5 : 1.5
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, padding)
    }

    // MARK: - Earlier This Month Section

    private var earlierThisMonthSection: some View {
        let padding = Brand.Adaptive.screenPadding(for: sizeClass)
        let columnCount = sizeClass == .regular ? 4 : 2
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Earlier this Month")
                .font(Brand.title2Font)
                .foregroundStyle(Brand.charcoal)
                .padding(.horizontal, padding)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(earlierArtworks.enumerated()), id: \.element.persistentModelID) { index, artwork in
                    NavigationLink(value: artwork) {
                        BentoArtworkCardView(
                            artwork: artwork,
                            rotation: index.isMultiple(of: 2) ? -1 : 1
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, padding)
        }
    }

    // MARK: - Gallery Layout

    private var compactGalleryScreen: some View {
        Group {
            if children.isEmpty {
                NoChildrenView(onAddChild: { showAddChild = true })
            } else {
                ScrollView {
                    VStack(spacing: Brand.sectionSpacing) {
                        // Child filter slider — always visible so user can switch children
                        ChildSliderView(
                            children: children,
                            selectedChild: selectedChildBinding,
                            onAddChild: showAddChildFlow,
                            onEditChild: { child in
                                editingChild = child
                            }
                        )

                        if filteredArtworks.isEmpty {
                            NoArtworkView()
                                .padding(.top, Brand.sectionSpacing)
                        } else {
                            // Today section
                            VStack(alignment: .leading, spacing: 16) {
                                latestSectionHeader
                                    .padding(.horizontal, Brand.Adaptive.screenPadding(for: sizeClass))

                                bentoGrid
                            }

                            // Earlier this Month section
                            if !earlierArtworks.isEmpty {
                                earlierThisMonthSection
                            }
                        }
                    }
                    .padding(.bottom, 100) // Space for FAB
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    // MARK: - Main Content

    /// Uses the same bento gallery on both iPhone and iPad.
    /// iPad gets more columns in the "Earlier" grid via Brand.Adaptive.
    /// Artwork detail is always pushed via NavigationLink, never shown in a split pane.
    @ViewBuilder
    private var mainContent: some View {
        compactGalleryScreen
    }

    // MARK: - Body

    var body: some View {
        mainContent
            .navigationTitle(navigationTitleText)
            .navigationBarTitleDisplayMode(.large)
            .background(BrandAppBackground())
            .navigationDestination(for: Artwork.self) { artwork in
                ArtworkDetailView(artwork: artwork)
            }
            .toolbar {
                if #available(iOS 26.0, *), let navigationSubtitleText {
                    ToolbarItem(placement: .subtitle) {
                        Text(navigationSubtitleText)
                            .lineLimit(1)
                    }
                }

                if !children.isEmpty {
                    ToolbarTitleMenu {
                        Button {
                            selectChild(nil)
                        } label: {
                            Label(
                                "All Children",
                                systemImage: selectedChild == nil ? "checkmark" : "person.3.sequence.fill"
                            )
                        }

                        Divider()

                        ForEach(children) { child in
                            Button {
                                selectChild(child.persistentModelID)
                            } label: {
                                Label(
                                    child.name,
                                    systemImage: selectedChildID == child.persistentModelID ? "checkmark" : "figure.child"
                                )
                            }
                        }

                        Divider()

                        Button {
                            showAddChildFlow()
                        } label: {
                            Label("Add Child", systemImage: "plus")
                        }
                    }
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
                EditChildView(child: child)
            }
            .sheet(item: paywallPresented) { reason in
                PaywallView(reason: reason)
            }
            .onChange(of: selectedChildID) { _, _ in
                // Child filter changed — UI updates via filteredArtworks
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
