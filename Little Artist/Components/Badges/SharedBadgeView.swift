//
//  SharedBadgeView.swift
//  Little Artist
//
//  A small pill badge indicating a child profile is shared,
//  showing a person.2.fill icon and participant count.
//

import SwiftUI

/// A compact pill badge displaying shared status and participant count.
///
/// Only renders when `isShared` is `true`. Uses `Brand.sky` colour family
/// to match the informational accent palette.
struct SharedBadgeView: View {
    let participantCount: Int
    let isShared: Bool

    var body: some View {
        if isShared {
            HStack(spacing: 4) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 10, weight: .semibold))
                if participantCount > 1 {
                    Text("\(participantCount)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
            }
            .foregroundStyle(Brand.sky)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Brand.sky.opacity(0.12))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        SharedBadgeView(participantCount: 2, isShared: true)
        SharedBadgeView(participantCount: 3, isShared: true)
        SharedBadgeView(participantCount: 1, isShared: false)
    }
    .padding()
}
