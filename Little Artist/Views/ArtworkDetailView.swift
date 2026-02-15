//
//  ArtworkDetailView.swift
//  Little Artist
//
//  Created by Codex on 15/02/2026.
//

import SwiftUI
import SwiftData
import Vision
#if canImport(FoundationModels)
import FoundationModels
#endif

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

    private var aiSuggestionsEnabled: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    private func generateAISuggestionsForEdits() {
        guard !isGeneratingSuggestions else { return }
        suggestionErrorMessage = nil
        isGeneratingSuggestions = true

        let currentTitle = editTitle
        let currentCaption = editCaption
        let extractedText = artwork.imageData.map(extractText(from:)) ?? ""
        let childName = artwork.child?.name ?? "the child"

        Task {
            #if canImport(FoundationModels)
            if #available(iOS 26.0, *) {
                do {
                    let suggestions = try await generateSuggestionsForEdits(
                        extractedText: extractedText,
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
            #endif

            await MainActor.run {
                suggestionErrorMessage = "On-device AI is only available on supported devices."
                isGeneratingSuggestions = false
            }
        }
    }

    private func extractText(from imageData: Data) -> String {
        guard let image = UIImage(data: imageData), let cgImage = image.cgImage else {
            return ""
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage)
        do {
            try handler.perform([request])
        } catch {
            return ""
        }

        let lines = (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .prefix(6)

        return lines.joined(separator: ", ")
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func generateSuggestionsForEdits(
        extractedText: String,
        existingTitle: String,
        existingCaption: String,
        childName: String
    ) async throws -> AISuggestions {
        let session = LanguageModelSession(
            instructions: """
            You improve title and caption text for a child's artwork.
            Keep language warm, family-friendly, and concise.
            Return ONLY valid JSON in this exact shape:
            {"title":"...","caption":"..."}
            Do not return markdown or extra keys.
            """
        )

        let prompt = """
        Child name: \(childName)
        Existing title: \(existingTitle.isEmpty ? "None" : existingTitle)
        Existing caption: \(existingCaption.isEmpty ? "None" : existingCaption)
        OCR text found in image: \(extractedText.isEmpty ? "None" : extractedText)
        Provide one improved title (max 5 words) and one improved caption (1 sentence, max 18 words).
        """

        do {
            let response = try await session.respond(to: prompt)
            return parseSuggestions(from: response.content)
        } catch {
            try await Task.sleep(for: .milliseconds(350))
            let retryResponse = try await session.respond(to: prompt)
            return parseSuggestions(from: retryResponse.content)
        }
    }
    #endif

    private func parseSuggestions(from content: String) -> AISuggestions {
        if let jsonRange = content.range(of: #"\{[\s\S]*\}"#, options: .regularExpression) {
            let jsonString = String(content[jsonRange])
            if let data = jsonString.data(using: .utf8),
               let decoded = try? JSONDecoder().decode(AISuggestions.self, from: data) {
                let cleanTitle = sanitizeSuggestionText(decoded.title)
                let cleanCaption = sanitizeSuggestionText(decoded.caption)
                if !cleanTitle.isEmpty || !cleanCaption.isEmpty {
                    return AISuggestions(
                        title: cleanTitle.isEmpty ? "My Artwork" : cleanTitle,
                        caption: cleanCaption.isEmpty ? "A colorful creation full of imagination." : cleanCaption
                    )
                }
            }
        }

        var parsedTitle = ""
        var parsedCaption = ""
        for line in content.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.lowercased().hasPrefix("title:") {
                parsedTitle = String(trimmed.dropFirst("title:".count))
            } else if trimmed.lowercased().hasPrefix("caption:") {
                parsedCaption = String(trimmed.dropFirst("caption:".count))
            }
        }

        let cleanTitle = sanitizeSuggestionText(parsedTitle)
        let cleanCaption = sanitizeSuggestionText(parsedCaption)

        return AISuggestions(
            title: cleanTitle.isEmpty ? "My Artwork" : cleanTitle,
            caption: cleanCaption.isEmpty ? "A colorful creation full of imagination." : cleanCaption
        )
    }

    private func sanitizeSuggestionText(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
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

private struct AISuggestions: Decodable {
    let title: String
    let caption: String
}

#Preview {
    NavigationStack {
        ArtworkDetailView(artwork: Artwork(title: "Rainbow House"))
            .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
    }
}
