//
//  TimelineView.swift
//  Little Artist
//
//  Chronological feed of all artworks with sticky month headers,
//  a vertical timeline spine, and year filter chips.
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    @Query(sort: \Artwork.createdAt, order: .reverse) private var allArtworks: [Artwork]

    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var selectedYear: Int? = nil
    @State private var selectedArtwork: Artwork?
    @State private var expandedMonths: Set<String> = []
    @State private var appearedArtworkIDs: Set<PersistentIdentifier> = []

    private let previewLimit = 3

    private var availableYears: [Int] {
        let calendar = Calendar.current
        let years = Set(allArtworks.map { calendar.component(.year, from: $0.createdAt) })
        return years.sorted(by: >)
    }

    private var filteredArtworks: [Artwork] {
        guard let year = selectedYear else { return allArtworks }
        let calendar = Calendar.current
        return allArtworks.filter { calendar.component(.year, from: $0.createdAt) == year }
    }

    private var groupedByMonth: [(key: String, artworks: [Artwork])] {
        let calendar = Calendar.current
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM yyyy"

        var groups: [(key: String, month: Int, year: Int, artworks: [Artwork])] = []
        var map: [String: [Artwork]] = [:]
        var order: [String: (month: Int, year: Int)] = [:]

        for artwork in filteredArtworks {
            let comps = calendar.dateComponents([.year, .month], from: artwork.createdAt)
            let key = "\(comps.year ?? 0)-\(comps.month ?? 0)"
            map[key, default: []].append(artwork)
            if order[key] == nil {
                order[key] = (month: comps.month ?? 0, year: comps.year ?? 0)
            }
        }

        for (key, artworks) in map {
            if let o = order[key] {
                groups.append((key: key, month: o.month, year: o.year, artworks: artworks))
            }
        }

        groups.sort { a, b in
            if a.year != b.year { return a.year > b.year }
            return a.month > b.month
        }

        return groups.map { group in
            var comps = DateComponents()
            comps.year = group.year
            comps.month = group.month
            comps.day = 1
            let date = calendar.date(from: comps) ?? .now
            let label = monthFormatter.string(from: date)
            return (key: label, artworks: group.artworks.sorted { $0.createdAt > $1.createdAt })
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allArtworks.isEmpty {
                    emptyState
                } else if sizeClass == .regular {
                    // iPad: master-detail split
                    HStack(spacing: 0) {
                        timelineContent
                            .frame(maxWidth: .infinity)

                        Divider()

                        Group {
                            if let selectedArtwork {
                                ArtworkDetailView(
                                    artwork: selectedArtwork,
                                    onDelete: {
                                        self.selectedArtwork = nil
                                    }
                                )
                                .id(selectedArtwork.persistentModelID)
                            } else {
                                VStack(spacing: 16) {
                                    Image(systemName: "hand.tap")
                                        .font(.system(size: 48, design: .rounded))
                                        .foregroundStyle(Brand.primary.opacity(0.3))
                                    Text("Select an artwork")
                                        .font(Brand.title3Font)
                                        .foregroundStyle(Brand.warmGray)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Brand.cream)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    timelineContent
                }
            }
            .navigationTitle("Timeline")
            .background(Brand.cream.ignoresSafeArea())
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()

            VStack(spacing: 14) {
                Image("LaunchFox")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)

                Text("No artwork yet")
                    .font(Brand.title1Font)
                    .foregroundStyle(Brand.charcoal)
                    .multilineTextAlignment(.center)

                Text("Add your first artwork from Gallery by tapping the + button.")
                    .font(Brand.title3Font)
                    .foregroundStyle(Brand.warmGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Your timeline will appear here")
                    .font(Brand.captionFont)
                    .foregroundStyle(Brand.warmGray.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.75))
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.58))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.75), lineWidth: 2)
            )
            .brandCardShadow()
            .padding(.horizontal, 16)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var adaptivePadding: CGFloat {
        Brand.Adaptive.screenPadding(for: sizeClass)
    }

    private var timelineContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                // Year chips
                if availableYears.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableYears, id: \.self) { year in
                                YearChipView(
                                    label: String(year),
                                    isSelected: selectedYear == year
                                ) {
                                    withAnimation(.snappy) {
                                        selectedYear = (selectedYear == year) ? nil : year
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, adaptivePadding)
                        .padding(.vertical, 12)
                    }
                }

                // Month sections
                ForEach(groupedByMonth, id: \.key) { group in
                    let isExpanded = expandedMonths.contains(group.key)
                    let hasMore = group.artworks.count > previewLimit
                    let visibleArtworks = isExpanded ? group.artworks : Array(group.artworks.prefix(previewLimit))

                    Section {
                        ForEach(Array(visibleArtworks.enumerated()), id: \.element.id) { index, artwork in
                            let hasAppeared = appearedArtworkIDs.contains(artwork.persistentModelID)

                            HStack(alignment: .top, spacing: 0) {
                                // Spine + dot
                                VStack(spacing: 0) {
                                    Circle()
                                        .fill(Brand.primary)
                                        .frame(width: 10, height: 10)
                                        .padding(.top, 20)
                                        .scaleEffect(hasAppeared ? 1 : 0)
                                    Rectangle()
                                        .fill(Brand.softTan)
                                        .frame(width: 2)
                                }
                                .frame(width: 30)

                                // Entry card — Button on iPad, NavigationLink on iPhone
                                Group {
                                    if sizeClass == .regular {
                                        Button {
                                            withAnimation(.snappy) {
                                                selectedArtwork = artwork
                                            }
                                        } label: {
                                            TimelineEntryCardView(
                                                artwork: artwork,
                                                isSelected: selectedArtwork?.persistentModelID == artwork.persistentModelID
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        NavigationLink {
                                            ArtworkDetailView(artwork: artwork)
                                        } label: {
                                            TimelineEntryCardView(artwork: artwork)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.trailing, adaptivePadding)
                                .padding(.vertical, 6)
                                .opacity(hasAppeared ? 1 : 0)
                                .offset(x: hasAppeared ? 0 : 40)
                            }
                            .onAppear {
                                guard !appearedArtworkIDs.contains(artwork.persistentModelID) else { return }
                                let stagger = Double(index) * 0.08
                                let _ = withAnimation(.spring(duration: 0.45, bounce: 0.15).delay(stagger)) {
                                    appearedArtworkIDs.insert(artwork.persistentModelID)
                                }
                            }
                        }

                        // Show All / Show Less toggle
                        if hasMore {
                            HStack(alignment: .top, spacing: 0) {
                                VStack(spacing: 0) {
                                    Circle()
                                        .fill(Brand.softTan)
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 14)
                                    Rectangle()
                                        .fill(Brand.softTan)
                                        .frame(width: 2)
                                }
                                .frame(width: 30)

                                Button {
                                    withAnimation(.snappy) {
                                        if isExpanded {
                                            expandedMonths.remove(group.key)
                                        } else {
                                            expandedMonths.insert(group.key)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(isExpanded ? "Show Less" : "Show All (\(group.artworks.count))")
                                            .font(Brand.captionFont.bold())
                                            .crayonStyle()
                                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                            .font(.caption.weight(.semibold))
                                    }
                                    .foregroundStyle(Brand.primary)
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                                .padding(.trailing, adaptivePadding)
                            }
                        }
                    } header: {
                        Text(group.key)
                            .font(Brand.title2Font.bold())
                            .foregroundStyle(Brand.charcoal)
                            .crayonStyle()
                            .padding(.horizontal, adaptivePadding)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Brand.cream.opacity(0.95))
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }
}

#Preview("With Data") {
    TimelineView()
        .modelContainer(PreviewSampleData.container)
}

#Preview("Empty") {
    TimelineView()
        .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
}
