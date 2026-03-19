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

**Search:** Moves from dedicated tab to a toolbar button (magnifying glass) on Gallery tab's navigation bar.

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

### Schema Migration

New `SchemaV7` adding `Comment` entity, `Achievement` entity, and `comments` relationship on `Artwork`.

### AchievementService

New `Services/AchievementService.swift`:
- `seedAchievements(context:)` — creates all default achievements on first launch
- `checkMilestones(context:)` — called after artwork save, voice memo save, memory view; queries counts and marks earned
- Achievements are per-app (family-level), not per-child

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
Reuses `MilestoneCarouselView`, filtered to child context.

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
  - iCloud Sync: icon + toggle (maps to `isSyncEnabled`)
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

**Data flow:** `PDFExportService` extended with options for time range, AI story inclusion, layout mode. Preview renders artwork + caption pairs.

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
- `Models/SchemaMigrationV7.swift`
- `Services/AchievementService.swift`
- `Views/TimelineView.swift`
- `Views/MilestonesView.swift`
- `Views/ChildProfileView.swift` (in `Views/Children/`)
- `Views/Artwork/PDFExportConfigView.swift`
- `Views/Artwork/PDFPreviewView.swift`
- `Components/Cards/MilestoneCarouselView.swift`
- `Components/Cards/MilestoneCardView.swift`
- `Components/Cards/FamilyCommentView.swift`
- `Components/Cards/BentoGridView.swift`
- `Components/Cards/ProgressBarView.swift`
- `Components/Avatars/ArtistSelectorView.swift`
