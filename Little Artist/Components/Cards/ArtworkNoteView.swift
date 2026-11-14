//
//  ArtworkNoteView.swift
//  Little Artist
//
//  A dated note the parent wrote about an artwork ("She drew this after
//  the zoo trip"). Stored as a `Comment` for CloudKit schema compatibility.
//

import SwiftUI

/// A card showing one note with its date.
struct ArtworkNoteView: View {
    let note: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "note.text")
                .font(Brand.subheadlineFont.weight(.semibold))
                .foregroundStyle(Brand.lavender)
                .frame(width: 32, height: 32)
                .background(Brand.lavender.opacity(0.15), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(note.createdAt, format: .dateTime.day().month(.abbreviated).year())
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray)

                Text(note.text)
                    .font(Brand.bodyFont)
                    .foregroundStyle(Brand.charcoal)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: Brand.radiusField, style: .continuous)
                .fill(Brand.surface.opacity(0.6))
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview {
    ArtworkNoteView(note: Comment(text: "Drawn after our trip to the zoo.", authorName: ""))
        .padding()
}
