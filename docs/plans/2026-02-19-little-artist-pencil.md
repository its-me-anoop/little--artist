# Little Artist Pencil Design File Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a faithful high-fidelity Pencil (.pen) design file reproducing all 12 Little Artist iOS app screens at iPhone 375×812.

**Architecture:** Open a new Pencil document, set global design variables (orange accent, typography), then build each screen as a top-level frame. Each screen is built with `batch_design`, validated with `get_screenshot`, and committed incrementally. No reusable components—YAGNI, since this is a single design document.

**Tech Stack:** Pencil MCP tools (`open_document`, `set_variables`, `batch_design`, `batch_get`, `get_screenshot`, `snapshot_layout`, `get_style_guide`)

**Design Spec:** `docs/plans/2026-02-19-pencil-design.md`

---

### Task 1: Open document and set design variables

**Files:**
- Create: `Little Artist.pen` (via Pencil MCP — place in project root)

**Step 1: Get style guide tags then fetch a matching style guide**

Call `get_style_guide_tags`, then call `get_style_guide` with tags that match:
- child-friendly, colorful, mobile, iOS, clean, minimal, warm, orange

Note the style guide name/fonts for use in later tasks.

**Step 2: Open a new Pencil document**

Call `open_document("new")`. Note the file path returned — use it for all subsequent calls.

**Step 3: Set global design variables**

Call `set_variables` with:
```json
{
  "accent": "#FF8C00",
  "accentLight": "#FF8C001F",
  "textPrimary": "#1C1C1E",
  "textSecondary": "#8A8A8E",
  "bgPrimary": "#FFFFFF",
  "bgSecondary": "#F2F2F7",
  "bgTertiary": "#E5E5EA",
  "bgGrouped": "#F2F2F7",
  "bgCard": "#FFFFFF",
  "shadowColor": "#00000020",
  "cornerCard": 18,
  "cornerImage": 12,
  "cornerSheet": 20,
  "screenW": 375,
  "screenH": 812
}
```

**Step 4: Commit**

```bash
git add "Little Artist.pen"
git commit -m "design: init Pencil file with design variables"
```

---

### Task 2: Onboarding Page 1 — "Preserve the Magic"

**Files:**
- Modify: `Little Artist.pen`

**Step 1: Get design guidelines**

Call `get_guidelines(topic="design-system")` to understand layout rules before building.

**Step 2: Build the screen**

Call `batch_design` to create a frame named "Onboarding 1" (375×812).

Structure (top to bottom):
1. **Background**: white fill, full frame
2. **Illustration area** (h=340, padding h=16):
   - Rounded rect, cornerRadius=40, linear gradient fill from `#FF8C001F` (top) to `#FF8C00` at 26% opacity (bottom)
   - Three icon cards layered/offset to imply drift motion:
     - Card 1 (bottom, slightly left): white rounded rect (100×100, r=20), shadow, `paintpalette.fill` icon (orange, 40pt) centered
     - Card 2 (middle): white rounded rect (100×100, r=20), shadow, `figure.child` icon (orange, 40pt) centered
     - Card 3 (top, slightly right): white rounded rect (100×100, r=20), shadow, `scribble.variable` icon (orange, 40pt) centered
   - "Skip" text button top-right (orange, subheadline weight medium), padding trailing=36, top=16
3. **Spacer** h=36
4. **Title block** (centred):
   - "Preserve the" — 32pt bold, primary color
   - "Magic" — 32pt bold, orange `#FF8C00`
5. **Spacer** h=16
6. **Description** (centred, subheadline, secondary, h-padding=40):
   "Never lose a precious drawing again. Digitally archive and share your child's masterpieces in one safe place."
7. **Spacer** (flex)
8. **Page indicator** (centred, HStack spacing=6):
   - Dot 1: capsule 24×8, orange fill (active)
   - Dots 2–5: circle 8×8, gray 30% opacity
9. **Spacer** h=24
10. **CTA button** (h-padding=32, bottom=48):
    - Capsule button, full width, orange fill, "Next →" white headline text, height=56

**Step 3: Take screenshot and verify**

Call `get_screenshot` on the "Onboarding 1" frame. Verify:
- Orange gradient illustration area at top
- Three layered icon cards
- "Skip" top right
- Two-line bold title with orange second line
- Description text
- Page indicator with active pill
- Orange "Next →" button at bottom

**Step 4: Commit**

```bash
git add "Little Artist.pen"
git commit -m "design: add Onboarding Page 1 - Preserve the Magic"
```

---

### Task 3: Onboarding Pages 2–5

**Files:**
- Modify: `Little Artist.pen`

**Step 1: Copy and adapt Page 1 four times**

For each page, call `batch_design` to copy the "Onboarding 1" frame and update:

| Frame name | Icons | Title line 1 | Title line 2 | Description | CTA | Skip visible |
|-----------|-------|-------------|-------------|-------------|-----|-------------|
| Onboarding 2 | camera.fill, photo.stack, rectangle.portrait.on.rectangle.portrait.angled.fill | Capture Every | Creation | "Snap photos of drawings, paintings, and crafts. Build a beautiful gallery of your child's creativity over time." | Next → | yes |
| Onboarding 3 | sparkles, text.quote, wand.and.stars | AI-Powered | Captions | "Let AI generate fun titles and captions for each artwork, capturing the magic and story behind every creation." | Next → | yes |
| Onboarding 4 | mic.fill, waveform, play.circle.fill | Add Voice | Notes | "Let your child record a voice note describing their artwork. Preserve their words and imagination forever." | Next → | yes |
| Onboarding 5 | square.and.arrow.up.fill, heart.fill, person.2.fill | Share & | Celebrate | "Share artwork with family and friends. Let everyone celebrate your little artist's wonderful creations." | Get Started | no (hidden) |

For each page, update the active page indicator dot (e.g. page 2 → dot 2 is the orange pill, rest are gray circles).

**Step 2: Screenshot Page 5 to verify "Get Started" variant**

Call `get_screenshot` on "Onboarding 5". Verify no Skip button, "Get Started" CTA, last dot active.

**Step 3: Commit**

```bash
git add "Little Artist.pen"
git commit -m "design: add Onboarding Pages 2-5"
```

---

### Task 4: Home — With Children & Artwork

**Files:**
- Modify: `Little Artist.pen`

**Step 1: Build the frame**

Call `batch_design` to create "Home - With Data" (375×812).

Structure:
1. **Status bar area**: h=44, empty (represents iOS status bar)
2. **Navigation bar** (h=44):
   - "Little Artist" title, 17pt semibold, centred
3. **Child Avatar Slider** (h=96, top-padding=8):
   - Horizontal scroll container with h-padding=20, v-padding=8
   - Child 1 (selected): orange circle ø60, "E" white bold 24pt, 3pt orange ring (use stroke)
   - Child 2: green (#6BCB77) circle ø60, "L" white bold 24pt
   - Child 3: blue (#4D96FF) circle ø60, "N" white bold 24pt
   - Below each: child name caption, 11pt, secondary
   - "+" button: 60×60 circle, bgSecondary fill, "+" SF icon 20pt, secondary color
4. **Divider** (1pt, top-margin=12)
5. **Gallery content** (ScrollView, top-padding=12):
   - Year chips row (h-scroll, h-padding=20):
     - "2025" chip: orange fill, white text, capsule, padding h=16 v=8, 14pt medium
     - "2024" chip: bgSecondary fill, primary text, same sizing
   - "2025" year label: title2 bold, padding h=20, top=8
   - **February section**:
     - Month header HStack: "February" headline + count badge "3" (orange text, 12% orange bg, capsule, padding h=8 v=2, caption weight medium)
     - Padding h=20
     - Horizontal scroll, h-padding=20, v-padding=20:
       - 3× `ArtworkThumbnailCard` (see below), spacing=16
   - **January section**: same pattern, "January" + badge "5"
     - Horizontal scroll with 3 visible cards
6. **FAB** (bottom-right, trailing=20, bottom=20):
   - Orange circle ø56, camera.fill SF icon white 20pt, shadow

**ArtworkThumbnailCard** (180pt wide, used inline):
- Outer: padding=8, cornerRadius=18, white fill, shadow (black 12% opacity, blur=14, y=6)
- Image area: 164×180, cornerRadius=12, bgTertiary fill, paintpalette icon orange 30% (placeholder)
- Info: padding h=12, top=10, bottom=12
  - Title: "Butterfly Garden" subheadline semibold
  - Date row: calendar icon (10pt) + "Feb 3" caption2, secondary

**Step 2: Screenshot and verify**

Call `get_screenshot`. Verify child avatar strip with selected state, year chips, month sections with badges, thumbnail cards, FAB.

**Step 3: Commit**

```bash
git add "Little Artist.pen"
git commit -m "design: add Home screen with children and artwork"
```

---

### Task 5: Home — Empty States (No Children & No Artwork)

**Files:**
- Modify: `Little Artist.pen`

**Step 1: Build "Home - No Children" (375×812)**

Call `batch_design`:
1. Status bar + nav bar (same as Task 4)
2. Child slider: only the "+" add button (same style as Task 4)
3. Divider
4. **Empty state** (centred, fills remaining height):
   - `figure.child` SF icon, 72pt, orange 30% opacity
   - "No little artists yet" title2 bold, top=24
   - "Tap + to add your first child" subheadline secondary, top=8, h-padding=40
   - Orange outlined capsule button "Add Child", padding h=32 v=16, top=32 (orange stroke 1.5pt, orange text)

**Step 2: Build "Home - No Artwork" (375×812)**

Call `batch_design`:
1. Status bar + nav bar
2. Child slider with selected child (Emma, orange ring) and "+" button
3. Divider
4. **Empty state**:
   - `paintpalette` SF icon, 72pt, orange 30% opacity
   - "No artwork yet" title2 bold, top=24
   - "Tap + to capture their first masterpiece" subheadline secondary, top=8, h-padding=40
5. FAB (bottom-right) — orange camera button still visible

**Step 3: Screenshot both and verify**

**Step 4: Commit**

```bash
git add "Little Artist.pen"
git commit -m "design: add Home empty state screens"
```

---

### Task 6: Add Child Sheet

**Files:**
- Modify: `Little Artist.pen`

**Step 1: Build "Add Child" (375×812)**

This is presented as a modal sheet. Frame represents the sheet at full height.

Call `batch_design`:
1. **Navigation bar** (inline style):
   - "Cancel" text button, left, orange subheadline
   - "New Little Artist" title, 17pt semibold, centred
2. **Scroll content** (VStack spacing=28, top=8):
   - **Avatar preview** (centred):
     - Circle ø110, orange fill (#FF8C00), "E" white 48pt bold
     - Shadow: black 8% opacity, blur=12, y=6
   - **Photo source buttons** (HStack spacing=16, centred):
     - Camera: orange camera.fill icon in 56×56 orange-tint rounded rect (r=16) + "Camera" caption below
     - Gallery: orange photo.on.rectangle.angled in same container + "Gallery"
     - Create: orange apple.image.playground icon + "Create" (slightly dimmed to suggest optional)
   - **Name field**: "Child's name" placeholder, title3, centred, rounded rect bg (bgSecondary, r=14), padding v=14 h=24, h-margin=40
   - **Color picker**:
     - "Pick a color" subheadline secondary, centred
     - HStack spacing=14: 7 circles ø40 in colors: #FF6B6B, #FF8C00 (selected — white checkmark overlay), #FFD93D, #6BCB77, #4D96FF, #9B59B6, #FF6B9D
   - **Save button**: full-width orange capsule, "Add Child" headline white, padding v=18, h-margin=32

**Step 2: Screenshot and verify**

**Step 3: Commit**

```bash
git add "Little Artist.pen"
git commit -m "design: add Add Child sheet"
```

---

### Task 7: Add Artwork Sheet

**Files:**
- Modify: `Little Artist.pen`

**Step 1: Build "Add Artwork - Empty" (375×812)**

Call `batch_design`:
1. **Navigation bar**: "Cancel" left, "New Artwork" centred, no right button
2. **Scroll area**:
   - **Image placeholder**: rounded rect h=220, bgTertiary fill, cornerRadius=20, h-margin=32
     - Centred: paintpalette icon 48pt orange 40% + "Capture or select artwork" subheadline secondary below
   - **Capture buttons** (HStack spacing=16, centred, top=24):
     - Camera / Gallery / Scan — same 56×56 orange-tint icon button style as Add Child
3. **Bottom pinned area** (bgPrimary, top-padding=16, bottom=16):
   - "Artwork title (optional)" text field (centred, title3, bgSecondary bg, r=14, v=14, h=24, margin=32)
   - "Caption (optional)" multiline text field (body, bgSecondary bg, r=14, v=12, h=16, margin=32)
   - "Suggest Title & Caption" button (sparkles icon + text, orange text, 12% orange bg, r=12, full-width, h-margin=32)
   - "Save Artwork" capsule button — **greyed** (Color.gray fill since no image), "Save Artwork" headline white, h-margin=32

**Step 2: Build "Add Artwork - With Image" (375×812)**

Copy the frame and update:
- Replace placeholder with an actual image (use `G(nodeId, "stock", "child artwork drawing colorful")` to get a stock photo)
- Remove xmark badge on image top-right (red circle)
- "Save Artwork" button: **orange** fill (active state)

**Step 3: Screenshot both and verify**

**Step 4: Commit**

```bash
git add "Little Artist.pen"
git commit -m "design: add Add Artwork sheet (empty + with image states)"
```

---

### Task 8: Artwork Detail

**Files:**
- Modify: `Little Artist.pen`

**Step 1: Build "Artwork Detail" (375×812)**

Call `batch_design`:
1. **Navigation bar**:
   - Back arrow + "Artwork" title inline
   - `···` (ellipsis.circle) icon button right
2. **Scroll content** (padding=20, bgGrouped background):
   - Full-width image, cornerRadius=20, aspectRatio ~4:3 (width=335, height ~250)
     - Use `G(nodeId, "stock", "child painting rainbow artwork")` for stock image
   - Title: "Butterfly Garden" title2 bold, top=16, full width leading
   - Caption: "Emma painted this during our garden walk. She said the butterflies were dancing!" body, secondary, top=8, full width leading
3. **Background**: bgGrouped (#F2F2F7) fills the frame

**Step 2: Screenshot and verify**

Verify full-width artwork image, title, caption on grouped background, ellipsis toolbar button.

**Step 3: Commit**

```bash
git add "Little Artist.pen"
git commit -m "design: add Artwork Detail screen"
```

---

### Task 9: Artwork Gallery (standalone view)

**Files:**
- Modify: `Little Artist.pen`

**Step 1: Build "Artwork Gallery" (375×812)**

This represents the standalone gallery with multiple year sections visible.

Call `batch_design`:
1. **Status bar** (h=44)
2. **Navigation bar**: "Little Artist" title + back arrow (representing nav stack context)
3. **Gallery scroll** (LazyVStack, spacing=24, top=12):
   - Year chips row: "2025" (orange, active), "2024", "2023" (bgSecondary)
   - "2025" year heading (title2 bold, h=20, top=8)
   - **March section**: "March" headline + "2" orange badge → horizontal strip of 2 thumbnail cards
   - **February section**: "February" + "5" badge → horizontal strip showing 3 cards + partial 4th
   - **January section**: "January" + "3" badge → horizontal strip of 3 cards
   - **Load more indicator** (if visible): subtle centered text "Loading more..." secondary

**Step 2: Screenshot and verify**

**Step 3: Commit**

```bash
git add "Little Artist.pen"
git commit -m "design: add Artwork Gallery standalone screen"
```

---

### Task 10: Final review and canvas tidy

**Files:**
- Modify: `Little Artist.pen`

**Step 1: Check layout of all frames on canvas**

Call `snapshot_layout(maxDepth=0)` to see all top-level frames and their positions.

**Step 2: Arrange frames in logical flow order**

Call `batch_design` to `M()` (move) frames into a left-to-right reading order:
```
Row 1: Onboarding 1 → 2 → 3 → 4 → 5
Row 2: Home-With Data | Home-No Children | Home-No Artwork
Row 3: Add Child | Add Artwork (empty) | Add Artwork (with image)
Row 4: Artwork Detail | Artwork Gallery
```

Space frames ~60pt apart horizontally and ~80pt apart between rows.

**Step 3: Full canvas screenshot**

Call `get_screenshot` on the root/document node (or the largest encompassing frame) to get an overview.

**Step 4: Final commit**

```bash
git add "Little Artist.pen"
git commit -m "design: arrange all screens in flow order, complete Pencil file"
```

---

## Screen Inventory Checklist

| # | Screen | Status |
|---|--------|--------|
| 1 | Onboarding 1 — Preserve the Magic | |
| 2 | Onboarding 2 — Capture Every Creation | |
| 3 | Onboarding 3 — AI-Powered Captions | |
| 4 | Onboarding 4 — Add Voice Notes | |
| 5 | Onboarding 5 — Share & Celebrate | |
| 6 | Home — With Children & Artwork | |
| 7 | Home — No Children | |
| 8 | Home — No Artwork | |
| 9 | Add Child Sheet | |
| 10 | Add Artwork — Empty | |
| 11 | Add Artwork — With Image | |
| 12 | Artwork Detail | |
| 13 | Artwork Gallery (standalone) | |

---

## Design Rules Summary

- **Never** hardcode dimensions smaller than 44pt for tappable elements
- **Always** use `bgSecondary` (`#F2F2F7`) for input field backgrounds, not pure white
- **Always** validate each screen with `get_screenshot` before committing
- Orange `#FF8C00` is the single accent — do not introduce secondary accent colors
- Shadows: `black 10-12% opacity, blur 12-14pt, y=6` for cards; `black 8%, blur=12, y=6` for avatars
- Font sizes: 32pt onboarding title, 17pt nav bar, title2 (22pt) for screen titles, subheadline (15pt) for descriptions
