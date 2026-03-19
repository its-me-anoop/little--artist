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
    @State private var isJoiningShare = false
    @State private var joinShareError: String?
    @State private var joinShareSuccess = false
    @State private var showSignOutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var accountError: String?
    @State private var showPaywall = false
    @State private var showSyncDiagnostics = false

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

    // MARK: - Body

    var body: some View {
        settingsAlertContent
    }

    // MARK: - Main Layout

    private var settingsForm: some View {
        ScrollView {
            VStack(spacing: Brand.sectionSpacing) {
                premiumHeroCard
                childProfilesSection
                dataPrivacySection
                supportSection
                syncDiagnosticsSection
                dangerZoneSection
            }
            .padding(.horizontal, Brand.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(settingsBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - 1. Premium Hero Card

    private var premiumHeroCard: some View {
        Group {
            if store.isPremium {
                premiumActiveCard
            } else {
                premiumUpsellCard
            }
        }
    }

    private var premiumActiveCard: some View {
        ZStack(alignment: .topTrailing) {
            // Decorative medal icon
            Image(systemName: "medal.fill")
                .font(.system(size: 80))
                .foregroundStyle(Brand.primary.opacity(0.12))
                .offset(x: -8, y: -4)

            VStack(alignment: .leading, spacing: 12) {
                // Current Plan pill
                Text("Current Plan")
                    .font(Brand.caption2Font.weight(.medium))
                    .foregroundStyle(Brand.charcoal)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.3))
                    .clipShape(Capsule())

                Text("Premium Account")
                    .font(Brand.title2Font)
                    .foregroundStyle(Brand.charcoal)

                // Active status
                HStack(spacing: 6) {
                    Circle()
                        .fill(Brand.sage)
                        .frame(width: 8, height: 8)
                    Text("Status: Active")
                        .font(Brand.captionFont)
                        .foregroundStyle(Brand.warmGray)
                }

                Spacer().frame(height: 4)

                // Manage button
                Button {
                    paywallReason = .artworks
                } label: {
                    Text("Manage")
                        .font(Brand.captionFont.weight(.semibold))
                        .foregroundStyle(Brand.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Brand.surface)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Brand.screenPadding)
        }
        .background(Brand.primary.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous))
        .rotationEffect(.degrees(-1))
    }

    private var premiumUpsellCard: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(Brand.primary.opacity(0.12))
                .offset(x: -12, y: 4)

            VStack(alignment: .leading, spacing: 12) {
                Text("Free Plan")
                    .font(Brand.caption2Font.weight(.medium))
                    .foregroundStyle(Brand.charcoal)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.3))
                    .clipShape(Capsule())

                Text("Upgrade to Premium")
                    .font(Brand.title2Font)
                    .foregroundStyle(Brand.charcoal)

                Text("Unlock unlimited children, AI captions, voice memos, cloud sync, and PDF export.")
                    .font(Brand.captionFont)
                    .foregroundStyle(Brand.warmGray)
                    .lineSpacing(2)

                Spacer().frame(height: 4)

                HStack(spacing: 12) {
                    Button {
                        paywallReason = .artworks
                    } label: {
                        Text("Upgrade")
                            .font(Brand.captionFont.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Brand.primary)
                            .clipShape(Capsule())
                    }

                    Button {
                        isRestoring = true
                        Task {
                            await store.restorePurchases()
                            isRestoring = false
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Restore")
                                .font(Brand.captionFont)
                                .foregroundStyle(Brand.warmGray)
                            if isRestoring {
                                ProgressView()
                                    .controlSize(.mini)
                            }
                        }
                    }
                    .disabled(isRestoring)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Brand.screenPadding)
        }
        .background(Brand.primary.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous))
        .rotationEffect(.degrees(-1))
    }

    // MARK: - 2. Child Profiles Section

    private var childProfilesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section header
            HStack {
                Text("Child Profiles")
                    .font(Brand.title2Font)
                    .foregroundStyle(Brand.charcoal)

                Spacer()

                Button {
                    if PremiumManager.canAddChild(currentCount: children.count) {
                        showAddChild = true
                    } else {
                        paywallReason = .children
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Add New")
                            .font(Brand.captionFont.weight(.semibold))
                    }
                    .foregroundStyle(Brand.sky)
                }
            }

            // Child cards
            VStack(spacing: 0) {
                ForEach(Array(children.enumerated()), id: \.element.id) { index, child in
                    NavigationLink {
                        EditChildView(child: child) {}
                    } label: {
                        childCardRow(child: child)
                    }
                    .buttonStyle(.plain)

                    if index < children.count - 1 {
                        Divider()
                            .padding(.leading, 80)
                    }
                }
            }
            .padding(.vertical, 4)
            .background(Brand.surface)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous))
        }
    }

    private func childCardRow(child: Child) -> some View {
        HStack(spacing: 14) {
            // Avatar
            Circle()
                .fill(Color(hex: child.avatarColor))
                .frame(width: 64, height: 64)
                .overlay {
                    if let data = child.avatarImageData,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                    } else {
                        Text(String(child.name.prefix(1)).uppercased())
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(child.name)
                        .font(Brand.headlineFont)
                        .foregroundStyle(Brand.charcoal)

                    if child.isShared || child.firestoreId != nil {
                        Image(systemName: child.isShared ? "person.2.wave.2" : "person.2.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Brand.sky)
                    }
                }

                let artworkCount = child.artworks?.count ?? 0
                Text("\(artworkCount) Masterpiece\(artworkCount == 1 ? "" : "s")")
                    .font(Brand.captionFont)
                    .foregroundStyle(Brand.warmGray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Brand.warmGray.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    // MARK: - 3. Data & Privacy Section

    private var dataPrivacySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Data & Privacy")
                .font(Brand.title2Font)
                .foregroundStyle(Brand.charcoal)

            VStack(spacing: 0) {
                // Cloud Sync row
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Brand.sky.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "cloud.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Brand.sky)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cloud Sync")
                            .font(Brand.bodyFont.weight(.medium))
                            .foregroundStyle(Brand.charcoal)
                        Text(isCloudSyncEnabled ? "Your data syncs across devices" : "Keep your data backed up")
                            .font(Brand.caption2Font)
                            .foregroundStyle(Brand.warmGray)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { isCloudSyncEnabled },
                        set: { newValue in
                            if newValue {
                                showCloudSyncSetup = true
                            } else {
                                firebaseSyncEnabled = false
                            }
                        }
                    ))
                    .tint(Brand.primary)
                    .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider()
                    .padding(.leading, 70)

                // Join Shared Profile row (only when sync is enabled)
                if isCloudSyncEnabled {
                    Button {
                        showJoinShare = true
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Brand.sage.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Brand.sage)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Join Shared Profile")
                                    .font(Brand.bodyFont.weight(.medium))
                                    .foregroundStyle(Brand.charcoal)
                                Text("Enter a code from another parent")
                                    .font(Brand.caption2Font)
                                    .foregroundStyle(Brand.warmGray)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Brand.warmGray.opacity(0.5))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .padding(.leading, 70)
                }

                // PDF Portfolio Export row
                Button {
                    if store.isPremium {
                        if let firstChild = children.first {
                            exportPortfolio(for: firstChild)
                        }
                    } else {
                        paywallReason = .artworks
                    }
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Brand.lavender.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "doc.richtext")
                                .font(.system(size: 18))
                                .foregroundStyle(Brand.lavender)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("PDF Portfolio Export")
                                .font(Brand.bodyFont.weight(.medium))
                                .foregroundStyle(Brand.charcoal)
                            Text("Export a child's artwork collection")
                                .font(Brand.caption2Font)
                                .foregroundStyle(Brand.warmGray)
                        }

                        Spacer()

                        if isExporting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 18))
                                .foregroundStyle(Brand.warmGray.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .disabled(isExporting || children.isEmpty)

                // Per-child export rows when multiple children exist
                if children.count > 1 {
                    ForEach(children) { child in
                        Divider()
                            .padding(.leading, 70)

                        Button {
                            if store.isPremium {
                                exportPortfolio(for: child)
                            } else {
                                paywallReason = .artworks
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Spacer().frame(width: 40)

                                Text("Export \(child.name)'s Portfolio")
                                    .font(Brand.captionFont)
                                    .foregroundStyle(store.isPremium ? Brand.primary : Brand.disabled)

                                Spacer()

                                if isExporting {
                                    ProgressView()
                                        .controlSize(.mini)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        .disabled(isExporting)
                    }
                }

                Divider()
                    .padding(.leading, 70)

                // Storage row
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Brand.warmGray.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: "externaldrive.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Brand.warmGray)
                    }

                    Text("Storage Used")
                        .font(Brand.bodyFont.weight(.medium))
                        .foregroundStyle(Brand.charcoal)

                    Spacer()

                    Text(storageUsed)
                        .font(Brand.captionFont)
                        .foregroundStyle(Brand.warmGray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Brand.surface)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous))
        }
    }

    // MARK: - 4. Support Section

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Support")
                .font(Brand.title2Font)
                .foregroundStyle(Brand.charcoal)

            VStack(spacing: 0) {
                // Privacy Policy
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    settingsRow(
                        icon: "hand.raised.fill",
                        iconColor: Brand.sage,
                        title: "Privacy Policy",
                        trailing: {
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 14))
                                .foregroundStyle(Brand.warmGray.opacity(0.5))
                        }
                    )
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.leading, 70)

                // About
                settingsRow(
                    icon: "info.circle.fill",
                    iconColor: Brand.sky,
                    title: "About Little Artist",
                    trailing: {
                        Text("v\(appVersion)")
                            .font(Brand.captionFont)
                            .foregroundStyle(Brand.warmGray)
                    }
                )

                Divider()
                    .padding(.leading, 70)

                // Appearance
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Brand.lavender.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.system(size: 18))
                            .foregroundStyle(Brand.lavender)
                    }

                    Text("Appearance")
                        .font(Brand.bodyFont.weight(.medium))
                        .foregroundStyle(Brand.charcoal)

                    Spacer()

                    Picker("", selection: $appAppearance) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(appearance.title).tag(appearance.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider()
                    .padding(.leading, 70)

                // Replay Onboarding
                Button {
                    hasCompletedOnboarding = false
                    Task { await FirestoreRepository.shared.syncUserPreferencesToFirestore() }
                } label: {
                    settingsRow(
                        icon: "arrow.counterclockwise",
                        iconColor: Brand.primary,
                        title: "Replay Onboarding",
                        trailing: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Brand.warmGray.opacity(0.5))
                        }
                    )
                }
                .buttonStyle(.plain)
            }
            .background(Brand.surface)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous))
        }
    }

    // MARK: - 5. Sync Diagnostics (Debug)

    @ViewBuilder
    private var syncDiagnosticsSection: some View {
        if syncService.isListening || !syncService.diagnosticLog.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Button {
                    withAnimation { showSyncDiagnostics.toggle() }
                } label: {
                    HStack {
                        Text("Sync Diagnostics")
                            .font(Brand.title2Font)
                            .foregroundStyle(Brand.charcoal)
                        Spacer()
                        Image(systemName: showSyncDiagnostics ? "chevron.up" : "chevron.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Brand.warmGray)
                    }
                }
                .buttonStyle(.plain)

                if showSyncDiagnostics {
                    VStack(spacing: 0) {
                        let snapshot = syncService.diagnosticSnapshot()
                        ForEach(Array(snapshot.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                            HStack {
                                Text(key)
                                    .font(Brand.captionFont)
                                    .foregroundStyle(Brand.charcoal)
                                Spacer()
                                Text(value)
                                    .font(Brand.captionFont)
                                    .foregroundStyle(value.contains("None") || value.contains("No") ? Brand.dustyRose : Brand.sage)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }

                        if !syncService.diagnosticLog.isEmpty {
                            Divider()
                                .padding(.horizontal, 16)

                            DisclosureGroup("Event Log (\(syncService.diagnosticLog.count))") {
                                ForEach(syncService.diagnosticLog.reversed(), id: \.self) { entry in
                                    Text(entry)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(Brand.warmGray)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }

                        Divider()
                            .padding(.horizontal, 16)

                        Button {
                            syncService.stop()
                            syncService.start()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 14))
                                Text("Force Sync Now")
                                    .font(Brand.captionFont.weight(.medium))
                            }
                            .foregroundStyle(Brand.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                    .background(Brand.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous))
                }
            }
        }
    }

    // MARK: - 6. Danger Zone

    @ViewBuilder
    private var dangerZoneSection: some View {
        if auth.isLinkedWithApple {
            VStack(spacing: 16) {
                Button {
                    showSignOutConfirmation = true
                } label: {
                    Text("Log Out of All Devices")
                        .font(Brand.bodyFont.weight(.medium))
                        .foregroundStyle(Brand.dustyRose)
                }

                Button {
                    showDeleteAccountConfirmation = true
                } label: {
                    Text("Delete Account")
                        .font(Brand.captionFont)
                        .foregroundStyle(Brand.dustyRose.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
    }

    // MARK: - Reusable Settings Row

    private func settingsRow<Trailing: View>(
        icon: String,
        iconColor: Color,
        title: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(Brand.bodyFont.weight(.medium))
                .foregroundStyle(Brand.charcoal)

            Spacer()

            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    // MARK: - Sheets & Alerts

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

    // MARK: - Cloud Sync Setup Sheet

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

    // MARK: - Actions

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
        if let allAchievements = try? modelContext.fetch(FetchDescriptor<Achievement>()) {
            for achievement in allAchievements { modelContext.delete(achievement) }
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

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
            .modelContainer(PreviewSampleData.container)
    }
}
