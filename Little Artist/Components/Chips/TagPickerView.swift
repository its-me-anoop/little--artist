//
//  TagPickerView.swift
//  Little Artist
//
//  A flow-layout picker for selecting tags on an artwork.
//  Shows existing tags and allows creating new ones.
//

import SwiftUI
import SwiftData

/// Displays available tags as selectable chips with an option to add new tags.
struct TagPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.name) private var allTags: [Tag]
    @Binding var selectedTags: [Tag]

    @State private var showNewTagField = false
    @State private var newTagName = ""

    /// Pre-seeded tag names created on first launch.
    static let seedTags = [
        "Paint", "Crayon", "Pencil", "Marker", "Watercolor",
        "Collage", "Animals", "Family", "Nature", "School"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Tags", systemImage: "tag.fill")
                .font(Brand.captionFont)
                .foregroundStyle(Brand.warmGray)

            FlowLayout(spacing: 8) {
                ForEach(allTags) { tag in
                    TagChipView(
                        name: tag.name,
                        isSelected: selectedTags.contains(where: { $0.persistentModelID == tag.persistentModelID })
                    ) {
                        toggleTag(tag)
                    }
                }

                // Add new tag button
                Button {
                    showNewTagField = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text("New")
                            .font(Brand.captionFont)
                    }
                    .foregroundStyle(Brand.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .strokeBorder(Brand.primary, style: StrokeStyle(lineWidth: 1, dash: [4]))
                    )
                }
            }

            if showNewTagField {
                HStack {
                    TextField("Tag name", text: $newTagName)
                        .font(Brand.bodyFont)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addNewTag() }

                    Button("Add") { addNewTag() }
                        .font(Brand.captionFont.weight(.semibold))
                        .foregroundStyle(Brand.primary)
                        .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear { seedTagsIfNeeded() }
    }

    private func toggleTag(_ tag: Tag) {
        if let index = selectedTags.firstIndex(where: { $0.persistentModelID == tag.persistentModelID }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }

    private func addNewTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard !allTags.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) else {
            newTagName = ""
            showNewTagField = false
            return
        }
        let tag = Tag(name: trimmed)
        modelContext.insert(tag)
        selectedTags.append(tag)
        newTagName = ""
        showNewTagField = false
    }

    private func seedTagsIfNeeded() {
        guard allTags.isEmpty else { return }
        for name in Self.seedTags {
            modelContext.insert(Tag(name: name))
        }
    }
}

// MARK: - Flow Layout

/// A simple flow layout that wraps children to the next line.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(subviews: subviews, containerWidth: proposal.width ?? .infinity)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(subviews: subviews, containerWidth: bounds.width)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(subviews[index].sizeThatFits(.unspecified))
            )
        }
    }

    private func layout(subviews: Subviews, containerWidth: CGFloat) -> (positions: [CGPoint], size: CGSize) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > containerWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxWidth = max(maxWidth, x - spacing)
        }

        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}
