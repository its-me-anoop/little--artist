//
//  ArtworkDetailView.swift
//  Little Artist
//
//  Full-screen artwork viewer with edit, share, and delete actions.
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
                if let imageData = artwork.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.tertiarySystemBackground))
                        .frame(maxWidth: .infinity, minHeight: 320)
                        .overlay {
                            Image(systemName: "paintpalette")
                                .font(.system(size: 52))
                                .foregroundStyle(.orange.opacity(0.35))
                        }
                }

                Text(displayTitle)
                    .font(.title2.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let displayCaption {
                    Text(displayCaption)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
        .navigationTitle("Artwork")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Share Artwork", systemImage: "square.and.arrow.up") {
                        prepareShareItems()
                    }

                    Button("Edit Artwork", systemImage: "pencil") {
                        startEditing()
                    }

                    Button("Delete Artwork", systemImage: "trash", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
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

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct SharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ArtworkDetailView(artwork: PreviewSampleData.singleArtwork)
            .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
    }
}
