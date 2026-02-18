//
//  ChildSliderView.swift
//  Little Artist
//
//  A horizontal scrollable strip of child avatar bubbles with an "Add" button.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI
import SwiftData

/// A horizontally scrolling list of child profile avatars.
///
/// Displays a ``ChildAvatarView`` for each child and an ``AddChildButton``
/// at the end. Tapping an avatar selects that child; the selection is
/// indicated by an orange ring.
struct ChildSliderView: View {
    let children: [Child]
    @Binding var selectedChild: Child?
    var onAddChild: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(children) { child in
                    ChildAvatarView(
                        child: child,
                        isSelected: selectedChild?.persistentModelID == child.persistentModelID
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedChild = child
                        }
                    }
                }

                AddChildButton(action: onAddChild)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Child Avatar

/// A circular avatar showing either a custom image or the child's initial
/// over a coloured background. Highlights with an orange ring when selected.
struct ChildAvatarView: View {
    let child: Child
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if let imageData = child.avatarImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(hex: child.avatarColor))
                        .frame(width: 60, height: 60)

                    Text(String(child.name.prefix(1)).uppercased())
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .overlay {
                Circle()
                    .strokeBorder(Color.orange, lineWidth: isSelected ? 3 : 0)
                    .frame(width: 68, height: 68)
            }
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)

            Text(child.name)
                .font(.caption)
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(1)
                .frame(width: 64)
        }
    }
}

// MARK: - Add Child Button

/// A dashed-circle button for adding a new child profile.
struct AddChildButton: View {
    var action: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .strokeBorder(Color.orange.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .frame(width: 60, height: 60)

                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            Text("Add")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 64)
        }
        .onTapGesture {
            action()
        }
    }
}

// MARK: - Previews

#Preview("Empty Slider") {
    ChildSliderView(
        children: [],
        selectedChild: .constant(nil),
        onAddChild: {}
    )
    .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
}

#Preview("With Children") {
    ChildSliderView(
        children: PreviewSampleData.sampleChildren,
        selectedChild: .constant(PreviewSampleData.emma),
        onAddChild: {}
    )
    .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
}

#Preview("Add Child Button") {
    AddChildButton(action: {})
}
