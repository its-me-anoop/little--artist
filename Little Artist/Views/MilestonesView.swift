//
//  MilestonesView.swift
//  Little Artist
//
//  Achievement badges and progress tracking.
//

import SwiftUI
import SwiftData

/// Displays the achievements/badges screen with a progress hero card, a badge grid, and an
/// optional voice-note highlight at the bottom.
struct MilestonesView: View {

    // MARK: - Queries

    @Query private var achievements: [Achievement]
    @Query(sort: \Artwork.createdAt, order: .reverse) private var allArtworks: [Artwork]

    // MARK: - Tier Configuration


    // MARK: - Computed

    private var artworkCount: Int { allArtworks.count }

    private var nextTier: Int {
        MilestoneTiers.nextTier(after: artworkCount)
    }

    private var remainingForNextTier: Int {
        max(nextTier - artworkCount, 0)
    }

    private var artworkWithVoiceMemo: Artwork? {
        allArtworks.first(where: { $0.voiceNoteData != nil })
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Brand.sectionSpacing) {
                progressHeroCard
                badgeGrid
                if artworkWithVoiceMemo != nil {
                    voiceNoteHighlight
                }
            }
            .padding(.horizontal, Brand.screenPadding)
            .padding(.top, Brand.screenPadding)
            .padding(.bottom, Brand.sectionSpacing)
        }
        .navigationTitle("Milestones")
        .background(BrandAppBackground())
    }

    // MARK: - Progress Hero Card

    private var progressHeroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Journey")
                        .font(Brand.title2Font)
                        .foregroundStyle(Brand.primary)
                    Text("Keep adding artworks to unlock new achievements.")
                        .font(Brand.bodyFont)
                        .foregroundStyle(Brand.warmGray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(artworkCount)")
                        .font(Brand.title2Font)
                        .foregroundStyle(Brand.charcoal)
                    Text("/ \(nextTier)")
                        .font(Brand.captionFont)
                        .foregroundStyle(Brand.warmGray)
                }
            }

            ProgressBarView(current: artworkCount, target: nextTier)

            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.primary)
                Text("\(remainingForNextTier) more to reach the next tier")
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray)
            }
        }
        .padding(Brand.fieldPadding + 2)
        .background(Brand.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous))
        .brandCardShadow()
    }

    // MARK: - Badge Grid

    private var badgeGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(achievements) { achievement in
                BadgeCardView(achievement: achievement)
            }
        }
    }

    // MARK: - Voice Note Highlight

    @ViewBuilder
    private var voiceNoteHighlight: some View {
        if let artwork = artworkWithVoiceMemo, let audio = artwork.voiceNoteData {
            VStack(alignment: .leading, spacing: 8) {
                Text("Latest Voice Memo")
                    .font(Brand.captionFont)
                    .foregroundStyle(Brand.charcoal)
                VoiceMemoPlayerView(audioData: audio)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous))
        }
    }
}

// MARK: - Milestone Tiers

/// Artwork-count tiers shown on the Milestones progress bar.
enum MilestoneTiers {
    /// Fixed early tiers; beyond the last one, tiers continue every 500.
    static let targets = [10, 25, 50, 100, 250, 500]

    /// The next tier strictly above `count`.
    static func nextTier(after count: Int) -> Int {
        targets.first(where: { $0 > count }) ?? (count / 500 + 1) * 500
    }
}

// MARK: - Badge Card View

/// A single achievement badge card — earned or locked.
private struct BadgeCardView: View {

    let achievement: Achievement

    private var accentColor: Color {
        switch achievement.category {
        case "artwork":    return Brand.primary
        case "voice":      return Brand.sky
        case "seasonal":   return Brand.sage
        case "medium":     return Brand.lavender
        case "engagement": return Brand.sky
        default:           return Brand.warmGray
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 96, height: 96)
                Image(systemName: achievement.isEarned ? achievement.iconName : "lock.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(achievement.isEarned ? accentColor : Brand.warmGray)
            }

            Text(achievement.title)
                .font(Brand.headlineFont)
                .foregroundStyle(Brand.charcoal)
                .multilineTextAlignment(.center)

            Text(achievement.subtitle)
                .font(Brand.caption2Font)
                .foregroundStyle(Brand.warmGray)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(Brand.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous))
        .brandCardShadow()
        .overlay {
            if !achievement.isEarned {
                RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous)
                    .strokeBorder(
                        Brand.softTan,
                        style: StrokeStyle(lineWidth: 1.5, dash: [6])
                    )
            }
        }
        .opacity(achievement.isEarned ? 1.0 : 0.6)
    }
}

// MARK: - Decorative Waveform View

/// A purely decorative waveform made of thin rounded rectangles.
private struct DecorativeWaveformView: View {

    private let barCount = 20
    private let barHeights: [CGFloat] = [
        10, 18, 28, 22, 32, 16, 26, 30, 14, 24,
        34, 20, 12, 28, 18, 32, 24, 16, 22, 10
    ]

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                Capsule()
                    .fill(index % 3 == 0 ? Brand.softTan : Brand.primary.opacity(0.5))
                    .frame(width: 3, height: barHeights[index % barHeights.count])
            }
        }
        .frame(height: 36)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MilestonesView()
    }
}
