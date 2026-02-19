# Little Artist — Project Rules

## Project Overview

Native SwiftUI iOS app for archiving and celebrating children's artwork. Targets iOS 17+ using SwiftData, Vision, and FoundationModels frameworks.

---

## Project Structure

```
Little Artist/
├── App/                        # Entry point & root views
├── Views/                      # Full-screen views
│   ├── Onboarding/             # Onboarding page & animation views
│   ├── Artwork/                # Artwork CRUD & gallery views
│   ├── Children/               # Child profile CRUD views
│   ├── HomeView.swift          # Tab root views stay at Views/ root
│   ├── TimelineView.swift
│   ├── SearchView.swift
│   ├── SettingsView.swift
│   └── MilestonesView.swift
├── Components/                 # Reusable UI components
│   ├── Buttons/                # Action buttons (AddArtwork, AddChild)
│   ├── Cards/                  # Card widgets (Thumbnail, Stat, Timeline, Achievement)
│   ├── Chips/                  # Filter & selection chips
│   ├── Avatars/                # Avatar & avatar slider components
│   └── UIKitBridges/           # UIKit wrappers (Camera, Scanner, Activity)
├── Models/                     # SwiftData models (Child, Artwork)
├── Services/                   # App services (AI suggestions, haptics)
├── Utilities/                  # Extensions, tokens, preview data
└── Assets.xcassets/            # Colors, app icon
```

**Conventions:**
- Views: `Little Artist/Views/` — named `*View.swift`; tab roots stay flat, feature views go in subfolders (`Artwork/`, `Children/`, `Onboarding/`)
- Reusable components: `Little Artist/Components/` — grouped by type (`Buttons/`, `Cards/`, `Chips/`, `Avatars/`, `UIKitBridges/`)
- Models: `Little Artist/Models/` — entity name (e.g., `Child.swift`)
- Services: `Little Artist/Services/` — named `*Service.swift`
- Extensions: `Little Artist/Utilities/` — named `Type+Feature.swift`
- All files and types use PascalCase; properties and variables use camelCase

---

## Design Tokens

IMPORTANT: All design tokens are centralized in `Utilities/BrandTokens.swift`. Always use `Brand.*` tokens — never hardcode color, font, shadow, or spacing values.

### Colors

| Token | Code | Hex | Usage |
|-------|------|-----|-------|
| Primary | `Brand.primary` | `#F2784B` | CTAs, selected states, FAB, highlights |
| Primary Tint | `Brand.primaryTint` | `#F2784B` at 12% | Badge backgrounds, tinted fills |
| Cream | `Brand.cream` | `#FFF8F0` | Main app background |
| Surface | `Brand.surface` | `#FFFBF7` | Cards, sheets, input fields |
| Charcoal | `Brand.charcoal` | `#3D3D3D` | Headings, body text |
| Warm Gray | `Brand.warmGray` | `#8A8680` | Subtitles, dates, hints |
| Soft Tan | `Brand.softTan` | `#E8E0D8` | Dividers, borders |
| Sage | `Brand.sage` | `#A8C5A0` | Success states |
| Sky | `Brand.sky` | `#7EB8DA` | Informational |
| Lavender | `Brand.lavender` | `#B8A9D4` | Tertiary accent |
| Dusty Rose | `Brand.dustyRose` | `#D4736C` | Destructive actions |
| Disabled | `Brand.disabled` | `#8A8680` | Disabled states |

### Avatar Palette

```swift
Brand.avatarColors  // ["F2784B", "A8C5A0", "7EB8DA", "B8A9D4", "E8C94A", "D4928A", "7BC8B5"]
Brand.defaultAvatarColor  // "F2784B"
```

### Typography (SF Rounded headings, SF Pro body)

| Token | Code | Usage |
|-------|------|-------|
| Display | `Brand.displayFont` | Onboarding headlines |
| Title 1 | `Brand.title1Font` | Screen titles |
| Title 2 | `Brand.title2Font` | Section headings, year labels |
| Title 3 | `Brand.title3Font` | Sheet titles |
| Headline | `Brand.headlineFont` | Month names, card titles |
| Body | `Brand.bodyFont` | Descriptions, input text |
| Subheadline | `Brand.subheadlineFont` | Thumbnail titles |
| Caption | `Brand.captionFont` | Dates, labels |
| Caption 2 | `Brand.caption2Font` | Metadata |

### Shadows

```swift
.brandCardShadow()    // charcoal 8%, 12pt blur, 6pt y
.brandAvatarShadow()  // charcoal 6%, 6pt blur, 3pt y
.brandFABShadow()     // primary 40%, 10pt blur, 4pt y
```

### Corner Radii

| Token | Code | Value |
|-------|------|-------|
| Onboarding | `Brand.radiusOnboarding` | 40pt |
| Sheets | `Brand.radiusSheet` | 20pt |
| Cards | `Brand.radiusCard` | 18pt |
| Buttons | `Brand.radiusButton` | 16pt |
| Fields | `Brand.radiusField` | 14pt |
| Images | `Brand.radiusImage` | 12pt |
| Pills | `Capsule()` | fully rounded |

### Spacing

| Token | Code | Value |
|-------|------|-------|
| Screen padding | `Brand.screenPadding` | 20pt |
| Form padding | `Brand.formPadding` | 32pt |
| Section spacing | `Brand.sectionSpacing` | 28pt |
| Gallery spacing | `Brand.gallerySpacing` | 24pt |
| Button padding | `Brand.buttonPadding` | 18pt |
| Field padding | `Brand.fieldPadding` | 14pt |

### Component Sizes

| Token | Code | Value |
|-------|------|-------|
| Avatar | `Brand.avatarSize` | 60pt |
| Avatar ring | `Brand.avatarRingSize` | 68pt |
| Ring stroke | `Brand.avatarRingStroke` | 3pt |
| Avatar preview | `Brand.avatarPreviewSize` | 110pt |
| Source buttons | `Brand.sourceButtonSize` | 56pt |
| Thumbnail | `Brand.thumbnailWidth` / `.thumbnailHeight` | 164x180pt |
| FAB | `Brand.fabSize` | 60pt |
| Onboarding cards | `Brand.onboardingCardHeight` | 340pt |
| Color circles | `Brand.colorCircleSize` | 40pt |

---

## Styling Approach

- IMPORTANT: Use native SwiftUI modifiers exclusively — no CSS, Tailwind, or external styling libraries
- IMPORTANT: Always use `Brand.*` tokens from `Utilities/BrandTokens.swift` for colors, fonts, shadows, spacing
- Colors via `Brand.primary`, `Brand.cream`, etc. — or `Color(hex:)` for dynamic values only
- Shapes: `Circle()`, `Capsule()`, `RoundedRectangle(cornerRadius:)`
- Layout: `VStack`, `HStack`, `ZStack`, `LazyVStack`, `LazyHStack`
- Scrolling: `ScrollView(.horizontal)` for sliders, `ScrollView` for galleries
- Images: `.resizable().scaledToFill()` with `.clipShape()` or `.cornerRadius()`

---

## State Management

- **Persistence:** SwiftData with `@Model`, `@Query`, `@Environment(\.modelContext)`
- **Local UI state:** `@State private var`
- **Parent-child binding:** `@Binding`
- **App-level flags:** `@AppStorage` (e.g., `hasCompletedOnboarding`)
- **No external state libraries** — pure SwiftUI patterns

---

## Navigation

- `NavigationStack` as root container
- Modal sheets via `.sheet(isPresented:)` and `.sheet(item:)`
- Full-screen covers via `.fullScreenCover()` for camera
- `NavigationLink` for drill-down (e.g., artwork detail)
- No URL routing or deep linking

---

## Icon System

- IMPORTANT: Use SF Symbols exclusively — do not add custom icon assets or icon packages
- Reference by name: `Image(systemName: "paintpalette.fill")`
- Common icons: `paintpalette.fill`, `camera.fill`, `photo.on.rectangle`, `sparkles`, `plus`, `xmark.circle.fill`

---

## Asset Handling

- User photos stored as `Data` in SwiftData with `@Attribute(.externalStorage)`
- JPEG compression: `jpegData(compressionQuality: 0.8)`
- Camera: `CameraPicker` wrapper (UIKit bridge)
- Photo library: `PhotosPicker` (PhotosUI framework)
- Scanner: `DocumentScannerPicker` wrapper (VisionKit bridge)
- App icon and accent color in `Assets.xcassets/`

---

## Code Patterns

### Component Structure

Every view/component follows this pattern:

```swift
import SwiftUI

/// Brief description of what this component does.
struct ComponentNameView: View {
    // Properties and state
    let requiredProp: Type
    var optionalProp: Type = defaultValue
    @State private var localState: Type

    var body: some View {
        // View hierarchy
    }
}

// MARK: - Preview

#Preview {
    ComponentNameView(requiredProp: PreviewSampleData.example)
}
```

### Key Patterns

- `/// Doc comments` for public APIs
- `// MARK: -` sections for code organization
- `#Preview` blocks with `PreviewSampleData` for every view
- Cascade delete rules on relationships: `@Relationship(deleteRule: .cascade)`
- External storage for large binary data: `@Attribute(.externalStorage)`
- Lazy loading for performance: `LazyVStack`, `LazyHStack`, batch month loading

---

## Figma MCP Integration Rules

These rules define how to translate Figma inputs into code for this project.

### Required Flow (do not skip)

1. Run `get_design_context` first to fetch the structured representation for the exact node(s)
2. If the response is too large or truncated, run `get_metadata` to get the high-level node map, then re-fetch only the required node(s) with `get_design_context`
3. Run `get_screenshot` for a visual reference of the node variant being implemented
4. Only after you have both `get_design_context` and `get_screenshot`, download any assets needed and start implementation
5. IMPORTANT: Translate the Figma MCP output (typically React + Tailwind) into native SwiftUI using this project's design tokens and conventions
6. Validate against Figma screenshot for 1:1 visual parity before marking complete

### Translation Rules

- Figma MCP returns React + Tailwind code — this is a **design reference**, not final code
- Convert all HTML/JSX elements to SwiftUI equivalents (`div` → `VStack`/`HStack`, `img` → `Image`, `span` → `Text`)
- Replace Tailwind classes with SwiftUI modifiers (e.g., `rounded-full` → `.clipShape(Circle())`, `text-lg font-bold` → `.font(Brand.title2Font)`)
- Map Figma colors to `Brand.*` tokens — never use raw hex from Figma output without checking BrandTokens.swift
- Reuse existing components from `Little Artist/Components/` subfolders before creating new ones
- Place new reusable components in the appropriate `Little Artist/Components/` subfolder (`Buttons/`, `Cards/`, `Chips/`, `Avatars/`, `UIKitBridges/`)
- Place new full-screen views in the appropriate `Little Artist/Views/` subfolder (`Artwork/`, `Children/`, `Onboarding/`) or at `Views/` root for tab-level screens
- Follow the component structure pattern above (doc comment, MARK sections, Preview block)

### Asset Handling from Figma

- IMPORTANT: If the Figma MCP server returns a localhost source for an image or SVG, use that source directly to download the asset
- IMPORTANT: DO NOT import new icon packages — use SF Symbols or assets from the Figma payload
- IMPORTANT: DO NOT create placeholders if a localhost source is provided
- Store downloaded image assets in `Assets.xcassets/`
- Convert SVG icons to SF Symbol equivalents when possible

---

## Design Spec Reference

- Brand identity design: `docs/plans/2026-02-19-brand-identity-design.md`
- Screen-by-screen layout specs: `docs/plans/2026-02-19-pencil-design.md`
- User flow diagram: `docs/userflow.md`
