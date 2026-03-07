//
//  ContentView.swift
//  Little Artist
//
//  Root view displayed after onboarding. Provides the main tab navigation
//  shell: Gallery and Search.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI
import SwiftData

/// The root content view displayed after onboarding is complete.
struct ContentView: View {
    @Query(sort: \Child.createdAt) private var children: [Child]
    @Query private var allArtworks: [Artwork]

    @Environment(\.horizontalSizeClass) private var sizeClass

    @AppStorage("hasSeenFirstArtworkUpsell") private var hasSeenUpsell = false

    @State private var selectedTab: AppTab = .gallery
    @State private var selectedChildID: PersistentIdentifier?
    @State private var searchText = ""
    @State private var showCreateSheet = false
    @State private var showAddChild = false
    @State private var showPremiumUpsell = false
    @State private var paywallReason: PaywallView.LimitReason?
    @State private var artworkCountBeforeSheet = 0
    @State private var showSettings = false

    private var store: StoreKitManager { StoreKitManager.shared }

    private var selectedChild: Child? {
        guard let selectedChildID else { return nil }
        return children.first { $0.persistentModelID == selectedChildID }
    }

    @ViewBuilder
    private var galleryTabIcon: some View {
        if let selectedChild {
            HStack(spacing: 8) {
                ZStack {
                    if let imageData = selectedChild.avatarImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Circle()
                            .fill(Color(hex: selectedChild.avatarColor))

                        Text(String(selectedChild.name.prefix(1)).uppercased())
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 24, height: 24)
                .clipShape(Circle())

                Text(selectedChild.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        } else {
            Image(systemName: "person.3.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
        }
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

    var body: some View {
        NavigationStack {
            Group {
                if selectedTab == .gallery {
                    HomeView(selectedChildID: $selectedChildID)
                } else {
                    SearchView(searchText: $searchText)
                }
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Menu {
                        Button {
                            selectedTab = .gallery
                            searchText = ""
                            selectedChildID = nil
                        } label: {
                            Label(
                                "All Children",
                                systemImage: selectedChild == nil ? "checkmark" : "person.3.sequence.fill"
                            )
                        }

                        if !children.isEmpty {
                            Divider()
                        }

                        ForEach(children) { child in
                            Button {
                                selectedTab = .gallery
                                searchText = ""
                                selectedChildID = child.persistentModelID
                            } label: {
                                Label(
                                    child.name,
                                    systemImage: selectedChildID == child.persistentModelID ? "checkmark" : "figure.child"
                                )
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

                        Button {
                            showSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    } label: {
                        galleryTabIcon
                            .opacity(selectedTab == .gallery ? 1 : 0.75)
                    }
                }

                ToolbarSpacer(.flexible, placement: .bottomBar)
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                ToolbarSpacer(.flexible, placement: .bottomBar)

                ToolbarItem(placement: .bottomBar) {
                    Button {
                        presentCreateFlow()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
            .searchable(
                text: $searchText,
                placement: .toolbar,
                prompt: "Search"
            )
            .searchToolbarBehavior(.automatic)
        }
        .toolbarBackground(Brand.backgroundBase, for: .bottomBar)
        .toolbarBackground(.visible, for: .bottomBar)
        .sheet(isPresented: $showAddChild) {
            AddChildView()
        }
        .sheet(isPresented: $showCreateSheet, onDismiss: {
            if artworkCountBeforeSheet == 0
                && allArtworks.count > artworkCountBeforeSheet
                && !store.isPremium
                && !hasSeenUpsell
            {
                hasSeenUpsell = true
                showPremiumUpsell = true
            }
        }) {
            if let child = children.first {
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
        .onChange(of: store.isPremium) { _, isPremium in
            guard isPremium else { return }
            paywallReason = nil
            showPremiumUpsell = false
        }
        .onChange(of: searchText) { _, newValue in
            if !newValue.isEmpty {
                selectedTab = .search
            } else {
                selectedTab = .gallery
            }
        }
    }
}

// MARK: - Tab Identifier

enum AppTab: Hashable {
    case gallery
    case search
}

#Preview {
    ContentView()
        .modelContainer(PreviewSampleData.container)
}
