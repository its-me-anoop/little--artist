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
/// indicated by an orange ring. Tapping the currently selected avatar opens
/// that child's edit profile sheet.
struct ChildSliderView: View {
    /// The ordered list of children to display.
    let children: [Child]
    /// The currently selected child (bound to the parent view).
    @Binding var selectedChild: Child?
    /// Closure invoked when the user taps the "Add" button.
    var onAddChild: () -> Void
    /// Closure invoked when the user requests editing a child profile.
    var onEditChild: (Child) -> Void = { _ in }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // "All" option
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(selectedChild == nil ? Brand.primary.opacity(0.15) : Brand.softTan.opacity(0.3))
                            .frame(width: Brand.avatarSize, height: Brand.avatarSize)
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(selectedChild == nil ? Brand.primary : Brand.warmGray)
                    }
                    .overlay {
                        if selectedChild == nil {
                            Circle()
                                .strokeBorder(Brand.primary, lineWidth: Brand.avatarRingStroke)
                                .frame(width: Brand.avatarRingSize, height: Brand.avatarRingSize)
                        }
                    }
                    Text("All")
                        .font(Brand.captionFont)
                        .foregroundStyle(selectedChild == nil ? Brand.primary : Brand.warmGray)
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedChild = nil
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(selectedChild == nil ? "All children, selected" : "All children")
                .accessibilityHint("Double tap to show artwork from all children")

                ForEach(children) { child in
                    ChildAvatarView(
                        child: child,
                        isSelected: selectedChild?.persistentModelID == child.persistentModelID
                    )
                    .onTapGesture {
                        let isAlreadySelected = selectedChild?.persistentModelID == child.persistentModelID
                        if isAlreadySelected {
                            onEditChild(child)
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedChild = child
                            }
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

// MARK: - Previews

#Preview("Empty Slider") {
    ChildSliderView(
        children: [],
        selectedChild: .constant(nil),
        onAddChild: {},
        onEditChild: { _ in }
    )
    .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
}

#Preview("With Children") {
    ChildSliderView(
        children: PreviewSampleData.sampleChildren,
        selectedChild: .constant(PreviewSampleData.emma),
        onAddChild: {},
        onEditChild: { _ in }
    )
    .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
}
