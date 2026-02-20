//
//  AddArtworkView.swift
//  Little Artist
//
//  A sheet view for capturing new artwork via camera, photo library,
//  or document scanner. Supports optional AI-generated title and caption
//  suggestions powered by on-device models.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI
import SwiftData
import PhotosUI
import VisionKit

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
    @State private var voiceNoteData: Data?
    @State private var isGeneratingSuggestions = false
    @State private var suggestionErrorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Child indicator chip
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

                            Text("Adding for \(child.name)")
                                .font(Brand.subheadlineFont)
                                .foregroundStyle(Brand.charcoal)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Brand.surface)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Brand.softTan, lineWidth: 1)
                                )
                        )
                        .padding(.top, 12)

                        // Image preview or placeholder
                        imagePreview
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)

                        // Capture source buttons
                        captureSourceButtons
                    }
                }
                .scrollDismissesKeyboard(.interactively)

                // Title field and save — pinned at the bottom
                VStack(spacing: 16) {
                    TextField("Artwork title (optional)", text: $title)
                        .font(Brand.title3Font)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Brand.surface)
                        )
                        .padding(.horizontal, 32)

                    TextField("Caption (optional)", text: $caption, axis: .vertical)
                        .lineLimit(2...4)
                        .font(Brand.bodyFont)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Brand.surface)
                        )
                        .padding(.horizontal, 32)

                    // Voice memo (optional)
                    VoiceMemoRecorderView(voiceNoteData: $voiceNoteData)
                        .padding(.horizontal, 32)

                    if aiSuggestionsEnabled {
                        Button {
                            generateAISuggestions()
                        } label: {
                            HStack(spacing: 8) {
                                if isGeneratingSuggestions {
                                    ProgressView()
                                        .tint(Brand.primary)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(isGeneratingSuggestions ? "Generating Suggestions..." : "Suggest Title & Caption")
                                    .font(Brand.subheadlineFont.weight(.semibold))
                            }
                            .foregroundStyle(Brand.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Brand.primaryTint)
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
                            .background(capturedImageData == nil ? Brand.disabled : Brand.primary)
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
                CameraPicker { image in
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
                        .brandCardShadow()

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
                            .font(.system(size: 48, design: .rounded))
                            .foregroundStyle(Brand.primary.opacity(0.4))
                        Text("Capture or select artwork")
                            .font(Brand.subheadlineFont)
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
                .font(.system(size: 20, design: .rounded))
                .foregroundStyle(Brand.primary)
                .frame(width: 56, height: 56)
                .background(Brand.primaryTint)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Text(title)
                .font(Brand.captionFont)
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
            voiceNoteData: voiceNoteData,
            child: child
        )
        modelContext.insert(artwork)
        dismiss()
    }

    /// Whether AI suggestions can be offered on this device.
    private var aiSuggestionsEnabled: Bool {
        guard capturedImageData != nil else { return false }
        return AISuggestionService.isAvailable
    }

    /// Generates AI-powered title and caption suggestions for the captured artwork.
    private func generateAISuggestions() {
        guard let capturedImageData, !isGeneratingSuggestions else { return }
        suggestionErrorMessage = nil
        isGeneratingSuggestions = true

        Task {
            if #available(iOS 26.0, *), AISuggestionService.isAvailable {
                do {
                    let suggestions = try await AISuggestionService.generateSuggestions(
                        imageData: capturedImageData,
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

            await MainActor.run {
                suggestionErrorMessage = "AI suggestions are only available on supported devices."
                isGeneratingSuggestions = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AddArtworkView(child: Child(name: "Test", avatarColor: "FF8C00"))
        .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
}
