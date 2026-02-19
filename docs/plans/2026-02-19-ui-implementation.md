# Little Artist UI Redesign — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform the single-screen NavigationStack app into a 4-tab architecture (Gallery, Timeline, Milestones, Settings) with new screens, search, accessibility, and micro-interactions — matching the approved UI design specification.

**Architecture:** `ContentView` becomes a `TabView` with 4 tabs, each wrapping its own `NavigationStack`. The existing `HomeView` is refactored into the Gallery tab. Three entirely new tabs (Timeline, Milestones, Settings) plus a Search view are added. Model updates add `isFavorited` field to `Artwork`.

**Tech Stack:** SwiftUI, SwiftData, iOS 17+, SF Symbols 5, SF Rounded + SF Pro typography, `BrandTokens.swift` design tokens

**Design Spec:** `docs/plans/2026-02-19-ui-design.md`

---

## Task 1: Update Artwork Model

Add `isFavorited` field to the `Artwork` SwiftData model and update preview sample data.

**Files:**
- Modify: `Little Artist/Models/Artwork.swift`
- Modify: `Little Artist/Utilities/PreviewSampleData.swift`

**Step 1: Add `isFavorited` property to Artwork model**

In `Little Artist/Models/Artwork.swift`, add a new stored property below `voiceNoteURL`:

```swift
/// Whether this artwork has been starred/favourited by the user.
var isFavorited: Bool
```

Update the `init` to include it with a default of `false`:

```swift
init(
    title: String,
    caption: String = "",
    imageData: Data? = nil,
    voiceNoteURL: String? = nil,
    isFavorited: Bool = false,
    createdAt: Date = .now,
    child: Child? = nil
) {
    self.title = title
    self.caption = caption
    self.imageData = imageData
    self.voiceNoteURL = voiceNoteURL
    self.isFavorited = isFavorited
    self.createdAt = createdAt
    self.child = child
}
```

**Step 2: Update PreviewSampleData to include favorited artworks**

In `Little Artist/Utilities/PreviewSampleData.swift`, mark 3 sample artworks as favorited by adding `isFavorited: true` to "Rainbow House", "Christmas Tree", and "Beach Day" entries:

```swift
Artwork(
    title: "Rainbow House",
    caption: "My dream house with a rainbow on top",
    isFavorited: true,
    createdAt: date(year: 2026, month: 2, day: 14)
),
```

Repeat for "Christmas Tree" and "Beach Day".

**Step 3: Build to verify**

Run:
```bash
xcodebuild build -scheme "Little Artist" -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```
Expected: `BUILD SUCCEEDED`

**Step 4: Commit**

```bash
git add "Little Artist/Models/Artwork.swift" "Little Artist/Utilities/PreviewSampleData.swift"
git commit -m "feat: add isFavorited field to Artwork model"
```

---

## Task 2: Create Tab Navigation Shell

Replace the single `NavigationStack` in `ContentView` with a 4-tab `TabView`. The existing `HomeView` becomes the Gallery tab content. Create placeholder views for Timeline, Milestones, and Settings tabs.

**Files:**
- Modify: `Little Artist/App/ContentView.swift`
- Modify: `Little Artist/Views/HomeView.swift`
- Create: `Little Artist/Views/TimelineView.swift` (placeholder)
- Create: `Little Artist/Views/MilestonesView.swift` (placeholder)
- Create: `Little Artist/Views/SettingsView.swift` (placeholder)

**Step 1: Create placeholder TimelineView**

Create `Little Artist/Views/TimelineView.swift`:

```swift
//
//  TimelineView.swift
//  Little Artist
//
//  Chronological feed of all artworks with sticky month headers
//  and a vertical timeline spine visualization.
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    @Query(sort: \Artwork.createdAt, order: .reverse) private var artworks: [Artwork]

    var body: some View {
        NavigationStack {
            Text("Timeline coming soon")
                .font(Brand.bodyFont)
                .foregroundStyle(.secondary)
                .navigationTitle("Timeline")
        }
    }
}

#Preview {
    TimelineView()
        .modelContainer(PreviewSampleData.container)
}
```

**Step 2: Create placeholder MilestonesView**

Create `Little Artist/Views/MilestonesView.swift`:

```swift
//
//  MilestonesView.swift
//  Little Artist
//
//  Statistics dashboard with achievement badges, capture streaks,
//  and per-child artwork breakdowns.
//

import SwiftUI
import SwiftData

struct MilestonesView: View {
    @Query private var children: [Child]
    @Query private var artworks: [Artwork]

    var body: some View {
        NavigationStack {
            Text("Milestones coming soon")
                .font(Brand.bodyFont)
                .foregroundStyle(.secondary)
                .navigationTitle("Milestones")
        }
    }
}

#Preview {
    MilestonesView()
        .modelContainer(PreviewSampleData.container)
}
```

**Step 3: Create placeholder SettingsView**

Create `Little Artist/Views/SettingsView.swift`:

```swift
//
//  SettingsView.swift
//  Little Artist
//
//  App settings with children management, preferences,
//  data management, and about section.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query(sort: \Child.createdAt) private var children: [Child]

    var body: some View {
        NavigationStack {
            Text("Settings coming soon")
                .font(Brand.bodyFont)
                .foregroundStyle(.secondary)
                .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewSampleData.container)
}
```

**Step 4: Refactor ContentView to a 4-tab TabView**

Replace the entire body of `ContentView` in `Little Artist/App/ContentView.swift`:

```swift
//
//  ContentView.swift
//  Little Artist
//
//  Root view displayed after onboarding. Provides a 4-tab navigation
//  shell: Gallery, Timeline, Milestones, and Settings.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Gallery", systemImage: "photo.on.rectangle.angled")
                }
                .tag(0)

            TimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                }
                .tag(1)

            MilestonesView()
                .tabItem {
                    Label("Milestones", systemImage: "star.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(Brand.primary)
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewSampleData.container)
}
```

**Step 5: Update HomeView navigation title**

In `Little Artist/Views/HomeView.swift`, change `.navigationTitle("Little Artist")` to `.navigationTitle("Gallery")` to match the tab name. Also add a trailing search button to the toolbar (navigation to search will be wired in Task 8):

```swift
.navigationTitle("Gallery")
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        NavigationLink {
            // SearchView will be added in Task 8
            Text("Search")
        } label: {
            Image(systemName: "magnifyingglass")
        }
    }
}
```

**Step 6: Build to verify**

```bash
xcodebuild build -scheme "Little Artist" -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```
Expected: `BUILD SUCCEEDED`

**Step 7: Commit**

```bash
git add "Little Artist/App/ContentView.swift" "Little Artist/Views/HomeView.swift" "Little Artist/Views/TimelineView.swift" "Little Artist/Views/MilestonesView.swift" "Little Artist/Views/SettingsView.swift"
git commit -m "feat: add 4-tab navigation shell (Gallery, Timeline, Milestones, Settings)"
```

---

## Task 3: Redesign Gallery Tab as 2-Column Grid

Transform the current horizontal-scroll-per-month gallery into a 2-column `LazyVGrid` with child filter chips at top. Keep the year/month grouping but display artwork cards in a vertical grid instead of horizontal sliders.

**Files:**
- Modify: `Little Artist/Views/ArtworkGalleryView.swift`
- Modify: `Little Artist/Views/HomeView.swift`
- Create: `Little Artist/Components/ChildFilterChipView.swift`

**Step 1: Create ChildFilterChipView component**

Create `Little Artist/Components/ChildFilterChipView.swift`:

```swift
//
//  ChildFilterChipView.swift
//  Little Artist
//
//  A toggleable filter chip showing a child's avatar and name,
//  used in the Gallery tab's horizontal filter bar.
//

import SwiftUI
import SwiftData

struct ChildFilterChipView: View {
    let child: Child
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                // Mini avatar circle
                Circle()
                    .fill(Color(hex: child.avatarColor))
                    .frame(width: 24, height: 24)
                    .overlay {
                        if let data = child.avatarImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .clipShape(Circle())
                        } else {
                            Text(String(child.name.prefix(1)).uppercased())
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }

                Text(child.name)
                    .font(Brand.caption2Font.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Brand.primary : Color(.tertiarySystemFill))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(child.name), \(isSelected ? "selected" : "not selected")")
        .accessibilityHint("Double tap to filter")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
```

**Step 2: Redesign ArtworkGalleryView with 2-column grid**

Replace the entire body of `ArtworkGalleryView` in `Little Artist/Views/ArtworkGalleryView.swift`. The new layout uses a 2-column `LazyVGrid` grouped by month within the selected year, replacing the horizontal sliders:

```swift
//
//  ArtworkGalleryView.swift
//  Little Artist
//
//  A scrollable gallery that organises artworks by year and month
//  in a 2-column vertical grid layout.
//

import SwiftUI
import SwiftData

struct ArtworkGalleryView: View {
    let artworks: [Artwork]

    @State private var selectedYear: Int? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var availableYears: [Int] {
        let calendar = Calendar.current
        let years = Set(artworks.map { calendar.component(.year, from: $0.createdAt) })
        return years.sorted(by: >)
    }

    private var selectedYearArtworks: [Artwork] {
        guard let selectedYear else { return [] }
        let calendar = Calendar.current
        return artworks.filter { calendar.component(.year, from: $0.createdAt) == selectedYear }
    }

    private var groupedMonths: [(month: Int, artworks: [Artwork])] {
        let calendar = Calendar.current
        var monthMap: [Int: [Artwork]] = [:]

        for artwork in selectedYearArtworks {
            let month = calendar.component(.month, from: artwork.createdAt)
            monthMap[month, default: []].append(artwork)
        }

        return monthMap
            .sorted { $0.key > $1.key }
            .map { (month: $0.key, artworks: $0.value.sorted { $0.createdAt > $1.createdAt }) }
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        var components = DateComponents()
        components.month = month
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return ""
    }

    private func ensureValidSelectedYear() {
        if let selectedYear, availableYears.contains(selectedYear) { return }
        selectedYear = availableYears.first
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Brand.gallerySpacing) {
                // Year filter chips
                if availableYears.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableYears, id: \.self) { year in
                                YearChipView(label: String(year), isSelected: selectedYear == year) {
                                    withAnimation(.snappy) {
                                        selectedYear = year
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Brand.screenPadding)
                    }
                }

                // Month sections with 2-column grid
                ForEach(groupedMonths, id: \.month) { monthGroup in
                    VStack(alignment: .leading, spacing: 12) {
                        // Month header with count
                        HStack(alignment: .firstTextBaseline) {
                            Text(monthName(monthGroup.month))
                                .font(Brand.headlineFont)
                            Text("\(monthGroup.artworks.count)")
                                .font(Brand.caption2Font.weight(.medium))
                                .foregroundStyle(Brand.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Brand.primaryTint)
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, Brand.screenPadding)

                        // 2-column grid
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(monthGroup.artworks) { artwork in
                                NavigationLink {
                                    ArtworkDetailView(artwork: artwork)
                                } label: {
                                    ArtworkThumbnailView(artwork: artwork)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Share", systemImage: "square.and.arrow.up") {}
                                    Button("Edit", systemImage: "pencil") {}
                                    Divider()
                                    Button("Delete", systemImage: "trash", role: .destructive) {}
                                }
                            }
                        }
                        .padding(.horizontal, Brand.screenPadding)
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 80)
        }
        .onAppear { ensureValidSelectedYear() }
        .onChange(of: availableYears) { _, _ in ensureValidSelectedYear() }
    }
}

#Preview {
    NavigationStack {
        ArtworkGalleryView(artworks: PreviewSampleData.sampleArtworks)
    }
    .modelContainer(PreviewSampleData.container)
}
```

**Step 3: Update HomeView to show child filter chips**

In `Little Artist/Views/HomeView.swift`, add a horizontal child filter chip bar below the navigation title. Replace the existing `ChildSliderView` with `ChildFilterChipView` chips. The `ChildSliderView` with full-size avatars is still used but we add an "All" chip option:

Replace the `ChildSliderView(...)` call and surrounding code with:

```swift
// Child filter chips
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 8) {
        // "All" chip
        Button {
            withAnimation(.snappy) {
                selectedChild = nil
            }
        } label: {
            Text("All")
                .font(Brand.caption2Font.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedChild == nil ? Brand.primary : Color(.tertiarySystemFill))
                .foregroundStyle(selectedChild == nil ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)

        ForEach(children) { child in
            ChildFilterChipView(
                child: child,
                isSelected: selectedChild?.persistentModelID == child.persistentModelID
            ) {
                withAnimation(.snappy) {
                    if selectedChild?.persistentModelID == child.persistentModelID {
                        selectedChild = nil
                    } else {
                        selectedChild = child
                    }
                }
            }
        }

        // Add child chip
        Button { showAddChild = true } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                Text("Add")
                    .font(Brand.caption2Font.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemFill))
            .foregroundStyle(Brand.primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    .padding(.horizontal, Brand.screenPadding)
    .padding(.vertical, 8)
}
```

Update `filteredArtworks` to handle the "All" case:

```swift
private var filteredArtworks: [Artwork] {
    if let child = selectedChild {
        return (child.artworks ?? []).sorted { $0.createdAt > $1.createdAt }
    }
    // "All" selected — return all children's artworks
    return children.flatMap { $0.artworks ?? [] }.sorted { $0.createdAt > $1.createdAt }
}
```

Update the gallery section to show when children exist (not just when selectedChild is set):

```swift
if children.isEmpty {
    NoChildrenView(onAddChild: { showAddChild = true })
} else if filteredArtworks.isEmpty {
    NoArtworkView()
} else {
    ArtworkGalleryView(artworks: filteredArtworks)
}
```

Update the FAB to show when any children exist:

```swift
.overlay(alignment: .bottomTrailing) {
    if !children.isEmpty {
        AddArtworkButton(action: { showAddArtwork = true })
    }
}
```

Remove `syncSelectedChild()` logic since we now default to "All" (selectedChild = nil). The `.onAppear` and `.onChange` modifiers calling `syncSelectedChild()` can be removed.

For the add artwork sheet, when `selectedChild` is nil, show a child picker inside `AddArtworkView` or pre-select the first child:

```swift
.sheet(isPresented: $showAddArtwork) {
    AddArtworkView(child: selectedChild ?? children.first!)
}
```

**Step 4: Build to verify**

```bash
xcodebuild build -scheme "Little Artist" -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```
Expected: `BUILD SUCCEEDED`

**Step 5: Commit**

```bash
git add "Little Artist/Components/ChildFilterChipView.swift" "Little Artist/Views/ArtworkGalleryView.swift" "Little Artist/Views/HomeView.swift"
git commit -m "feat: redesign Gallery tab with 2-column grid and child filter chips"
```

---

## Task 4: Enhance Artwork Detail View

Add pinch-to-zoom on the hero image, an attribution line ("by [Child] · [date]"), a favorite toggle, and a horizontal action button row (Share, Edit, Delete).

**Files:**
- Modify: `Little Artist/Views/ArtworkDetailView.swift`

**Step 1: Add pinch-to-zoom and attribution**

In `Little Artist/Views/ArtworkDetailView.swift`:

1. Add `@State private var imageScale: CGFloat = 1.0` at the top of the struct
2. Add a `MagnifyGesture` to the hero image for pinch-to-zoom (1x–5x range)
3. Add double-tap to toggle between fit and 2x zoom
4. Below the title, add an attribution line: "by [Child Name] · [formatted date]"
5. Add a favorite heart button in the top-right of the image
6. Replace the toolbar "..." menu with a horizontal action button row at the bottom
7. Add formatted date helper

Attribution line code:
```swift
// Below the title Text
if let childName = artwork.child?.name {
    HStack(spacing: 4) {
        Text("by \(childName)")
        Text("·")
        Text(artwork.createdAt, format: .dateTime.month(.abbreviated).day().year())
    }
    .font(Brand.captionFont)
    .foregroundStyle(.secondary)
}
```

Action buttons row:
```swift
HStack(spacing: 16) {
    Button { prepareShareItems() } label: {
        Label("Share", systemImage: "square.and.arrow.up")
            .font(Brand.subheadlineFont)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Brand.primaryTint)
            .foregroundStyle(Brand.primary)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusButton))
    }

    Button { startEditing() } label: {
        Label("Edit", systemImage: "pencil")
            .font(Brand.subheadlineFont)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Brand.primaryTint)
            .foregroundStyle(Brand.primary)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusButton))
    }

    Button { showDeleteConfirmation = true } label: {
        Label("Delete", systemImage: "trash")
            .font(Brand.subheadlineFont)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Brand.dustyRose.opacity(0.12))
            .foregroundStyle(Brand.dustyRose)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusButton))
    }
}
.buttonStyle(.plain)
.padding(.horizontal, Brand.screenPadding)
```

Favorite toggle (in toolbar or as overlay on image):
```swift
Button {
    artwork.isFavorited.toggle()
} label: {
    Image(systemName: artwork.isFavorited ? "heart.fill" : "heart")
        .foregroundStyle(artwork.isFavorited ? Brand.dustyRose : .secondary)
}
```

**Step 2: Build to verify**

```bash
xcodebuild build -scheme "Little Artist" -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```
Expected: `BUILD SUCCEEDED`

**Step 3: Commit**

```bash
git add "Little Artist/Views/ArtworkDetailView.swift"
git commit -m "feat: enhance artwork detail with zoom, attribution, and action buttons"
```

---

## Task 5: Build Timeline Tab

Implement the full Timeline tab with a chronological vertical feed, sticky month headers, timeline spine visualization, year filter chips, and timeline entry cards.

**Files:**
- Modify: `Little Artist/Views/TimelineView.swift` (replace placeholder)
- Create: `Little Artist/Components/TimelineEntryCardView.swift`

**Step 1: Create TimelineEntryCardView component**

Create `Little Artist/Components/TimelineEntryCardView.swift`:

```swift
//
//  TimelineEntryCardView.swift
//  Little Artist
//
//  A horizontal card for a single artwork entry in the Timeline feed.
//  Shows a small thumbnail, title, child name, and date.
//

import SwiftUI

struct TimelineEntryCardView: View {
    let artwork: Artwork

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let data = artwork.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "paintpalette")
                            .font(.system(size: 20))
                            .foregroundStyle(Brand.primary.opacity(0.3))
                    }
            }

            // Text stack
            VStack(alignment: .leading, spacing: 4) {
                Text(artwork.title.isEmpty ? "Untitled" : artwork.title)
                    .font(Brand.subheadlineFont.weight(.semibold))
                    .foregroundStyle(artwork.title.isEmpty ? .secondary : .primary)
                    .lineLimit(1)

                if let child = artwork.child {
                    Text("by \(child.name)")
                        .font(Brand.caption2Font)
                        .foregroundStyle(.secondary)
                }

                Text(artwork.createdAt, format: .dateTime.month(.abbreviated).day())
                    .font(Brand.caption2Font)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if artwork.isFavorited {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(Brand.dustyRose)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusImage))
        .brandCardShadow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(artwork.title.isEmpty ? "Untitled" : artwork.title) by \(artwork.child?.name ?? "unknown"), \(artwork.createdAt.formatted(.dateTime.month(.wide).day().year()))")
        .accessibilityHint("Double tap for details")
    }
}

#Preview {
    TimelineEntryCardView(artwork: PreviewSampleData.singleArtwork)
        .padding()
        .background(Color(.systemGroupedBackground))
}
```

**Step 2: Implement full TimelineView**

Replace `Little Artist/Views/TimelineView.swift` with the full implementation:

```swift
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

    @State private var selectedYear: Int? = nil

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
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

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

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM yyyy"

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
                } else {
                    timelineContent
                }
            }
            .navigationTitle("Timeline")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                .font(.system(size: 60, design: .rounded))
                .foregroundStyle(Brand.primary.opacity(0.6))
            Text("No artwork yet")
                .font(.system(.title3, design: .rounded).weight(.semibold))
            Text("Capture your first artwork\nto start building your timeline.")
                .font(Brand.subheadlineFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
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
                        .padding(.horizontal, Brand.screenPadding)
                        .padding(.vertical, 12)
                    }
                }

                // Month sections
                ForEach(groupedByMonth, id: \.key) { group in
                    Section {
                        ForEach(group.artworks) { artwork in
                            HStack(alignment: .top, spacing: 0) {
                                // Spine + dot
                                VStack(spacing: 0) {
                                    Circle()
                                        .fill(Brand.primary)
                                        .frame(width: 10, height: 10)
                                        .padding(.top, 20)
                                    Rectangle()
                                        .fill(Brand.softTan)
                                        .frame(width: 2)
                                }
                                .frame(width: 30)

                                // Entry card
                                NavigationLink {
                                    ArtworkDetailView(artwork: artwork)
                                } label: {
                                    TimelineEntryCardView(artwork: artwork)
                                }
                                .buttonStyle(.plain)
                                .padding(.trailing, Brand.screenPadding)
                                .padding(.vertical, 6)
                            }
                        }
                    } header: {
                        Text(group.key)
                            .font(Brand.title3Font)
                            .padding(.horizontal, Brand.screenPadding)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.ultraThinMaterial)
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
```

**Step 3: Build to verify**

```bash
xcodebuild build -scheme "Little Artist" -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```
Expected: `BUILD SUCCEEDED`

**Step 4: Commit**

```bash
git add "Little Artist/Views/TimelineView.swift" "Little Artist/Components/TimelineEntryCardView.swift"
git commit -m "feat: implement Timeline tab with spine visualization and sticky headers"
```

---

## Task 6: Build Milestones Tab

Implement the Milestones tab with a hero stat card, 2x2 stat grid, achievement badges with progress rings, and per-child artwork breakdown.

**Files:**
- Modify: `Little Artist/Views/MilestonesView.swift` (replace placeholder)
- Create: `Little Artist/Components/StatCardView.swift`
- Create: `Little Artist/Components/AchievementBadgeView.swift`

**Step 1: Create StatCardView**

Create `Little Artist/Components/StatCardView.swift`:

```swift
//
//  StatCardView.swift
//  Little Artist
//
//  A compact card displaying a single statistic with an icon, label, and value.
//

import SwiftUI

struct StatCardView: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Brand.primary)

            Text(value)
                .font(Brand.title2Font)
                .foregroundStyle(.primary)

            Text(label)
                .font(Brand.caption2Font)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
        .brandCardShadow()
    }
}

#Preview {
    HStack {
        StatCardView(icon: "figure.child", label: "Artists", value: "3")
        StatCardView(icon: "flame.fill", label: "Streak", value: "12 days")
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
```

**Step 2: Create AchievementBadgeView**

Create `Little Artist/Components/AchievementBadgeView.swift`:

```swift
//
//  AchievementBadgeView.swift
//  Little Artist
//
//  A circular badge with a progress ring showing completion
//  toward an achievement milestone.
//

import SwiftUI

struct Achievement: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let current: Int
    let target: Int
    let description: String

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }

    var isUnlocked: Bool { current >= target }
}

struct AchievementBadgeView: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Brand.softTan, lineWidth: 3)
                    .frame(width: 56, height: 56)

                // Progress ring
                Circle()
                    .trim(from: 0, to: achievement.progress)
                    .stroke(Brand.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))

                // Icon
                if achievement.isUnlocked {
                    Image(systemName: achievement.icon)
                        .font(.title3)
                        .foregroundStyle(Brand.primary)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(Brand.warmGray)
                }
            }

            Text(achievement.name)
                .font(Brand.caption2Font.weight(.medium))
                .lineLimit(1)
                .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)

            Text("\(Int(achievement.progress * 100))%")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .frame(width: 72)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(achievement.name), \(Int(achievement.progress * 100))% complete")
        .accessibilityHint("Double tap for details")
    }
}

#Preview {
    HStack {
        AchievementBadgeView(achievement: Achievement(
            name: "First Steps", icon: "star.fill",
            current: 1, target: 1, description: "Save your first artwork"
        ))
        AchievementBadgeView(achievement: Achievement(
            name: "Prolific", icon: "paintbrush.fill",
            current: 7, target: 10, description: "Save 10 artworks"
        ))
        AchievementBadgeView(achievement: Achievement(
            name: "Time Capsule", icon: "clock.fill",
            current: 3, target: 12, description: "Artwork spanning 12 months"
        ))
    }
    .padding()
}
```

**Step 3: Implement full MilestonesView**

Replace `Little Artist/Views/MilestonesView.swift` with the full implementation. The view queries all children and artworks, computes stats (total artworks, child count, current streak, this month count), generates achievements, and displays per-child breakdowns:

```swift
//
//  MilestonesView.swift
//  Little Artist
//
//  Statistics dashboard showing total artwork count, capture streaks,
//  achievement badges, and per-child breakdowns.
//

import SwiftUI
import SwiftData

struct MilestonesView: View {
    @Query(sort: \Child.createdAt) private var children: [Child]
    @Query(sort: \Artwork.createdAt, order: .reverse) private var artworks: [Artwork]

    private var totalArtworks: Int { artworks.count }
    private var childCount: Int { children.count }

    private var thisMonthCount: Int {
        let calendar = Calendar.current
        let now = Date.now
        return artworks.filter { calendar.isDate($0.createdAt, equalTo: now, toGranularity: .month) }.count
    }

    private var nextMilestone: Int {
        let milestones = [10, 25, 50, 100, 250, 500]
        return milestones.first(where: { $0 > totalArtworks }) ?? (totalArtworks + 50)
    }

    private var achievements: [Achievement] {
        let calendar = Calendar.current
        let uniqueMonths = Set(artworks.map {
            calendar.dateComponents([.year, .month], from: $0.createdAt)
        }).count
        let favoritedCount = artworks.filter(\.isFavorited).count

        return [
            Achievement(name: "First Steps", icon: "star.fill", current: min(totalArtworks, 1), target: 1, description: "Save your first artwork"),
            Achievement(name: "Prolific", icon: "paintbrush.fill", current: min(totalArtworks, 10), target: 10, description: "Save 10 artworks"),
            Achievement(name: "Gallery", icon: "photo.stack.fill", current: min(totalArtworks, 25), target: 25, description: "Save 25 artworks"),
            Achievement(name: "Rainbow", icon: "figure.child", current: min(childCount, 3), target: 3, description: "Artwork from 3 children"),
            Achievement(name: "Collector", icon: "heart.fill", current: min(favoritedCount, 5), target: 5, description: "Favorite 5 artworks"),
            Achievement(name: "Time Capsule", icon: "clock.fill", current: min(uniqueMonths, 12), target: 12, description: "Artwork spanning 12 months"),
        ]
    }

    private func artworkCount(for child: Child) -> Int {
        child.artworks?.count ?? 0
    }

    private var maxChildArtworks: Int {
        children.map { artworkCount(for: $0) }.max() ?? 1
    }

    var body: some View {
        NavigationStack {
            Group {
                if artworks.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle("Milestones")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "star.fill")
                .font(.system(size: 60, design: .rounded))
                .foregroundStyle(Brand.primary.opacity(0.6))
            Text("No milestones yet")
                .font(.system(.title3, design: .rounded).weight(.semibold))
            Text("Capture your first artwork\nto start tracking milestones.")
                .font(Brand.subheadlineFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: Brand.gallerySpacing) {
                // Hero stat card
                VStack(spacing: 12) {
                    Image(systemName: "paintpalette.fill")
                        .font(.title)
                        .foregroundStyle(Brand.primary)

                    Text("\(totalArtworks)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))

                    Text("Total Artworks")
                        .font(Brand.subheadlineFont)
                        .foregroundStyle(.secondary)

                    // Progress bar to next milestone
                    VStack(spacing: 4) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Brand.softTan.opacity(0.5))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Brand.primary)
                                    .frame(width: geo.size.width * CGFloat(totalArtworks) / CGFloat(nextMilestone), height: 8)
                            }
                        }
                        .frame(height: 8)

                        Text("Next: \(nextMilestone)")
                            .font(Brand.caption2Font)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
                .brandCardShadow()
                .padding(.horizontal, Brand.screenPadding)

                // 2x2 stat grid
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    StatCardView(icon: "figure.child", label: "Artists", value: "\(childCount)")
                    StatCardView(icon: "calendar", label: "This Month", value: "\(thisMonthCount)")
                    StatCardView(icon: "heart.fill", label: "Favorites", value: "\(artworks.filter(\.isFavorited).count)")
                    StatCardView(icon: "trophy.fill", label: "Badges", value: "\(achievements.filter(\.isUnlocked).count)/\(achievements.count)")
                }
                .padding(.horizontal, Brand.screenPadding)

                // Achievements
                VStack(alignment: .leading, spacing: 12) {
                    Text("Achievements")
                        .font(Brand.title3Font)
                        .padding(.horizontal, Brand.screenPadding)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(achievements) { achievement in
                                AchievementBadgeView(achievement: achievement)
                            }
                        }
                        .padding(.horizontal, Brand.screenPadding)
                    }
                }

                // Per child breakdown
                if !children.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Per Child")
                            .font(Brand.title3Font)
                            .padding(.horizontal, Brand.screenPadding)

                        VStack(spacing: 0) {
                            ForEach(children) { child in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color(hex: child.avatarColor))
                                        .frame(width: 32, height: 32)
                                        .overlay {
                                            Text(String(child.name.prefix(1)).uppercased())
                                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                                .foregroundStyle(.white)
                                        }

                                    Text(child.name)
                                        .font(Brand.subheadlineFont.weight(.medium))

                                    Spacer()

                                    Text("\(artworkCount(for: child))")
                                        .font(Brand.subheadlineFont)
                                        .foregroundStyle(.secondary)

                                    Image(systemName: "photo.on.rectangle")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                                if child.persistentModelID != children.last?.persistentModelID {
                                    Divider().padding(.leading, 60)
                                }
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
                        .padding(.horizontal, Brand.screenPadding)
                    }
                }
            }
            .padding(.vertical, Brand.screenPadding)
        }
    }
}

#Preview("With Data") {
    MilestonesView()
        .modelContainer(PreviewSampleData.container)
}

#Preview("Empty") {
    MilestonesView()
        .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
}
```

**Step 4: Build to verify**

```bash
xcodebuild build -scheme "Little Artist" -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```
Expected: `BUILD SUCCEEDED`

**Step 5: Commit**

```bash
git add "Little Artist/Views/MilestonesView.swift" "Little Artist/Components/StatCardView.swift" "Little Artist/Components/AchievementBadgeView.swift"
git commit -m "feat: implement Milestones tab with stats, achievements, and child breakdown"
```

---

## Task 7: Build Settings Tab

Implement the Settings tab with grouped sections: children management, preferences, data management, and about.

**Files:**
- Modify: `Little Artist/Views/SettingsView.swift` (replace placeholder)

**Step 1: Implement full SettingsView**

Replace `Little Artist/Views/SettingsView.swift`:

```swift
//
//  SettingsView.swift
//  Little Artist
//
//  App settings with children management, preferences,
//  data management, and about information.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Child.createdAt) private var children: [Child]
    @Query private var artworks: [Artwork]

    @AppStorage("aiCaptionsEnabled") private var aiCaptionsEnabled = true
    @AppStorage("defaultCameraBack") private var defaultCameraBack = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    @State private var showAddChild = false
    @State private var editingChild: Child?
    @State private var showDeleteChildConfirmation = false
    @State private var childToDelete: Child?

    private var storageUsed: String {
        let bytes = artworks.compactMap(\.imageData).reduce(0) { $0 + $1.count }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                // CHILDREN
                Section {
                    ForEach(children) { child in
                        NavigationLink {
                            EditChildView(child: child) {
                                // onDelete callback — no special handling needed
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: child.avatarColor))
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if let data = child.avatarImageData,
                                           let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .clipShape(Circle())
                                        } else {
                                            Text(String(child.name.prefix(1)).uppercased())
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                                .foregroundStyle(.white)
                                        }
                                    }

                                Text(child.name)
                                    .font(Brand.bodyFont)

                                Spacer()

                                Text("\(child.artworks?.count ?? 0) artworks")
                                    .font(Brand.caption2Font)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            childToDelete = children[index]
                            showDeleteChildConfirmation = true
                        }
                    }

                    Button {
                        showAddChild = true
                    } label: {
                        Label("Add Child", systemImage: "plus")
                            .foregroundStyle(Brand.primary)
                    }
                } header: {
                    Text("Children")
                }

                // PREFERENCES
                Section {
                    Toggle(isOn: $aiCaptionsEnabled) {
                        Label("AI Captions", systemImage: "sparkles")
                    }
                    .tint(Brand.primary)

                    HStack {
                        Label("Default Camera", systemImage: "camera.fill")
                        Spacer()
                        Picker("", selection: $defaultCameraBack) {
                            Text("Back").tag(true)
                            Text("Front").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 140)
                    }
                } header: {
                    Text("Preferences")
                }

                // DATA
                Section {
                    HStack {
                        Label("Storage", systemImage: "externaldrive.fill")
                        Spacer()
                        Text(storageUsed)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Data")
                }

                // ABOUT
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        hasCompletedOnboarding = false
                    } label: {
                        Label("Replay Onboarding", systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAddChild) {
                AddChildView()
            }
            .alert("Delete Child?", isPresented: $showDeleteChildConfirmation) {
                Button("Cancel", role: .cancel) {
                    childToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let child = childToDelete {
                        modelContext.delete(child)
                        childToDelete = nil
                    }
                }
            } message: {
                if let child = childToDelete {
                    Text("This will permanently delete \(child.name) and all their \(child.artworks?.count ?? 0) artworks.")
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewSampleData.container)
}
```

**Step 2: Build to verify**

```bash
xcodebuild build -scheme "Little Artist" -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```
Expected: `BUILD SUCCEEDED`

**Step 3: Commit**

```bash
git add "Little Artist/Views/SettingsView.swift"
git commit -m "feat: implement Settings tab with children, preferences, data, and about"
```

---

## Task 8: Build Search & Filter View

Implement full-text search across artwork titles and captions, with child filter chips, recent searches persistence, and a results grid.

**Files:**
- Create: `Little Artist/Views/SearchView.swift`
- Modify: `Little Artist/Views/HomeView.swift` (wire up NavigationLink to SearchView)

**Step 1: Create SearchView**

Create `Little Artist/Views/SearchView.swift`:

```swift
//
//  SearchView.swift
//  Little Artist
//
//  Full-text search across artwork titles and captions with
//  child filter chips and recent search history.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Query(sort: \Artwork.createdAt, order: .reverse) private var allArtworks: [Artwork]
    @Query(sort: \Child.createdAt) private var children: [Child]

    @State private var searchText = ""
    @State private var selectedChildIDs: Set<PersistentIdentifier> = []
    @State private var showFavoritesOnly = false
    @AppStorage("recentSearches") private var recentSearchesData: Data = Data()

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var recentSearches: [String] {
        (try? JSONDecoder().decode([String].self, from: recentSearchesData)) ?? []
    }

    private func saveSearch(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var searches = recentSearches.filter { $0 != trimmed }
        searches.insert(trimmed, at: 0)
        if searches.count > 10 { searches = Array(searches.prefix(10)) }
        recentSearchesData = (try? JSONEncoder().encode(searches)) ?? Data()
    }

    private func removeRecentSearch(_ term: String) {
        var searches = recentSearches.filter { $0 != term }
        recentSearchesData = (try? JSONEncoder().encode(searches)) ?? Data()
    }

    private var filteredArtworks: [Artwork] {
        var results = allArtworks

        // Child filter
        if !selectedChildIDs.isEmpty {
            results = results.filter { artwork in
                guard let child = artwork.child else { return false }
                return selectedChildIDs.contains(child.persistentModelID)
            }
        }

        // Favorites filter
        if showFavoritesOnly {
            results = results.filter(\.isFavorited)
        }

        // Text search
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            results = results.filter { artwork in
                artwork.title.lowercased().contains(query) ||
                artwork.caption.lowercased().contains(query)
            }
        }

        return results
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // Recent searches (shown when search is empty)
                if searchText.isEmpty && !recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Searches")
                            .font(Brand.caption2Font.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, Brand.screenPadding)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recentSearches, id: \.self) { term in
                                    Button {
                                        searchText = term
                                    } label: {
                                        Text(term)
                                            .font(Brand.caption2Font)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color(.tertiarySystemFill))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, Brand.screenPadding)
                        }
                    }
                }

                // Filter chips
                VStack(alignment: .leading, spacing: 8) {
                    Text("Filter By")
                        .font(Brand.caption2Font.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Brand.screenPadding)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(children) { child in
                                ChildFilterChipView(
                                    child: child,
                                    isSelected: selectedChildIDs.contains(child.persistentModelID)
                                ) {
                                    withAnimation(.snappy) {
                                        if selectedChildIDs.contains(child.persistentModelID) {
                                            selectedChildIDs.remove(child.persistentModelID)
                                        } else {
                                            selectedChildIDs.insert(child.persistentModelID)
                                        }
                                    }
                                }
                            }

                            Button {
                                withAnimation(.snappy) {
                                    showFavoritesOnly.toggle()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                                        .font(.system(size: 11))
                                    Text("Starred")
                                        .font(Brand.caption2Font.weight(.medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(showFavoritesOnly ? Brand.dustyRose : Color(.tertiarySystemFill))
                                .foregroundStyle(showFavoritesOnly ? .white : .primary)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, Brand.screenPadding)
                    }
                }

                // Results
                if !searchText.isEmpty || !selectedChildIDs.isEmpty || showFavoritesOnly {
                    Text("Results (\(filteredArtworks.count))")
                        .font(Brand.caption2Font.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Brand.screenPadding)

                    if filteredArtworks.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40, design: .rounded))
                                .foregroundStyle(Brand.primary.opacity(0.4))
                            Text("No artwork found")
                                .font(Brand.subheadlineFont.weight(.medium))
                            Text("Try a different search or adjust filters")
                                .font(Brand.caption2Font)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(filteredArtworks) { artwork in
                                NavigationLink {
                                    ArtworkDetailView(artwork: artwork)
                                } label: {
                                    ArtworkThumbnailView(artwork: artwork)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Brand.screenPadding)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search artwork...")
        .onSubmit(of: .search) {
            saveSearch(searchText)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
    .modelContainer(PreviewSampleData.container)
}
```

**Step 2: Wire SearchView in HomeView**

In `Little Artist/Views/HomeView.swift`, replace the placeholder `Text("Search")` in the toolbar NavigationLink with `SearchView()`:

```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        NavigationLink {
            SearchView()
        } label: {
            Image(systemName: "magnifyingglass")
        }
    }
}
```

**Step 3: Build to verify**

```bash
xcodebuild build -scheme "Little Artist" -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```
Expected: `BUILD SUCCEEDED`

**Step 4: Commit**

```bash
git add "Little Artist/Views/SearchView.swift" "Little Artist/Views/HomeView.swift"
git commit -m "feat: implement Search & Filter view with recent searches and child filters"
```

---

## Task 9: Polish Onboarding with Liquid Glass and Flow Improvements

Refine the existing onboarding flow: add `ultraThinMaterial` to the illustration container, improve the "Get Started" button to navigate to AddChildView, hide Skip on last page, and add haptic feedback.

**Files:**
- Modify: `Little Artist/Views/OnboardingView.swift`

**Step 1: Apply Liquid Glass material and flow improvements**

In `Little Artist/Views/OnboardingView.swift`:

1. Replace the `RoundedRectangle` background fill (LinearGradient) with `ultraThinMaterial`:
```swift
RoundedRectangle(cornerRadius: 40)
    .fill(.ultraThinMaterial)
    .frame(height: 340)
    .padding(.horizontal, 16)
```

2. Add `@State private var showAddChild = false` to the struct

3. Change the "Get Started" action on the last page to show AddChildView instead of just setting hasCompletedOnboarding:
```swift
if currentPage < pages.count - 1 {
    currentPage += 1
} else {
    showAddChild = true
}
```

4. Add a sheet for AddChildView that completes onboarding on dismiss:
```swift
.sheet(isPresented: $showAddChild, onDismiss: {
    hasCompletedOnboarding = true
}) {
    AddChildView()
}
```

5. Add haptic feedback on page changes. Add to the struct:
```swift
private let selectionFeedback = UISelectionFeedbackGenerator()
private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
```

Add `.onChange(of: currentPage)` to trigger selection haptic:
```swift
.onChange(of: currentPage) { _, _ in
    selectionFeedback.selectionChanged()
}
```

On "Get Started" tap, fire medium impact:
```swift
impactFeedback.impactOccurred()
```

**Step 2: Build to verify**

```bash
xcodebuild build -scheme "Little Artist" -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```
Expected: `BUILD SUCCEEDED`

**Step 3: Commit**

```bash
git add "Little Artist/Views/OnboardingView.swift"
git commit -m "feat: polish onboarding with Liquid Glass material and haptics"
```

---

## Task 10: Add Accessibility and Micro-Interactions

Add VoiceOver labels to key interactive elements, Reduce Motion support for card animations, and haptic feedback throughout the app.

**Files:**
- Modify: `Little Artist/Components/ArtworkThumbnailView.swift` (VoiceOver label)
- Modify: `Little Artist/Components/AddArtworkButton.swift` (VoiceOver + haptic)
- Modify: `Little Artist/Views/HomeView.swift` (haptics on filter)
- Modify: `Little Artist/Views/ArtworkDetailView.swift` (haptics on actions)
- Create: `Little Artist/Utilities/HapticService.swift`

**Step 1: Create HapticService utility**

Create `Little Artist/Utilities/HapticService.swift`:

```swift
//
//  HapticService.swift
//  Little Artist
//
//  Centralized haptic feedback helpers for consistent
//  tactile responses throughout the app.
//

import UIKit

enum HapticService {
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
```

**Step 2: Add VoiceOver to ArtworkThumbnailView**

In `Little Artist/Components/ArtworkThumbnailView.swift`, add after the closing brace of the outer `VStack` (before `.padding(8)`):

```swift
.accessibilityElement(children: .combine)
.accessibilityLabel("\(artwork.title.isEmpty ? "Untitled" : artwork.title) by \(artwork.child?.name ?? "unknown"), created \(formattedDate)")
.accessibilityHint("Double tap to view details")
```

**Step 3: Add VoiceOver and haptic to AddArtworkButton**

In `Little Artist/Components/AddArtworkButton.swift`, add to the Button's action:

```swift
Button {
    HapticService.medium()
    action()
}
```

Add accessibility modifiers to the button label:

```swift
.accessibilityLabel("Add new artwork")
.accessibilityHint("Double tap to capture artwork")
```

**Step 4: Add haptics to HomeView filter chip taps**

In `Little Artist/Views/HomeView.swift`, add `HapticService.selection()` inside the filter chip tap handlers (inside `withAnimation(.snappy)` blocks).

**Step 5: Add haptics to ArtworkDetailView actions**

In `Little Artist/Views/ArtworkDetailView.swift`:
- Add `HapticService.success()` in `saveEdits()`
- Add `HapticService.warning()` in `deleteArtwork()`
- Add `HapticService.light()` when toggling favorite

**Step 6: Add Reduce Motion support to onboarding animations**

In `Little Artist/Views/Onboarding/AnimationTrigger.swift`, check `UIAccessibility.isReduceMotionEnabled`. If true, skip the animated entrance and just set states immediately:

```swift
// Inside the onPlay closure check:
if UIAccessibility.isReduceMotionEnabled {
    // Instant state, no animation
    withAnimation(.easeIn(duration: 0.2)) {
        onPlay()
    }
} else {
    onPlay()
}
```

**Step 7: Build to verify**

```bash
xcodebuild build -scheme "Little Artist" -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```
Expected: `BUILD SUCCEEDED`

**Step 8: Commit**

```bash
git add "Little Artist/Utilities/HapticService.swift" "Little Artist/Components/ArtworkThumbnailView.swift" "Little Artist/Components/AddArtworkButton.swift" "Little Artist/Views/HomeView.swift" "Little Artist/Views/ArtworkDetailView.swift" "Little Artist/Views/Onboarding/AnimationTrigger.swift"
git commit -m "feat: add VoiceOver labels, haptic feedback, and Reduce Motion support"
```

---

## Summary

| Task | Description | New Files | Modified Files |
|------|-------------|-----------|----------------|
| 1 | Artwork model update (isFavorited) | 0 | 2 |
| 2 | Tab navigation shell | 3 | 2 |
| 3 | Gallery tab redesign (2-col grid) | 1 | 2 |
| 4 | Artwork detail enhancements | 0 | 1 |
| 5 | Timeline tab | 1 | 1 |
| 6 | Milestones tab | 2 | 1 |
| 7 | Settings tab | 0 | 1 |
| 8 | Search & filter view | 1 | 1 |
| 9 | Onboarding polish | 0 | 1 |
| 10 | Accessibility & micro-interactions | 1 | 5 |
| **Total** | | **9 new** | **17 modified** |

**Dependency order:** Task 1 → Task 2 → Tasks 3–10 (mostly independent after tab shell exists, but Tasks 3 and 8 both touch HomeView so run sequentially).

**Recommended execution order:** 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
