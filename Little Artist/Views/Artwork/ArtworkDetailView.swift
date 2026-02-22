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
                    .clipShape(RoundedRectangle(cornerRadius: 20))
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
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(maxWidth: .infinity, minHeight: 320)
                    .overlay {
                        Image(systemName: "paintpalette")
                            .font(.system(size: 52, design: .rounded))
                            .foregroundStyle(Brand.primary.opacity(0.35))
                    }
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
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text(displayTitle)
                .font(Brand.title2Font)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Attribution line
            if let child = artwork.child {
                HStack(spacing: 8) {
                    ZStack {
                        if let imageData = child.avatarImageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(hex: child.avatarColor))
                                .frame(width: 24, height: 24)
                                .overlay {
                                    Text(String(child.name.prefix(1)).uppercased())
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                        }
                    }

                    Text(child.name)
                        .font(Brand.captionFont)
                        .foregroundStyle(.primary)
                    Text("·")
                        .font(Brand.captionFont)
                        .foregroundStyle(.secondary)
                    Text(artwork.createdAt, format: .dateTime.month(.abbreviated).day().year())
                        .font(Brand.captionFont)
                        .foregroundStyle(.secondary)
                }
            }

            // Caption
            if let displayCaption {
                Text(displayCaption)
                    .font(Brand.bodyFont)
                    .foregroundStyle(.secondary)
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
                    VoiceMemoPlayerView(audioData: voiceData)
                }
            }

            Spacer().frame(height: 8)

            // Action buttons row
            HStack(spacing: 16) {
                Button { prepareShareItems() } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(Brand.subheadlineFont)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Brand.primaryTint)
                        .foregroundStyle(Brand.primary)
                        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusButton))
                }

                Button { startEditing() } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(Brand.subheadlineFont)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Brand.primaryTint)
                        .foregroundStyle(Brand.primary)
                        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusButton))
                }

                Button { showDeleteConfirmation = true } label: {
                    Label("Delete", systemImage: "trash")
                        .font(Brand.subheadlineFont)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Brand.dustyRose.opacity(0.12))
                        .foregroundStyle(Brand.dustyRose)
                        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusButton))
                }
            }
            .buttonStyle(.plain)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                imageSection
                metadataSection
            }
            .padding(Brand.Adaptive.screenPadding(for: sizeClass))
        }
        .navigationTitle("Artwork")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                Form {
                    Section("Details") {
                        TextField("Artwork title (optional)", text: $editTitle)
                        TextField("Caption (optional)", text: $editCaption, axis: .vertical)
                            .lineLimit(2...5)
                        DatePicker(
                            "Date Created",
                            selection: $editDate,
                            in: ...Date.now,
                            displayedComponents: .date
                        )
                        .tint(Brand.primary)
                    }

                    Section("Voice Memo") {
                        VoiceMemoRecorderView(voiceNoteData: $editVoiceNoteData)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }

                    Section("Tags") {
                        TagPickerView(selectedTags: $editTags)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }

                    Section {
                        AIShimmerView(isAnimating: isGeneratingSuggestions) {
                            Button {
                                generateAISuggestionsForEdits()
                            } label: {
                                HStack(spacing: 8) {
                                    if isGeneratingSuggestions {
                                        Image(systemName: "sparkles")
                                            .symbolEffect(.variableColor.iterative, isActive: true)
                                    } else {
                                        Image(systemName: "sparkles")
                                    }
                                    Text(isGeneratingSuggestions ? "Creating magic..." : "Improve with On-Device AI")
                                        .font(Brand.subheadlineFont.weight(.semibold))
                                }
                                .foregroundStyle(aiSuggestionsEnabled ? Brand.primary : Brand.disabled)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(aiSuggestionsEnabled ? Brand.primaryTint : Color(.tertiarySystemFill))
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(!aiSuggestionsEnabled || isGeneratingSuggestions)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))

                        if let suggestionErrorMessage {
                            Text(suggestionErrorMessage)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Label("AI", systemImage: "sparkles")
                    }
                }
                .navigationTitle("Edit Artwork")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showEditSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveEdits()
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
        .background(Color(.systemGroupedBackground))
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
        FirestoreRepository.shared.updateArtwork(
            artwork,
            title: editTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            caption: editCaption.trimmingCharacters(in: .whitespacesAndNewlines),
            voiceNoteData: editVoiceNoteData,
            tags: editTags,
            in: modelContext
        )
        artwork.createdAt = editDate
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

    /// Whether AI suggestions can be used (cloud or on-device).
    private var aiSuggestionsEnabled: Bool {
        AISuggestionService.isAvailable
    }

    /// Uses the shared AI service to improve the current title and caption.
    private func generateAISuggestionsForEdits() {
        guard !isGeneratingSuggestions else { return }
        suggestionErrorMessage = nil
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
