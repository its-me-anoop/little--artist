//
//  ProgressBarView.swift
//  Little Artist
//
//  An animated horizontal progress bar for milestone and achievement tracking.
//

import SwiftUI

/// An animated horizontal progress bar that fills from left to right.
///
/// Displays progress as a gradient fill over a muted background track,
/// clamped to the range [0, 1].
struct ProgressBarView: View {

    // MARK: - Properties

    /// The current progress value.
    let current: Int
    /// The target value representing 100% completion.
    let target: Int

    // MARK: - Computed

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Brand.softTan.opacity(0.3))

                // Foreground gradient fill
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Brand.primary, Brand.primary.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75), value: progress)
            }
        }
        .frame(height: 24)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ProgressBarView(current: 3, target: 10)
        ProgressBarView(current: 7, target: 10)
        ProgressBarView(current: 10, target: 10)
    }
    .padding()
    .background(Brand.cream)
}
