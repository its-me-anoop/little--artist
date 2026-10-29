//
//  ArtworkWidget.swift
//  Little Artist Widget
//
//  Home Screen widget that rotates through the family's artwork —
//  "On This Day" anniversaries first, then favourites and recent pieces.
//

import SwiftUI
import WidgetKit

// MARK: - Brand (widget subset)

/// Widget-local copies of the app's brand tokens (the widget is a separate
/// target and can't see `Brand`). Keep in sync with `BrandTokens.swift`.
private enum WidgetBrand {
    static let primary = Color(red: 0xF2 / 255, green: 0x78 / 255, blue: 0x4B / 255)
    static let cream = Color(red: 0xFF / 255, green: 0xF8 / 255, blue: 0xF0 / 255)
    static let charcoal = Color(red: 0x3D / 255, green: 0x3D / 255, blue: 0x3D / 255)
    static let warmGray = Color(red: 0x8A / 255, green: 0x86 / 255, blue: 0x80 / 255)
}

// MARK: - Timeline

struct ArtworkTimelineEntry: TimelineEntry {
    let date: Date
    let artwork: WidgetArtworkEntry?
    let image: UIImage?
    let totalArtworks: Int
}

struct ArtworkTimelineProvider: TimelineProvider {
    /// How long each artwork stays on screen.
    private let rotationInterval: TimeInterval = 3 * 60 * 60

    func placeholder(in context: Context) -> ArtworkTimelineEntry {
        ArtworkTimelineEntry(date: .now, artwork: nil, image: nil, totalArtworks: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (ArtworkTimelineEntry) -> Void) {
        let snapshot = WidgetSnapshot.load()
        completion(entry(for: snapshot.entries.first, at: .now, total: snapshot.totalArtworks))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ArtworkTimelineEntry>) -> Void) {
        let snapshot = WidgetSnapshot.load()
        let now = Date.now

        guard !snapshot.entries.isEmpty else {
            let empty = entry(for: nil, at: now, total: snapshot.totalArtworks)
            completion(Timeline(entries: [empty], policy: .after(nextMidnight(after: now))))
            return
        }

        // Rotate through the snapshot until midnight, then ask again so
        // "On This Day" picks stay correct.
        let midnight = nextMidnight(after: now)
        var entries: [ArtworkTimelineEntry] = []
        var date = now
        var index = rotationStartIndex(snapshot, now: now)
        while date < midnight, entries.count < 8 {
            entries.append(entry(for: snapshot.entries[index], at: date, total: snapshot.totalArtworks))
            index = (index + 1) % snapshot.entries.count
            date = date.addingTimeInterval(rotationInterval)
        }
        completion(Timeline(entries: entries, policy: .after(min(date, midnight))))
    }

    // MARK: Helpers

    private func entry(for artwork: WidgetArtworkEntry?, at date: Date, total: Int) -> ArtworkTimelineEntry {
        var image: UIImage?
        if let artwork, let url = WidgetSnapshot.imageURL(for: artwork) {
            image = UIImage(contentsOfFile: url.path)
        }
        return ArtworkTimelineEntry(date: date, artwork: artwork, image: image, totalArtworks: total)
    }

    /// "On This Day" entries always lead; otherwise vary the start by hour
    /// so the widget doesn't restart on the same piece every reload.
    private func rotationStartIndex(_ snapshot: WidgetSnapshot, now: Date) -> Int {
        if snapshot.entries.first?.reason == .onThisDay { return 0 }
        let hour = Calendar.current.component(.hour, from: now)
        return (hour / 3) % max(snapshot.entries.count, 1)
    }

    private func nextMidnight(after date: Date) -> Date {
        Calendar.current.nextDate(
            after: date,
            matching: DateComponents(hour: 0, minute: 1),
            matchingPolicy: .nextTime
        ) ?? date.addingTimeInterval(24 * 60 * 60)
    }
}

// MARK: - View

struct ArtworkWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ArtworkTimelineEntry

    var body: some View {
        if let artwork = entry.artwork, let image = entry.image {
            artworkView(artwork, image: image)
        } else {
            emptyView
        }
    }

    private func artworkView(_ artwork: WidgetArtworkEntry, image: UIImage) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(badge(for: artwork))
                    .font(.system(size: family == .systemSmall ? 10 : 11, weight: .bold, design: .rounded))
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.85))

                if family != .systemSmall, !artwork.title.isEmpty {
                    Text(artwork.title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                Text(subtitle(for: artwork))
                    .font(.system(size: family == .systemSmall ? 11 : 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
            }
            .padding(family == .systemSmall ? 12 : 16)
        }
        .accessibilityElement(children: .combine)
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "paintpalette.fill")
                .font(.system(size: family == .systemSmall ? 28 : 34))
                .foregroundStyle(WidgetBrand.primary)
            Text(entry.totalArtworks == 0 ? "Add your first masterpiece" : "Open Little Artist to refresh")
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(WidgetBrand.charcoal)
                .multilineTextAlignment(.center)
            if family != .systemSmall {
                Text("Your little artist's gallery will appear here.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(WidgetBrand.warmGray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    private func badge(for artwork: WidgetArtworkEntry) -> String {
        switch artwork.reason {
        case .onThisDay:
            return artwork.yearsAgo == 1 ? "1 year ago today" : "\(artwork.yearsAgo) years ago today"
        case .favorite:
            return "Favourite"
        case .recent:
            return "From the gallery"
        }
    }

    private func subtitle(for artwork: WidgetArtworkEntry) -> String {
        let date = artwork.createdAt.formatted(.dateTime.month(.abbreviated).year())
        if artwork.childName.isEmpty { return date }
        if family == .systemSmall { return artwork.childName }
        return "\(artwork.childName) · \(date)"
    }
}

// MARK: - Widget

struct ArtworkWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSnapshot.artworkWidgetKind, provider: ArtworkTimelineProvider()) { entry in
            ArtworkWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBrand.cream
                }
        }
        .configurationDisplayName("Gallery & Memories")
        .description("Rotates through your child's artwork, with \"On This Day\" anniversaries first.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

@main
struct LittleArtistWidgetBundle: WidgetBundle {
    var body: some Widget {
        ArtworkWidget()
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    ArtworkWidget()
} timeline: {
    ArtworkTimelineEntry(date: .now, artwork: nil, image: nil, totalArtworks: 0)
}
