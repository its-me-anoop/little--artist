//
//  AddChildView.swift
//  Little Artist
//
//  A sheet for creating a new child profile with name, avatar colour,
//  and optional custom photo (camera, gallery, or Image Playground).
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI
import SwiftData
import PhotosUI
import ImagePlayground

/// A modal form for adding a new child profile.
///
/// The user can enter a name, pick an avatar colour from seven presets,
/// and optionally choose a custom avatar image via camera, photo library,
/// or Apple's Image Playground.
struct AddChildView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supportsImagePlayground) private var supportsImagePlayground

    @State private var name = ""
    @State private var selectedColor = Brand.defaultAvatarColor
    @State private var avatarImageData: Data?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showImagePlayground = false

    private let presetColors = Brand.avatarColors

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

                    Spacer().frame(height: 16)

                    // Save button
                    Button {
                        saveChild()
                    } label: {
                        Text("Add Child")
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
            .navigationTitle("New Little Artist")
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
            .imagePlaygroundSheet(isPresented: $showImagePlayground) { url in
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

            // Image Playground
            Button {
                showImagePlayground = true
            } label: {
                photoSourceLabel(icon: "apple.image.playground", title: "Create")
            }
            .buttonStyle(.plain)
            .disabled(!supportsImagePlayground)
            .opacity(supportsImagePlayground ? 1 : 0.4)
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

    // MARK: - Save

    private func saveChild() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        FirestoreRepository.shared.createChild(
            name: trimmedName,
            avatarColor: selectedColor,
            avatarImageData: avatarImageData,
            in: modelContext
        )
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddChildView()
        .modelContainer(for: Child.self, inMemory: true)
}
