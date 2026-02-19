# Little Artist — Project Rules

## Project Overview

Native SwiftUI iOS app for archiving and celebrating children's artwork. Targets iOS 17+ using SwiftData, Vision, and FoundationModels frameworks.

---

## Project Structure

```
Little Artist/
├── App/                    # Entry point & root views
├── Views/                  # Full-screen views (HomeView, AddChildView, etc.)
│   └── Onboarding/         # Onboarding page & animation views
├── Components/             # Reusable UI components (avatars, buttons, thumbnails)
├── Models/                 # SwiftData models (Child, Artwork)
├── Utilities/              # Extensions, services, preview data
└── Assets.xcassets/        # Colors, app icon
```

**Conventions:**
- Views: `Little Artist/Views/` — named `*View.swift`
- Reusable components: `Little Artist/Components/` — named descriptively (e.g., `ChildAvatarView.swift`)
- Models: `Little Artist/Models/` — entity name (e.g., `Child.swift`)
- Extensions: `Little Artist/Utilities/` — named `Type+Feature.swift`
- All files and types use PascalCase; properties and variables use camelCase

---

## Design Tokens

IMPORTANT: Never hardcode colors or spacing. Use these tokens consistently.

### Colors

| Token | Value | Usage |
|-------|-------|-------|
| Accent | `#FF8C00` / `Color.orange` | Primary buttons, selected states, highlights, FAB |
| Accent Light | `#FF8C00` at 12% opacity | Subtle fills, badge backgrounds, tinted buttons |
| Text Primary | `.primary` (system) | Headings, main text |
| Text Secondary | `.secondary` (system) | Subtitles, dates, hints |
| Background | `.white` / system white | Main screen background |
| Background Secondary | `Color(.secondarySystemBackground)` | Input fields, cards |
| Background Grouped | `Color(.systemGroupedBackground)` | Detail view backgrounds |
| Shadow | `.black.opacity(0.08)` | Card shadows |

### Avatar Palette (7 preset colors)

```swift
["#FF6B6B", "#FF8C00", "#FFD93D", "#6BCB77", "#4D96FF", "#9B59B6", "#FF6B9D"]
```

### Corner Radii

| Element | Radius |
|---------|--------|
| Cards | 18pt |
| Images | 12pt |
| Sheets | 20pt |
| Buttons | Capsule (fully rounded) |
| Onboarding gradient | 40pt |

### Shadows

```swift
.shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)   // cards
.shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)    // avatars
```

### Typography

| Style | Font | Usage |
|-------|------|-------|
| Onboarding title | `.system(size: 32, weight: .bold)` | Onboarding headlines |
| Section heading | `.title2.bold()` | Year labels, detail titles |
| Body | `.body` | Descriptions, captions |
| Subheadline | `.subheadline` | Card titles |
| Caption | `.caption` / `.caption2` | Dates, labels, counts |

### Spacing

- Screen horizontal padding: 20pt
- Section vertical spacing: 24pt
- Component internal spacing: 8–16pt
- Divider top padding: 12pt

### Component Sizes

| Component | Size |
|-----------|------|
| Child avatar | 60x60pt |
| Avatar selected ring | 68x68pt, 3pt stroke |
| Photo source buttons | 56x56pt |
| Avatar preview (sheets) | 110x110pt |
| Artwork thumbnail image | 164x180pt |
| Onboarding gradient area | height 340pt |

---

## Styling Approach

- IMPORTANT: Use native SwiftUI modifiers exclusively — no CSS, Tailwind, or external styling libraries
- Colors via `Color(hex:)` extension (defined in `Utilities/Color+Hex.swift`) or system colors
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
- Replace Tailwind classes with SwiftUI modifiers (e.g., `rounded-full` → `.clipShape(Circle())`, `text-lg font-bold` → `.font(.title2.bold())`)
- Map Figma colors to the design tokens above — never use raw hex from Figma output without checking the token table
- Reuse existing components from `Little Artist/Components/` before creating new ones
- Place new reusable components in `Little Artist/Components/`
- Place new full-screen views in `Little Artist/Views/`
- Follow the component structure pattern above (doc comment, MARK sections, Preview block)

### Asset Handling from Figma

- IMPORTANT: If the Figma MCP server returns a localhost source for an image or SVG, use that source directly to download the asset
- IMPORTANT: DO NOT import new icon packages — use SF Symbols or assets from the Figma payload
- IMPORTANT: DO NOT create placeholders if a localhost source is provided
- Store downloaded image assets in `Assets.xcassets/`
- Convert SVG icons to SF Symbol equivalents when possible

---

## Design Spec Reference

Detailed design specifications are in `docs/plans/2026-02-19-pencil-design.md` — consult this for screen-by-screen layout details, spacing, and component specs.

User flow diagram is in `docs/userflow.md`.
