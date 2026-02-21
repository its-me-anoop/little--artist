# Brand Identity Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Apply the "Art Studio" brand identity to the Little Artist app — centralized design tokens, new color palette, SF Rounded typography, and updated avatar colors.

**Architecture:** Create a single `BrandTokens.swift` file that centralizes all design values (colors, typography, spacing, shadows, radii). Then systematically replace hardcoded values across all views and components to reference these tokens. This eliminates duplication (e.g., avatar colors defined in two files) and makes future brand changes trivial.

**Tech Stack:** SwiftUI, Swift, Xcode asset catalogs

**Design doc:** `docs/plans/2026-02-19-brand-identity-design.md`

---

### Task 1: Create BrandTokens.swift

**Files:**
- Create: `Little Artist/Utilities/BrandTokens.swift`

**Step 1: Create the centralized design token file**

```swift
//
//  BrandTokens.swift
//  Little Artist
//
//  Centralized design tokens for the Little Artist brand identity.
//

import SwiftUI

/// Centralized brand design tokens.
///
/// All colors, typography, spacing, shadows, and radii are defined here.
/// Reference these tokens instead of hardcoding values in views.
enum Brand {

    // MARK: - Colors

    /// Primary coral-orange accent color.
    static let primary = Color(hex: "F2784B")
    /// Primary at 12% opacity for tinted fills and badge backgrounds.
    static let primaryTint = Color(hex: "F2784B").opacity(0.12)

    /// Cream background for main screens.
    static let cream = Color(hex: "FFF8F0")
    /// Warm white for cards, sheets, input fields.
    static let surface = Color(hex: "FFFBF7")
    /// Charcoal for headings and body text.
    static let charcoal = Color(hex: "3D3D3D")
    /// Warm gray for subtitles, dates, hints.
    static let warmGray = Color(hex: "8A8680")
    /// Soft tan for dividers and borders.
    static let softTan = Color(hex: "E8E0D8")

    /// Sage green accent for success states.
    static let sage = Color(hex: "A8C5A0")
    /// Sky blue accent for informational elements.
    static let sky = Color(hex: "7EB8DA")
    /// Soft lavender accent.
    static let lavender = Color(hex: "B8A9D4")
    /// Dusty rose for destructive actions.
    static let dustyRose = Color(hex: "D4736C")

    /// Disabled button background.
    static let disabled = Color(hex: "8A8680")

    // MARK: - Avatar Palette

    /// The 7 preset avatar colors.
    static let avatarColors = [
        "F2784B", // Coral
        "A8C5A0", // Sage
        "7EB8DA", // Sky
        "B8A9D4", // Lavender
        "E8C94A", // Sunshine
        "D4928A", // Rose
        "7BC8B5", // Mint
    ]

    /// Default avatar color hex (first in the palette).
    static let defaultAvatarColor = "F2784B"

    // MARK: - Typography

    /// Display — SF Rounded 32pt Bold. Onboarding headlines.
    static let displayFont = Font.system(.largeTitle, design: .rounded).bold()
    /// Title 1 — SF Rounded 28pt Bold. Screen titles.
    static let title1Font = Font.system(.title, design: .rounded).bold()
    /// Title 2 — SF Rounded 22pt Semibold. Section headings.
    static let title2Font = Font.system(.title2, design: .rounded).weight(.semibold)
    /// Title 3 — SF Rounded 20pt Medium. Sheet titles.
    static let title3Font = Font.system(.title3, design: .rounded).weight(.medium)
    /// Headline — SF Rounded 17pt Semibold. Month names, card titles.
    static let headlineFont = Font.system(.headline, design: .rounded)
    /// Body — SF Pro 17pt. Descriptions, input text.
    static let bodyFont = Font.body
    /// Subheadline — SF Pro 15pt. Thumbnail titles.
    static let subheadlineFont = Font.subheadline
    /// Caption — SF Pro 12pt. Dates, labels.
    static let captionFont = Font.caption
    /// Caption 2 — SF Pro 11pt. Metadata.
    static let caption2Font = Font.caption2

    // MARK: - Shadows

    /// Card shadow: charcoal 8% opacity, 12pt blur, 6pt y-offset.
    static func cardShadow() -> some ViewModifier { ShadowModifier(opacity: 0.08, radius: 12, y: 6) }
    /// Avatar shadow: charcoal 6% opacity, 6pt blur, 3pt y-offset.
    static func avatarShadow() -> some ViewModifier { ShadowModifier(opacity: 0.06, radius: 6, y: 3) }
    /// FAB shadow: primary color 40% opacity, 10pt blur, 4pt y-offset.
    static func fabShadow() -> some ViewModifier { FABShadowModifier() }

    // MARK: - Corner Radii

    /// Onboarding gradient area corner radius.
    static let radiusOnboarding: CGFloat = 40
    /// Sheet and large image corner radius.
    static let radiusSheet: CGFloat = 20
    /// Card corner radius.
    static let radiusCard: CGFloat = 18
    /// Photo source button corner radius.
    static let radiusButton: CGFloat = 16
    /// Text field corner radius.
    static let radiusField: CGFloat = 14
    /// Thumbnail image corner radius.
    static let radiusImage: CGFloat = 12

    // MARK: - Spacing

    /// Screen horizontal padding.
    static let screenPadding: CGFloat = 20
    /// Primary horizontal padding for forms.
    static let formPadding: CGFloat = 32
    /// Section vertical spacing.
    static let sectionSpacing: CGFloat = 28
    /// Gallery section spacing.
    static let gallerySpacing: CGFloat = 24
    /// Button vertical padding.
    static let buttonPadding: CGFloat = 18
    /// Field vertical padding.
    static let fieldPadding: CGFloat = 14

    // MARK: - Component Sizes

    /// Standard child avatar diameter.
    static let avatarSize: CGFloat = 60
    /// Avatar selection ring diameter.
    static let avatarRingSize: CGFloat = 68
    /// Avatar selection ring stroke width.
    static let avatarRingStroke: CGFloat = 3
    /// Large avatar preview (sheets).
    static let avatarPreviewSize: CGFloat = 110
    /// Photo source button size.
    static let sourceButtonSize: CGFloat = 56
    /// Artwork thumbnail image size.
    static let thumbnailWidth: CGFloat = 164
    static let thumbnailHeight: CGFloat = 180
    /// FAB size.
    static let fabSize: CGFloat = 60
    /// Onboarding card area height.
    static let onboardingCardHeight: CGFloat = 340
    /// Color picker circle size.
    static let colorCircleSize: CGFloat = 40
}

// MARK: - Shadow Modifiers

private struct ShadowModifier: ViewModifier {
    let opacity: Double
    let radius: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        content.shadow(
            color: Color(hex: "3D3D3D").opacity(opacity),
            radius: radius,
            x: 0,
            y: y
        )
    }
}

private struct FABShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(
            color: Brand.primary.opacity(0.4),
            radius: 10,
            x: 0,
            y: 4
        )
    }
}

// MARK: - View Extension

extension View {
    /// Applies the brand card shadow.
    func brandCardShadow() -> some View {
        modifier(Brand.cardShadow())
    }

    /// Applies the brand avatar shadow.
    func brandAvatarShadow() -> some View {
        modifier(Brand.avatarShadow())
    }

    /// Applies the brand FAB shadow.
    func brandFABShadow() -> some View {
        modifier(Brand.fabShadow())
    }
}
```

**Step 2: Build the project in Xcode to verify no compile errors**

Run: `xcodebuild build -project "Little Artist.xcodeproj" -scheme "Little Artist" -destination "platform=iOS Simulator,name=iPhone 16" -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add "Little Artist/Utilities/BrandTokens.swift"
git commit -m "feat: add centralized BrandTokens design token file"
```

---

### Task 2: Update AccentColor.colorset

**Files:**
- Modify: `Little Artist/Assets.xcassets/AccentColor.colorset/Contents.json`

**Step 1: Set the accent color to Coral Orange (#F2784B)**

Replace the contents of the file with:
```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.294",
          "green" : "0.471",
          "red" : "0.949"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

Note: RGB values for `#F2784B` are R=0.949, G=0.471, B=0.294.

**Step 2: Build to verify**

Run: `xcodebuild build -project "Little Artist.xcodeproj" -scheme "Little Artist" -destination "platform=iOS Simulator,name=iPhone 16" -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add "Little Artist/Assets.xcassets/AccentColor.colorset/Contents.json"
git commit -m "feat: set AccentColor to coral-orange #F2784B"
```

---

### Task 3: Update OnboardingView.swift

**Files:**
- Modify: `Little Artist/Views/OnboardingView.swift`

**Changes:**
1. Replace `private let accentColor = Color.orange` with `Brand.primary`
2. Replace all `accentColor` references with `Brand.primary`
3. Update typography to use `Brand.displayFont` for headlines
4. Replace `Color.gray.opacity(0.3)` with `Brand.warmGray.opacity(0.3)` for inactive dots
5. Replace `.font(.headline)` with `Brand.headlineFont`
6. Replace `.font(.subheadline)` and `.font(.subheadline.weight(.medium))` with `Brand.subheadlineFont`
7. Replace `Color.orange.opacity(0.08)` and `.opacity(0.15)` gradient with `Brand.primary.opacity(0.08)` / `Brand.primary.opacity(0.15)`
8. Replace hardcoded `.font(.system(size: 32, weight: .bold))` with `Brand.displayFont`

**Step 1: Make all replacements in OnboardingView.swift**

Remove the `private let accentColor` property. Replace every `accentColor` with `Brand.primary`. Replace font references with Brand tokens. Replace gray with Brand.warmGray.

**Step 2: Build to verify**

Run: `xcodebuild build -project "Little Artist.xcodeproj" -scheme "Little Artist" -destination "platform=iOS Simulator,name=iPhone 16" -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add "Little Artist/Views/OnboardingView.swift"
git commit -m "refactor: apply brand tokens to OnboardingView"
```

---

### Task 4: Update AddChildView.swift

**Files:**
- Modify: `Little Artist/Views/AddChildView.swift`

**Changes:**
1. Replace `@State private var selectedColor = "FF8C00"` with `@State private var selectedColor = Brand.defaultAvatarColor`
2. Replace the `presetColors` array with `Brand.avatarColors`
3. Replace all `Color.orange` / `.orange` with `Brand.primary`
4. Replace `Color.orange.opacity(0.12)` with `Brand.primaryTint`
5. Replace `Color.gray` (disabled state) with `Brand.disabled`
6. Replace `.shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)` with `.brandCardShadow()`
7. Replace `.font(.system(size: 48, weight: .bold))` with `.font(.system(size: 48, weight: .bold, design: .rounded))`
8. Replace `.font(.title3)` with `.font(Brand.title3Font)`
9. Replace `.font(.headline)` with `.font(Brand.headlineFont)`
10. Replace `.font(.subheadline)` with `.font(Brand.subheadlineFont)`
11. Replace `.font(.caption.bold())` with `.font(Brand.captionFont.bold())`
12. Replace `.font(.caption)` with `.font(Brand.captionFont)`
13. Replace `.font(.system(size: 20))` with `.font(.system(size: 20, design: .rounded))`
14. Replace `.foregroundStyle(.white, .red)` on xmark with `.foregroundStyle(.white, Brand.dustyRose)`
15. Replace `Color(.secondarySystemBackground)` in text fields with `Brand.surface`
16. Replace `.background(Color(.secondarySystemBackground))` with `.background(Brand.surface)`

**Step 1: Apply all replacements**

**Step 2: Build to verify**

Run: `xcodebuild build -project "Little Artist.xcodeproj" -scheme "Little Artist" -destination "platform=iOS Simulator,name=iPhone 16" -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add "Little Artist/Views/AddChildView.swift"
git commit -m "refactor: apply brand tokens to AddChildView"
```

---

### Task 5: Update EditChildView.swift

**Files:**
- Modify: `Little Artist/Views/EditChildView.swift`

**Changes:** Same pattern as AddChildView — this file mirrors AddChildView closely.
1. Replace `presetColors` array with `Brand.avatarColors`
2. Replace all `Color.orange` / `.orange` with `Brand.primary`
3. Replace `Color.orange.opacity(0.12)` with `Brand.primaryTint`
4. Replace `Color.gray` (disabled state) with `Brand.disabled`
5. Replace `.shadow(color: .black.opacity(0.08), ...)` with `.brandCardShadow()`
6. Replace `.foregroundStyle(.white, .red)` with `.foregroundStyle(.white, Brand.dustyRose)`
7. Replace `Color.red` stroke with `Brand.dustyRose`
8. Replace font references with Brand tokens
9. Replace `Color(.secondarySystemBackground)` with `Brand.surface`

**Step 1: Apply all replacements**

**Step 2: Build to verify**

Run: `xcodebuild build -project "Little Artist.xcodeproj" -scheme "Little Artist" -destination "platform=iOS Simulator,name=iPhone 16" -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add "Little Artist/Views/EditChildView.swift"
git commit -m "refactor: apply brand tokens to EditChildView"
```

---

### Task 6: Update AddArtworkView.swift

**Files:**
- Modify: `Little Artist/Views/AddArtworkView.swift`

**Changes:**
1. Replace all `Color.orange` / `.orange` with `Brand.primary`
2. Replace `Color.orange.opacity(0.12)` with `Brand.primaryTint`
3. Replace `Color.gray` (disabled state) with `Brand.disabled`
4. Replace `.tint(.orange)` with `.tint(Brand.primary)`
5. Replace shadow with `.brandCardShadow()`
6. Replace font references with Brand tokens
7. Replace `Color(.secondarySystemBackground)` with `Brand.surface`
8. Replace `.font(.system(size: 48))` placeholder icon with `.font(.system(size: 48, design: .rounded))`
9. Replace `.font(.system(size: 20))` source button icon with `.font(.system(size: 20, design: .rounded))`

**Step 1: Apply all replacements**

**Step 2: Build to verify**

Run: `xcodebuild build -project "Little Artist.xcodeproj" -scheme "Little Artist" -destination "platform=iOS Simulator,name=iPhone 16" -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add "Little Artist/Views/AddArtworkView.swift"
git commit -m "refactor: apply brand tokens to AddArtworkView"
```

---

### Task 7: Update Components (ChildAvatarView, AddArtworkButton, AddChildButton, YearChipView, ArtworkThumbnailView)

**Files:**
- Modify: `Little Artist/Components/ChildAvatarView.swift`
- Modify: `Little Artist/Components/AddArtworkButton.swift`
- Modify: `Little Artist/Components/AddChildButton.swift`
- Modify: `Little Artist/Components/YearChipView.swift`
- Modify: `Little Artist/Components/ArtworkThumbnailView.swift`

**Changes per file:**

**ChildAvatarView.swift:**
1. Replace `Color.orange` ring with `Brand.primary`
2. Replace `.shadow(color: .black.opacity(0.06), ...)` with `.brandAvatarShadow()`
3. Replace `.font(.caption)` with `.font(Brand.captionFont)`
4. Replace `.font(.system(size: 26, weight: .bold))` with `.font(.system(size: 26, weight: .bold, design: .rounded))`

**AddArtworkButton.swift:**
1. Replace `Color.orange` background with `Brand.primary`
2. Replace `.shadow(color: .orange.opacity(0.4), ...)` with `.brandFABShadow()`

**AddChildButton.swift:**
1. Replace `Color.orange.opacity(0.5)` with `Brand.primary.opacity(0.5)`
2. Replace `.foregroundStyle(.orange)` with `.foregroundStyle(Brand.primary)`
3. Replace `.font(.caption)` with `.font(Brand.captionFont)`

**YearChipView.swift:**
1. Replace `Color.orange` selected with `Brand.primary`
2. Replace `Color(.tertiarySystemFill)` unselected with `Brand.softTan.opacity(0.5)`

**ArtworkThumbnailView.swift:**
1. Replace shadow with `.brandCardShadow()` (consolidate two-layer shadow to single brand shadow for consistency)
2. Replace `.font(.subheadline.weight(.semibold))` with `.font(Brand.subheadlineFont.weight(.semibold))`
3. Replace `.font(.caption2)` with `.font(Brand.caption2Font)`

**Step 1: Apply all changes across the 5 component files**

**Step 2: Build to verify**

Run: `xcodebuild build -project "Little Artist.xcodeproj" -scheme "Little Artist" -destination "platform=iOS Simulator,name=iPhone 16" -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add "Little Artist/Components/"
git commit -m "refactor: apply brand tokens to all components"
```

---

### Task 8: Update Empty State Views (NoChildrenView, NoArtworkView)

**Files:**
- Modify: `Little Artist/Views/NoChildrenView.swift`
- Modify: `Little Artist/Views/NoArtworkView.swift`

**Changes:**

**NoChildrenView.swift:**
1. Replace `.foregroundStyle(.orange.opacity(0.6))` with `.foregroundStyle(Brand.primary.opacity(0.6))`
2. Replace `.background(Color.orange)` button with `.background(Brand.primary)`
3. Replace `.font(.system(size: 60))` with `.font(.system(size: 60, design: .rounded))`
4. Replace `.font(.title3.weight(.semibold))` with `.font(Brand.title3Font)`
5. Replace `.font(.subheadline)` with `.font(Brand.subheadlineFont)`
6. Replace `.font(.headline)` with `.font(Brand.headlineFont)`

**NoArtworkView.swift:**
1. Replace `.foregroundStyle(.orange.opacity(0.6))` with `.foregroundStyle(Brand.primary.opacity(0.6))`
2. Replace `.font(.system(size: 60))` with `.font(.system(size: 60, design: .rounded))`
3. Replace `.font(.title3.weight(.semibold))` with `.font(Brand.title3Font)`
4. Replace `.font(.subheadline)` with `.font(Brand.subheadlineFont)`

**Step 1: Apply changes to both files**

**Step 2: Build to verify**

Run: `xcodebuild build -project "Little Artist.xcodeproj" -scheme "Little Artist" -destination "platform=iOS Simulator,name=iPhone 16" -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add "Little Artist/Views/NoChildrenView.swift" "Little Artist/Views/NoArtworkView.swift"
git commit -m "refactor: apply brand tokens to empty state views"
```

---

### Task 9: Update ArtworkGalleryView.swift and ArtworkDetailView.swift

**Files:**
- Modify: `Little Artist/Views/ArtworkGalleryView.swift`
- Modify: `Little Artist/Views/ArtworkDetailView.swift`

**Changes:**

**ArtworkGalleryView.swift:**
1. Replace `.foregroundStyle(.orange)` count badge with `.foregroundStyle(Brand.primary)`
2. Replace `Color.orange.opacity(0.12)` badge background with `Brand.primaryTint`
3. Replace `.font(.title2.weight(.bold))` with `.font(Brand.title2Font)`

**ArtworkDetailView.swift:**
1. Replace `.foregroundStyle(.orange.opacity(0.35))` with `.foregroundStyle(Brand.primary.opacity(0.35))`
2. Replace `.font(.title2.weight(.bold))` with `.font(Brand.title2Font)`
3. Replace `.font(.system(size: 52))` with `.font(.system(size: 52, design: .rounded))`

**Step 1: Apply changes to both files**

**Step 2: Build to verify**

Run: `xcodebuild build -project "Little Artist.xcodeproj" -scheme "Little Artist" -destination "platform=iOS Simulator,name=iPhone 16" -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add "Little Artist/Views/ArtworkGalleryView.swift" "Little Artist/Views/ArtworkDetailView.swift"
git commit -m "refactor: apply brand tokens to gallery and detail views"
```

---

### Task 10: Update Onboarding Animation Components

**Files:**
- Modify: `Little Artist/Views/Onboarding/IconCard.swift`
- Modify: `Little Artist/Views/Onboarding/AnimatedCardsView.swift`

**Changes:**

**IconCard.swift:**
1. Replace `.fill(.white)` background with `.fill(Brand.surface)`
2. Replace `.shadow(color: .black.opacity(0.08), ...)` with `.brandCardShadow()`
3. Replace `color: .orange` in Preview with `color: Brand.primary`

**AnimatedCardsView.swift:**
1. Replace `Color.orange.opacity(0.08)` in Preview with `Brand.primary.opacity(0.08)`

**Step 1: Apply changes**

**Step 2: Build to verify**

Run: `xcodebuild build -project "Little Artist.xcodeproj" -scheme "Little Artist" -destination "platform=iOS Simulator,name=iPhone 16" -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add "Little Artist/Views/Onboarding/"
git commit -m "refactor: apply brand tokens to onboarding animation components"
```

---

### Task 11: Update CLAUDE.md with new token references

**Files:**
- Modify: `CLAUDE.md`

**Changes:**
Update the Design Tokens section to reference `BrandTokens.swift` and use the new color values. Replace the old `#FF8C00` references with the new `#F2784B` coral-orange. Add a note about always using `Brand.*` tokens instead of hardcoded values.

Key updates:
1. Update the color table to reflect the new palette
2. Add a note: "IMPORTANT: Always use `Brand.*` tokens from `Utilities/BrandTokens.swift`. Never hardcode color, font, shadow, or spacing values."
3. Update the avatar palette to the new 7 colors
4. Update typography section to reference `Brand.displayFont`, etc.
5. Update shadow section to reference `.brandCardShadow()`, etc.

**Step 1: Update CLAUDE.md**

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md with new brand token references"
```

---

### Task 12: Final verification build

**Files:** None (verification only)

**Step 1: Clean build**

Run: `xcodebuild clean build -project "Little Artist.xcodeproj" -scheme "Little Artist" -destination "platform=iOS Simulator,name=iPhone 16" -quiet 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 2: Verify no remaining hardcoded orange references**

Run: `grep -rn "Color\.orange\|\.orange\b" "Little Artist/" --include="*.swift" | grep -v "Brand\." | grep -v "//"`
Expected: No results (all `.orange` replaced with `Brand.primary`)

Run: `grep -rn "FF8C00" "Little Artist/" --include="*.swift"`
Expected: No results (old hex completely removed)

**Step 3: Verify no remaining hardcoded shadows**

Run: `grep -rn "\.shadow(color: \.black" "Little Artist/" --include="*.swift"`
Expected: Only the `ShadowModifier` in `BrandTokens.swift`

**Step 4: Review all changes**

Run: `git diff --stat HEAD~12` to see all files changed across the implementation.

---

## Summary of Files Changed

| # | File | Action |
|---|------|--------|
| 1 | `Little Artist/Utilities/BrandTokens.swift` | **Create** — centralized tokens |
| 2 | `Little Artist/Assets.xcassets/AccentColor.colorset/Contents.json` | **Modify** — set coral-orange |
| 3 | `Little Artist/Views/OnboardingView.swift` | **Modify** — tokens + SF Rounded |
| 4 | `Little Artist/Views/AddChildView.swift` | **Modify** — tokens + avatar palette |
| 5 | `Little Artist/Views/EditChildView.swift` | **Modify** — tokens + avatar palette |
| 6 | `Little Artist/Views/AddArtworkView.swift` | **Modify** — tokens |
| 7 | `Little Artist/Components/ChildAvatarView.swift` | **Modify** — tokens |
| 8 | `Little Artist/Components/AddArtworkButton.swift` | **Modify** — tokens |
| 9 | `Little Artist/Components/AddChildButton.swift` | **Modify** — tokens |
| 10 | `Little Artist/Components/YearChipView.swift` | **Modify** — tokens |
| 11 | `Little Artist/Components/ArtworkThumbnailView.swift` | **Modify** — tokens |
| 12 | `Little Artist/Views/NoChildrenView.swift` | **Modify** — tokens |
| 13 | `Little Artist/Views/NoArtworkView.swift` | **Modify** — tokens |
| 14 | `Little Artist/Views/ArtworkGalleryView.swift` | **Modify** — tokens |
| 15 | `Little Artist/Views/ArtworkDetailView.swift` | **Modify** — tokens |
| 16 | `Little Artist/Views/Onboarding/IconCard.swift` | **Modify** — tokens |
| 17 | `Little Artist/Views/Onboarding/AnimatedCardsView.swift` | **Modify** — tokens |
| 18 | `CLAUDE.md` | **Modify** — updated references |

**Total:** 1 new file, 17 modified files, 12 commits
