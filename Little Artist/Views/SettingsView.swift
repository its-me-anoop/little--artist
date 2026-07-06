//
//  SettingsView.swift
//  Little Artist
//
//  App settings with children management, preferences,
//  data management, and about information.
//

import os
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Child.createdAt) private var children: [Child]
    // The `@Query` here only tracks COUNT for the storage calculation — we
    // never loop over the array directly since accessing `imageData` would
    // fault the externally-stored blob for every artwork on every body eval.
    // The actual byte count is computed lazily off the main thread and cached
    // in `storageUsedString` below.
    @Query private var artworks: [Artwork]

    private var store: StoreKitManager { StoreKitManager.shared }
    private var cloudStatus: CloudSyncStatus { CloudSyncStatus.shared }

    @AppStorage("aiCaptionsEnabled") private var aiCaptionsEnabled = true
    @AppStorage("defaultCameraBack") private var defaultCameraBack = true
    @AppStorage("appAppearance") private var appAppearance = AppAppearance.system.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false

    @State private var showAddChild = false
    @State private var showDeleteChildConfirmation = false
    @State private var childToDelete: Child?
    @State private var paywallReason: PaywallView.LimitReason?
    @State private var isRestoring = false
    @State private var exportPayload: SharePayload?
    @State private var isExporting = false
    @State private var showPaywall = false

    @State private var storageUsedString: String = "Calculating…"
    @State private var storageCalcTask: Task<Void, Never>?

    /// Recomputes the total bytes used by artwork image + voice note blobs in
    /// the background. Each `imageData` access faults the externally-stored
    /// blob, so this must never run on the main thread from a body eval.
    @MainActor
    private func recomputeStorageUsed() {
        storageCalcTask?.cancel()

        // Snapshot the current artwork IDs on the main actor, then hand off
        // to a background task that opens its own ModelContext to read the
        // blob sizes without racing with the main-actor model context.
        let modelIDs = artworks.map(\.persistentModelID)
        let container = modelContext.container

        storageCalcTask = Task.detached(priority: .utility) {
            let context = ModelContext(container)
            var totalBytes: Int = 0

            for id in modelIDs {
                if Task.isCancelled { return }
                guard let artwork = context.model(for: id) as? Artwork else { continue }
                if let data = artwork.imageData { totalBytes += data.count }
                if let data = artwork.thumbnailData { totalBytes += data.count }
                if let data = artwork.voiceNoteData { totalBytes += data.count }
            }

            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            let formatted = formatter.string(fromByteCount: Int64(totalBytes))

            await MainActor.run {
                storageUsedString = formatted
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var paywallPresented: Binding<PaywallView.LimitReason?> {
        Binding(
            get: { store.isPremium ? nil : paywallReason },
            set: { paywallReason = $0 }
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

                Text("Unlock unlimited children, unlimited artworks, AI captions, voice memos, and PDF export.")
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
                Text(child.name)
                    .font(Brand.headlineFont)
                    .foregroundStyle(Brand.charcoal)

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
                // iCloud Sync row — automatic, informational only
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Brand.sky.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: cloudStatus.status.isActive ? "checkmark.icloud.fill" : "icloud.slash")
                            .font(.system(size: 18))
                            .foregroundStyle(Brand.sky)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud Sync")
                            .font(Brand.bodyFont.weight(.medium))
                            .foregroundStyle(Brand.charcoal)
                        Text(cloudStatus.status.label)
                            .font(Brand.caption2Font)
                            .foregroundStyle(Brand.warmGray)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider()
                    .padding(.leading, 70)

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

                    Text(storageUsedString)
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
                cloudStatus.refresh()
                recomputeStorageUsed()
            }
            .onDisappear {
                storageCalcTask?.cancel()
            }
            .onChange(of: artworks.count) { _, _ in
                recomputeStorageUsed()
            }
            .sheet(isPresented: $showAddChild) {
                AddChildView()
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
                        ArtworkRepository.shared.deleteChild(child, in: modelContext)
                        childToDelete = nil
                    }
                }
            } message: {
                deleteChildMessageView
            }
    }

    @ViewBuilder
    private var deleteChildMessageView: some View {
        if let child = childToDelete {
            Text("This will permanently delete \(child.name) and all their \(child.artworks?.count ?? 0) artworks from all your devices.")
        }
    }

    // MARK: - Actions

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

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
            .modelContainer(PreviewSampleData.container)
    }
}
