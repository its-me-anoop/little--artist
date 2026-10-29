//
//  ContentView.swift
//  Little Artist
//
//  Root view displayed after onboarding. Provides the main 4-tab navigation
//  shell (Gallery, Timeline, Milestones, Settings) with a floating action button.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI
import SwiftData
import StoreKit

/// The root content view displayed after onboarding is complete.
struct ContentView: View {
    @Query(sort: \Child.createdAt) private var children: [Child]
    @Query private var allArtworks: [Artwork]

    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    @AppStorage("hasSeenFirstArtworkUpsell") private var hasSeenUpsell = false

    @State private var selectedTab: AppTab = .gallery
    @State private var selectedChildID: PersistentIdentifier?
    @State private var showCreateSheet = false
    @State private var showAddChild = false
    @State private var showPremiumUpsell = false
    @State private var showSlideshow = false
    @State private var paywallReason: PaywallView.LimitReason?
    @State private var artworkCountBeforeSheet = 0

    private var store: StoreKitManager { StoreKitManager.shared }
    private var celebration: CelebrationCenter { CelebrationCenter.shared }
    private var reviewPrompt: ReviewPromptService { ReviewPromptService.shared }

    /// True when nothing modal is on screen, so a rating prompt won't
    /// interrupt the user mid-task.
    private var isIdleForReviewPrompt: Bool {
        celebration.current == nil
            && !showCreateSheet && !showAddChild && !showSlideshow
            && !showPremiumUpsell && paywallReason == nil
    }

    /// Artworks in chronological order for exhibition mode, so the
    /// slideshow tells the growth story from first to latest.
    private var slideshowArtworks: [Artwork] {
        allArtworks.sorted { $0.createdAt < $1.createdAt }
    }

    private var selectedChild: Child? {
        guard let selectedChildID else { return nil }
        return children.first { $0.persistentModelID == selectedChildID }
    }

    private var premiumUpsellPresented: Binding<Bool> {
        Binding(
            get: { showPremiumUpsell && !store.isPremium },
            set: { showPremiumUpsell = $0 }
        )
    }

    private var paywallPresented: Binding<PaywallView.LimitReason?> {
        Binding(
            get: { store.isPremium ? nil : paywallReason },
            set: { paywallReason = $0 }
        )
    }

    private func presentCreateFlow() {
        if children.isEmpty {
            showAddChild = true
        } else if PremiumManager.canAddArtwork(currentCount: allArtworks.count) {
            artworkCountBeforeSheet = allArtworks.count
            showCreateSheet = true
        } else {
            paywallReason = .artworks
        }
    }

    private var galleryRoot: some View {
        NavigationStack {
            HomeView(selectedChildID: $selectedChildID)
                .toolbar {
                    if !allArtworks.isEmpty {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showSlideshow = true
                            } label: {
                                Image(systemName: "play.rectangle")
                            }
                            .accessibilityLabel("Play slideshow")
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            SearchView()
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                }
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                Tab("Gallery", systemImage: "photo.on.rectangle.angled", value: .gallery) {
                    galleryRoot
                }

                Tab("Timeline", systemImage: "book.pages", value: .timeline) {
                    NavigationStack {
                        TimelineView()
                    }
                }

                Tab("Milestones", systemImage: "medal", value: .milestones) {
                    NavigationStack {
                        MilestonesView()
                    }
                }

                Tab("Settings", systemImage: "slider.horizontal.3", value: .settings) {
                    NavigationStack {
                        SettingsView()
                    }
                }
            }

            // Floating Action Button
            Button {
                presentCreateFlow()
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: Brand.fabSize, height: Brand.fabSize)
                    .background(Brand.primary)
                    .clipShape(Circle())
                    .brandFABShadow()
            }
            .accessibilityLabel("Add artwork")
            .padding(.trailing, Brand.screenPadding)
            .padding(.bottom, 80)
        }
        .sheet(isPresented: $showAddChild) {
            AddChildView()
        }
        .sheet(isPresented: $showCreateSheet, onDismiss: {
            let savedCount = allArtworks.count - artworkCountBeforeSheet
            if savedCount > 0 {
                reviewPrompt.record(.artworkSaved(count: savedCount))
            }
            if artworkCountBeforeSheet == 0
                && allArtworks.count > artworkCountBeforeSheet
                && !store.isPremium
                && !hasSeenUpsell
            {
                hasSeenUpsell = true
                showPremiumUpsell = true
            }
        }) {
            // Honor the current child filter — attribute the new artwork to
            // the selected child when one is active, otherwise fall back to
            // the first child in creation order.
            if let child = selectedChild ?? children.first {
                AddArtworkView(child: child)
                    .adaptiveSheetSizing(sizeClass: sizeClass)
            }
        }
        .sheet(isPresented: premiumUpsellPresented) {
            PremiumUpsellView()
        }
        .sheet(item: paywallPresented) { reason in
            PaywallView(reason: reason)
        }
        .fullScreenCover(isPresented: $showSlideshow) {
            ArtworkSlideshowView(artworks: slideshowArtworks)
        }
        .overlay {
            if let achievement = celebration.current {
                AchievementCelebrationView(achievement: achievement) {
                    celebration.dismissCurrent()
                    reviewPrompt.record(.milestoneCelebrated)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.3), value: celebration.current?.identifier)
        .onChange(of: store.isPremium) { _, isPremium in
            guard isPremium else { return }
            paywallReason = nil
            showPremiumUpsell = false
        }
        .task(id: reviewPrompt.shouldRequestReview && isIdleForReviewPrompt) {
            guard reviewPrompt.shouldRequestReview, isIdleForReviewPrompt else { return }
            // Let the dismiss animation settle so the prompt feels calm.
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled, isIdleForReviewPrompt else { return }
            reviewPrompt.didRequestReview()
            requestReview()
        }
        // Keep the Home Screen widget fresh.
        .task(id: allArtworks.count) {
            WidgetSnapshotService.refresh(container: modelContext.container)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                WidgetSnapshotService.refresh(container: modelContext.container)
            }
        }
        .onChange(of: QuickActionRouter.shared.pendingAction, initial: true) { _, action in
            guard let action else { return }
            handleQuickAction(action)
        }
    }

    /// Consumes a pending Siri / shortcut action and navigates to it.
    private func handleQuickAction(_ action: QuickActionRouter.Action) {
        QuickActionRouter.shared.pendingAction = nil
        switch action {
        case .captureArtwork:
            selectedTab = .gallery
            presentCreateFlow()
        case .showMilestones:
            selectedTab = .milestones
        case .showTimeline:
            selectedTab = .timeline
        }
    }
}

// MARK: - Tab Identifier

enum AppTab: Hashable {
    case gallery
    case timeline
    case milestones
    case settings
}

#Preview {
    ContentView()
        .modelContainer(PreviewSampleData.container)
}
