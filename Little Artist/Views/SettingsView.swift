//
//  SettingsView.swift
//  Little Artist
//
//  App settings with children management, preferences,
//  data management, and about information.
//

import AuthenticationServices
import os
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Child.createdAt) private var children: [Child]
    @Query private var artworks: [Artwork]

    private var store: StoreKitManager { StoreKitManager.shared }
    private let syncService = FirestoreSyncService.shared

    @AppStorage("aiCaptionsEnabled") private var aiCaptionsEnabled = true
    @AppStorage("defaultCameraBack") private var defaultCameraBack = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("firebaseSyncEnabled") private var firebaseSyncEnabled = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false

    @State private var showAddChild = false
    @State private var showDeleteChildConfirmation = false
    @State private var showLeaveChildConfirmation = false
    @State private var childToDelete: Child?
    @State private var childToLeave: Child?
    @State private var paywallReason: PaywallView.LimitReason?
    @State private var isRestoring = false
    @State private var exportPayload: SharePayload?
    @State private var isExporting = false
    @State private var showSyncEnabledConfirmation = false
    @State private var syncError: String?
    @State private var showJoinShare = false
    @State private var shareCodeInput = ""
    @State private var isJoiningShare = false
    @State private var joinShareError: String?
    @State private var joinShareSuccess = false

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

                                if child.isShared || child.firestoreId != nil {
                                    Image(systemName: child.isShared ? "person.2.wave.2" : "person.2.fill")
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
                            let child = children[index]
                            let isShared = child.isShared
                            let isOwner = !child.isShared

                            if isShared && !isOwner {
                                // Participant: show leave confirmation instead of delete
                                childToLeave = child
                                showLeaveChildConfirmation = true
                            } else {
                                childToDelete = child
                                showDeleteChildConfirmation = true
                            }
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
                    // Firebase Sync toggle (premium only)
                    if store.isPremium {
                        Toggle(isOn: $firebaseSyncEnabled) {
                            Label("Cloud Sync", systemImage: "arrow.triangle.2.circlepath.cloud.fill")
                        }
                        .tint(Brand.primary)
                        .onChange(of: firebaseSyncEnabled) { _, enabled in
                            if enabled {
                                // Prompt Sign in with Apple if not yet linked
                                if !FirebaseAuthService.shared.isLinkedWithApple {
                                    Task {
                                        do {
                                            try await FirebaseAuthService.shared.signInWithApple()
                                            FirestoreSyncService.shared.start()
                                            // Upload existing local data
                                            await FirestoreRepository.shared.uploadAllLocalData(from: modelContext)
                                            showSyncEnabledConfirmation = true
                                        } catch let error as ASAuthorizationError where error.code == .canceled {
                                            // User tapped Cancel — silently revert toggle, no alert
                                            firebaseSyncEnabled = false
                                        } catch {
                                            firebaseSyncEnabled = false
                                            syncError = error.localizedDescription
                                        }
                                    }
                                } else {
                                    FirestoreSyncService.shared.start()
                                    showSyncEnabledConfirmation = true
                                }
                            } else {
                                FirestoreSyncService.shared.stop()
                            }
                        }
                    } else {
                        Button {
                            paywallReason = .artworks
                        } label: {
                            HStack {
                                Label("Cloud Sync", systemImage: "arrow.triangle.2.circlepath.cloud.fill")
                                    .foregroundStyle(Brand.disabled)
                                Spacer()
                                Text("Premium")
                                    .font(Brand.caption2Font)
                                    .foregroundStyle(Brand.primary)
                            }
                        }
                    }

                    // Join Shared Profile (requires sync)
                    if firebaseSyncEnabled {
                        Button {
                            showJoinShare = true
                        } label: {
                            Label("Join Shared Profile", systemImage: "person.badge.plus")
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

                // SYNC DIAGNOSTICS (visible when Firebase sync is active)
                if syncService.isListening || !syncService.diagnosticLog.isEmpty {
                    Section {
                        let snapshot = syncService.diagnosticSnapshot()
                        ForEach(Array(snapshot.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                            HStack {
                                Text(key)
                                    .font(Brand.captionFont)
                                Spacer()
                                Text(value)
                                    .font(Brand.captionFont)
                                    .foregroundStyle(value.contains("None") || value.contains("No") ? Brand.dustyRose : Brand.sage)
                            }
                        }

                        if !syncService.diagnosticLog.isEmpty {
                            DisclosureGroup("Event Log (\(syncService.diagnosticLog.count))") {
                                ForEach(syncService.diagnosticLog.reversed(), id: \.self) { entry in
                                    Text(entry)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(Brand.warmGray)
                                }
                            }
                        }

                        Button {
                            syncService.stop()
                            syncService.start()
                        } label: {
                            Label("Force Sync Now", systemImage: "arrow.triangle.2.circlepath")
                                .foregroundStyle(Brand.primary)
                        }
                    } header: {
                        Text("Sync Diagnostics")
                    }
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
                        FirestoreRepository.shared.deleteChild(child, in: modelContext)
                        childToDelete = nil
                    }
                }
            } message: {
                if let child = childToDelete {
                    if child.isShared {
                        Text("This will permanently delete \(child.name) and all their artworks for everyone this profile is shared with.")
                    } else {
                        Text("This will permanently delete \(child.name) and all their \(child.artworks?.count ?? 0) artworks.")
                    }
                }
            }
            .alert("Leave Shared Profile?", isPresented: $showLeaveChildConfirmation) {
                Button("Cancel", role: .cancel) {
                    childToLeave = nil
                }
                Button("Leave", role: .destructive) {
                    if let child = childToLeave {
                        // Remove local mirror of shared child
                        modelContext.delete(child)
                        childToLeave = nil
                    }
                }
            } message: {
                if let child = childToLeave {
                    Text("\(child.name)'s profile will be removed from your device. The owner will keep their copy.")
                }
            }
            .alert("Sync Enabled", isPresented: $showSyncEnabledConfirmation) {
                Button("OK") {}
            } message: {
                Text("Your data will now sync across your devices. You can share child profiles from the Edit Profile screen.")
            }
            .alert("Sync Unavailable", isPresented: Binding(
                get: { syncError != nil },
                set: { if !$0 { syncError = nil } }
            )) {
                Button("OK") { syncError = nil }
            } message: {
                Text(syncError ?? "")
            }
            .alert("Join Shared Profile", isPresented: $showJoinShare) {
                TextField("Paste share code", text: $shareCodeInput)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("Cancel", role: .cancel) {
                    shareCodeInput = ""
                }
                Button("Join") {
                    Task { await joinSharedProfile() }
                }
                .disabled(shareCodeInput.trimmingCharacters(in: .whitespaces).isEmpty)
            } message: {
                Text("Enter the share code you received from another parent.")
            }
            .alert("Joined!", isPresented: $joinShareSuccess) {
                Button("OK") {}
            } message: {
                Text("The shared profile will appear shortly.")
            }
            .alert("Join Failed", isPresented: Binding(
                get: { joinShareError != nil },
                set: { if !$0 { joinShareError = nil } }
            )) {
                Button("OK") { joinShareError = nil }
            } message: {
                Text(joinShareError ?? "")
            }
        }
    }
    private func joinSharedProfile() async {
        let code = shareCodeInput.trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty else { return }
        isJoiningShare = true
        do {
            try await FirestoreRepository.shared.acceptShare(shareId: code)
            // Restart sync to pick up the shared data
            FirestoreSyncService.shared.stop()
            FirestoreSyncService.shared.start()
            shareCodeInput = ""
            joinShareSuccess = true
        } catch {
            joinShareError = "Could not join: \(error.localizedDescription)"
        }
        isJoiningShare = false
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
