//
//  ArtistSelectorView.swift
//  Little Artist
//
//  Horizontal artist picker with selection ring for choosing the active child.
//

import SwiftUI
import SwiftData

/// A horizontal artist picker that shows child avatars with a selection ring.
///
/// Displays each child in a scrollable row with an orange ring around the selected
/// child and an optional "New" button to add a new child profile.
struct ArtistSelectorView: View {

    // MARK: - Properties

    /// The children to display.
    let children: [Child]
    /// The currently selected child.
    @Binding var selectedChild: Child?
    /// Optional closure invoked when the user taps the "New" add button.
    var onAddChild: (() -> Void)?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: Section Label
            Text("ARTIST")
                .font(Brand.caption2Font.bold())
                .tracking(2)
                .foregroundStyle(Brand.warmGray)
                .padding(.horizontal, Brand.screenPadding)

            // MARK: Horizontal Scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(children) { child in
                        artistAvatarItem(child: child)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedChild = child
                                }
                            }
                    }

                    if let addAction = onAddChild {
                        addButton(action: addAction)
                    }
                }
                .padding(.horizontal, Brand.screenPadding)
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Child Avatar Item

    @ViewBuilder
    private func artistAvatarItem(child: Child) -> some View {
        let isSelected = selectedChild?.persistentModelID == child.persistentModelID

        VStack(spacing: 6) {
            ZStack {
                // Avatar image or colored initial
                if let imageData = child.avatarImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(hex: child.avatarColor))
                        .frame(width: 64, height: 64)

                    Text(String(child.name.prefix(1)).uppercased())
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                // Selection ring
                if isSelected {
                    Circle()
                        .strokeBorder(Brand.primary, lineWidth: Brand.avatarRingStroke)
                        .frame(width: 70, height: 70)
                }
            }
            .opacity(isSelected ? 1.0 : 0.5)

            Text(child.name)
                .font(isSelected ? Brand.captionFont.bold() : Brand.captionFont)
                .foregroundStyle(isSelected ? Brand.primary : Brand.warmGray)
                .lineLimit(1)
                .frame(width: 70)
        }
    }

    // MARK: - Add Button

    @ViewBuilder
    private func addButton(action: @escaping () -> Void) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1.5, dash: [6]),
                        antialiased: true
                    )
                    .foregroundStyle(Brand.softTan)
                    .frame(width: 64, height: 64)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Brand.warmGray)
            }

            Text("New")
                .font(Brand.captionFont)
                .foregroundStyle(Brand.warmGray)
                .lineLimit(1)
                .frame(width: 70)
        }
        .onTapGesture(perform: action)
    }
}

// MARK: - Preview

#Preview {
    ArtistSelectorView(
        children: PreviewSampleData.sampleChildren,
        selectedChild: .constant(PreviewSampleData.emma),
        onAddChild: {}
    )
    .padding(.vertical)
    .background(Brand.cream)
    .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
}
