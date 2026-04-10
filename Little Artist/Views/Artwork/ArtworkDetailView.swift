//
//  ArtworkDetailView.swift
//  Little Artist
//
//  Full-screen artwork viewer with pinch-to-zoom, attribution,
//  favorite toggle, edit, share, and delete actions.
//  Supports AI-powered caption improvement via AISuggestionService.
//
//  Created by Codex on 15/02/2026.
//

import SwiftUI
import SwiftData

struct ArtworkDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("aiCaptionsEnabled") private var aiCaptionsEnabled = true

    let artwork: Artwork
    /// When set, called after deletion instead of dismissing (for master-detail pane).
    var onDelete: (() -> Void)? = nil
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var sharePayload: SharePayload?
    @State private var editTitle = ""
    @State private var editCaption = ""
    @State private var editVoiceNoteData: Data?
    @State private var editTags: [Tag] = []
    @State private var editDate = Date.now
    @State private var isGeneratingSuggestions = false
    @State private var suggestionErrorMessage: String?
    @State private var imageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var showAIPermissionCard = false

    private var displayTitle: String {
        let trimmed = artwork.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled" : trimmed
    }

    private var displayCaption: String? {
        let trimmed = artwork.caption.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: - Image Section

    private var imageSection: some View {
        ZStack(alignment: .topTrailing) {
            if let imageData = artwork.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Brand.glassStroke, lineWidth: 2)
                    )
                    .scaleEffect(imageScale)
                    .offset(imageOffset)
                    .gesture(zoomGesture)
                    .simultaneousGesture(panGesture)
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            if imageScale > 1.0 {
                                imageScale = 1.0
                                imageOffset = .zero
                            } else {
                                imageScale = 2.5
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .brandCardShadow()
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Brand.glass)
                    .frame(maxWidth: .infinity, minHeight: 320)
                    .overlay {
                        Image(systemName: "paintpalette")
                            .font(.system(size: 52, design: .rounded))
                            .foregroundStyle(Brand.primary.opacity(0.35))
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Brand.glassStroke, lineWidth: 2)
                    )
            }

            // Favorite toggle
            Button {
                HapticService.light()
                artwork.isFavorited.toggle()
            } label: {
                Image(systemName: artwork.isFavorited ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(artwork.isFavorited ? Brand.dustyRose : .white)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .padding(12)
        }
    }

    // MARK: - Zoom Gestures

    /// Pinch-to-zoom with spring-back to original size on release.
    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let newScale = lastScale * value.magnification
                imageScale = min(max(newScale, 0.5), 5.0)
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    imageScale = 1.0
                    imageOffset = .zero
                    lastScale = 1.0
                }
            }
    }

    /// Drag-to-pan while zoomed, springs back on release.
    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard imageScale > 1.0 else { return }
                imageOffset = value.translation
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    imageOffset = .zero
                }
            }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(spacing: 16) {
            // Details card
            VStack(alignment: .leading, spacing: 14) {
                // Title
                Text(displayTitle)
                    .font(Brand.title2Font)
                    .foregroundStyle(Brand.charcoal)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Attribution line
                if let child = artwork.child {
                    HStack(spacing: 8) {
                        ZStack {
                            if let imageData = child.avatarImageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 28, height: 28)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color(hex: child.avatarColor))
                                    .frame(width: 28, height: 28)
                                    .overlay {
                                        Text(String(child.name.prefix(1)).uppercased())
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                    }
                            }
                        }

                        Text(child.name)
                            .font(Brand.captionFont.weight(.medium))
                            .foregroundStyle(Brand.charcoal)
                        Text("·")
                            .font(Brand.captionFont)
                            .foregroundStyle(Brand.warmGray)
                        Text(artwork.createdAt, format: .dateTime.month(.abbreviated).day().year())
                            .font(Brand.captionFont)
                            .foregroundStyle(Brand.warmGray)
                    }
                }

                // Caption
                if let displayCaption {
                    Text(displayCaption)
                        .font(Brand.bodyFont)
                        .foregroundStyle(Brand.warmGray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Tags
                if let tags = artwork.tags, !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(tags) { tag in
                                Text(tag.name)
                                    .font(Brand.caption2Font)
                                    .foregroundStyle(Brand.primary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Brand.primaryTint)
                                    )
                            }
                        }
                    }
                }

                // Voice memo playback
                if let voiceData = artwork.voiceNoteData {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Voice Memo", systemImage: "mic.fill")
                            .font(Brand.captionFont.weight(.medium))
                            .foregroundStyle(Brand.warmGray)
                            .crayonStyle()
                        VoiceMemoPlayerView(audioData: voiceData)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Brand.glass)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Brand.glassStroke, lineWidth: 2)
            )

            // Action buttons row
            HStack(spacing: 12) {
                Button { prepareShareItems() } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(Brand.subheadlineFont.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: Brand.radiusButton, style: .continuous)
                                .fill(Brand.glass)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Brand.radiusButton, style: .continuous)
                                .stroke(Brand.glassStroke, lineWidth: 1.5)
                        )
                        .foregroundStyle(Brand.primary)
                }

                Button { startEditing() } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(Brand.subheadlineFont.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: Brand.radiusButton, style: .continuous)
                                .fill(Brand.glass)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Brand.radiusButton, style: .continuous)
                                .stroke(Brand.glassStroke, lineWidth: 1.5)
                        )
                        .foregroundStyle(Brand.primary)
                }

                Button { showDeleteConfirmation = true } label: {
                    Label("Delete", systemImage: "trash")
                        .font(Brand.subheadlineFont.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: Brand.radiusButton, style: .continuous)
                                .fill(Brand.dustyRose.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Brand.radiusButton, style: .continuous)
                                .stroke(Brand.dustyRose.opacity(0.25), lineWidth: 1.5)
                        )
                        .foregroundStyle(Brand.dustyRose)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Detail Background

    private var detailBackground: some View {
        GeometryReader { geo in
            ZStack {
                BrandAppBackground()

                Circle()
                    .fill(Brand.primary.opacity(0.10))
                    .frame(width: geo.size.width * 1.2, height: geo.size.width * 1.2)
                    .blur(radius: 60)
                    .offset(x: -geo.size.width / 3, y: -geo.size.height / 5)

                Circle()
                    .fill(Brand.sky.opacity(0.08))
                    .frame(width: geo.size.width, height: geo.size.width)
                    .blur(radius: 70)
                    .offset(x: geo.size.width / 3, y: geo.size.height / 3)
            }
        }
        .ignoresSafeArea()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                imageSection
                metadataSection
            }
            .padding(Brand.Adaptive.screenPadding(for: sizeClass))
        }
        .background(detailBackground)
        .navigationTitle("Artwork")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                VStack(spacing: 0) {
                    ScrollView {
                        editSheetContent
                            .padding(.bottom, 24)
                    }
                    .scrollDismissesKeyboard(.interactively)

                    // Save button pinned at bottom
                    Button {
                        saveEdits()
                    } label: {
                        Text("Save Changes")
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
                            .shadow(color: Brand.primary.opacity(0.35), radius: 10, x: 0, y: 5)
                            .crayonStyle()
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 16)
                    .background(Color(.systemBackground).opacity(0.01))
                }
                .background(editSheetBackground)
                .navigationTitle("Edit Artwork")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showEditSheet = false
                        }
                    }
                }
            }
            .editSheetSizing(sizeClass: sizeClass)
        }
        .sheet(item: $sharePayload) { payload in
            ActivityView(activityItems: payload.items)
        }
        .alert("Delete this artwork?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteArtwork()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Edit Sheet Content

    private var editSheetContent: some View {
        VStack(spacing: 24) {
            // Artwork thumbnail preview
            if let imageData = artwork.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Brand.glassStroke, lineWidth: 2)
                    )
                    .brandCardShadow()
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
            }

            // Details card
            VStack(spacing: 16) {
                // Section label
                Label("Details", systemImage: "pencil.and.outline")
                    .font(Brand.captionFont.weight(.medium))
                    .foregroundStyle(Brand.warmGray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .crayonStyle()

                // Title
                TextField("Artwork title (optional)", text: $editTitle)
                    .font(Brand.title3Font)
                    .foregroundStyle(Brand.charcoal)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Brand.glassStrong)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Brand.softTan, lineWidth: 1.5)
                    )

                // Caption
                TextField("Caption (optional)", text: $editCaption, axis: .vertical)
                    .lineLimit(2...5)
                    .font(Brand.bodyFont)
                    .foregroundStyle(Brand.charcoal)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Brand.glassStrong)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Brand.softTan, lineWidth: 1.5)
                    )

                // Date
                DatePicker(
                    "Date Created",
                    selection: $editDate,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .font(Brand.bodyFont)
                .foregroundStyle(Brand.charcoal)
                .tint(Brand.primary)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Brand.glassStrong)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Brand.softTan, lineWidth: 1.5)
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Brand.glass)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Brand.glassStroke, lineWidth: 2)
            )
            .padding(.horizontal, 20)

            // Voice memo card (premium only)
            if PremiumManager.isPremium {
                VStack(spacing: 12) {
                    Label("Voice Memo", systemImage: "mic.fill")
                        .font(Brand.captionFont.weight(.medium))
                        .foregroundStyle(Brand.warmGray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .crayonStyle()

                    VoiceMemoRecorderView(voiceNoteData: $editVoiceNoteData)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 22)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Brand.glass)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Brand.glassStroke, lineWidth: 2)
                )
                .padding(.horizontal, 20)
            }

            // Tags card
            VStack(spacing: 12) {
                Label("Tags", systemImage: "tag.fill")
                    .font(Brand.captionFont.weight(.medium))
                    .foregroundStyle(Brand.warmGray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .crayonStyle()

                TagPickerView(selectedTags: $editTags)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Brand.glass)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Brand.glassStroke, lineWidth: 2)
            )
            .padding(.horizontal, 20)

            // AI suggestion button
            if PremiumManager.isPremium {
                if showAIPermissionCard {
                    AIPermissionRequestCardView(
                        title: "Turn on AI captions?",
                        message: "AI captions are currently off. Enable them to improve titles and captions entirely on-device.",
                        actionTitle: "Enable AI Captions",
                        onEnable: enableAICaptionsAndContinue,
                        onDismiss: { withAnimation(.snappy) { showAIPermissionCard = false } }
                    )
                    .padding(.horizontal, 28)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                AIShimmerView(isAnimating: isGeneratingSuggestions) {
                    Button {
                        handleAITap()
                    } label: {
                        HStack(spacing: 8) {
                            if isGeneratingSuggestions {
                                Image(systemName: "sparkles")
                                    .symbolEffect(.variableColor.iterative, isActive: true)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(aiButtonTitle)
                                .font(Brand.subheadlineFont.weight(.semibold))
                        }
                        .foregroundStyle(canRequestAISuggestions ? Brand.primary : Brand.disabled)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(canRequestAISuggestions ? Brand.primaryTint : Brand.glassMuted)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(canRequestAISuggestions ? Brand.primary.opacity(0.25) : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canRequestAISuggestions || isGeneratingSuggestions)
                }
                .padding(.horizontal, 28)

                if let suggestionErrorMessage {
                    Text(suggestionErrorMessage)
                        .font(Brand.caption2Font)
                        .foregroundStyle(Brand.warmGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
        }
    }

    private var editSheetBackground: some View {
        GeometryReader { geo in
            ZStack {
                BrandAppBackground()

                Circle()
                    .fill(Brand.primary.opacity(0.12))
                    .frame(width: geo.size.width * 1.3, height: geo.size.width * 1.3)
                    .blur(radius: 60)
                    .offset(x: -geo.size.width / 4, y: -geo.size.height / 4)

                Circle()
                    .fill(Brand.sky.opacity(0.10))
                    .frame(width: geo.size.width * 1.1, height: geo.size.width * 1.1)
                    .blur(radius: 70)
                    .offset(x: geo.size.width / 3, y: geo.size.height / 4)
            }
        }
        .ignoresSafeArea()
    }

    private func startEditing() {
        editTitle = artwork.title
        editCaption = artwork.caption
        editVoiceNoteData = artwork.voiceNoteData
        editTags = artwork.tags ?? []
        editDate = artwork.createdAt
        suggestionErrorMessage = nil
        showEditSheet = true
    }

    private func saveEdits() {
        let anchoredDate = ArtworkDate.dayAnchored(editDate)
        FirestoreRepository.shared.updateArtwork(
            artwork,
            title: editTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            caption: editCaption.trimmingCharacters(in: .whitespacesAndNewlines),
            voiceNoteData: editVoiceNoteData,
            createdAt: anchoredDate,
            tags: editTags,
            in: modelContext
        )
        HapticService.success()
        showEditSheet = false
    }

    private func prepareShareItems() {
        var items: [Any] = []

        if let imageData = artwork.imageData, let image = UIImage(data: imageData) {
            items.append(image)
        }

        var lines: [String] = [displayTitle]
        if let displayCaption {
            lines.append(displayCaption)
        }
        items.append(lines.joined(separator: "\n"))

        sharePayload = SharePayload(items: items)
    }

    private func deleteArtwork() {
        HapticService.warning()
        FirestoreRepository.shared.deleteArtwork(artwork, in: modelContext)
        if let onDelete {
            onDelete()
        } else {
            dismiss()
        }
    }

    private var canRequestAISuggestions: Bool {
        PremiumManager.isPremium && AISuggestionService.isAvailable
    }

    private var aiButtonTitle: String {
        if isGeneratingSuggestions {
            return "Creating magic..."
        }
        if !AISuggestionService.isAvailable {
            return "AI Unavailable"
        }
        return "Improve with AI"
    }

    private func handleAITap() {
        if !aiCaptionsEnabled {
            withAnimation(.snappy) {
                showAIPermissionCard = true
            }
            return
        }
        generateAISuggestionsForEdits()
    }

    @MainActor
    private func enableAICaptionsAndContinue() {
        aiCaptionsEnabled = true
        showAIPermissionCard = false
        Task { await FirestoreRepository.shared.syncUserPreferencesToFirestore() }
        generateAISuggestionsForEdits()
    }

    /// Uses the shared AI service to improve the current title and caption.
    private func generateAISuggestionsForEdits() {
        guard !isGeneratingSuggestions, canRequestAISuggestions else { return }
        guard aiCaptionsEnabled else {
            withAnimation(.snappy) {
                showAIPermissionCard = true
            }
            return
        }
        suggestionErrorMessage = nil
        showAIPermissionCard = false
        isGeneratingSuggestions = true

        let currentTitle = editTitle
        let currentCaption = editCaption
        let childName = artwork.child?.name ?? "the child"

        Task {
            do {
                let suggestions = try await AISuggestionService.improveSuggestions(
                    imageData: artwork.imageData,
                    existingTitle: currentTitle,
                    existingCaption: currentCaption,
                    childName: childName
                )

                await MainActor.run {
                    editTitle = suggestions.title
                    editCaption = suggestions.caption
                    isGeneratingSuggestions = false
                }
            } catch {
                await MainActor.run {
                    suggestionErrorMessage = "Suggestions unavailable right now."
                    isGeneratingSuggestions = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ArtworkDetailView(artwork: PreviewSampleData.singleArtwork)
            .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
    }
}
