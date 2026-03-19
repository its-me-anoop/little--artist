# Little Artist — Complete App Redesign (Excluding Onboarding)

**Date:** 2026-03-19
**Status:** Approved

---

## Overview

Redesign the entire Little Artist app UI and add new features, keeping the existing color palette (`Brand.*` tokens) and onboarding screens unchanged. The redesign adopts layouts from provided HTML/Tailwind mockups, translated into native SwiftUI.

## Decisions

- **Colors:** Keep existing `Brand.*` palette. Map mockup layouts to current tokens.
- **Navigation:** 4-tab structure (Gallery, Timeline, Milestones, Settings) + floating action button.
- **Feature scope:** Full implementation of all mockup features including achievements, family comments, timeline, and PDF preview.
- **Typography:** Keep SF Rounded (headings) and SF Pro (body) — do not adopt web fonts from mockups.
- **Icons:** SF Symbols exclusively — map Material Symbols from mockups to SF Symbol equivalents.

## Implementation Approach

Feature-grouped phases:

1. **Phase 1: Navigation Shell** — New 4-tab structure + FAB, stub new tabs
2. **Phase 2: Core Screens** — Gallery Home, Artwork Detail, Add Artwork
3. **Phase 3: New Features** — Timeline tab, Milestones/Achievements, Family Comments
4. **Phase 4: Settings & Paywall** — Settings redesign, Premium paywall, Child Profile
5. **Phase 5: PDF Flow** — Export config + magazine preview

---

## 1. Navigation Architecture

### Current
2-tab `TabView` (Gallery, Search) with toolbar buttons for + and settings.

### New

```
AppTab enum:
  .gallery     → HomeView
  .timeline    → TimelineView
  .milestones  → MilestonesView
  .settings    → SettingsView
```

**Tab bar icons (SF Symbols):**
- Gallery: `photo.on.rectangle.angled` / `.fill` variant when active
- Timeline: `book.pages` / `.fill` variant when active
- Milestones: `medal` / `.fill` variant when active
- Settings: `slider.horizontal.3`

**FAB:** Floating `+` button, bottom-right above tab bar, 60pt (`Brand.fabSize`), `Brand.primary`, `.brandFABShadow()`. Opens `AddArtworkView` as sheet.

**Search:** Moves from dedicated tab to a toolbar button (magnifying glass) on Gallery tab's navigation bar. The `AppTab.search` case and its `Tab(role: .search)` entry are removed entirely from `ContentView`.

**Child profile:** Tapping a child avatar navigates to `ChildProfileView` via `NavigationLink`.

---

## 2. New Data Models

### Comment

```swift
@Model final class Comment {
    var text: String
    var authorName: String           // "Mom", "Dad", "Grandma"
    var authorAvatarData: Data?      // Optional profile image
    var createdAt: Date
    var artwork: Artwork?            // Belongs to artwork
    var firestoreId: String?         // Firestore sync
}
```

Add to `Artwork`:
```swift
@Relationship(deleteRule: .cascade, inverse: \Comment.artwork)
var comments: [Comment]?
```

### Achievement

```swift
@Model final class Achievement {
    var identifier: String           // e.g., "first_masterpiece"
    var title: String
    var subtitle: String
    var iconName: String             // SF Symbol name
    var isEarned: Bool
    var earnedAt: Date?
    var category: String             // "artwork", "voice", "seasonal", "medium"
}
```

### Default Achievements

| ID | Title | Icon | Requirement |
|---|---|---|---|
| `first_masterpiece` | First Masterpiece | `star.fill` | Save 1 artwork |
| `prolific` | Prolific | `square.stack.3d.up.fill` | Save 50 artworks |
| `gallery_owner` | Gallery Owner | `person.crop.rectangle.stack.fill` | Save 100 artworks |
| `memory_lane` | Memory Lane | `text.book.closed.fill` | View an "On This Day" memory |
| `year_in_review` | Year in Review | `calendar.badge.checkmark` | Artworks spanning 365 days |
| `seasonal_artist` | Seasonal Artist | `leaf.fill` | Artworks in all 4 seasons |
| `storyteller` | Storyteller | `mic.fill` | Record 10 voice memos |
| `rainbow_palette` | Rainbow Palette | `paintpalette.fill` | Use all medium tags |

### Medium Tags

The `rainbow_palette` achievement requires tracking which art mediums have been used. A canonical list of medium tag names is defined in `AchievementService`:

```swift
static let mediumTags = ["Craft", "Painting", "Drawing", "Watercolor", "Collage", "Sculpture", "Digital", "Mixed Media"]
```

When checking this achievement, the service queries all unique tag names across artworks and intersects with this list. No changes to the `Tag` model are needed — medium tags are identified by matching against this hardcoded list.

### Comment Firestore Sync

Comments sync to Firestore at path: `users/{uid}/children/{childId}/artworks/{artworkId}/comments/{commentId}`

`FirestoreRepository` gets new methods:
- `saveComment(_ comment: Comment, artworkId: String, childId: String)` — writes comment to subcollection
- `deleteComment(commentId: String, artworkId: String, childId: String)` — removes comment
- `observeComments(artworkId: String, childId: String)` — snapshot listener for real-time comment updates

`FirestoreSyncService` adds comment observation when syncing artworks, using the existing `isSyncEnabled` flow.

### Schema Migration

New `SchemaV8` (version `8, 0, 0`) adding `Comment` entity, `Achievement` entity, and `comments` relationship on `Artwork`. File: `Models/SchemaMigrationV8.swift`. The models array includes all five entities: `Child`, `Artwork`, `Tag`, `Comment`, `Achievement`.

Note: `SchemaV7` already exists in the codebase — using V7 again would cause a duplicate version checksums crash.

### AchievementService

New `Services/AchievementService.swift`:
- `seedAchievements(context:)` — creates all default achievements on first launch
- `checkMilestones(context:)` — called after artwork save, voice memo save, and memory card tap; queries counts and marks earned
- Achievements are per-app (family-level), not per-child

**Counting voice memos:** Since `voiceNoteData` uses `@Attribute(.externalStorage)` and `#Predicate` may not reliably filter on optional external-storage Data fields, the service fetches all artworks and filters in memory: `artworks.filter { $0.voiceNoteData != nil }.count`.

**Memory Lane trigger:** The `memory_lane` achievement is earned when the user taps an "On This Day" memory card in `HomeView`. The card's tap action calls `AchievementService.markMemoryViewed(context:)` which sets the achievement as earned. Simply scrolling past the card does not trigger it — an explicit tap is required.

---

## 3. Gallery Home (HomeView)

### Header
- Navigation bar: child avatar (tappable → ChildProfileView), app title, search icon + filter menu
- Thin divider below

### "Today" Section
- Section header: "Timeline" label + "Today" heading + date pill
- Bento grid layout:
  - **Featured artwork:** 2×2 span, paper-stack shadow, slight -1° rotation, title badge overlay, voice memo play button if applicable
  - **"On This Day" memory:** 2×1 span, accent-colored background, pin decoration, shows artwork from same date previous years with quote
  - **2 smaller cards:** 1×1 each, simple image thumbnails

### "Earlier this Month" Section
- Header with grid/filter toggle
- Staggered 2-column masonry grid (4 on iPad):
  - Cards at varying heights
  - Paper-stack effect on featured items
  - Tag pills on cards
  - Voice memo indicator cards (image + mic icon + waveform + quote)

### Child Filter
- `ChildSliderView` below nav bar for filtering by child
- "All" option shows mixed gallery

### Data Flow
- `@Query` artworks filtered by selected child, sorted by date
- Latest artwork → hero spot
- Memory card: artworks matching today's month+day in previous years

---

## 4. Artwork Detail (ArtworkDetailView)

Scrollable detail page replacing full-screen viewer.

### Hero Artwork
- Large image in paper-frame container (white padding, -0.5° rotation, card shadow)
- Zoom button overlay (bottom-right) → opens full-screen pinch-to-zoom as `.fullScreenCover`

### Details Header
- Category badge pill (tag-based or "Masterpiece" default)
- Date label
- Large bold title (`Brand.title1Font`)
- Child info: avatar + "Leo, Age 4"

### AI Smart Analysis
- Dashed border container with `Brand.surface` fill
- Sparkles icon + "Smart Analysis" heading
- Voice quote block: left border accent + quote icon + italic transcription text
- AI narrative block: white sub-card with AI-generated caption
- Uses `AISuggestionService`

### Action Buttons
- "Share Masterpiece" — primary filled pill button, triggers share sheet
- "Edit Entry" — secondary filled pill button, opens edit sheet

### Family Love
- Section title "Family Love"
- List of `Comment` entries: avatar + name + timestamp + text in card
- Add comment input/button
- Comments from artwork's `comments` relationship
- Saved to SwiftData + synced via Firestore

### Navigation
- Back button, favorite toggle in toolbar

---

## 5. Add Artwork (AddArtworkView)

### Navigation
- Close (X) + centered "Add Masterpiece" title

### Preview Section
- Centered artwork preview in rounded container with paper-stack shadow
- Edit button overlay to re-open image source picker
- Placeholder if no image

### Artist Selector
- "ARTIST" label (uppercase tracking)
- Horizontal scroll of child avatars: selected has primary ring, unselected dimmed
- "New" dashed circle button → opens `AddChildView`

### Form Fields
- Title: pill-shaped text field, headline font
- Date Created: read-only pill with calendar icon → date picker
- Medium: pill picker (Craft, Painting, Drawing, Watercolor, etc.)

### Action Buttons (2 columns)
- "Record Story" — mic icon in `Brand.sky` circle, triggers `VoiceMemoRecorderView`
- "Magic Caption" — sparkles icon in `Brand.lavender` circle, triggers `AISuggestionService`

### Creative Notes
- Multi-line text area, large corner radius → maps to `caption` field

### Tags
- Horizontal wrap of tag pills + "Add" button → `TagPickerView`

### Save
- Fixed bottom: full-width primary pill "Save to Gallery"
- Gradient fade above button
- Triggers `AchievementService.checkMilestones()` after save

---

## 6. Timeline Tab (TimelineView)

### Profile Hero
- Large avatar (140pt) with accent background, primary badge overlay
- Child name in display font
- "Age 4 · Artist since 2023"
- Two stat cards: artwork count + level/tier

### Milestones Carousel
- "Milestones" header + "View All" button → Milestones tab
- Horizontal scroll of milestone cards (earned: colored + icon, locked: dashed + dimmed)
- Reusable `MilestoneCarouselView` component

### Art Timeline
- Vertical 2px line on left side
- Entries grouped by relative time ("Today", "Last Week", month names)
- Each group:
  - Colored dot (cycling primary/sky/lavender)
  - Date label header
  - Artwork cards with paper-frame style, alternating ±1° rotation
  - Multiple artworks in 2-column mini grid
- Voice memo entries: glass pill with play button + waveform + quote

### Data Flow
- `@Query` artworks by selected child, sorted newest first
- Grouped into: Today, This Week, This Month, then by month
- Timeline dot colors cycle through `[Brand.primary, Brand.sky, Brand.lavender]`

---

## 7. Milestones Tab (MilestonesView)

### Progress Hero
- White card with shadow
- "Your Journey" heading + description
- Count / target (e.g., "128 / 500")
- Animated gradient progress bar
- "372 more to reach the next tier" subtitle

### Badge Grid (2 columns)
- **Earned:** white card, colored icon circle (96pt), filled SF Symbol, optional count badge, title + subtitle
- **Locked:** dimmed card (60% opacity), dashed border, grayscale icon, lock + requirement text pill

### Voice Note Highlight
- Glass pill card at bottom: play button + waveform bars + quote
- Shows most recent voice memo from any artwork
- Compact `VoiceMemoPlayerView`

---

## 8. Child Profile (ChildProfileView)

Pushed from child avatar taps.

### Profile Hero
Same as Timeline: large avatar, name, age, stat cards.

### Milestones Carousel
Reuses `MilestoneCarouselView`. In ChildProfileView, the carousel shows achievements that are relevant to the child's artwork — specifically, artwork-count-based achievements (first_masterpiece, prolific, gallery_owner) are evaluated against this child's artwork count, and displayed as earned/locked accordingly. Voice/seasonal/medium achievements show their global earned state since they are family-level.

### Art Timeline
Same structure as Timeline tab, scoped to this specific child.

### Edit
Toolbar trailing edit button → `EditChildView` sheet.

---

## 9. Settings (SettingsView)

### Premium Account Hero
- Asymmetric card (-1° rotation), primary tint background
- Decorative medal icon at low opacity
- "Current Plan" pill + "Premium Account" title + active status
- "Manage" button → PaywallView
- Free tier: shows upsell card instead

### Child Profiles
- Section title + "Add New" button
- Child cards: avatar (64pt) + name + age + artwork count + chevron
- Tap → `ChildProfileView`

### Data & Privacy
- Grouped container:
  - iCloud Sync: icon + toggle (maps to existing `@AppStorage("firebaseSyncEnabled")` key)
  - PDF Portfolio Export: icon + download action → `PDFExportConfigView`

### Support
- Privacy Policy → `PrivacyPolicyView`
- About Little Artist → version number
- Appearance picker (system/light/dark)

### Danger Zone
- "Log Out of All Devices" in `Brand.dustyRose` (shown when Firebase auth active)

---

## 10. Premium Paywall (PaywallView)

### Navigation
Close + "Little Artist Premium" title, presented as sheet.

### Hero
- "Unlock Your Full Studio" heading
- Subtitle about preserving memories

### Visual Asset
- Featured image card with paper-stack shadow + rotation
- Badge overlay pill

### Benefit Cards (vertical list)
Each: tinted icon circle + title + description.
- Unlimited Child Profiles (primary tint)
- Unlimited Artworks (secondary/sky tint)
- Cloud Backup & Sync (tertiary/lavender tint)
- PDF Portfolio Export (warmGray tint)
- Voice Memo & AI Captions (primary tint, emphasized/larger)

### Subscription Tiers
- **Yearly:** highlighted card with border + "Best Value" badge, "$39.99/year"
- **Monthly:** subtle card, "$5.99/month"

### CTA
- Full-width primary gradient button "Subscribe Now"
- Auto-renewal fine print
- Privacy Policy + Terms links
- Restore Purchases + Help buttons at bottom

---

## 11. PDF Export Flow

### PDFExportConfigView

**Navigation:** Close + "Studio Journal" title

**Config cards:**
- Artist selector: child avatars with selection ring
- Time range: radio list (Last 12 Months, All Time, Custom Range)
- Layout & Features: toggle cards (AI Stories on/off, Full Page Layout on/off)
- Preview thumbnail: rotated mini PDF mockup

**Bottom bar:** Generate + "Generate PDF" primary button + Share

### PDFPreviewView

**Navigation:** Close + "Studio Journal" + "PREVIEW MODE"

**Intro:** Child name in serif-style + edition label

**Page spreads (scrollable):**
- Alternating layouts:
  - Art + Story: image left, narrative right
  - Story + Art: reversed
  - Full spread: centered image + title + narrative
- Page numbers + figure captions

**Bottom bar:** Generate + "Share PDF" primary button + Options

**Data flow:** `PDFPreviewView` is a pure SwiftUI layout — it renders artwork images and captions directly from SwiftData queries, not from a pre-generated PDF. The preview is a visual representation of what the PDF will look like, built with SwiftUI views (Image, Text, VStack/HStack). When the user taps "Share PDF", `PDFExportService` generates the actual PDF data on a background task (`Task.detached`) with a loading indicator, then presents the share sheet. The service is extended with options for time range filtering, AI story inclusion, and layout mode (grid vs full-page).

---

## Shared/Reusable Components

| Component | Location | Used By |
|---|---|---|
| `MilestoneCarouselView` | `Components/Cards/` | TimelineView, ChildProfileView |
| `FamilyCommentView` | `Components/Cards/` | ArtworkDetailView |
| `BentoGridView` | `Components/Cards/` | HomeView |
| `ArtistSelectorView` | `Components/Avatars/` | AddArtworkView, PDFExportConfigView |
| `ProgressBarView` | `Components/Cards/` | MilestonesView |

---

## Files Changed/Created

### Modified
- `App/ContentView.swift` — 4-tab structure + FAB
- `Views/HomeView.swift` — Bento gallery layout
- `Views/SearchView.swift` — Minor: accessible from toolbar
- `Views/SettingsView.swift` — Full redesign
- `Views/Artwork/ArtworkDetailView.swift` — Scrollable detail + AI + comments
- `Views/Artwork/AddArtworkView.swift` — New form layout
- `Views/Artwork/NoArtworkView.swift` — Restyle
- `Views/Children/NoChildrenView.swift` — Restyle
- `Views/PaywallView.swift` — Benefit cards + tiers
- `Models/Artwork.swift` — Add `comments` relationship
- `Services/PDFExportService.swift` — Add options, time range, layout mode

### Created
- `Models/Comment.swift`
- `Models/Achievement.swift`
- `Models/SchemaMigrationV8.swift`
- `Services/AchievementService.swift`
- `Views/TimelineView.swift`
- `Views/MilestonesView.swift`
- `Views/Children/ChildProfileView.swift`
- `Views/Artwork/PDFExportConfigView.swift`
- `Views/Artwork/PDFPreviewView.swift`
- `Components/Cards/MilestoneCarouselView.swift`
- `Components/Cards/MilestoneCardView.swift`
- `Components/Cards/FamilyCommentView.swift`
- `Components/Cards/BentoGridView.swift`
- `Components/Cards/ProgressBarView.swift`
- `Components/Avatars/ArtistSelectorView.swift`
