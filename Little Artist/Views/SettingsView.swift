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
    @State private var showSignOutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var accountError: String?

    private var storageUsed: String {
        let bytes = artworks.compactMap(\.imageData).reduce(0) { $0 + $1.count }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var settingsBackground: some View {
        GeometryReader { geo in
            ZStack {
                Brand.cream.ignoresSafeArea()

                Circle()
                    .fill(Brand.sky.opacity(0.10))
                    .frame(width: geo.size.width * 1.1, height: geo.size.width * 1.1)
                    .blur(radius: 60)
                    .offset(x: -geo.size.width * 0.25, y: -geo.size.height * 0.15)

                Circle()
                    .fill(Brand.primary.opacity(0.10))
                    .frame(width: geo.size.width * 1.2, height: geo.size.width * 1.2)
                    .blur(radius: 70)
                    .offset(x: geo.size.width * 0.25, y: geo.size.height * 0.35)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                childrenSection
                preferencesSection
                aiUsageSection
                subscriptionSection
                dataSection
                accountSection
                syncDiagnosticsSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(20)
            .scrollContentBackground(.hidden)
            .background(settingsBackground)
            .tint(Brand.primary)
            .navigationTitle("Settings")
            .onAppear {
                firebaseSyncEnabled = true
            }
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
            .alert("Sign Out?", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task { await performSignOut() }
                }
            } message: {
                Text("You can sign in again any time with Sign in with Apple.")
            }
            .alert("Delete Account?", isPresented: $showDeleteAccountConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Account", role: .destructive) {
                    Task { await performDeleteAccount() }
                }
            } message: {
                Text("This permanently deletes your account and data from this device and cloud storage. Other signed-in devices will remove this data when they reconnect online.")
            }
            .alert("Account Action Failed", isPresented: Binding(
                get: { accountError != nil },
                set: { if !$0 { accountError = nil } }
            )) {
                Button("OK") { accountError = nil }
            } message: {
                Text(accountError ?? "")
            }
        }
        .toolbarBackground(Brand.cream, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var childrenSection: some View {
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
                    .crayonStyle()
            }
        } header: {
            Text("Children")
                .crayonStyle()
        }
    }

    private var preferencesSection: some View {
        Section {
            if store.isPremium {
                Toggle(isOn: $aiCaptionsEnabled) {
                    Label("AI Captions", systemImage: "sparkles")
                }
                .tint(Brand.primary)
                .onChange(of: aiCaptionsEnabled) { _, _ in
                    Task { await FirestoreRepository.shared.syncUserPreferencesToFirestore() }
                }
            } else {
                Button {
                    paywallReason = .artworks
                } label: {
                    HStack {
                        Label("AI Captions", systemImage: "sparkles")
                            .foregroundStyle(Brand.disabled)
                        Spacer()
                        Text("Premium")
                            .font(Brand.caption2Font)
                            .foregroundStyle(Brand.primary)
                    }
                }
            }

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
            .onChange(of: defaultCameraBack) { _, _ in
                Task { await FirestoreRepository.shared.syncUserPreferencesToFirestore() }
            }

            if !store.isPremium {
                Button {
                    paywallReason = .artworks
                } label: {
                    HStack {
                        Label("Voice Memos", systemImage: "mic.fill")
                            .foregroundStyle(Brand.disabled)
                        Spacer()
                        Text("Premium")
                            .font(Brand.caption2Font)
                            .foregroundStyle(Brand.primary)
                    }
                }
            }

            Toggle(isOn: $notificationsEnabled) {
                Label("Notifications", systemImage: "bell.fill")
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
                Task { await FirestoreRepository.shared.syncUserPreferencesToFirestore() }
            }
        } header: {
            Text("Preferences")
                .crayonStyle()
        }
    }

    @ViewBuilder
    private var aiUsageSection: some View {
        if store.isPremium && aiCaptionsEnabled {
            Section {
                let summary = GeminiUsageTracker.shared.usageSummary

                UsageRow(label: "Today", usage: summary.daily)
                UsageRow(label: "This Week", usage: summary.weekly)
                UsageRow(label: "This Month", usage: summary.monthly)

                if let exceeded = GeminiUsageTracker.shared.exceededLimit {
                    Label(exceeded.message, systemImage: "exclamationmark.triangle.fill")
                        .font(Brand.captionFont)
                        .foregroundStyle(Brand.dustyRose)
                }
            } header: {
                Text("AI Usage")
                    .crayonStyle()
            } footer: {
                Text("Limits help manage cloud AI costs. Counters reset automatically.")
                    .font(Brand.caption2Font)
            }
        }
    }

    private var subscriptionSection: some View {
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
                        .crayonStyle()
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
                        .crayonStyle()
                    if isRestoring {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isRestoring)
        } header: {
            Text("Subscription")
                .crayonStyle()
        }
    }

    private var dataSection: some View {
        Section {
            HStack {
                Label("Cloud Sync", systemImage: "arrow.triangle.2.circlepath.icloud.fill")
                Spacer()
                Text("Always On")
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.sage)
            }

            if firebaseSyncEnabled {
                Button {
                    showJoinShare = true
                } label: {
                    Label("Join Shared Profile", systemImage: "person.badge.plus")
                        .crayonStyle()
                }
            }

            HStack {
                Label("Storage", systemImage: "externaldrive.fill")
                Spacer()
                Text(storageUsed)
                    .foregroundStyle(.secondary)
            }

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
                            .crayonStyle()
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
                .crayonStyle()
        }
    }

    private var accountSection: some View {
        Section {
            Button(role: .destructive) {
                showSignOutConfirmation = true
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .crayonStyle()
            }

            Button(role: .destructive) {
                showDeleteAccountConfirmation = true
            } label: {
                Label("Delete Account", systemImage: "person.crop.circle.badge.xmark")
                    .crayonStyle()
            }
        } header: {
            Text("Account")
                .crayonStyle()
        }
    }

    @ViewBuilder
    private var syncDiagnosticsSection: some View {
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
                        .crayonStyle()
                }
            } header: {
                Text("Sync Diagnostics")
                    .crayonStyle()
            }
        }
    }

    private var aboutSection: some View {
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
                Task { await FirestoreRepository.shared.syncUserPreferencesToFirestore() }
            } label: {
                Label("Replay Onboarding", systemImage: "arrow.counterclockwise")
                    .crayonStyle()
            }
        } header: {
            Text("About")
                .crayonStyle()
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

    @MainActor
    private func performSignOut() async {
        do {
            FirestoreSyncService.shared.stop()
            purgeLocalData()
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            try FirebaseAuthService.shared.signOut()
        } catch {
            accountError = error.localizedDescription
        }
    }

    @MainActor
    private func performDeleteAccount() async {
        do {
            guard let userId = FirebaseAuthService.shared.userId else {
                throw FirebaseAuthService.AuthError.noCurrentUser
            }

            FirestoreSyncService.shared.stop()
            // Purge local data first to prevent SwiftData fault errors
            // when the UI tries to access deleted objects during async cleanup
            purgeLocalData()
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            await FirestoreRepository.shared.deleteAllUserData(userId: userId)
            try await FirebaseAuthService.shared.deleteAccount()
        } catch {
            accountError = error.localizedDescription
        }
    }

    @MainActor
    private func purgeLocalData() {
        if let allArtworks = try? modelContext.fetch(FetchDescriptor<Artwork>()) {
            for artwork in allArtworks { modelContext.delete(artwork) }
        }
        if let allChildren = try? modelContext.fetch(FetchDescriptor<Child>()) {
            for child in allChildren { modelContext.delete(child) }
        }
        if let allTags = try? modelContext.fetch(FetchDescriptor<Tag>()) {
            for tag in allTags { modelContext.delete(tag) }
        }
        try? modelContext.save()
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

// MARK: - Usage Row

/// A single row showing usage progress for a tracking period.
private struct UsageRow: View {
    let label: String
    let usage: PeriodUsage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(Brand.captionFont)
                Spacer()
                Text("\(usage.used)/\(usage.limit)")
                    .font(Brand.caption2Font)
                    .foregroundStyle(usage.isExceeded ? Brand.dustyRose : Brand.warmGray)
            }
            ProgressView(value: min(usage.fraction, 1.0))
                .tint(progressColor)
        }
        .padding(.vertical, 2)
    }

    private var progressColor: Color {
        if usage.fraction >= 1.0 { return Brand.dustyRose }
        if usage.fraction >= 0.8 { return Brand.primary }
        return Brand.sage
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewSampleData.container)
}
