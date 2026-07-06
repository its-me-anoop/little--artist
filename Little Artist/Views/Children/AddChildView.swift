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
    @State private var name = ""
    @State private var selectedColor = Brand.defaultAvatarColor
    @State private var avatarImageData: Data?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showImagePlayground = false

    private let presetColors = Brand.avatarColors
    private var isNameValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView { content }
            .scrollIndicators(.hidden)
            .background(onboardingBackground)
            .navigationTitle("New Little Artist")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
        }
    }

    private var content: some View {
        VStack(spacing: 24) {
            formCard
            addButton
        }
        .padding(.top, 8)
        .padding(.bottom, 24)
    }

    private var formCard: some View {
        VStack(spacing: 20) {
            avatarPreview
                .onTapGesture {
                    if avatarImageData != nil {
                        avatarImageData = nil
                    }
                }

            photoSourceButtons
            nameField
            colorPickerSection
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Brand.glass)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Brand.glassStroke, lineWidth: 2)
        )
        .padding(.horizontal, 20)
    }

    private var nameField: some View {
        TextField("Child's name", text: $name)
            .font(Brand.title3Font)
            .foregroundStyle(Brand.charcoal)
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(.words)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Brand.glassStrong)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Brand.softTan, lineWidth: 1.5)
            )
    }

    private var colorPickerSection: some View {
        VStack(spacing: 12) {
            Text("Pick a color")
                .font(Brand.subheadlineFont)
                .foregroundStyle(Brand.warmGray)
                .crayonStyle()

            HStack(spacing: 14) {
                ForEach(presetColors, id: \.self) { hex in
                    ColorSwatchView(
                        hex: hex,
                        isSelected: selectedColor == hex
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedColor = hex
                        }
                    }
                }
            }
        }
    }

    private var addButton: some View {
        Button {
            saveChild()
        } label: {
            Text("Add Child")
                .font(Brand.title2Font.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background((isNameValid ? Brand.primary : Brand.disabled).gradient)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Brand.glassStrokeSoft, lineWidth: 3)
                )
                .shadow(color: (isNameValid ? Brand.primary : Brand.disabled).opacity(0.35), radius: 10, x: 0, y: 5)
                .crayonStyle()
        }
        .disabled(!isNameValid)
        .padding(.horizontal, 28)
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

    private var onboardingBackground: some View {
        GeometryReader { geo in
            ZStack {
                BrandAppBackground()

                Circle()
                    .fill(Brand.primary.opacity(0.15))
                    .frame(width: geo.size.width * 1.3, height: geo.size.width * 1.3)
                    .blur(radius: 60)
                    .offset(x: -geo.size.width / 4, y: -geo.size.height / 4)

                Circle()
                    .fill(Brand.sky.opacity(0.12))
                    .frame(width: geo.size.width * 1.1, height: geo.size.width * 1.1)
                    .blur(radius: 70)
                    .offset(x: geo.size.width / 3, y: geo.size.height / 4)
            }
        }
        .ignoresSafeArea()
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
                .background(Brand.glassStrong)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Brand.primary.opacity(0.25), lineWidth: 1.5)
                )
            Text(title)
                .font(Brand.captionFont)
                .foregroundStyle(Brand.warmGray)
                .crayonStyle()
        }
    }

    // MARK: - Save

    private func saveChild() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        ArtworkRepository.shared.createChild(
            name: trimmedName,
            avatarColor: selectedColor,
            avatarImageData: avatarImageData,
            in: modelContext
        )
        dismiss()
    }
}

private struct ColorSwatchView: View {
    let hex: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Circle()
            .fill(Color(hex: hex))
            .frame(width: 40, height: 40)
            .overlay {
                if isSelected {
                    Circle()
                        .strokeBorder(.white, lineWidth: 3)
                    Image(systemName: "checkmark")
                        .font(Brand.captionFont.bold())
                        .foregroundStyle(.white)
                }
            }
            .shadow(color: Color(hex: hex).opacity(0.35), radius: 4, x: 0, y: 2)
            .onTapGesture(perform: onTap)
    }
}

// MARK: - Preview

#Preview {
    AddChildView()
        .modelContainer(for: Child.self, inMemory: true)
}
