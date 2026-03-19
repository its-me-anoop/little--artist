# App Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the entire Little Artist app (except onboarding) with new 4-tab navigation, bento gallery, timeline, achievements system, family comments, and PDF export flow.

**Architecture:** 5-phase feature-grouped approach. Phase 1 lays data model + navigation foundation. Phases 2-5 build screens on top. Each phase produces a buildable app.

**Tech Stack:** SwiftUI, SwiftData (SchemaV8), Firebase Firestore, SF Symbols, FoundationModels (AI captions)

**Spec:** `docs/superpowers/specs/2026-03-19-app-redesign-design.md`

---

## File Structure

### New Files
| File | Responsibility |
|------|---------------|
| `Models/Comment.swift` | SwiftData model for family comments on artworks |
| `Models/Achievement.swift` | SwiftData model for milestone badges |
| `Models/SchemaMigrationV8.swift` | Schema migration adding Comment + Achievement |
| `Services/AchievementService.swift` | Achievement seeding, milestone checking |
| `Views/TimelineView.swift` | Timeline tab — chronological artwork feed |
| `Views/MilestonesView.swift` | Milestones tab — achievement badge grid |
| `Views/Children/ChildProfileView.swift` | Child profile with stats + scoped timeline |
| `Views/PDF/PDFExportConfigView.swift` | PDF export configuration |
| `Views/PDF/PDFPreviewView.swift` | Magazine-style PDF preview |
| `Components/Cards/MilestoneCardView.swift` | Single milestone card (earned/locked) |
| `Components/Cards/MilestoneCarouselView.swift` | Horizontal milestone scroll strip |
| `Components/Cards/FamilyCommentView.swift` | Single comment row in artwork detail |
| `Components/Cards/BentoArtworkCardView.swift` | Bento grid artwork card (paper-stack style) |
| `Components/Cards/ProgressBarView.swift` | Animated gradient progress bar |
| `Components/Avatars/ArtistSelectorView.swift` | Horizontal artist picker with selection ring |

### Modified Files
| File | Changes |
|------|---------|
| `App/Little_ArtistApp.swift` | SchemaV7 → SchemaV8 in model container |
| `App/ContentView.swift` | 4-tab nav + FAB overlay, remove .search tab |
| `Models/Artwork.swift` | Add `comments` relationship |
| `Views/HomeView.swift` | Bento gallery layout with "On This Day" |
| `Views/SettingsView.swift` | Full redesign: premium card, profiles, data/privacy |
| `Views/Artwork/ArtworkDetailView.swift` | Scrollable detail + AI analysis + comments |
| `Views/Artwork/AddArtworkView.swift` | New form: artist selector, magic caption, medium picker |
| `Views/Artwork/NoArtworkView.swift` | Restyle to match new design |
| `Views/Children/NoChildrenView.swift` | Restyle to match new design |
| `Views/PaywallView.swift` | Benefit cards + subscription tiers |
| `Services/FirestoreSyncService.swift` | Add comment listeners + lifecycle |
| `Services/FirestoreRepository.swift` | Add comment CRUD methods |
| `Services/PDFExportService.swift` | Add time range, layout mode, async generation |

---

## Phase 1: Navigation Shell + Data Models

### Task 1: Create Comment Model

**Files:**
- Create: `Little Artist/Models/Comment.swift`

- [ ] **Step 1: Create the Comment model**

```swift
import Foundation
import SwiftData

/// A family member's comment on an artwork.
@Model final class Comment {
    var text: String
    var authorName: String
    @Attribute(.externalStorage)
    var authorAvatarData: Data?
    var createdAt: Date
    var artwork: Artwork?
    var firestoreId: String?

    init(
        text: String,
        authorName: String,
        authorAvatarData: Data? = nil,
        createdAt: Date = .now,
        artwork: Artwork? = nil,
        firestoreId: String? = nil
    ) {
        self.text = text
        self.authorName = authorName
        self.authorAvatarData = authorAvatarData
        self.createdAt = createdAt
        self.artwork = artwork
        self.firestoreId = firestoreId
    }
}
```

- [ ] **Step 2: Add comments relationship to Artwork**

In `Little Artist/Models/Artwork.swift`, after the `tags` relationship (around line 35), add:

```swift
@Relationship(deleteRule: .cascade, inverse: \Comment.artwork)
var comments: [Comment]?
```

- [ ] **Step 3: Build to verify compilation**

Run: Xcode build (Cmd+B)
Expected: Successful compilation

- [ ] **Step 4: Commit**

```
git add "Little Artist/Models/Comment.swift" "Little Artist/Models/Artwork.swift"
git commit -m "feat: add Comment model with cascade relationship on Artwork"
```

---

### Task 2: Create Achievement Model

**Files:**
- Create: `Little Artist/Models/Achievement.swift`

- [ ] **Step 1: Create the Achievement model**

```swift
import Foundation
import SwiftData

/// A milestone badge that tracks the family's creative journey.
@Model final class Achievement {
    var identifier: String
    var title: String
    var subtitle: String
    var iconName: String
    var isEarned: Bool
    var earnedAt: Date?
    var category: String

    init(
        identifier: String,
        title: String,
        subtitle: String,
        iconName: String,
        isEarned: Bool = false,
        earnedAt: Date? = nil,
        category: String
    ) {
        self.identifier = identifier
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.isEarned = isEarned
        self.earnedAt = earnedAt
        self.category = category
    }
}
```

- [ ] **Step 2: Build to verify**

Run: Xcode build
Expected: Pass

- [ ] **Step 3: Commit**

```
git add "Little Artist/Models/Achievement.swift"
git commit -m "feat: add Achievement model for milestone badges"
```

---

### Task 3: Schema Migration V8

**Files:**
- Create: `Little Artist/Models/SchemaMigrationV8.swift`
- Modify: `Little Artist/App/Little_ArtistApp.swift`

- [ ] **Step 1: Create SchemaV8**

```swift
import Foundation
import SwiftData

enum SchemaV8: VersionedSchema {
    static var versionIdentifier = Schema.Version(8, 0, 0)
    static var models: [any PersistentModel.Type] = [
        Child.self,
        Artwork.self,
        Tag.self,
        Comment.self,
        Achievement.self
    ]
}
```

- [ ] **Step 2: Update Little_ArtistApp.swift model container**

In `Little_ArtistApp.swift`, find the `ModelConfiguration` setup (around line 39-43) and replace `SchemaV7` with `SchemaV8`:

Change:
```swift
let schema = Schema(versionedSchema: SchemaV7.self)
```
To:
```swift
let schema = Schema(versionedSchema: SchemaV8.self)
```

- [ ] **Step 3: Build and run on simulator**

Run: Build + run on iPhone simulator
Expected: App launches without migration crash. Check console for any SwiftData errors.

- [ ] **Step 4: Commit**

```
git add "Little Artist/Models/SchemaMigrationV8.swift" "Little Artist/App/Little_ArtistApp.swift"
git commit -m "feat: schema migration V8 adding Comment and Achievement entities"
```

---

### Task 4: Create AchievementService

**Files:**
- Create: `Little Artist/Services/AchievementService.swift`

- [ ] **Step 1: Create the service**

```swift
import Foundation
import SwiftData

/// Tracks creative milestones and seeds default achievements.
enum AchievementService {

    /// Canonical list of medium tag names for the "Rainbow Palette" achievement.
    static let mediumTags = [
        "Craft", "Painting", "Drawing", "Watercolor",
        "Collage", "Sculpture", "Digital", "Mixed Media"
    ]

    /// All default achievement definitions.
    private static let defaults: [(id: String, title: String, subtitle: String, icon: String, category: String)] = [
        ("first_masterpiece", "First Masterpiece", "The journey begins!", "star.fill", "artwork"),
        ("prolific", "Prolific", "A growing stack of art.", "square.stack.3d.up.fill", "artwork"),
        ("gallery_owner", "Gallery Owner", "100 masterpieces saved.", "person.crop.rectangle.stack.fill", "artwork"),
        ("memory_lane", "Memory Lane", "Relived your first memory.", "text.book.closed.fill", "engagement"),
        ("year_in_review", "Year in Review", "365 days of creativity.", "calendar.badge.checkmark", "seasonal"),
        ("seasonal_artist", "Seasonal Artist", "Art in every season.", "leaf.fill", "seasonal"),
        ("storyteller", "Storyteller", "10 voice stories recorded.", "mic.fill", "voice"),
        ("rainbow_palette", "Rainbow Palette", "Every medium explored.", "paintpalette.fill", "medium")
    ]

    /// Seeds all default achievements if none exist. Call on first launch.
    static func seedAchievements(context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Achievement>())) ?? 0
        guard existing == 0 else { return }

        for def in defaults {
            let achievement = Achievement(
                identifier: def.id,
                title: def.title,
                subtitle: def.subtitle,
                iconName: def.icon,
                category: def.category
            )
            context.insert(achievement)
        }
        try? context.save()
    }

    /// Checks all milestone conditions and marks newly earned achievements.
    static func checkMilestones(context: ModelContext) {
        let allArtworks = (try? context.fetch(FetchDescriptor<Artwork>())) ?? []
        let achievements = (try? context.fetch(FetchDescriptor<Achievement>())) ?? []

        let artworkCount = allArtworks.count
        let voiceMemoCount = allArtworks.filter { $0.voiceNoteData != nil }.count
        let allTagNames = Set(allArtworks.flatMap { $0.tags?.map(\.name) ?? [] })
        let usedMediums = allTagNames.intersection(Set(mediumTags))

        // Date range checks
        let dates = allArtworks.map(\.createdAt)
        let hasYearSpan: Bool = {
            guard let earliest = dates.min(), let latest = dates.max() else { return false }
            return Calendar.current.dateComponents([.day], from: earliest, to: latest).day ?? 0 >= 365
        }()
        let seasons: Set<Int> = Set(dates.map { Calendar.current.component(.month, from: $0) / 3 })
        let hasFourSeasons = seasons.count >= 4

        for achievement in achievements where !achievement.isEarned {
            let shouldEarn: Bool = switch achievement.identifier {
            case "first_masterpiece": artworkCount >= 1
            case "prolific": artworkCount >= 50
            case "gallery_owner": artworkCount >= 100
            case "year_in_review": hasYearSpan
            case "seasonal_artist": hasFourSeasons
            case "storyteller": voiceMemoCount >= 10
            case "rainbow_palette": usedMediums.count >= mediumTags.count
            default: false
            }

            if shouldEarn {
                achievement.isEarned = true
                achievement.earnedAt = .now
            }
        }
        try? context.save()
    }

    /// Marks the "Memory Lane" achievement as earned when user taps an "On This Day" card.
    static func markMemoryViewed(context: ModelContext) {
        let descriptor = FetchDescriptor<Achievement>(
            predicate: #Predicate { $0.identifier == "memory_lane" }
        )
        guard let achievement = try? context.fetch(descriptor).first,
              !achievement.isEarned else { return }
        achievement.isEarned = true
        achievement.earnedAt = .now
        try? context.save()
    }
}
```

- [ ] **Step 2: Seed achievements on app launch**

In `Little_ArtistApp.swift`, inside the model container setup (after sync service injection, around line 47), add:

```swift
AchievementService.seedAchievements(context: ModelContext(container))
```

- [ ] **Step 3: Build to verify**

Run: Xcode build + run
Expected: App launches. Achievements seeded (verify via debugger or console).

- [ ] **Step 4: Commit**

```
git add "Little Artist/Services/AchievementService.swift" "Little Artist/App/Little_ArtistApp.swift"
git commit -m "feat: add AchievementService with seeding and milestone checking"
```

---

### Task 5: Update ContentView — 4-Tab Navigation + FAB

**Files:**
- Modify: `Little Artist/App/ContentView.swift`

- [ ] **Step 1: Update AppTab enum**

Replace the `AppTab` enum (lines 134-137) with:

```swift
enum AppTab: Hashable {
    case gallery
    case timeline
    case milestones
    case settings
}
```

- [ ] **Step 2: Create stub views for new tabs**

Add temporary stubs at the bottom of ContentView.swift (or in their final files — see next tasks). For now, to get the app building:

Create `Little Artist/Views/TimelineView.swift`:
```swift
import SwiftUI

/// Chronological artwork feed with vertical timeline.
struct TimelineView: View {
    var body: some View {
        Text("Timeline — Coming Soon")
            .font(Brand.title1Font)
    }
}

#Preview { TimelineView() }
```

Create `Little Artist/Views/MilestonesView.swift`:
```swift
import SwiftUI

/// Achievement badges and progress tracking.
struct MilestonesView: View {
    var body: some View {
        Text("Milestones — Coming Soon")
            .font(Brand.title1Font)
    }
}

#Preview { MilestonesView() }
```

- [ ] **Step 3: Rewrite the TabView body**

Replace the entire `body` property in ContentView (around lines 99-132) with the new 4-tab layout + FAB overlay:

```swift
var body: some View {
    ZStack(alignment: .bottomTrailing) {
        TabView(selection: $selectedTab) {
            Tab("Gallery", systemImage: "photo.on.rectangle.angled", value: .gallery) {
                galleryRoot
            }
            Tab("Timeline", systemImage: "book.pages", value: .timeline) {
                NavigationStack {
                    TimelineView()
                }
            }
            Tab("Milestones", systemImage: "medal", value: .milestones) {
                NavigationStack {
                    MilestonesView()
                }
            }
            Tab("Settings", systemImage: "slider.horizontal.3", value: .settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }

        // Floating Action Button
        Button {
            presentCreateFlow()
        } label: {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: Brand.fabSize, height: Brand.fabSize)
                .background(Brand.primary)
                .clipShape(Circle())
                .brandFABShadow()
        }
        .padding(.trailing, Brand.screenPadding)
        .padding(.bottom, 80) // Above tab bar
    }
    .sheet(isPresented: $showAddChild) {
        AddChildView()
    }
    .sheet(item: $showCreateSheet) { child in
        AddArtworkView(child: child)
    }
    .sheet(item: paywallPresented) { reason in
        PaywallView(reason: reason)
    }
}
```

- [ ] **Step 4: Remove searchRoot and search-related code**

Remove the `searchRoot` computed property and `@State private var searchText` since search moves to a toolbar button on Gallery. Also update `galleryRoot` to add a search toolbar button:

In `galleryRoot`, add to the toolbar:
```swift
ToolbarItem(placement: .topBarTrailing) {
    NavigationLink {
        SearchView()
    } label: {
        Image(systemName: "magnifyingglass")
    }
}
```

- [ ] **Step 5: Update default selectedTab**

Change the default value of `selectedTab` from `.gallery` to `.gallery` (should already be correct). Remove any references to `.search`.

- [ ] **Step 6: Build and run**

Run: Build + run on simulator
Expected: 4 tabs visible (Gallery, Timeline, Milestones, Settings). FAB visible bottom-right. Tapping FAB opens add artwork flow. Timeline and Milestones show placeholder text.

- [ ] **Step 7: Commit**

```
git add -A
git commit -m "feat: 4-tab navigation with FAB overlay, stub Timeline and Milestones tabs"
```

---

## Phase 2: Core Screens

### Task 6: Reusable Components — BentoArtworkCardView

**Files:**
- Create: `Little Artist/Components/Cards/BentoArtworkCardView.swift`

- [ ] **Step 1: Create the bento card component**

```swift
import SwiftUI
import SwiftData

/// Paper-stack style artwork card for bento grid layouts.
struct BentoArtworkCardView: View {
    let artwork: Artwork
    var rotation: Double = 0
    var showTitle: Bool = true
    var showVoiceMemoIndicator: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Paper-frame container
            ZStack(alignment: .bottomLeading) {
                if let data = artwork.thumbnailData ?? artwork.imageData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: Brand.radiusImage)
                        .fill(Brand.surface)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(Brand.warmGray)
                        }
                }

                // Voice memo indicator
                if showVoiceMemoIndicator, artwork.voiceNoteData != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "mic.fill")
                            .font(.caption2)
                        Text("Story")
                            .font(Brand.caption2Font)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusImage))

            if showTitle {
                Text(artwork.title.isEmpty ? "Untitled" : artwork.title)
                    .font(Brand.captionFont)
                    .foregroundStyle(Brand.charcoal)
                    .lineLimit(1)
                    .padding(.top, 6)

                Text(artwork.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray)
            }
        }
        .padding(6)
        .background(Brand.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
        .brandCardShadow()
        .rotationEffect(.degrees(rotation))
    }
}
```

- [ ] **Step 2: Build to verify**

- [ ] **Step 3: Commit**

```
git add "Little Artist/Components/Cards/BentoArtworkCardView.swift"
git commit -m "feat: add BentoArtworkCardView paper-stack component"
```

---

### Task 7: Reusable Components — ArtistSelectorView

**Files:**
- Create: `Little Artist/Components/Avatars/ArtistSelectorView.swift`

- [ ] **Step 1: Create the artist selector**

```swift
import SwiftUI
import SwiftData

/// Horizontal artist picker with selection ring and add button.
struct ArtistSelectorView: View {
    let children: [Child]
    @Binding var selectedChild: Child?
    var onAddChild: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Brand.fieldPadding) {
            Text("ARTIST")
                .font(Brand.caption2Font)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundStyle(Brand.warmGray)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(children) { child in
                        childAvatar(child)
                            .onTapGesture { selectedChild = child }
                    }

                    // Add new child button
                    if let onAddChild {
                        VStack(spacing: 6) {
                            Circle()
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                .foregroundStyle(Brand.softTan)
                                .frame(width: 64, height: 64)
                                .overlay {
                                    Image(systemName: "plus")
                                        .foregroundStyle(Brand.warmGray)
                                }
                            Text("New")
                                .font(Brand.caption2Font)
                                .foregroundStyle(Brand.warmGray)
                        }
                        .onTapGesture { onAddChild() }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func childAvatar(_ child: Child) -> some View {
        let isSelected = selectedChild?.persistentModelID == child.persistentModelID
        VStack(spacing: 6) {
            Group {
                if let data = child.avatarImageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Circle()
                        .fill(Color(hex: child.avatarColor))
                        .overlay {
                            Text(String(child.name.prefix(1)).uppercased())
                                .font(Brand.headlineFont)
                                .foregroundStyle(.white)
                        }
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .strokeBorder(isSelected ? Brand.primary : .clear, lineWidth: 3)
                    .frame(width: 70, height: 70)
            }
            .opacity(isSelected ? 1 : 0.5)

            Text(child.name)
                .font(Brand.caption2Font)
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundStyle(isSelected ? Brand.primary : Brand.charcoal)
        }
    }
}
```

- [ ] **Step 2: Commit**

```
git add "Little Artist/Components/Avatars/ArtistSelectorView.swift"
git commit -m "feat: add ArtistSelectorView horizontal picker component"
```

---

### Task 8: Reusable Components — ProgressBarView, MilestoneCardView, MilestoneCarouselView

**Files:**
- Create: `Little Artist/Components/Cards/ProgressBarView.swift`
- Create: `Little Artist/Components/Cards/MilestoneCardView.swift`
- Create: `Little Artist/Components/Cards/MilestoneCarouselView.swift`

- [ ] **Step 1: Create ProgressBarView**

```swift
import SwiftUI

/// Animated gradient progress bar.
struct ProgressBarView: View {
    let current: Int
    let target: Int

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Brand.softTan.opacity(0.3))

                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Brand.primary, Brand.primary.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress)
                    .animation(.spring(duration: 1.0), value: progress)
            }
        }
        .frame(height: 24)
    }
}
```

- [ ] **Step 2: Create MilestoneCardView**

```swift
import SwiftUI
import SwiftData

/// Single milestone card showing earned or locked state.
struct MilestoneCardView: View {
    let achievement: Achievement

    private var accentColor: Color {
        switch achievement.category {
        case "artwork": Brand.primary
        case "voice": Brand.sky
        case "seasonal": Brand.sage
        case "medium": Brand.lavender
        default: Brand.warmGray
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(achievement.isEarned ? accentColor.opacity(0.2) : Brand.softTan.opacity(0.3))
                    .frame(width: 40, height: 40)

                Image(systemName: achievement.isEarned ? achievement.iconName : "lock.fill")
                    .font(.title3)
                    .foregroundStyle(achievement.isEarned ? accentColor : Brand.warmGray)
            }

            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(Brand.captionFont)
                    .fontWeight(.bold)
                    .lineLimit(1)

                if achievement.isEarned, let date = achievement.earnedAt {
                    Text("Unlocked \(date.formatted(.dateTime.month(.abbreviated).year()))")
                        .font(Brand.caption2Font)
                        .foregroundStyle(Brand.warmGray)
                } else {
                    Text(achievement.subtitle)
                        .font(Brand.caption2Font)
                        .foregroundStyle(Brand.warmGray)
                }
            }
        }
        .frame(width: 150)
        .padding()
        .background(Brand.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
        .opacity(achievement.isEarned ? 1 : 0.5)
    }
}
```

- [ ] **Step 3: Create MilestoneCarouselView**

```swift
import SwiftUI
import SwiftData

/// Horizontal scrollable strip of milestone cards.
struct MilestoneCarouselView: View {
    let achievements: [Achievement]
    var onViewAll: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Brand.fieldPadding) {
            HStack {
                Text("Milestones")
                    .font(Brand.headlineFont)
                Spacer()
                if let onViewAll {
                    Button("View All") { onViewAll() }
                        .font(Brand.caption2Font)
                        .fontWeight(.bold)
                        .foregroundStyle(Brand.primary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(achievements) { achievement in
                        MilestoneCardView(achievement: achievement)
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 4: Build to verify**

- [ ] **Step 5: Commit**

```
git add "Little Artist/Components/Cards/ProgressBarView.swift" \
       "Little Artist/Components/Cards/MilestoneCardView.swift" \
       "Little Artist/Components/Cards/MilestoneCarouselView.swift"
git commit -m "feat: add ProgressBarView, MilestoneCardView, MilestoneCarouselView components"
```

---

### Task 9: Redesign HomeView — Bento Gallery

**Files:**
- Modify: `Little Artist/Views/HomeView.swift`

This is a large view rewrite. Reference the spec Section 3 for full layout details.

- [ ] **Step 1: Restructure HomeView body**

Replace the current body with the new bento layout structure. Keep existing `@Query`, `@Binding`, and computed properties (`memoriesArtworks`, `filteredArtworks`, `selectedChild`). Replace the view hierarchy with:

1. **Header area:** Child avatar (tappable NavigationLink to ChildProfileView) + app title + search NavigationLink
2. **"Today" section:** `todaySection` extracted view with bento grid
3. **"Earlier" section:** `earlierSection` extracted view with staggered grid
4. **Child filter:** `ChildSliderView` below nav bar

Key extracted views to create within HomeView:

```swift
// MARK: - Today Section
private var todaySection: some View {
    VStack(alignment: .leading, spacing: Brand.sectionSpacing) {
        // Section header
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TIMELINE")
                    .font(Brand.caption2Font)
                    .fontWeight(.bold)
                    .tracking(2)
                    .foregroundStyle(Brand.warmGray)
                Text("Today")
                    .font(Brand.displayFont)
            }
            Spacer()
            Text(Date.now.formatted(.dateTime.month(.abbreviated).day()))
                .font(Brand.captionFont)
                .fontWeight(.bold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Brand.surface)
                .clipShape(Capsule())
        }

        // Bento grid
        bentoGrid
    }
}
```

The bento grid uses a combination of `LazyVGrid` with varying column spans or a custom layout. For simplicity, use nested HStack/VStack:

```swift
private var bentoGrid: some View {
    let artworks = filteredArtworks
    return VStack(spacing: 12) {
        if let featured = artworks.first {
            HStack(spacing: 12) {
                // Featured artwork (2x2)
                NavigationLink(value: featured) {
                    BentoArtworkCardView(artwork: featured, rotation: -1)
                }
                .frame(maxWidth: .infinity)

                // Right column: memory + small card
                VStack(spacing: 12) {
                    if let memory = memoriesArtworks.first {
                        memoryCard(memory)
                    }
                    if artworks.count > 1 {
                        NavigationLink(value: artworks[1]) {
                            BentoArtworkCardView(artwork: artworks[1], showTitle: false)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
```

- [ ] **Step 2: Add "On This Day" memory card with achievement trigger**

```swift
private func memoryCard(_ artwork: Artwork) -> some View {
    NavigationLink(value: artwork) {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption2)
                Text("MEMORY LANE")
                    .font(Brand.caption2Font)
                    .fontWeight(.bold)
                    .tracking(1.5)
            }
            .foregroundStyle(Brand.warmGray)

            Text("On this day...")
                .font(Brand.headlineFont)

            if let data = artwork.thumbnailData ?? artwork.imageData,
               let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: Brand.radiusImage))
            }
        }
        .padding()
        .background(Brand.lavender.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
    }
    .simultaneousGesture(TapGesture().onEnded {
        AchievementService.markMemoryViewed(context: modelContext)
    })
}
```

Note: Add `@Environment(\.modelContext) private var modelContext` to HomeView if not already present.

- [ ] **Step 3: Add "Earlier this Month" staggered grid**

```swift
private var earlierSection: some View {
    let earlier = Array(filteredArtworks.dropFirst(3)) // Skip today's featured
    guard !earlier.isEmpty else { return AnyView(EmptyView()) }

    return AnyView(
        VStack(alignment: .leading, spacing: Brand.sectionSpacing) {
            Text("Earlier this Month")
                .font(Brand.title2Font)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: Brand.gallerySpacing
            ) {
                ForEach(Array(earlier.enumerated()), id: \.element.persistentModelID) { index, artwork in
                    NavigationLink(value: artwork) {
                        BentoArtworkCardView(
                            artwork: artwork,
                            rotation: index.isMultiple(of: 2) ? -0.8 : 1.2
                        )
                    }
                }
            }
        }
    )
}
```

- [ ] **Step 4: Build and run**

Expected: Gallery tab shows bento layout with featured artwork, memory card, and staggered grid. Tapping artworks navigates to detail.

- [ ] **Step 5: Commit**

```
git add "Little Artist/Views/HomeView.swift"
git commit -m "feat: redesign HomeView with bento gallery layout and On This Day memories"
```

---

### Task 10: Redesign ArtworkDetailView

**Files:**
- Modify: `Little Artist/Views/Artwork/ArtworkDetailView.swift`
- Create: `Little Artist/Components/Cards/FamilyCommentView.swift`

- [ ] **Step 1: Create FamilyCommentView component**

```swift
import SwiftUI
import SwiftData

/// Single comment row for the Family Love section.
struct FamilyCommentView: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Author avatar
            Circle()
                .fill(Brand.sky.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay {
                    if let data = comment.authorAvatarData, let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                    } else {
                        Text(String(comment.authorName.prefix(1)).uppercased())
                            .font(Brand.headlineFont)
                            .foregroundStyle(Brand.sky)
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.authorName)
                        .font(Brand.subheadlineFont)
                        .fontWeight(.bold)
                    Spacer()
                    Text(comment.createdAt.formatted(.relative(presentation: .named)))
                        .font(Brand.caption2Font)
                        .foregroundStyle(Brand.warmGray)
                }

                Text(comment.text)
                    .font(Brand.bodyFont)
                    .foregroundStyle(Brand.charcoal)
            }
            .padding()
            .background(Brand.surface)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
        }
    }
}
```

- [ ] **Step 2: Rewrite ArtworkDetailView body**

Replace the current full-screen zoom view with a scrollable detail layout. Keep existing state properties for edit/delete/share. Remove the pinch-zoom gesture from the main view (it moves to a fullScreenCover).

The new body structure:

```swift
var body: some View {
    ScrollView {
        VStack(alignment: .leading, spacing: Brand.sectionSpacing) {
            heroArtworkSection
            detailsHeaderSection
            aiAnalysisSection
            actionButtonsSection
            familyLoveSection
        }
        .padding(.horizontal, Brand.screenPadding)
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
            Button { artwork.isFavorited.toggle() } label: {
                Image(systemName: artwork.isFavorited ? "heart.fill" : "heart")
                    .foregroundStyle(artwork.isFavorited ? Brand.primary : Brand.warmGray)
            }
        }
    }
    .fullScreenCover(isPresented: $showFullScreenZoom) {
        fullScreenZoomView
    }
    // Keep existing sheet/alert modifiers
}
```

Key extracted sections:

**Hero artwork** — paper-frame with zoom button:
```swift
@State private var showFullScreenZoom = false

private var heroArtworkSection: some View {
    ZStack(alignment: .bottomTrailing) {
        if let data = artwork.imageData, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .aspectRatio(4/5, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: Brand.radiusImage))
        }

        Button { showFullScreenZoom = true } label: {
            Image(systemName: "plus.magnifyingglass")
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .padding()
    }
    .padding(8)
    .background(Brand.surface)
    .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
    .brandCardShadow()
    .rotationEffect(.degrees(-0.5))
}
```

**AI Analysis section:**
```swift
private var aiAnalysisSection: some View {
    VStack(alignment: .leading, spacing: Brand.sectionSpacing) {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(Brand.primary)
            Text("Smart Analysis")
                .font(Brand.headlineFont)
        }

        // Voice quote (if voice memo exists)
        if artwork.voiceNoteData != nil {
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(Brand.primary.opacity(0.2))
                    .frame(width: 4)
                Text(artwork.caption.isEmpty ? "No transcription available" : artwork.caption)
                    .font(Brand.bodyFont)
                    .italic()
                    .foregroundStyle(Brand.warmGray)
            }
        }

        // AI narrative
        if !artwork.caption.isEmpty {
            Text(artwork.caption)
                .font(Brand.bodyFont)
                .padding()
                .background(Brand.surface.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
        }
    }
    .padding(Brand.screenPadding)
    .background {
        RoundedRectangle(cornerRadius: 32)
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
            .foregroundStyle(Brand.softTan)
    }
    .background(Brand.cream)
    .clipShape(RoundedRectangle(cornerRadius: 32))
}
```

**Family Love section:**
```swift
@State private var newCommentText = ""

private var familyLoveSection: some View {
    VStack(alignment: .leading, spacing: Brand.fieldPadding) {
        Text("Family Love")
            .font(Brand.headlineFont)

        ForEach(artwork.comments ?? []) { comment in
            FamilyCommentView(comment: comment)
        }

        // Add comment
        HStack {
            TextField("Add a comment...", text: $newCommentText)
                .font(Brand.bodyFont)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Brand.surface)
                .clipShape(Capsule())

            Button {
                guard !newCommentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                let comment = Comment(text: newCommentText, authorName: "Me", artwork: artwork)
                modelContext.insert(comment)
                try? modelContext.save()
                newCommentText = ""
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Brand.primary)
            }
        }
    }
}
```

- [ ] **Step 3: Move existing zoom logic to fullScreenCover**

Extract the existing pinch-to-zoom, double-tap, pan gesture code into a `fullScreenZoomView` computed property presented as `.fullScreenCover`. Keep the existing `@State` vars for scale/offset/lastScale.

- [ ] **Step 4: Build and run**

Expected: Artwork detail shows scrollable layout with hero image, details header, AI section, action buttons, and family comments. Tapping zoom opens full-screen viewer.

- [ ] **Step 5: Commit**

```
git add "Little Artist/Components/Cards/FamilyCommentView.swift" \
       "Little Artist/Views/Artwork/ArtworkDetailView.swift"
git commit -m "feat: redesign ArtworkDetailView with AI analysis and family comments"
```

---

### Task 11: Redesign AddArtworkView

**Files:**
- Modify: `Little Artist/Views/Artwork/AddArtworkView.swift`

- [ ] **Step 1: Replace child indicator with ArtistSelectorView**

The current view takes a `child: Child` binding. Change to support child selection:
- Add `@Query(sort: \Child.createdAt) private var children: [Child]`
- Change `let child: Child` to `@State private var selectedChild: Child?`
- Initialize `selectedChild` from an optional binding or the first child
- Replace the `childIndicatorChip` (lines 40-65) with `ArtistSelectorView`

- [ ] **Step 2: Restructure the form layout**

Replace the form body with the new rounded layout per spec Section 5:

1. Close button header bar (centered "Add Masterpiece" title)
2. Centered artwork preview with paper-stack shadow
3. `ArtistSelectorView`
4. Pill-shaped title field
5. Date + Medium pickers (2-column grid)
6. Record Story + Magic Caption buttons (2-column)
7. Creative Notes textarea
8. Tag pills with add button
9. Fixed bottom "Save to Gallery" button

Key new elements:

**Medium picker** — add a new `@State private var selectedMedium = "Painting"` and a Picker:
```swift
Menu {
    ForEach(AchievementService.mediumTags, id: \.self) { medium in
        Button(medium) { selectedMedium = medium }
    }
} label: {
    HStack {
        Text(selectedMedium)
        Spacer()
        Image(systemName: "chevron.down")
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(Brand.surface)
    .clipShape(Capsule())
}
```

**Magic Caption button:**
```swift
Button {
    Task { await generateAISuggestion() }
} label: {
    VStack(spacing: 8) {
        Circle()
            .fill(Brand.lavender.opacity(0.2))
            .frame(width: 48, height: 48)
            .overlay {
                Image(systemName: "sparkles")
                    .foregroundStyle(Brand.lavender)
            }
        Text("Magic Caption")
            .font(Brand.captionFont)
            .fontWeight(.bold)
            .foregroundStyle(Brand.lavender)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(Brand.surface)
    .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
}
```

- [ ] **Step 3: Update save logic**

After saving the artwork, add:
```swift
// Create medium tag if needed
if !selectedMedium.isEmpty {
    let mediumTag = Tag(name: selectedMedium)
    newArtwork.tags = [mediumTag]
    context.insert(mediumTag)
}

// Check milestones
AchievementService.checkMilestones(context: modelContext)
```

- [ ] **Step 4: Update ContentView to pass children query instead of single child**

In `ContentView.swift`, update the `.sheet(item: $showCreateSheet)` to use the new AddArtworkView that supports child selection internally. Change from:
```swift
.sheet(item: $showCreateSheet) { child in
    AddArtworkView(child: child)
}
```
To:
```swift
.sheet(isPresented: $showCreateSheet) {
    AddArtworkView()
}
```
And update `showCreateSheet` from `Child?` to `Bool`, updating `presentCreateFlow()` accordingly.

- [ ] **Step 5: Build and run**

Expected: Add artwork sheet shows new form with artist selector, pill fields, medium picker, magic caption button. Save creates artwork with medium tag.

- [ ] **Step 6: Commit**

```
git add "Little Artist/Views/Artwork/AddArtworkView.swift" "Little Artist/App/ContentView.swift"
git commit -m "feat: redesign AddArtworkView with artist selector, medium picker, magic caption"
```

---

## Phase 3: New Features

### Task 12: Implement TimelineView

**Files:**
- Modify: `Little Artist/Views/TimelineView.swift` (replace stub)

- [ ] **Step 1: Implement the full TimelineView**

Reference spec Section 6. Key structure:

```swift
import SwiftUI
import SwiftData

/// Chronological artwork feed with vertical timeline.
struct TimelineView: View {
    @Query(sort: \Child.createdAt) private var children: [Child]
    @Query(sort: \Artwork.createdAt, order: .reverse) private var allArtworks: [Artwork]
    @Query private var achievements: [Achievement]
    @State private var selectedChildID: PersistentIdentifier?

    private var selectedChild: Child? {
        children.first { $0.persistentModelID == selectedChildID }
    }

    private var filteredArtworks: [Artwork] {
        guard let child = selectedChild else { return allArtworks }
        return allArtworks.filter { $0.child?.persistentModelID == child.persistentModelID }
    }

    // Group artworks by time period
    private var groupedArtworks: [(title: String, subtitle: String, artworks: [Artwork])] {
        // Implementation: group into Today, This Week, This Month, then by month name
        // ... (full grouping logic)
    }

    private let dotColors: [Color] = [Brand.primary, Brand.sky, Brand.lavender]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Brand.sectionSpacing) {
                if let child = selectedChild {
                    profileHero(child: child)
                }

                MilestoneCarouselView(achievements: achievements) {
                    // Navigate to milestones tab — set via binding or notification
                }

                timelineContent
            }
            .padding(.horizontal, Brand.screenPadding)
        }
        .navigationTitle("Timeline")
    }
}
```

The timeline content uses a vertical line + dots pattern. Each group has a colored dot, date header, and artwork cards.

- [ ] **Step 2: Add profile hero section**

```swift
private func profileHero(child: Child) -> some View {
    VStack(spacing: 16) {
        // Large avatar with badge
        ZStack(alignment: .bottomTrailing) {
            // Avatar
            Group {
                if let data = child.avatarImageData, let img = UIImage(data: data) {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    Circle().fill(Color(hex: child.avatarColor))
                        .overlay {
                            Text(String(child.name.prefix(1)).uppercased())
                                .font(Brand.displayFont)
                                .foregroundStyle(.white)
                        }
                }
            }
            .frame(width: 140, height: 140)
            .clipShape(Circle())

            // Badge
            Circle()
                .fill(Brand.primary)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "paintpalette.fill")
                        .foregroundStyle(.white)
                }
        }

        Text(child.name)
            .font(Brand.displayFont)

        let artworkCount = child.artworks?.count ?? 0
        Text("Age 4 · Artist since \(child.createdAt.formatted(.dateTime.year()))")
            .font(Brand.captionFont)
            .foregroundStyle(Brand.warmGray)

        // Stat cards
        HStack(spacing: 12) {
            StatPill(value: "\(artworkCount)", label: "Masterpieces", rotation: -1)
            StatPill(value: "Level \(artworkCount / 10 + 1)", label: "Art Explorer", rotation: 1)
        }
    }
}
```

- [ ] **Step 3: Add timeline entry rendering with vertical line**

```swift
private var timelineContent: some View {
    VStack(alignment: .leading, spacing: 0) {
        ForEach(Array(groupedArtworks.enumerated()), id: \.offset) { index, group in
            HStack(alignment: .top, spacing: 16) {
                // Timeline line + dot
                VStack(spacing: 0) {
                    Circle()
                        .fill(dotColors[index % dotColors.count])
                        .frame(width: 16, height: 16)
                    if index < groupedArtworks.count - 1 {
                        Rectangle()
                            .fill(Brand.softTan.opacity(0.3))
                            .frame(width: 2)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(group.title)
                            .font(Brand.headlineFont)
                        Text(group.subtitle)
                            .font(Brand.caption2Font)
                            .foregroundStyle(Brand.warmGray)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(group.artworks) { artwork in
                            NavigationLink(value: artwork) {
                                BentoArtworkCardView(
                                    artwork: artwork,
                                    rotation: Bool.random() ? -0.8 : 1.2
                                )
                            }
                        }
                    }
                }
            }
            .padding(.bottom, Brand.sectionSpacing)
        }
    }
}
```

- [ ] **Step 4: Build and run**

Expected: Timeline tab shows profile hero, milestone carousel, and chronological timeline with artwork cards.

- [ ] **Step 5: Commit**

```
git add "Little Artist/Views/TimelineView.swift"
git commit -m "feat: implement TimelineView with profile hero, milestones, and chronological feed"
```

---

### Task 13: Implement MilestonesView

**Files:**
- Modify: `Little Artist/Views/MilestonesView.swift` (replace stub)

- [ ] **Step 1: Implement full MilestonesView**

Reference spec Section 7.

```swift
import SwiftUI
import SwiftData

/// Achievement badges and progress tracking.
struct MilestonesView: View {
    @Query private var achievements: [Achievement]
    @Query private var allArtworks: [Artwork]

    private var earnedCount: Int { achievements.filter(\.isEarned).count }
    private var totalCount: Int { achievements.count }
    private var artworkCount: Int { allArtworks.count }

    // Next tier targets
    private let tiers = [10, 50, 100, 250, 500]
    private var nextTier: Int {
        tiers.first { $0 > artworkCount } ?? 1000
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Brand.sectionSpacing) {
                progressHero
                badgeGrid
                voiceNoteHighlight
            }
            .padding(.horizontal, Brand.screenPadding)
        }
        .navigationTitle("Achievements")
    }

    private var progressHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Journey")
                        .font(Brand.title2Font)
                        .foregroundStyle(Brand.primary)
                    Text("Collecting memories one doodle at a time.")
                        .font(Brand.bodyFont)
                        .foregroundStyle(Brand.warmGray)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(artworkCount)")
                        .font(Brand.title2Font)
                    Text("/ \(nextTier)")
                        .font(Brand.captionFont)
                        .foregroundStyle(Brand.warmGray)
                }
            }

            ProgressBarView(current: artworkCount, target: nextTier)

            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundStyle(Brand.lavender)
                Text("\(nextTier - artworkCount) more to reach the next tier")
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray)
            }
        }
        .padding(Brand.screenPadding)
        .background(Brand.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
        .brandCardShadow()
    }

    private var badgeGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(achievements) { achievement in
                achievementCard(achievement)
            }
        }
    }

    private func achievementCard(_ achievement: Achievement) -> some View {
        // Per spec: earned = white card + colored icon, locked = dimmed + dashed border
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(achievement.isEarned ? accentColor(for: achievement).opacity(0.2) : Brand.softTan.opacity(0.2))
                    .frame(width: 96, height: 96)
                Image(systemName: achievement.isEarned ? achievement.iconName : "lock.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(achievement.isEarned ? accentColor(for: achievement) : Brand.warmGray)
            }

            Text(achievement.title)
                .font(Brand.headlineFont)
                .multilineTextAlignment(.center)

            Text(achievement.subtitle)
                .font(Brand.caption2Font)
                .foregroundStyle(Brand.warmGray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Brand.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
        .brandCardShadow()
        .opacity(achievement.isEarned ? 1 : 0.6)
        .overlay {
            if !achievement.isEarned {
                RoundedRectangle(cornerRadius: Brand.radiusCard)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                    .foregroundStyle(Brand.softTan)
            }
        }
    }

    private func accentColor(for achievement: Achievement) -> Color {
        switch achievement.category {
        case "artwork": Brand.primary
        case "voice": Brand.sky
        case "seasonal": Brand.sage
        case "medium": Brand.lavender
        default: Brand.warmGray
        }
    }

    private var voiceNoteHighlight: some View {
        // Show most recent artwork with voice memo
        let artworkWithVoice = allArtworks.first { $0.voiceNoteData != nil }
        return Group {
            if let artwork = artworkWithVoice {
                HStack(spacing: 12) {
                    Button {} label: {
                        Circle()
                            .fill(Brand.primary)
                            .frame(width: 48, height: 48)
                            .overlay {
                                Image(systemName: "play.fill")
                                    .foregroundStyle(.white)
                            }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        // Simple waveform bars
                        HStack(spacing: 2) {
                            ForEach(0..<10, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(i < 5 ? Brand.primary : Brand.softTan)
                                    .frame(width: 3, height: CGFloat.random(in: 8...20))
                            }
                        }
                        Text(artwork.title.isEmpty ? "Voice memo" : artwork.title)
                            .font(Brand.caption2Font)
                            .fontWeight(.bold)
                            .foregroundStyle(Brand.primary)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
        }
    }
}
```

- [ ] **Step 2: Build and run**

Expected: Milestones tab shows progress hero, badge grid with earned/locked states, voice note highlight.

- [ ] **Step 3: Commit**

```
git add "Little Artist/Views/MilestonesView.swift"
git commit -m "feat: implement MilestonesView with progress hero and badge grid"
```

---

### Task 14: Comment Firestore Sync

**Files:**
- Modify: `Little Artist/Services/FirestoreRepository.swift`
- Modify: `Little Artist/Services/FirestoreSyncService.swift`

- [ ] **Step 1: Add comment CRUD to FirestoreRepository**

Add these methods to `FirestoreRepository`:

```swift
// MARK: - Comments

func saveComment(_ comment: Comment, artworkFirestoreId: String, childFirestoreId: String) async throws {
    guard let userId = FirebaseAuthService.shared.userId else { return }
    let path = "users/\(userId)/children/\(childFirestoreId)/artworks/\(artworkFirestoreId)/comments"
    let ref = Firestore.firestore().collection(path).document()
    try await ref.setData([
        "text": comment.text,
        "authorName": comment.authorName,
        "createdAt": Timestamp(date: comment.createdAt)
    ])
    comment.firestoreId = ref.documentID
    try? modelContainer?.mainContext.save()
}

func deleteComment(commentId: String, artworkFirestoreId: String, childFirestoreId: String) async throws {
    guard let userId = FirebaseAuthService.shared.userId else { return }
    let path = "users/\(userId)/children/\(childFirestoreId)/artworks/\(artworkFirestoreId)/comments/\(commentId)"
    try await Firestore.firestore().document(path).delete()
}
```

- [ ] **Step 2: Add comment listener to FirestoreSyncService**

Add a `commentListeners` dictionary and teardown in `stop()`:

```swift
private var commentListeners: [String: ListenerRegistration] = [:]

func observeComments(artworkFirestoreId: String, childFirestoreId: String) {
    guard isSyncActive, let userId = FirebaseAuthService.shared.userId else { return }
    guard commentListeners[artworkFirestoreId] == nil else { return }

    let path = "users/\(userId)/children/\(childFirestoreId)/artworks/\(artworkFirestoreId)/comments"
    let listener = Firestore.firestore().collection(path)
        .addSnapshotListener { [weak self] snapshot, error in
            // Process comment changes — add/update/delete in SwiftData
        }
    commentListeners[artworkFirestoreId] = listener
}

func removeCommentListener(artworkFirestoreId: String) {
    commentListeners[artworkFirestoreId]?.remove()
    commentListeners.removeValue(forKey: artworkFirestoreId)
}
```

In `stop()` (line 103-129), add before `isListening = false`:
```swift
for (_, listener) in commentListeners {
    listener.remove()
}
commentListeners.removeAll()
```

- [ ] **Step 3: Build to verify**

- [ ] **Step 4: Commit**

```
git add "Little Artist/Services/FirestoreRepository.swift" \
       "Little Artist/Services/FirestoreSyncService.swift"
git commit -m "feat: add comment Firestore sync with listener lifecycle management"
```

---

## Phase 4: Settings, Paywall, Child Profile

### Task 15: Redesign SettingsView

**Files:**
- Modify: `Little Artist/Views/SettingsView.swift`

- [ ] **Step 1: Rewrite SettingsView body**

Replace the current `settingsForm` (Form with sections) with a ScrollView layout matching spec Section 9:

1. Premium hero card (asymmetric, primary tint)
2. Child profiles section (cards with avatars)
3. Data & Privacy section (grouped container with sync toggle + PDF export)
4. Support section (privacy policy, about, appearance)
5. Danger zone (log out button)

Key structural changes:
- Remove the Form wrapper, use ScrollView + VStack
- Replace child list with card-style rows
- Sync toggle gates through SiwA flow (show `cloudSyncSetupView` when toggled on)
- Add PDF export navigation link to `PDFExportConfigView`

- [ ] **Step 2: Update purgeLocalData()**

Add Achievement deletion after Tag deletion (line 873):
```swift
if let allAchievements = try? modelContext.fetch(FetchDescriptor<Achievement>()) {
    for achievement in allAchievements { modelContext.delete(achievement) }
}
```

- [ ] **Step 3: Build and run**

Expected: Settings tab shows premium card, child profile cards, sync toggle, export link, support links, and log out button.

- [ ] **Step 4: Commit**

```
git add "Little Artist/Views/SettingsView.swift"
git commit -m "feat: redesign SettingsView with premium card, profile cards, and grouped sections"
```

---

### Task 16: Redesign PaywallView

**Files:**
- Modify: `Little Artist/Views/PaywallView.swift`

- [ ] **Step 1: Rewrite PaywallView**

Replace current layout with spec Section 10: hero heading, visual asset card, benefit cards list, subscription tiers (yearly highlighted + monthly), CTA button, legal text, restore purchases.

Keep existing StoreKit integration and `LimitReason` enum. Add the benefit cards as a vertical list of icon + title + description rows.

- [ ] **Step 2: Build and run**

Expected: Paywall shows benefit cards, subscription tiers with "Best Value" badge on yearly, and subscribe button.

- [ ] **Step 3: Commit**

```
git add "Little Artist/Views/PaywallView.swift"
git commit -m "feat: redesign PaywallView with benefit cards and subscription tiers"
```

---

### Task 17: Implement ChildProfileView

**Files:**
- Create: `Little Artist/Views/Children/ChildProfileView.swift`

- [ ] **Step 1: Create ChildProfileView**

Structure mirrors TimelineView but scoped to a single child:

```swift
import SwiftUI
import SwiftData

/// Child profile with stats, milestones, and scoped artwork timeline.
struct ChildProfileView: View {
    let child: Child
    @Query private var achievements: [Achievement]
    @State private var showEditSheet = false

    private var childArtworks: [Artwork] {
        (child.artworks ?? []).sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Brand.sectionSpacing) {
                profileHero
                MilestoneCarouselView(achievements: achievements)
                artTimeline
            }
            .padding(.horizontal, Brand.screenPadding)
        }
        .navigationTitle(child.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEditSheet = true } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditChildView(child: child)
        }
    }

    // profileHero — same pattern as TimelineView.profileHero(child:)
    // artTimeline — same pattern as TimelineView.timelineContent, scoped to child
}
```

Reuse the profile hero and timeline patterns from TimelineView. Extract shared helpers if needed.

- [ ] **Step 2: Add NavigationLink to ChildProfileView from Settings and Gallery**

In SettingsView child cards and HomeView child avatar, wrap with:
```swift
NavigationLink(destination: ChildProfileView(child: child)) { ... }
```

- [ ] **Step 3: Build and run**

Expected: Tapping a child avatar/card navigates to their profile with stats, milestones, and artwork timeline.

- [ ] **Step 4: Commit**

```
git add "Little Artist/Views/Children/ChildProfileView.swift" \
       "Little Artist/Views/SettingsView.swift" \
       "Little Artist/Views/HomeView.swift"
git commit -m "feat: add ChildProfileView with stats, milestones, and scoped timeline"
```

---

## Phase 5: PDF Export Flow

### Task 18: PDF Export Configuration

**Files:**
- Create: `Little Artist/Views/PDF/PDFExportConfigView.swift`

- [ ] **Step 1: Create the view**

```swift
import SwiftUI
import SwiftData

/// PDF export configuration — select artist, time range, layout options.
struct PDFExportConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Child.createdAt) private var children: [Child]

    @State private var selectedChild: Child?
    @State private var timeRange: TimeRange = .lastYear
    @State private var includeAIStories = true
    @State private var fullPageLayout = false
    @State private var isGenerating = false
    @State private var showPreview = false
    @State private var generatedPDFData: Data?

    enum TimeRange: String, CaseIterable {
        case lastYear = "Last 12 Months"
        case allTime = "All Time"
        case custom = "Custom Range"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Brand.sectionSpacing) {
                    introSection
                    artistSelector
                    timeRangeSelector
                    layoutOptions
                    previewThumbnail
                }
                .padding(.horizontal, Brand.screenPadding)
                .padding(.bottom, 100) // Space for bottom bar
            }
            .navigationTitle("Studio Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                generateButton
            }
            .navigationDestination(isPresented: $showPreview) {
                if let data = generatedPDFData, let child = selectedChild {
                    PDFPreviewView(pdfData: data, child: child)
                }
            }
        }
    }

    // ... extracted sections per spec Section 11
}
```

- [ ] **Step 2: Implement generate action**

```swift
private var generateButton: some View {
    Button {
        Task {
            isGenerating = true
            guard let child = selectedChild else { return }
            let artworks = filteredArtworks(for: child)
            generatedPDFData = await Task.detached {
                PDFExportService.generatePortfolio(
                    childName: child.name,
                    avatarImageData: child.avatarImageData,
                    avatarColorHex: child.avatarColor,
                    artworks: artworks
                )
            }.value
            isGenerating = false
            showPreview = true
        }
    } label: {
        HStack {
            if isGenerating {
                ProgressView()
            } else {
                Image(systemName: "doc.richtext")
                Text("Generate PDF")
                    .fontWeight(.bold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Brand.primary)
        .foregroundStyle(.white)
        .clipShape(Capsule())
    }
    .disabled(selectedChild == nil || isGenerating)
    .padding()
    .background(.ultraThinMaterial)
}
```

- [ ] **Step 3: Commit**

```
git add "Little Artist/Views/PDF/PDFExportConfigView.swift"
git commit -m "feat: add PDFExportConfigView with artist, time range, and layout options"
```

---

### Task 19: PDF Preview View

**Files:**
- Create: `Little Artist/Views/PDF/PDFPreviewView.swift`

- [ ] **Step 1: Create the preview view**

```swift
import SwiftUI
import SwiftData

/// Magazine-style PDF preview with alternating spreads.
struct PDFPreviewView: View {
    let pdfData: Data
    let child: Child
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false

    private var childArtworks: [Artwork] {
        (child.artworks ?? []).sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 48) {
                // Intro
                VStack(spacing: 8) {
                    Text("The Collection of \(child.name)")
                        .font(.system(.largeTitle, design: .serif))
                        .italic()
                        .foregroundStyle(Brand.sky)
                    Text("\(Date.now.formatted(.dateTime.year())) Digital Edition")
                        .font(Brand.caption2Font)
                        .fontWeight(.bold)
                        .tracking(3)
                        .foregroundStyle(Brand.warmGray)
                }
                .padding(.top, Brand.sectionSpacing)

                // Page spreads
                ForEach(Array(childArtworks.prefix(6).enumerated()), id: \.element.persistentModelID) { index, artwork in
                    if index.isMultiple(of: 2) {
                        artLeftStoryRight(artwork: artwork, pageNumber: index + 1)
                    } else {
                        storyLeftArtRight(artwork: artwork, pageNumber: index + 1)
                    }
                }
            }
            .padding(.horizontal, Brand.screenPadding)
            .padding(.bottom, 100)
        }
        .navigationTitle("Studio Journal")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            shareBar
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [pdfData])
        }
    }

    // Spread layouts with artwork image + narrative text
    // ... per spec Section 11
}
```

- [ ] **Step 2: Implement spread layouts**

Create alternating art+story and story+art layouts with paper-frame styling, page numbers, and figure captions per the spec.

- [ ] **Step 3: Build and run full PDF flow**

Expected: Settings → PDF Export → Configure → Generate → Preview with magazine spreads → Share PDF

- [ ] **Step 4: Commit**

```
git add "Little Artist/Views/PDF/PDFPreviewView.swift"
git commit -m "feat: add PDFPreviewView with magazine-style spread layouts"
```

---

### Task 20: Restyle Empty States + Final Polish

**Files:**
- Modify: `Little Artist/Views/Artwork/NoArtworkView.swift`
- Modify: `Little Artist/Views/Children/NoChildrenView.swift`

- [ ] **Step 1: Restyle NoArtworkView**

Update to match the new design language — paper-stack card, updated typography using Brand tokens, keep existing LaunchFox image.

- [ ] **Step 2: Restyle NoChildrenView**

Same approach — update card style and typography.

- [ ] **Step 3: Build and run full app**

Verify all tabs, navigation, empty states, and core flows work end-to-end.

- [ ] **Step 4: Final commit**

```
git add -A
git commit -m "feat: restyle empty states and complete app redesign"
```
