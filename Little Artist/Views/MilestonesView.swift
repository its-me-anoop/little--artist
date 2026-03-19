//
//  MilestonesView.swift
//  Little Artist
//
//  Achievement badges and progress tracking.
//

import SwiftUI

/// Achievement badges and progress tracking.
struct MilestonesView: View {
    var body: some View {
        VStack {
            Text("Milestones")
                .font(Brand.title1Font)
                .foregroundStyle(Brand.charcoal)
            Text("Coming Soon")
                .font(Brand.bodyFont)
                .foregroundStyle(Brand.warmGray)
        }
    }
}

#Preview {
    MilestonesView()
}
