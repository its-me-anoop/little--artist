# Little Artist — Pencil Design File

**Date:** 2026-02-19
**Approach:** Faithful High-Fidelity Recreation
**Device:** iPhone 375×812 (standard)
**Scope:** Full app flow — all screens

---

## Design Tokens

| Token | Value |
|-------|-------|
| Accent | `#FF8C00` (orange) |
| Background | System white |
| Secondary text | Gray |
| Orange tint fill | `#FF8C00` at 12% opacity |
| Card corner radius | 12–18pt |
| Sheet corner radius | 20pt |
| Button corner radius | Capsule (fully rounded) |
| Card shadow | black 10–12% opacity, blur 12–14pt |

---

## Screens

### 1–5. Onboarding Pages (5 screens)

**Layout:**
- Top half (h=340): soft orange linear gradient rounded rectangle (cornerRadius 40, padding 16)
- Three layered icon cards representing page content, animated entrance implied by card arrangement
- Skip button (orange, top-right) — hidden on page 5
- `TabView`-style page indicator: active dot is pill (24×8), inactive dots are circles (8×8), gray at 30% opacity
- Large bold title (32pt, 2 lines): first line primary, second line orange
- Body description (subheadline, secondary, centred, h-padding 40)
- Full-width orange capsule CTA button ("Next →" on pages 1–4, "Get Started" on page 5)

**Pages:**

| # | Icons | Title | Animation style |
|---|-------|-------|-----------------|
| 1 | palette, child-figure, scribble | Preserve the **Magic** | Drift (layered offset) |
| 2 | camera, photo-stack, angled-rect | Capture Every **Creation** | Fan (fanned arc) |
| 3 | sparkles, text-quote, wand | AI-Powered **Captions** | Drop (falling in) |
| 4 | mic, waveform, play-circle | Add Voice **Notes** | Pulse (scale ripple) |
| 5 | share, heart, people | Share & **Celebrate** | Scatter (exploded) |

---

### 6. Home — With Children & Artwork

**Navigation bar:** title "Little Artist"

**Child avatar slider** (horizontal scroll, padding 20):
- Colored circles (ø 60), initial letter white bold
- Selected child: orange ring border (3pt)
- "+" add button at end

**Divider** (top padding 12)

**Artwork gallery** (LazyVStack, spacing 24, padding top 12):
- Year chips row (horizontal scroll): pill chips, selected = orange fill + white text, unselected = gray tint
- Year label ("2025", title2 bold, padding h-20)
- Per month: month name (headline) + orange count badge (caption, orange text on 12% orange bg, capsule)
- Horizontal artwork strip: `ArtworkThumbnailView` cards (see component below)

**FAB** (bottom-right, padding 20): orange circle, "+" or camera icon

---

### 7. Home — No Children (Empty State)

Same nav bar and avatar slider (only "+" button). Central empty state:
- Large paintbrush SF symbol, orange tint
- "No little artists yet" heading
- "Tap + to add your first child" subtitle
- Orange outlined "Add Child" capsule button

---

### 8. Home — No Artwork (Empty State)

Child selected in slider. Gallery area:
- Paintpalette SF symbol, orange tint
- "No artwork yet" heading
- "Tap + to capture their first masterpiece" subtitle

---

### 9. Add Child Sheet

**Nav bar:** "New Little Artist" (inline), Cancel button

**Content (VStack, spacing 28):**
- Avatar preview circle (ø 110): orange fill with white initial letter; if custom photo set, shows photo with red xmark badge
- Photo source buttons row (HStack, spacing 16): Camera / Gallery / Create — each is orange SF icon (56×56 rounded rect, 12% fill) + caption label
- Name text field (centred, title3, rounded rect bg, h-padding 40)
- "Pick a color" label + 7 color circles (ø 40, spacing 14) with checkmark overlay on selected
- Orange "Add Child" capsule button (greyed when name empty)

---

### 10. Add Artwork Sheet

**Nav bar:** "New Artwork" (inline), Cancel button

**Top (scroll area):**
- Image placeholder: rounded rect (h=220), paintpalette icon orange 40%, "Capture or select artwork" subtitle
- (When image selected): full-width image, rounded corners, red xmark badge top-right
- Capture source buttons row: Camera / Gallery / Scan — same style as Add Child photo buttons

**Bottom (pinned):**
- "Artwork title" text field (centred, title3, rounded rect)
- "Caption" multiline text field (body, rounded rect)
- "Suggest Title & Caption" button (sparkles icon, orange text, orange 12% bg rounded rect)
- Orange "Save Artwork" capsule button (greyed when no image)

---

### 11. Artwork Gallery (standalone)

Full-screen scroll view showing multiple year sections:
- Year chip filter row at top
- Year heading
- Multiple month groups, each with month name + count badge + horizontal thumbnail strip

---

### 12. Artwork Detail

**Nav bar:** "Artwork" (inline), `···` ellipsis menu (Share / Edit / Delete)

**Content (ScrollView, padding 20):**
- Full-width artwork image, scaledToFit, cornerRadius 20
- Title (title2 bold)
- Caption body text (secondary)

**Background:** systemGroupedBackground (light gray)

---

## Artwork Thumbnail Card Component

- Outer card: padding 8, cornerRadius 18, secondarySystemGroupedBackground fill, subtle shadow
- Image area: 164×180, scaledToFill, clipped, cornerRadius 12
- Placeholder: orange palette icon at 30% opacity
- Info row below: title (subheadline semibold, 1 line) + date (calendar icon + "MMM d", caption2, secondary)
- Total card footprint: ~180pt wide

---

## Child Avatar Component

- Circle ø 60, filled with child's color hex
- White initial letter (title2 bold)
- Custom photo: scaledToFill clipped to circle
- Selected state: 3pt orange ring + 2pt white gap

