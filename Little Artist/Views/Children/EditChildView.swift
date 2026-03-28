//
//  EditChildView.swift
//  Little Artist
//
//  A sheet for editing an existing child profile with name, avatar colour,
//  and optional custom photo (camera, gallery, or Image Playground).
//
//  Created by Codex on 19/02/2026.
//

import SwiftUI
import SwiftData
import PhotosUI
import ImagePlayground

/// A modal form for editing an existing child profile.
///
/// The user can update the child's name, avatar colour, and optional custom
/// avatar image. The profile can also be deleted from this screen.
struct EditChildView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let child: Child
    var onDelete: (() -> Void)? = nil

    @State private var name: String
    @State private var selectedColor: String
    @State private var avatarImageData: Data?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showImagePlayground = false
    @State private var showDeleteConfirmation = false
    @State private var showLeaveConfirmation = false
    @State private var showFirebaseShare = false
    @State private var showShareManagement = false
    @State private var activeShareId: String?
    @State private var sharingError: String?
    @State private var isLeavingShare = false
    @AppStorage("firebaseSyncEnabled") private var firebaseSyncEnabled = false

    private let presetColors = Brand.avatarColors

    init(child: Child, onDelete: (() -> Void)? = nil) {
        self.child = child
        self.onDelete = onDelete
        _name = State(initialValue: child.name)
        _selectedColor = State(initialValue: child.avatarColor)
        _avatarImageData = State(initialValue: child.avatarImageData)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 8)

                    // Avatar preview
                    avatarPreview
                        .onTapGesture {
                            if avatarImageData != nil {
                                avatarImageData = nil
                            }
                        }

                    // Photo source buttons
                    photoSourceButtons

                    // Name field
                    TextField("Child's name", text: $name)
                        .font(Brand.title3Font)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Brand.surface)
                        )
                        .padding(.horizontal, 40)

                    // Color picker
                    VStack(spacing: 12) {
                        Text("Pick a color")
                            .font(Brand.subheadlineFont)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 14) {
                            ForEach(presetColors, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        if hex == selectedColor {
                                            Circle()
                                                .strokeBorder(.white, lineWidth: 3)
                                            Image(systemName: "checkmark")
                                                .font(Brand.captionFont.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .shadow(color: Color(hex: hex).opacity(0.4), radius: 4, x: 0, y: 2)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedColor = hex
                                        }
                                    }
                            }
                        }
                    }

                    // Sharing section (premium only)
                    if PremiumManager.isPremium {
                        VStack(spacing: 8) {
                            Button {
                                if firebaseSyncEnabled {
                                    Task { await presentSharing() }
                                } else {
                                    sharingError = "Enable Sync in Settings to share profiles with another parent."
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: isChildShared ? "person.2.fill" : "person.badge.plus")
                                        .font(.system(size: 16, weight: .medium))
                                    Text(isChildShared ? "Manage Sharing" : "Share Profile")
                                        .font(Brand.headlineFont)
                                }
                                .foregroundStyle(Brand.sky)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .overlay {
                                    Capsule()
                                        .stroke(Brand.sky, lineWidth: 1.5)
                                }
                            }
                            .padding(.horizontal, 32)

                            Text(firebaseSyncEnabled
                                ? "Invite another parent to view and edit this profile"
                                : "Requires Sync (enable in Settings)")
                                .font(Brand.caption2Font)
                                .foregroundStyle(Brand.warmGray)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Spacer().frame(height: 8)

                    // Delete or Leave button — owner can delete, participant can leave
                    if isChildShared && !isCurrentUserOwner {
                        // Participant: show Leave Profile
                        Button(role: .destructive) {
                            showLeaveConfirmation = true
                        } label: {
                            HStack(spacing: 8) {
                                if isLeavingShare {
                                    ProgressView()
                                        .tint(Brand.dustyRose)
                                } else {
                                    Image(systemName: "person.badge.minus")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Leave Profile")
                                        .font(Brand.headlineFont)
                                }
                            }
                            .foregroundStyle(Brand.dustyRose)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .overlay {
                                Capsule()
                                    .stroke(Brand.dustyRose, lineWidth: 1.5)
                            }
                        }
                        .disabled(isLeavingShare)
                        .padding(.horizontal, 32)
                    } else {
                        // Owner or unshared: show Delete Profile
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Text("Delete Profile")
                                .font(Brand.headlineFont)
                                .foregroundStyle(Brand.dustyRose)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .overlay {
                                    Capsule()
                                        .stroke(Brand.dustyRose, lineWidth: 1.5)
                                }
                        }
                        .padding(.horizontal, 32)
                    }

                    // Save button
                    Button {
                        saveChanges()
                    } label: {
                        Text("Save Changes")
                            .font(Brand.headlineFont)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(name.trimmingCharacters(in: .whitespaces).isEmpty ? Brand.disabled : Brand.primary)
                            .clipShape(Capsule())
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in
                    if let data = image.jpegData(compressionQuality: 0.8) {
                        avatarImageData = data
                    }
                }
                .ignoresSafeArea()
            }
            .imagePlaygroundSheetCompat(isPresented: $showImagePlayground) { url in
                if let data = try? Data(contentsOf: url) {
                    avatarImageData = data
                }
            }
            .onChange(of: photoPickerItem) { _, newItem in
                if let newItem {
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            avatarImageData = data
                        }
                        photoPickerItem = nil
                    }
                }
            }
            .sheet(isPresented: $showFirebaseShare) {
                if let activeShareId {
                    ShareManagementView(
                        child: child,
                        shareId: activeShareId,
                        isNewShare: true,
                        onStoppedSharing: { self.activeShareId = nil }
                    )
                }
            }
            .sheet(isPresented: $showShareManagement) {
                if let activeShareId {
                    ShareManagementView(
                        child: child,
                        shareId: activeShareId,
                        onStoppedSharing: { self.activeShareId = nil }
                    )
                }
            }
            .alert("Sharing Unavailable", isPresented: Binding(
                get: { sharingError != nil },
                set: { if !$0 { sharingError = nil } }
            )) {
                Button("OK") { sharingError = nil }
            } message: {
                Text(sharingError ?? "")
            }
            .alert("Delete this child profile?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteChild()
                }
            } message: {
                if isChildShared {
                    Text("This will permanently delete \(child.name) and all their artworks for everyone this profile is shared with.")
                } else {
                    Text("All artworks for \(child.name) will be permanently removed.")
                }
            }
            .task {
                // Check if this child is already shared
                if let existingShare = await FirestoreRepository.shared.findShare(for: child),
                   existingShare.status == "active" {
                    activeShareId = existingShare.shareId
                }
            }
            .alert("Leave this shared profile?", isPresented: $showLeaveConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Leave", role: .destructive) {
                    Task { await leaveSharedProfile() }
                }
            } message: {
                Text("\(child.name)'s profile and all artworks will be removed from your device. The owner will keep their copy.")
            }
        }
    }

    // MARK: - Avatar Preview

    @ViewBuilder
    private var avatarPreview: some View {
        ZStack {
            if let avatarImageData, let uiImage = UIImage(data: avatarImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color(hex: selectedColor))
                    .frame(width: 110, height: 110)

                Text(name.isEmpty ? "?" : String(name.prefix(1)).uppercased())
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .brandCardShadow()
        .overlay(alignment: .bottomTrailing) {
            if avatarImageData != nil {
                Image(systemName: "xmark.circle.fill")
                    .font(Brand.title3Font)
                    .foregroundStyle(.white, Brand.dustyRose)
                    .offset(x: 4, y: 4)
            }
        }
    }

    // MARK: - Photo Source Buttons

    private var photoSourceButtons: some View {
        HStack(spacing: 16) {
            // Camera
            Button {
                showCamera = true
            } label: {
                photoSourceLabel(icon: "camera.fill", title: "Camera")
            }
            .buttonStyle(.plain)

            // Gallery
            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                photoSourceLabel(icon: "photo.on.rectangle.angled", title: "Gallery")
            }
            .buttonStyle(.plain)

            // Image Playground (iOS 18.1+)
            if isImagePlaygroundAvailable {
                Button {
                    showImagePlayground = true
                } label: {
                    photoSourceLabel(icon: "apple.image.playground", title: "Create")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func photoSourceLabel(icon: String, title: String) -> some View {
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

    // MARK: - Sharing State

    private var isChildShared: Bool {
        child.isShared || child.firestoreId != nil && activeShareId != nil
    }

    private var isCurrentUserOwner: Bool {
        !child.isShared
    }

    // MARK: - Actions

    private func saveChanges() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        FirestoreRepository.shared.updateChild(
            child,
            name: trimmedName,
            avatarColor: selectedColor,
            avatarImageData: avatarImageData,
            in: modelContext
        )
        dismiss()
    }

    private func presentSharing() async {
        // If we already know about an active share, just show management
        if activeShareId != nil {
            showShareManagement = true
            return
        }

        // Check Firestore for an existing active share before creating one
        if let existingShare = await FirestoreRepository.shared.findShare(for: child),
           existingShare.status == "active" {
            activeShareId = existingShare.shareId
            showShareManagement = true
            return
        }

        // No existing share — create a new one and auto-present the share link
        do {
            let shareId = try await FirestoreRepository.shared.shareChild(child)
            activeShareId = shareId
            showFirebaseShare = true
        } catch {
            sharingError = error.localizedDescription
        }
    }

    private func deleteChild() {
        // Delete via repository (handles both local + Firestore)
        FirestoreRepository.shared.deleteChild(child, in: modelContext)
        onDelete?()
        dismiss()
    }

    private func leaveSharedProfile() async {
        isLeavingShare = true
        do {
            if let shareId = activeShareId {
                try await FirestoreRepository.shared.leaveShare(shareId: shareId)
            }
            // Remove local mirror
            modelContext.delete(child)
            onDelete?()
            dismiss()
        } catch {
            sharingError = "Failed to leave: \(error.localizedDescription)"
            isLeavingShare = false
        }
    }
}

// MARK: - Preview

#Preview {
    EditChildView(child: Child(name: "Liam", avatarColor: "4D96FF"))
        .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
}
