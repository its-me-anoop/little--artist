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
