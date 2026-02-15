//
//  AddArtworkView.swift
//  Little Artist
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI
import SwiftData
import PhotosUI
import VisionKit
import Vision
#if canImport(FoundationModels)
import FoundationModels
#endif

struct AddArtworkView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let child: Child

    @State private var title = ""
    @State private var caption = ""
    @State private var capturedImageData: Data?
    @State private var showCamera = false
    @State private var showDocumentScanner = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isGeneratingSuggestions = false
    @State private var suggestionErrorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Image preview or placeholder
                        imagePreview
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 16)

                        // Capture source buttons
                        captureSourceButtons
                    }
                }
                .scrollDismissesKeyboard(.interactively)

                // Title field and save — pinned at the bottom
                VStack(spacing: 16) {
                    TextField("Artwork title (optional)", text: $title)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .padding(.horizontal, 32)

                    TextField("Caption (optional)", text: $caption, axis: .vertical)
                        .lineLimit(2...4)
                        .font(.body)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .padding(.horizontal, 32)

                    if aiSuggestionsEnabled {
                        Button {
                            generateAISuggestions()
                        } label: {
                            HStack(spacing: 8) {
                                if isGeneratingSuggestions {
                                    ProgressView()
                                        .tint(.orange)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(isGeneratingSuggestions ? "Generating Suggestions..." : "Suggest Title & Caption")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.12))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 32)
                        .disabled(capturedImageData == nil || isGeneratingSuggestions)
                    }

                    if let suggestionErrorMessage {
                        Text(suggestionErrorMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    Button {
                        saveArtwork()
                    } label: {
                        Text("Save Artwork")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(capturedImageData == nil ? Color.gray : Color.orange)
                            .clipShape(Capsule())
                    }
                    .disabled(capturedImageData == nil)
                    .padding(.horizontal, 32)
                }
                .padding(.top, 16)
                .padding(.bottom, 16)
                .background(Color(.systemBackground))
            }
            .navigationTitle("New Artwork")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                ArtworkCameraPicker { image in
                    if let data = image.jpegData(compressionQuality: 0.85) {
                        capturedImageData = data
                        suggestionErrorMessage = nil
                    }
                }
                .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showDocumentScanner) {
                DocumentScannerPicker { image in
                    if let data = image.jpegData(compressionQuality: 0.85) {
                        capturedImageData = data
                        suggestionErrorMessage = nil
                    }
                }
                .ignoresSafeArea()
            }
            .onChange(of: photoPickerItem) { _, newItem in
                if let newItem {
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            capturedImageData = data
                            suggestionErrorMessage = nil
                        }
                        photoPickerItem = nil
                    }
                }
            }
        }
    }

    // MARK: - Image Preview

    @ViewBuilder
    private var imagePreview: some View {
        if let capturedImageData, let uiImage = UIImage(data: capturedImageData) {
            HStack {
                Spacer(minLength: 0)

                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)

                    Button {
                        self.capturedImageData = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .red)
                            .padding(8)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 32)
        } else {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.tertiarySystemBackground))
                .frame(height: 220)
                .overlay {
                    VStack(spacing: 12) {
                        Image(systemName: "paintpalette")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange.opacity(0.4))
                        Text("Capture or select artwork")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Capture Source Buttons

    private var captureSourceButtons: some View {
        HStack(spacing: 16) {
            // Camera
            Button {
                showCamera = true
            } label: {
                captureSourceLabel(icon: "camera.fill", title: "Camera")
            }
            .buttonStyle(.plain)

            // Gallery
            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                captureSourceLabel(icon: "photo.on.rectangle.angled", title: "Gallery")
            }
            .buttonStyle(.plain)

            // Document Scanner
            Button {
                showDocumentScanner = true
            } label: {
                captureSourceLabel(icon: "doc.viewfinder", title: "Scan")
            }
            .buttonStyle(.plain)
            .disabled(!VNDocumentCameraViewController.isSupported)
            .opacity(VNDocumentCameraViewController.isSupported ? 1 : 0.4)
        }
    }

    private func captureSourceLabel(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.orange)
                .frame(width: 56, height: 56)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Save

    private func saveArtwork() {
        guard let capturedImageData else { return }
        let artwork = Artwork(
            title: title.trimmingCharacters(in: .whitespaces),
            caption: caption.trimmingCharacters(in: .whitespacesAndNewlines),
            imageData: capturedImageData,
            child: child
        )
        modelContext.insert(artwork)
        dismiss()
    }

    private var aiSuggestionsEnabled: Bool {
        guard capturedImageData != nil else { return false }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    private func generateAISuggestions() {
        guard let capturedImageData, !isGeneratingSuggestions else { return }
        suggestionErrorMessage = nil
        isGeneratingSuggestions = true

        Task {
            let extractedText = extractText(from: capturedImageData)

            #if canImport(FoundationModels)
            if #available(iOS 26.0, *) {
                do {
                    let suggestions = try await generateSuggestions(
                        extractedText: extractedText,
                        childName: child.name
                    )
                    await MainActor.run {
                        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            title = suggestions.title
                        }
                        if caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            caption = suggestions.caption
                        }
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
                suggestionErrorMessage = "AI suggestions are only available on supported devices."
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
    private func generateSuggestions(extractedText: String, childName: String) async throws -> AISuggestions {
        let session = LanguageModelSession(
            instructions: """
            You create short, joyful title and caption suggestions for a child's artwork.
            Keep language family-friendly and specific.
            Return ONLY valid JSON in this exact shape:
            {"title":"...","caption":"..."}
            Do not return markdown or extra keys.
            """
        )

        let prompt = """
        Child name: \(childName)
        OCR text found in image: \(extractedText.isEmpty ? "None" : extractedText)
        Generate one unique title (max 5 words) and one unique caption (1 sentence, max 18 words).
        """
        do {
            let response = try await session.respond(to: prompt)
            return parseSuggestions(from: response.content)
        } catch {
            // Retry once because the first call can fail while the model is warming up.
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

private struct AISuggestions: Decodable {
    let title: String
    let caption: String
}

// MARK: - Camera Picker (UIViewControllerRepresentable)

private struct ArtworkCameraPicker: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCaptured: (UIImage) -> Void

        init(onImageCaptured: @escaping (UIImage) -> Void) {
            self.onImageCaptured = onImageCaptured
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImageCaptured(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Document Scanner (UIViewControllerRepresentable)

private struct DocumentScannerPicker: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onImageCaptured: (UIImage) -> Void

        init(onImageCaptured: @escaping (UIImage) -> Void) {
            self.onImageCaptured = onImageCaptured
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            // Use the first scanned page as the artwork image
            if scan.pageCount > 0 {
                let image = scan.imageOfPage(at: 0)
                onImageCaptured(image)
            }
            controller.dismiss(animated: true)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: any Error) {
            controller.dismiss(animated: true)
        }
    }
}

#Preview {
    AddArtworkView(child: Child(name: "Test", avatarColor: "FF8C00"))
        .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
}
