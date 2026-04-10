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
    private var auth: FirebaseAuthService { FirebaseAuthService.shared }
    private let syncService = FirestoreSyncService.shared

    @AppStorage("aiCaptionsEnabled") private var aiCaptionsEnabled = true
    @AppStorage("defaultCameraBack") private var defaultCameraBack = true
    @AppStorage("appAppearance") private var appAppearance = AppAppearance.system.rawValue
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
    @State private var isEnablingCloudSync = false
    @State private var exportPayload: SharePayload?
    @State private var isExporting = false
    @State private var showCloudSyncSetup = false
    @State private var showSyncEnabledConfirmation = false
    @State private var syncError: String?
    @State private var showJoinShare = false
    @State private var shareCodeInput = ""
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

    private var deleteAccountMessage: String {
        var parts = [
            "This permanently deletes your account and data from this device and cloud storage. Other signed-in devices will remove this data when they reconnect online."
        ]

        if store.isPremium {
            parts.append("Any active subscription must still be cancelled separately in Apple Subscriptions.")
        }

        if auth.isLinkedWithApple {
            parts.append("You'll be asked to confirm with Apple before deletion.")
        }

        return parts.joined(separator: " ")
    }

    private var isCloudSyncEnabled: Bool {
        firebaseSyncEnabled && auth.isLinkedWithApple
    }

    private var paywallPresented: Binding<PaywallView.LimitReason?> {
        Binding(
            get: { store.isPremium ? nil : paywallReason },
            set: { paywallReason = $0 }
        )
    }

    private var syncErrorPresented: Binding<Bool> {
        Binding(
            get: { syncError != nil },
            set: { if !$0 { syncError = nil } }
        )
    }

    private var joinShareErrorPresented: Binding<Bool> {
        Binding(
            get: { joinShareError != nil },
            set: { if !$0 { joinShareError = nil } }
        )
    }

    private var accountErrorPresented: Binding<Bool> {
        Binding(
            get: { accountError != nil },
            set: { if !$0 { accountError = nil } }
        )
    }

    private var settingsBackground: some View {
        GeometryReader { geo in
            ZStack {
                BrandAppBackground()

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
            settingsAlertContent
        }
        .toolbarBackground(Brand.backgroundBase, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var settingsForm: some View {
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
        .navigationBarTitleDisplayMode(.large)
    }

    private var settingsSheetContent: some View {
        settingsForm
            .onAppear {
                if isCloudSyncEnabled {
                    Task { await FirestoreRepository.shared.activateCloudSyncIfNeeded() }
                }
            }
            .sheet(isPresented: $showAddChild) {
                AddChildView()
            }
            .sheet(isPresented: $showCloudSyncSetup) {
                cloudSyncSetupView
            }
            .sheet(item: paywallPresented) { reason in
                PaywallView(reason: reason)
            }
            .sheet(item: $exportPayload) { payload in
                ActivityView(activityItems: payload.items)
            }
            .onChange(of: store.isPremium) { _, isPremium in
                if isPremium {
                    paywallReason = nil
                }
            }
    }

    private var settingsAlertContent: some View {
        settingsSheetContent
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
                deleteChildMessageView
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
                leaveSharedProfileMessageView
            }
            .alert("Sync Enabled", isPresented: $showSyncEnabledConfirmation) {
                Button("OK") {}
            } message: {
                Text("Artwork, child profiles, voice memos, and preferences will now sync across your devices. You can share child profiles from the Edit Profile screen.")
            }
            .alert("Sync Unavailable", isPresented: syncErrorPresented) {
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
            .alert("Join Failed", isPresented: joinShareErrorPresented) {
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
                Text(deleteAccountMessage)
            }
            .alert("Account Action Failed", isPresented: accountErrorPresented) {
                Button("OK") { accountError = nil }
            } message: {
                Text(accountError ?? "")
            }
    }

    @ViewBuilder
    private var deleteChildMessageView: some View {
        if let child = childToDelete {
            if child.isShared {
                Text("This will permanently delete \(child.name) and all their artworks for everyone this profile is shared with.")
            } else {
                Text("This will permanently delete \(child.name) and all their \(child.artworks?.count ?? 0) artworks.")
            }
        }
    }

    @ViewBuilder
    private var leaveSharedProfileMessageView: some View {
        if let child = childToLeave {
            Text("\(child.name)'s profile will be removed from your device. The owner will keep their copy.")
        }
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
            Picker("Appearance", selection: $appAppearance) {
                ForEach(AppAppearance.allCases) { appearance in
                    Text(appearance.title).tag(appearance.rawValue)
                }
            }

            if store.isPremium {
                Toggle(isOn: $aiCaptionsEnabled) {
                    Label("AI Captions", systemImage: "sparkles")
                }
                .tint(Brand.primary)
                .onChange(of: aiCaptionsEnabled) { _, _ in
                    Task { await FirestoreRepository.shared.syncUserPreferencesToFirestore() }
                }

                Text(
                    aiCaptionsEnabled
                    ? AISuggestionService.engineDescription
                    : "Turn this on to generate titles and captions entirely on-device."
                )
                .font(Brand.caption2Font)
                .foregroundStyle(Brand.warmGray)
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
                HStack {
                    Label("Engine", systemImage: "brain.head.profile")
                    Spacer()
                    Text(AISuggestionService.engineName)
                        .font(Brand.caption2Font)
                        .foregroundStyle(Brand.primary)
                }

                HStack {
                    Label("Processing", systemImage: "iphone")
                    Spacer()
                    Text("On Device")
                        .font(Brand.caption2Font)
                        .foregroundStyle(Brand.sage)
                }

                Text(AISuggestionService.engineDescription)
                    .font(Brand.captionFont)
                    .foregroundStyle(Brand.warmGray)
            } header: {
                Text("AI Engine")
                    .crayonStyle()
            } footer: {
                Text("Apple Intelligence is used when available. Other devices fall back to a lightweight local Vision pipeline.")
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

            Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                Label("Manage Subscription", systemImage: "arrow.up.right.square")
                    .crayonStyle()
            }
        } header: {
            Text("Subscription")
                .crayonStyle()
        }
    }

    private var dataSection: some View {
        Section {
            if isCloudSyncEnabled {
                HStack {
                    Label("Cloud Sync", systemImage: "arrow.triangle.2.circlepath.icloud.fill")
                    Spacer()
                    Text("Enabled")
                        .font(Brand.caption2Font)
                        .foregroundStyle(Brand.sage)
                }

                Button {
                    showJoinShare = true
                } label: {
                    Label("Join Shared Profile", systemImage: "person.badge.plus")
                        .crayonStyle()
                }
            } else {
                Button {
                    showCloudSyncSetup = true
                } label: {
                    HStack {
                        Label("Enable Cloud Sync", systemImage: "icloud.and.arrow.up")
                            .foregroundStyle(Brand.primary)
                            .crayonStyle()
                        Spacer()
                        if isEnablingCloudSync {
                            ProgressView()
                        }
                    }
                }

                Text("Cloud sync stays off until you explicitly enable it with Sign in with Apple.")
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray)
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

    private var cloudSyncSetupView: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image("LaunchFox")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)

                Text("Enable Cloud Sync")
                    .font(Brand.displayFont)
                    .foregroundStyle(Brand.charcoal)
                    .multilineTextAlignment(.center)
                    .crayonStyle()

                Text("Cloud Sync uploads artwork, child profiles, voice memos, and preferences to your account for backup, multi-device sync, and sharing.")
                    .font(Brand.title3Font)
                    .foregroundStyle(Brand.warmGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .crayonStyle()

                Spacer()

                if auth.isLinkedWithApple {
                    Button {
                        Task { await enableCloudSync() }
                    } label: {
                        HStack {
                            Text("Enable Cloud Sync")
                            if isEnablingCloudSync {
                                ProgressView()
                            }
                        }
                        .font(Brand.title2Font.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Brand.primary.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Brand.glassStrokeSoft, lineWidth: 3)
                        )
                        .crayonStyle()
                    }
                    .disabled(isEnablingCloudSync)
                } else {
                    SignInWithAppleButton(.continue) { request in
                        auth.configureSignInWithAppleRequest(request)
                    } onCompletion: { result in
                        Task { await handleCloudSyncAuthorization(result) }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .disabled(isEnablingCloudSync)
                }

                Button("Not Now") {
                    showCloudSyncSetup = false
                }
                .font(Brand.captionFont)
                .foregroundStyle(Brand.warmGray)
                .disabled(isEnablingCloudSync)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
            .background(settingsBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        showCloudSyncSetup = false
                    }
                    .disabled(isEnablingCloudSync)
                }
            }
        }
    }

    @MainActor
    private func enableCloudSync() async {
        guard !isEnablingCloudSync else { return }
        isEnablingCloudSync = true
        defer { isEnablingCloudSync = false }

        firebaseSyncEnabled = true
        await FirestoreRepository.shared.activateCloudSyncIfNeeded()
        showCloudSyncSetup = false
        showSyncEnabledConfirmation = true
    }

    @MainActor
    private func handleCloudSyncAuthorization(_ result: Result<ASAuthorization, Error>) async {
        guard !isEnablingCloudSync else { return }
        isEnablingCloudSync = true
        defer { isEnablingCloudSync = false }

        do {
            try await auth.handleSignInWithAppleResult(result)
            firebaseSyncEnabled = true
            await FirestoreRepository.shared.activateCloudSyncIfNeeded()
            showCloudSyncSetup = false
            showSyncEnabledConfirmation = true
        } catch let error as ASAuthorizationError where error.code == .canceled {
            return
        } catch {
            syncError = error.localizedDescription
        }
    }

    private func joinSharedProfile() async {
        let code = shareCodeInput.trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty else { return }
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
    }

    @MainActor
    private func performSignOut() async {
        do {
            FirestoreSyncService.shared.stop()
            firebaseSyncEnabled = false
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
            if FirebaseAuthService.shared.isLinkedWithApple {
                try await FirebaseAuthService.shared.revokeAppleTokenForCurrentUser()
            }
            firebaseSyncEnabled = false
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
            let pdfData = PDFExportService.generatePortfolio(child: child, artworks: childArtworks)
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
