# Little Artist — Brand Identity Design

**Date:** 2026-02-19
**Direction:** "The Art Studio" — Warm & Whimsical
**Scope:** Full brand system (logo, colors, typography, iconography, illustration style, voice)
**Touchpoints:** iOS app, App Store, landing page, social media

---

## 1. Color Palette

### Primary Colors

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| **Primary** | Coral Orange | `#F2784B` | CTAs, selected states, FAB, key highlights |
| **Primary Light** | Coral Tint | `#F2784B` at 12% | Badge backgrounds, tinted fills, subtle accents |
| **On-Primary** | White | `#FFFFFF` | Text/icons on primary-colored surfaces |

### Neutral Colors

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| **Background** | Cream | `#FFF8F0` | Main app background |
| **Surface** | Warm White | `#FFFBF7` | Cards, sheets, input fields |
| **Text Primary** | Charcoal | `#3D3D3D` | Headings, body text |
| **Text Secondary** | Warm Gray | `#8A8680` | Subtitles, dates, hints |
| **Divider** | Soft Tan | `#E8E0D8` | Dividers, borders |

### Accent Colors

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| **Accent 1** | Sage Green | `#A8C5A0` | Success states, secondary highlights |
| **Accent 2** | Sky Blue | `#7EB8DA` | Informational, links |
| **Accent 3** | Soft Lavender | `#B8A9D4` | Tertiary accent, tags |
| **Danger** | Dusty Rose | `#D4736C` | Delete, destructive actions |

### Avatar Palette (7 colors)

```
Coral #F2784B  |  Sage #A8C5A0  |  Sky #7EB8DA
Lavender #B8A9D4  |  Sunshine #E8C94A  |  Rose #D4928A  |  Mint #7BC8B5
```

---

## 2. Typography

### System: SF Rounded (headings) + SF Pro (body)

SF Rounded is built into iOS. Headings use the rounded variant for warmth and personality. Body text stays in the system default (SF Pro) for readability.

| Style | Spec | SwiftUI | Usage |
|-------|------|---------|-------|
| **Display** | SF Rounded, 32pt, Bold | `.system(.largeTitle, design: .rounded).bold()` | Onboarding headlines |
| **Title 1** | SF Rounded, 28pt, Bold | `.system(.title, design: .rounded).bold()` | Screen titles |
| **Title 2** | SF Rounded, 22pt, Semibold | `.system(.title2, design: .rounded).weight(.semibold)` | Section headings, year labels |
| **Title 3** | SF Rounded, 20pt, Medium | `.system(.title3, design: .rounded).weight(.medium)` | Sheet titles, input labels |
| **Headline** | SF Rounded, 17pt, Semibold | `.system(.headline, design: .rounded)` | Month names, card titles |
| **Body** | SF Pro, 17pt | `.body` | Descriptions, captions, input text |
| **Subheadline** | SF Pro, 15pt | `.subheadline` | Thumbnail titles, secondary info |
| **Caption** | SF Pro, 12pt | `.caption` | Dates, labels, metadata |

### Text Colors

- Primary text: Charcoal `#3D3D3D`
- Secondary text: Warm Gray `#8A8680`
- Accent text: Coral Orange `#F2784B`
- On-primary text: White `#FFFFFF`

---

## 3. Logo & App Icon

### Wordmark

"Little Artist" in SF Rounded Bold. "Little" in Charcoal `#3D3D3D`, "Artist" in Coral Orange `#F2784B`.

### Brandmark

A simplified paintbrush stroke forming the letter "L" with a small sparkle/star at the tip. Stroke in Coral Orange, sparkle in Sage Green.

### App Icon

- Rounded-square canvas (standard iOS)
- Cream `#FFF8F0` background
- "L" brushstroke brandmark centered, Coral Orange
- Small Sage Green sparkle accent
- Subtle warm shadow for depth
- No text

### Logo Variations

| Variant | Use Case |
|---------|----------|
| **Full lockup** (brandmark + wordmark) | Landing page header, App Store screenshots, social banners |
| **Brandmark only** | App icon, favicon, small social avatars |
| **Wordmark only** | Navigation bar title, email headers |

### Logo Clear Space

Minimum clear space around the logo equals the height of the "L" brandmark on all sides.

---

## 4. Iconography & Illustration Style

### Iconography

- SF Symbols exclusively within the app
- Coral Orange for primary actions, Warm Gray for secondary/inactive
- In marketing materials, icons inside soft rounded squares with Coral Tint fill
- Icon weight: Medium throughout

### Illustration Style ("Soft Studio")

- Rounded, organic shapes with slightly irregular edges (hand-drawn feel)
- Soft textured fills — subtle grain or watercolor wash, not flat solid
- Limited palette: max 3 brand colors + cream background per illustration
- Warm shadows (`#3D3D3D` at 6-8% opacity)
- Illustrations are supportive, not dominant — they frame content, never compete with children's artwork

### Where Illustrations Appear

- Onboarding: gradient area with icon cards
- Empty states: SF Symbol icons with soft background shapes
- App Store: screenshot frames with branded backgrounds
- Landing page: hero section, feature sections

### What This Is NOT

- Not cartoon characters or mascots
- Not realistic/photographic illustrations
- Not flat/geometric minimalism

---

## 5. Brand Voice & Tone

### Personality Traits

| Trait | What it means | What it doesn't mean |
|-------|---------------|----------------------|
| **Warm** | Gentle, encouraging, supportive | Not sentimental or over-emotional |
| **Whimsical** | Playful, delightful, wonder-filled | Not silly, childish, or gimmicky |
| **Celebratory** | Elevates children's creativity | Not performative or competitive |
| **Simple** | Clear, concise, jargon-free | Not dumbed-down or condescending |

### Voice Guidelines

**Headings & CTAs:** Short, active, encouraging.
- "Preserve the Magic" not "Save your children's artwork"
- "Add a Little Artist" not "Create new child profile"
- "Capture a Masterpiece" not "Take photo of artwork"

**Descriptions:** Warm and clear.
- "Every scribble tells a story worth keeping."
- "Your child's creativity deserves a gallery of its own."

**Empty states:** Gentle invitation, not error language.
- "No little artists yet — tap + to add your first"
- "No masterpieces yet — time to capture some magic"

**System messages:** Human and reassuring.
- "Saved!" not "Artwork successfully created"
- "All done" not "Operation completed"

### Words We Use / Avoid

| Use | Avoid |
|-----|-------|
| masterpiece, creation, magic | file, upload, content |
| little artist, creator | user, child (in UI copy) |
| gallery, collection | library, database, storage |
| capture, preserve | save, store, record |
| celebrate, share | export, publish |

---

## 6. Design Tokens (SwiftUI Implementation Reference)

### Colors (to define in code)

```swift
// Primary
static let coralOrange = Color(hex: "#F2784B")
static let coralTint = Color(hex: "#F2784B").opacity(0.12)

// Neutrals
static let cream = Color(hex: "#FFF8F0")
static let warmWhite = Color(hex: "#FFFBF7")
static let charcoal = Color(hex: "#3D3D3D")
static let warmGray = Color(hex: "#8A8680")
static let softTan = Color(hex: "#E8E0D8")

// Accents
static let sageGreen = Color(hex: "#A8C5A0")
static let skyBlue = Color(hex: "#7EB8DA")
static let softLavender = Color(hex: "#B8A9D4")
static let dustyRose = Color(hex: "#D4736C")

// Avatar palette
static let avatarColors = ["#F2784B", "#A8C5A0", "#7EB8DA", "#B8A9D4", "#E8C94A", "#D4928A", "#7BC8B5"]
```

### Corner Radii

| Element | Radius |
|---------|--------|
| Cards | 18pt |
| Images | 12pt |
| Sheets | 20pt |
| Buttons | Capsule |
| Onboarding gradient | 40pt |

### Shadows

```swift
.shadow(color: Color(hex: "#3D3D3D").opacity(0.08), radius: 12, x: 0, y: 6)  // cards
.shadow(color: Color(hex: "#3D3D3D").opacity(0.06), radius: 6, x: 0, y: 3)   // avatars
```

### Spacing

| Token | Value | Usage |
|-------|-------|-------|
| Screen padding | 20pt | Horizontal page margins |
| Section spacing | 24pt | Between major sections |
| Component spacing | 8–16pt | Internal component spacing |
| Divider padding | 12pt | Top padding above dividers |

### Component Sizes

| Component | Size |
|-----------|------|
| Child avatar | 60x60pt |
| Avatar selected ring | 68x68pt, 3pt stroke |
| Photo source buttons | 56x56pt |
| Avatar preview (sheets) | 110x110pt |
| Artwork thumbnail image | 164x180pt |
| Onboarding gradient area | height 340pt |
