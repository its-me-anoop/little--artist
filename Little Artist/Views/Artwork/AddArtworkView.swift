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
    @AppStorage("aiCaptionsEnabled") private var aiCaptionsEnabled = true

    @Query(sort: \Child.createdAt) private var children: [Child]

    /// Optional child passed from the caller. When nil, the user picks from the artist selector.
    private let initialChild: Child?

    @State private var selectedChild: Child?
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
    @State private var suggestionEngine: AIEngine?
    @State private var selectedTags: [Tag] = []
    @State private var validationResult: ArtworkValidationResult?
    @State private var isValidatingImage = false
    @State private var validationDismissed = false
    @State private var showAIPermissionCard = false
    @State private var showSourcePicker = false
    @State private var showAddChild = false
    @State private var selectedMedium = "Painting"
    @State private var showDatePicker = false

    // MARK: - Init

    init(child: Child? = nil) {
        self.initialChild = child
    }

    // MARK: - Computed Properties

    /// Whether saving is blocked (no image, inappropriate content, or no child selected).
    private var isSaveDisabled: Bool {
        capturedImageData == nil
        || isValidatingImage
        || validationResult?.isAppropriate == false
        || selectedChild == nil
    }

    private var aiSuggestionsEnabled: Bool {
        canRequestAISuggestions && aiCaptionsEnabled
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
        return "Suggest Title & Caption"
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: Brand.sectionSpacing) {
                        // MARK: Artwork Preview
                        artworkPreviewSection
                            .padding(.top, 8)

                        // MARK: Validation Banner
                        validationWarningBanner

                        // MARK: Artist Selector
                        ArtistSelectorView(
                            children: children,
                            selectedChild: $selectedChild,
                            onAddChild: { showAddChild = true }
                        )

                        // MARK: Form Fields
                        formFieldsSection
                            .padding(.horizontal, Brand.screenPadding)

                        // MARK: Action Buttons
                        if capturedImageData != nil {
                            actionButtonsSection
                                .padding(.horizontal, Brand.screenPadding)
                        }

                        // MARK: AI Permission Card
                        if showAIPermissionCard {
                            AIPermissionRequestCardView(
                                title: "Turn on AI captions?",
                                message: "AI captions are currently off. Enable them to generate titles and captions entirely on-device.",
                                actionTitle: "Enable AI Captions",
                                onEnable: enableAICaptionsAndContinue,
                                onDismiss: { withAnimation(.snappy) { showAIPermissionCard = false } }
                            )
                            .padding(.horizontal, Brand.screenPadding)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        if let suggestionErrorMessage {
                            Text(suggestionErrorMessage)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Brand.screenPadding)
                        }

                        if let badge = suggestionEngine?.privacyBadge {
                            Label(badge, systemImage: "lock.shield")
                                .font(Brand.caption2Font)
                                .foregroundStyle(Brand.sage)
                                .padding(.horizontal, Brand.screenPadding)
                                .transition(.opacity)
                        }

                        // MARK: Creative Notes
                        creativeNotesSection
                            .padding(.horizontal, Brand.screenPadding)

                        // MARK: Tags
                        TagPickerView(selectedTags: $selectedTags)
                            .padding(.horizontal, Brand.screenPadding)
                    }
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)

                // MARK: Save Button
                saveButton
            }
            .navigationTitle("Add Masterpiece")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Brand.charcoal)
                    }
                }
            }
            .onAppear {
                if selectedChild == nil {
                    selectedChild = initialChild ?? children.first
                }
                // Warm the on-device model so the first suggestion is fast.
                #if compiler(>=6.4)
                if #available(iOS 27.0, *), canRequestAISuggestions, aiCaptionsEnabled {
                    AppleIntelligenceService.prewarm()
                }
                #endif
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
            .sheet(isPresented: $showAddChild) {
                AddChildView()
            }
            .confirmationDialog("Choose Source", isPresented: $showSourcePicker) {
                Button("Camera") { showCamera = true }
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Text("Photo Library")
                }
                PhotosPicker(
                    selection: $batchPickerItems,
                    maxSelectionCount: 50,
                    matching: .images
                ) {
                    Text("Batch Import")
                }
                if VNDocumentCameraViewController.isSupported {
                    Button("Scan Document") { showDocumentScanner = true }
                }
                Button("Cancel", role: .cancel) {}
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

    // MARK: - Artwork Preview Section

    private var artworkPreviewSection: some View {
        ZStack(alignment: .bottomTrailing) {
            if let capturedImageData, let uiImage = UIImage(data: capturedImageData) {
                // Captured image with paper-stack effect
                ZStack {
                    // Background "paper" layers
                    RoundedRectangle(cornerRadius: Brand.radiusCard)
                        .fill(Brand.surface)
                        .frame(maxWidth: 260, maxHeight: 280)
                        .rotationEffect(.degrees(-3))
                        .brandCardShadow()

                    RoundedRectangle(cornerRadius: Brand.radiusCard)
                        .fill(Brand.surface)
                        .frame(maxWidth: 260, maxHeight: 280)
                        .rotationEffect(.degrees(1.5))
                        .brandCardShadow()

                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: 240, maxHeight: 260)
                        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusImage))
                        .rotationEffect(.degrees(2))
                        .brandCardShadow()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Brand.screenPadding)
            } else {
                // Placeholder — tappable
                Button {
                    showSourcePicker = true
                } label: {
                    RoundedRectangle(cornerRadius: Brand.radiusCard)
                        .fill(Brand.surface)
                        .frame(height: 220)
                        .overlay {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 40, design: .rounded))
                                    .foregroundStyle(Brand.primary.opacity(0.5))
                                Text("Tap to capture")
                                    .font(Brand.subheadlineFont)
                                    .foregroundStyle(Brand.warmGray)
                            }
                        }
                        .brandCardShadow()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Brand.formPadding)
            }

            // Edit button overlay
            if capturedImageData != nil {
                Button {
                    showSourcePicker = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white, Brand.lavender)
                        .brandAvatarShadow()
                }
                .padding(.trailing, 40)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Form Fields

    private var formFieldsSection: some View {
        VStack(spacing: 16) {
            // Title field
            TextField("Artwork title", text: $title)
                .font(Brand.headlineFont)
                .foregroundStyle(Brand.charcoal)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Brand.surface)
                )

            // Date Created (read-only capsule with tap to expand)
            Button {
                withAnimation(.snappy) {
                    showDatePicker.toggle()
                }
            } label: {
                HStack {
                    Text(dateFormatter.string(from: artworkDate))
                        .font(Brand.bodyFont)
                        .foregroundStyle(Brand.charcoal)
                    Spacer()
                    Image(systemName: "calendar")
                        .foregroundStyle(Brand.warmGray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Brand.surface)
                )
            }
            .buttonStyle(.plain)

            if showDatePicker {
                DatePicker(
                    "Date Created",
                    selection: $artworkDate,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(Brand.primary)
                .padding(.horizontal, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Medium picker
            Menu {
                ForEach(AchievementService.mediumTags, id: \.self) { medium in
                    Button {
                        selectedMedium = medium
                    } label: {
                        if medium == selectedMedium {
                            Label(medium, systemImage: "checkmark")
                        } else {
                            Text(medium)
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedMedium)
                        .font(Brand.bodyFont)
                        .foregroundStyle(Brand.charcoal)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.warmGray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Brand.surface)
                )
            }
        }
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Voice memo (premium only)
                if PremiumManager.isPremium {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Brand.sky.opacity(0.2))
                                .frame(width: 48, height: 48)
                            Image(systemName: "mic.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Brand.sky)
                        }
                        Text("Record Story")
                            .font(Brand.captionFont)
                            .foregroundStyle(Brand.charcoal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: Brand.radiusCard)
                            .fill(Brand.surface)
                    )
                }

                // Magic Caption
                AIShimmerView(isAnimating: isGeneratingSuggestions) {
                    Button {
                        handleAITap()
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Brand.lavender.opacity(0.2))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "sparkles")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Brand.lavender)
                                    .symbolEffect(.variableColor.iterative, isActive: isGeneratingSuggestions)
                            }
                            Text("Magic Caption")
                                .font(Brand.captionFont)
                                .foregroundStyle(Brand.charcoal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: Brand.radiusCard)
                                .fill(Brand.surface)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canRequestAISuggestions || isGeneratingSuggestions)
                    .opacity(canRequestAISuggestions ? 1 : 0.5)
                }
            }

            // Inline voice memo recorder (premium only)
            if PremiumManager.isPremium {
                VoiceMemoRecorderView(voiceNoteData: $voiceNoteData)
            }
        }
    }

    // MARK: - Creative Notes

    private var creativeNotesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Creative Notes")
                .font(Brand.caption2Font.bold())
                .tracking(2)
                .foregroundStyle(Brand.warmGray)
                .textCase(.uppercase)

            TextField("What inspired this masterpiece?", text: $caption, axis: .vertical)
                .lineLimit(3...6)
                .font(Brand.bodyFont)
                .foregroundStyle(Brand.charcoal)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: Brand.radiusCard)
                        .fill(Brand.surface)
                )
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            saveArtwork()
        } label: {
            Text("Save to Gallery")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Brand.buttonPadding)
                .background(isSaveDisabled ? Brand.disabled : Brand.primary)
                .clipShape(Capsule())
        }
        .disabled(isSaveDisabled)
        .padding(.horizontal, Brand.screenPadding)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(Brand.cream)
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
            .padding(.horizontal, Brand.screenPadding)
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
            .padding(.horizontal, Brand.screenPadding)
        }
    }

    // MARK: - Batch Import

    private func batchImport(items: [PhotosPickerItem]) async {
        guard let child = selectedChild else { return }
        let repo = FirestoreRepository.shared
        for (index, item) in items.enumerated() {
            guard let rawData = try? await item.loadTransferable(type: Data.self),
                  let processed = ImageProcessingService.processForStorage(data: rawData) else { continue }
            let anchoredDate = ArtworkDate.dayAnchored(artworkDate, offsetSeconds: Double(index))
            repo.createArtwork(
                title: "",
                imageData: processed.imageData,
                thumbnailData: processed.thumbnailData,
                createdAt: anchoredDate,
                child: child,
                in: modelContext
            )
        }
        let newlyEarned = AchievementService.checkMilestones(context: modelContext)
        if !newlyEarned.isEmpty {
            CelebrationCenter.shared.celebrate(newlyEarned)
        }
        HapticService.success()
    }

    // MARK: - Save

    private func saveArtwork() {
        guard let capturedImageData, let child = selectedChild else { return }
        let anchoredDate = ArtworkDate.dayAnchored(artworkDate)

        // Build tags list including medium tag
        var tags = selectedTags
        if !selectedMedium.isEmpty {
            // Find or create the medium tag
            let mediumName = selectedMedium
            let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.name == mediumName })
            if let existingTag = try? modelContext.fetch(descriptor).first {
                if !tags.contains(where: { $0.persistentModelID == existingTag.persistentModelID }) {
                    tags.append(existingTag)
                }
            } else {
                let newTag = Tag(name: selectedMedium)
                modelContext.insert(newTag)
                tags.append(newTag)
            }
        }

        FirestoreRepository.shared.createArtwork(
            title: title.trimmingCharacters(in: .whitespaces),
            caption: caption.trimmingCharacters(in: .whitespacesAndNewlines),
            imageData: capturedImageData,
            thumbnailData: capturedThumbnailData,
            voiceNoteData: voiceNoteData,
            createdAt: anchoredDate,
            child: child,
            tags: tags,
            in: modelContext
        )

        let newlyEarned = AchievementService.checkMilestones(context: modelContext)
        if !newlyEarned.isEmpty {
            CelebrationCenter.shared.celebrate(newlyEarned)
        }
        HapticService.success()
        dismiss()
    }

    // MARK: - Image Validation

    private func validateCapturedImage(_ imageData: Data) {
        isValidatingImage = true
        Task {
            let result = await AISuggestionService.validateArtworkOnDevice(imageData: imageData)
            await MainActor.run {
                validationResult = result
                isValidatingImage = false
            }
        }
    }

    // MARK: - AI Suggestions

    private func handleAITap() {
        if !aiCaptionsEnabled {
            withAnimation(.snappy) {
                showAIPermissionCard = true
            }
            return
        }
        generateAISuggestions()
    }

    @MainActor
    private func enableAICaptionsAndContinue() {
        aiCaptionsEnabled = true
        showAIPermissionCard = false
        Task { await FirestoreRepository.shared.syncUserPreferencesToFirestore() }
        generateAISuggestions()
    }

    private func generateAISuggestions() {
        guard let capturedImageData, !isGeneratingSuggestions, canRequestAISuggestions else { return }
        guard aiCaptionsEnabled else {
            withAnimation(.snappy) {
                showAIPermissionCard = true
            }
            return
        }
        suggestionErrorMessage = nil
        showAIPermissionCard = false
        isGeneratingSuggestions = true

        let childName = selectedChild?.name ?? "the artist"

        Task {
            let result = await AISuggestionService.generateSuggestions(
                imageData: capturedImageData,
                childName: childName
            )
            await MainActor.run {
                if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    title = result.suggestion.title
                }
                if caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    caption = result.suggestion.caption
                }
                withAnimation(.snappy) {
                    suggestionEngine = result.engine
                }
                isGeneratingSuggestions = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AddArtworkView(child: Child(name: "Test", avatarColor: "FF8C00"))
        .modelContainer(for: [Child.self, Artwork.self, Tag.self], inMemory: true)
}
