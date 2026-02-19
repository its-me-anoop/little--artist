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

    let artwork: Artwork
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var sharePayload: SharePayload?
    @State private var editTitle = ""
    @State private var editCaption = ""
    @State private var isGeneratingSuggestions = false
    @State private var suggestionErrorMessage: String?
    @State private var imageScale: CGFloat = 1.0

    private var displayTitle: String {
        let trimmed = artwork.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled" : trimmed
    }

    private var displayCaption: String? {
        let trimmed = artwork.caption.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Hero image with pinch-to-zoom and favorite overlay
                ZStack(alignment: .topTrailing) {
                    if let imageData = artwork.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(imageScale)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .gesture(
                                MagnifyGesture()
                                    .onChanged { value in
                                        imageScale = min(max(value.magnification, 1.0), 5.0)
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring(duration: 0.3)) {
                                            if imageScale < 1.2 {
                                                imageScale = 1.0
                                            }
                                        }
                                    }
                            )
                            .onTapGesture(count: 2) {
                                withAnimation(.spring(duration: 0.3)) {
                                    imageScale = imageScale > 1.5 ? 1.0 : 2.0
                                }
                            }
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

                // Title
                Text(displayTitle)
                    .font(Brand.title2Font)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Attribution line
                if let child = artwork.child {
                    HStack(spacing: 8) {
                        // Inline child avatar
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
            .padding(Brand.screenPadding)
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
                    }

                    if aiSuggestionsEnabled {
                        Section("AI") {
                            Button {
                                generateAISuggestionsForEdits()
                            } label: {
                                HStack(spacing: 8) {
                                    if isGeneratingSuggestions {
                                        ProgressView()
                                    } else {
                                        Image(systemName: "sparkles")
                                    }
                                    Text(isGeneratingSuggestions ? "Improving..." : "Improve with On-Device AI")
                                }
                            }
                            .disabled(isGeneratingSuggestions)

                            if let suggestionErrorMessage {
                                Text(suggestionErrorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
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
            .presentationDetents([.medium, .large])
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
        suggestionErrorMessage = nil
        showEditSheet = true
    }

    private func saveEdits() {
        artwork.title = editTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        artwork.caption = editCaption.trimmingCharacters(in: .whitespacesAndNewlines)
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
        modelContext.delete(artwork)
        dismiss()
    }

    /// Whether AI suggestions can be offered on this device.
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
            if #available(iOS 26.0, *), AISuggestionService.isAvailable {
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
                    return
                } catch {
                    await MainActor.run {
                        suggestionErrorMessage = "Suggestions unavailable right now."
                        isGeneratingSuggestions = false
                    }
                    return
                }
            }

            await MainActor.run {
                suggestionErrorMessage = "On-device AI is only available on supported devices."
                isGeneratingSuggestions = false
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
