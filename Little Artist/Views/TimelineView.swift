//
//  TimelineView.swift
//  Little Artist
//
//  Chronological artwork feed with vertical timeline.
//

import SwiftUI

/// Chronological artwork feed with vertical timeline.
struct TimelineView: View {
    var body: some View {
        VStack {
            Text("Timeline")
                .font(Brand.title1Font)
                .foregroundStyle(Brand.charcoal)
            Text("Coming Soon")
                .font(Brand.bodyFont)
                .foregroundStyle(Brand.warmGray)
        }
    }
}

#Preview {
    TimelineView()
}
