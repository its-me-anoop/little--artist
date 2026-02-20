//
//  SettingsView.swift
//  Little Artist
//
//  App settings with children management, preferences,
//  data management, and about information.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Child.createdAt) private var children: [Child]
    @Query private var artworks: [Artwork]

    private var store: StoreKitManager { StoreKitManager.shared }
    private let sharingService = CloudKitSharingService.shared

    @AppStorage("aiCaptionsEnabled") private var aiCaptionsEnabled = true
    @AppStorage("defaultCameraBack") private var defaultCameraBack = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false

    @State private var showAddChild = false
    @State private var showDeleteChildConfirmation = false
    @State private var childToDelete: Child?
    @State private var paywallReason: PaywallView.LimitReason?
    @State private var isRestoring = false
    @State private var exportPayload: SharePayload?
    @State private var isExporting = false
    @State private var showSyncEnabledConfirmation = false

    private var storageUsed: String {
        let bytes = artworks.compactMap(\.imageData).reduce(0) { $0 + $1.count }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                // CHILDREN
                Section {
                    ForEach(children) { child in
                        NavigationLink {
                            EditChildView(child: child) {
                                // onDelete callback
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: child.avatarColor))
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if let data = child.avatarImageData,
                                           let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .clipShape(Circle())
                                        } else {
                                            Text(String(child.name.prefix(1)).uppercased())
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                                .foregroundStyle(.white)
                                        }
                                    }

                                Text(child.name)
                                    .font(Brand.bodyFont)

                                if sharingService.isInitialised, child.sharedRecordName == nil, sharingService.isShared(child) {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(Brand.sky)
                                }

                                Spacer()

                                Text("\(child.artworks?.count ?? 0) artworks")
                                    .font(Brand.caption2Font)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            childToDelete = children[index]
                            showDeleteChildConfirmation = true
                        }
                    }

                    Button {
                        if PremiumManager.canAddChild(currentCount: children.count) {
                            showAddChild = true
                        } else {
                            paywallReason = .children
                        }
                    } label: {
                        Label("Add Child", systemImage: "plus")
                            .foregroundStyle(Brand.primary)
                    }
                } header: {
                    Text("Children")
                }

                // PREFERENCES
                Section {
                    Toggle(isOn: $aiCaptionsEnabled) {
                        Label("AI Captions", systemImage: "sparkles")
                    }
                    .tint(Brand.primary)

                    HStack {
                        Label("Default Camera", systemImage: "camera.fill")
                        Spacer()
                        Picker("", selection: $defaultCameraBack) {
                            Text("Back").tag(true)
                            Text("Front").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 140)
                    }

                    Toggle(isOn: $notificationsEnabled) {
                        Label("Reminders", systemImage: "bell.fill")
                    }
                    .tint(Brand.primary)
                    .onChange(of: notificationsEnabled) { _, enabled in
                        if enabled {
                            Task { @MainActor in
                                let granted = await NotificationService.requestPermission()
                                if granted {
                                    NotificationService.scheduleAll(artworks: artworks)
                                } else {
                                    notificationsEnabled = false
                                }
                            }
                        } else {
                            NotificationService.cancelAll()
                        }
                    }
                } header: {
                    Text("Preferences")
                }

                // SUBSCRIPTION
                Section {
                    HStack {
                        Label("Plan", systemImage: "crown.fill")
                        Spacer()
                        Text(store.isPremium ? "Premium" : "Free")
                            .foregroundStyle(store.isPremium ? Brand.primary : .secondary)
                            .fontWeight(store.isPremium ? .semibold : .regular)
                    }

                    if !store.isPremium {
                        Button {
                            paywallReason = .artworks
                        } label: {
                            Label("Upgrade to Premium", systemImage: "sparkles")
                                .foregroundStyle(Brand.primary)
                        }
                    }

                    Button {
                        isRestoring = true
                        Task {
                            await store.restorePurchases()
                            isRestoring = false
                        }
                    } label: {
                        HStack {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                            if isRestoring {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isRestoring)
                } header: {
                    Text("Subscription")
                }

                // DATA
                Section {
                    // iCloud Sync toggle (premium only)
                    if store.isPremium {
                        Toggle(isOn: $iCloudSyncEnabled) {
                            Label("iCloud Sync", systemImage: "icloud.fill")
                        }
                        .tint(Brand.primary)
                        .onChange(of: iCloudSyncEnabled) { _, enabled in
                            if enabled {
                                CloudKitSharingService.shared.setup()
                                showSyncEnabledConfirmation = true
                            }
                        }
                    } else {
                        Button {
                            paywallReason = .artworks
                        } label: {
                            HStack {
                                Label("iCloud Sync", systemImage: "icloud.fill")
                                    .foregroundStyle(Brand.disabled)
                                Spacer()
                                Text("Premium")
                                    .font(Brand.caption2Font)
                                    .foregroundStyle(Brand.primary)
                            }
                        }
                    }

                    HStack {
                        Label("Storage", systemImage: "externaldrive.fill")
                        Spacer()
                        Text(storageUsed)
                            .foregroundStyle(.secondary)
                    }

                    // PDF Export per child
                    ForEach(children) { child in
                        Button {
                            if store.isPremium {
                                exportPortfolio(for: child)
                            } else {
                                paywallReason = .artworks
                            }
                        } label: {
                            HStack {
                                Label("Export \(child.name)'s Portfolio", systemImage: "doc.richtext")
                                    .foregroundStyle(store.isPremium ? Brand.primary : Brand.disabled)
                                if isExporting {
                                    Spacer()
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(isExporting)
                    }
                } header: {
                    Text("Data")
                }

                // ABOUT
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }

                    Button {
                        hasCompletedOnboarding = false
                    } label: {
                        Label("Replay Onboarding", systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAddChild) {
                AddChildView()
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
            .sheet(item: $exportPayload) { payload in
                ActivityView(activityItems: payload.items)
            }
            .alert("Delete Child?", isPresented: $showDeleteChildConfirmation) {
                Button("Cancel", role: .cancel) {
                    childToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let child = childToDelete {
                        modelContext.delete(child)
                        childToDelete = nil
                    }
                }
            } message: {
                if let child = childToDelete {
                    Text("This will permanently delete \(child.name) and all their \(child.artworks?.count ?? 0) artworks.")
                }
            }
            .alert("iCloud Sync Enabled", isPresented: $showSyncEnabledConfirmation) {
                Button("OK") {}
            } message: {
                Text("Your data will now sync across your devices. You can share child profiles from the Edit Profile screen.")
            }
        }
    }
    private func exportPortfolio(for child: Child) {
        isExporting = true
        let childArtworks = child.artworks ?? []
        let name = child.name

        Task {
            let pdfData = PDFExportService.generatePortfolio(childName: name, artworks: childArtworks)
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(name)_Portfolio.pdf")
            try? pdfData.write(to: tempURL)
            isExporting = false
            exportPayload = SharePayload(items: [tempURL])
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewSampleData.container)
}
