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
    @Environment(\.horizontalSizeClass) private var sizeClass

    let child: Child

    @State private var title = ""
    @State private var caption = ""
    @State private var capturedImageData: Data?
    @State private var capturedThumbnailData: Data?
    @State private var showCamera = false
    @State private var showDocumentScanner = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var batchPickerItems: [PhotosPickerItem] = []
    @State private var isBatchImporting = false
    @State private var voiceNoteData: Data?
    @State private var artworkDate = Date.now
    @State private var isGeneratingSuggestions = false
    @State private var suggestionErrorMessage: String?
    @State private var selectedTags: [Tag] = []
    @State private var validationResult: ArtworkValidationResult?
    @State private var isValidatingImage = false
    @State private var validationDismissed = false

    // MARK: - Extracted Subviews

    private var childIndicatorChip: some View {
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
                .foregroundStyle(.primary)
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
    }

    private var formFields: some View {
        let isRegular = sizeClass == .regular
        let fieldPadding: CGFloat = isRegular ? 0 : 32

        return VStack(spacing: 24) {
            // Title field
            TextField("Artwork title (optional)", text: $title)
                .font(Brand.title3Font)
                .foregroundStyle(.primary)
                .multilineTextAlignment(isRegular ? .leading : .center)
                .padding(.vertical, 14)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Brand.surface)
                )
                .padding(.horizontal, fieldPadding)

            // Caption field
            TextField("Caption (optional)", text: $caption, axis: .vertical)
                .lineLimit(2...4)
                .font(Brand.bodyFont)
                .foregroundStyle(.primary)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Brand.surface)
                )
                .padding(.horizontal, fieldPadding)

            // Date picker
            DatePicker(
                "Date Created",
                selection: $artworkDate,
                in: ...Date.now,
                displayedComponents: .date
            )
            .font(Brand.bodyFont)
            .foregroundStyle(.primary)
            .tint(Brand.primary)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Brand.surface)
            )
            .padding(.horizontal, fieldPadding)

            // Voice memo (premium only)
            if PremiumManager.isPremium {
                VoiceMemoRecorderView(voiceNoteData: $voiceNoteData)
                    .padding(.horizontal, fieldPadding)
            }

            // Tag selection
            TagPickerView(selectedTags: $selectedTags)
                .padding(.horizontal, fieldPadding)

            // AI suggestions
            if capturedImageData != nil {
                AIShimmerView(isAnimating: isGeneratingSuggestions) {
                    Button {
                        generateAISuggestions()
                    } label: {
                        HStack(spacing: 8) {
                            if isGeneratingSuggestions {
                                Image(systemName: "sparkles")
                                    .symbolEffect(.variableColor.iterative, isActive: true)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isGeneratingSuggestions ? "Creating magic..." : "Suggest Title & Caption")
                                .font(Brand.subheadlineFont.weight(.semibold))
                        }
                        .foregroundStyle(aiSuggestionsEnabled ? Brand.primary : Brand.disabled)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(aiSuggestionsEnabled ? Brand.primaryTint : Color.white.opacity(0.4))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!aiSuggestionsEnabled || isGeneratingSuggestions)
                }
                .padding(.horizontal, fieldPadding)
            }

            if let suggestionErrorMessage {
                Text(suggestionErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, fieldPadding)
            }
        }
    }

    /// Whether saving is blocked (no image or inappropriate content).
    private var isSaveDisabled: Bool {
        capturedImageData == nil
        || isValidatingImage
        || validationResult?.isAppropriate == false
    }

    private var saveButton: some View {
        Button {
            saveArtwork()
        } label: {
            Text("Save Artwork")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(isSaveDisabled ? Brand.disabled : Brand.primary)
                .clipShape(Capsule())
        }
        .disabled(isSaveDisabled)
        .padding(.horizontal, 32)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(Color(.systemBackground))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        childIndicatorChip
                            .padding(.top, 12)

                        if sizeClass == .regular {
                            // iPad: two-column layout
                            HStack(alignment: .top, spacing: 32) {
                                VStack(spacing: 24) {
                                    imagePreview
                                    validationWarningBanner
                                    captureSourceButtons
                                }
                                .frame(maxWidth: .infinity)

                                formFields
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, Brand.screenPadding)
                        } else {
                            // iPhone: single-column layout
                            imagePreview
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 4)

                            validationWarningBanner

                            captureSourceButtons

                            formFields
                        }
                    }
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)

                saveButton
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
                    let processed = ImageProcessingService.processForStorage(image: image)
                    capturedImageData = processed.imageData
                    capturedThumbnailData = processed.thumbnailData
                    suggestionErrorMessage = nil
                }
                .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showDocumentScanner) {
                DocumentScannerPicker { image in
                    let processed = ImageProcessingService.processForStorage(image: image)
                    capturedImageData = processed.imageData
                    capturedThumbnailData = processed.thumbnailData
                    suggestionErrorMessage = nil
                }
                .ignoresSafeArea()
            }
            .onChange(of: photoPickerItem) { _, newItem in
                if let newItem {
                    Task {
                        if let rawData = try? await newItem.loadTransferable(type: Data.self),
                           let processed = ImageProcessingService.processForStorage(data: rawData) {
                            capturedImageData = processed.imageData
                            capturedThumbnailData = processed.thumbnailData
                            suggestionErrorMessage = nil
                        }
                        photoPickerItem = nil
                    }
                }
            }
            .onChange(of: batchPickerItems) { _, items in
                guard !items.isEmpty else { return }
                isBatchImporting = true
                Task {
                    await batchImport(items: items)
                    batchPickerItems = []
                    isBatchImporting = false
                    dismiss()
                }
            }
            .onChange(of: capturedImageData) { _, newData in
                validationResult = nil
                validationDismissed = false
                if let newData {
                    validateCapturedImage(newData)
                }
            }
            .overlay {
                if isBatchImporting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        VStack(spacing: 14) {
                            ProgressView()
                                .controlSize(.large)
                                .tint(Brand.primary)
                            Text("Importing \(batchPickerItems.count) artworks...")
                                .font(Brand.subheadlineFont)
                                .foregroundStyle(Brand.charcoal)
                        }
                        .padding(28)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
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
                        .frame(maxHeight: sizeClass == .regular ? 400 : 300)
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
            .padding(.horizontal, sizeClass == .regular ? 0 : 32)
        } else {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.5))
                .frame(height: sizeClass == .regular ? 300 : 220)
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
                .padding(.horizontal, sizeClass == .regular ? 0 : 32)
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

            // Gallery (single)
            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                captureSourceLabel(icon: "photo.on.rectangle.angled", title: "Gallery")
            }
            .buttonStyle(.plain)

            // Batch import (multiple)
            PhotosPicker(
                selection: $batchPickerItems,
                maxSelectionCount: 50,
                matching: .images
            ) {
                captureSourceLabel(icon: "square.stack.3d.up.fill", title: "Batch")
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

    // MARK: - Batch Import

    private func batchImport(items: [PhotosPickerItem]) async {
        let repo = FirestoreRepository.shared
        for (index, item) in items.enumerated() {
            guard let rawData = try? await item.loadTransferable(type: Data.self),
                  let processed = ImageProcessingService.processForStorage(data: rawData) else { continue }
            // Offset each item's date by its index to avoid key collisions
            repo.createArtwork(
                title: "",
                imageData: processed.imageData,
                thumbnailData: processed.thumbnailData,
                createdAt: artworkDate.addingTimeInterval(Double(index)),
                child: child,
                in: modelContext
            )
        }
        HapticService.success()
    }

    // MARK: - Save

    private func saveArtwork() {
        guard let capturedImageData else { return }
        FirestoreRepository.shared.createArtwork(
            title: title.trimmingCharacters(in: .whitespaces),
            caption: caption.trimmingCharacters(in: .whitespacesAndNewlines),
            imageData: capturedImageData,
            thumbnailData: capturedThumbnailData,
            voiceNoteData: voiceNoteData,
            createdAt: artworkDate,
            child: child,
            tags: selectedTags,
            in: modelContext
        )
        dismiss()
    }

    // MARK: - Validation Warning Banner

    @ViewBuilder
    private var validationWarningBanner: some View {
        if isValidatingImage {
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text("Checking image...")
                    .font(Brand.captionFont)
                    .foregroundStyle(Brand.warmGray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: Brand.radiusField)
                    .fill(Brand.surface)
            )
            .padding(.horizontal, 32)
        } else if let result = validationResult, result.message != nil, !validationDismissed {
            let isBlocked = !result.isAppropriate

            HStack(spacing: 10) {
                Image(systemName: isBlocked ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill")
                    .font(.body)
                    .foregroundStyle(isBlocked ? Brand.dustyRose : .orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isBlocked ? "Image not allowed" : "Doesn't look like artwork")
                        .font(Brand.captionFont.weight(.semibold))
                        .foregroundStyle(Brand.charcoal)

                    Text(result.message ?? "")
                        .font(Brand.caption2Font)
                        .foregroundStyle(Brand.warmGray)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                if !isBlocked {
                    Button {
                        validationDismissed = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Brand.warmGray)
                            .padding(6)
                    }
                } else {
                    Button {
                        capturedImageData = nil
                        capturedThumbnailData = nil
                    } label: {
                        Text("Remove")
                            .font(Brand.caption2Font.weight(.semibold))
                            .foregroundStyle(Brand.dustyRose)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .strokeBorder(Brand.dustyRose, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: Brand.radiusField)
                    .fill(isBlocked ? Brand.dustyRose.opacity(0.08) : Color.orange.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: Brand.radiusField)
                            .strokeBorder(isBlocked ? Brand.dustyRose.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Image Validation

    /// Validates a captured image to check if it looks like children's artwork.
    /// Uses Gemini cloud validation for premium users, skips for free tier.
    private func validateCapturedImage(_ imageData: Data) {
        guard PremiumManager.isPremium else {
            // Free users skip cloud validation
            validationResult = .valid
            return
        }
        isValidatingImage = true
        Task {
            let result = await AISuggestionService.validateArtwork(imageData: imageData)
            await MainActor.run {
                validationResult = result
                isValidatingImage = false
            }
        }
    }

    /// Whether AI suggestions can be used (requires premium subscription).
    private var aiSuggestionsEnabled: Bool {
        PremiumManager.isPremium && AISuggestionService.isAvailable
    }

    /// Generates AI-powered title and caption suggestions for the captured artwork.
    private func generateAISuggestions() {
        guard let capturedImageData, !isGeneratingSuggestions else { return }
        suggestionErrorMessage = nil
        isGeneratingSuggestions = true

        Task {
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
    AddArtworkView(child: Child(name: "Test", avatarColor: "FF8C00"))
        .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
}
