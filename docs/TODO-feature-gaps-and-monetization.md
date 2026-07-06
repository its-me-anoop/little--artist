# Little Artist — Feature Gaps, Monetization & App Store Compliance

**Date:** 2026-02-20
**Status:** Pending — start after 8 AM

---

## Current State

The app is feature-complete relative to design specs. All 13 planned screens are implemented with ~54 Swift files. No TODOs, stubs, or incomplete features. The codebase is production-ready from a functionality standpoint.

---

## Phase 1 — App Store Ready (Ship First)

### Must Fix Before Submission

- [x] **Add Privacy Policy in Settings** — Required for App Store submission. Must be accessible in-app (SettingsView) AND linked in App Store Connect. Cover: data collected (child names, photos, voice memos, avatar photos), local-only storage, no third-party sharing, on-device AI only, COPPA compliance statement.
- [x] **Verify/Add Info.plist Purpose Strings** — Ensure camera, photo library, and microphone strings are specific and descriptive:
  - `NSCameraUsageDescription`: "Little Artist uses the camera to photograph your child's artwork for their art collection."
  - `NSPhotoLibraryUsageDescription`: "Little Artist accesses your photo library so you can select artwork photos to add to your child's collection."
  - `NSMicrophoneUsageDescription`: "Little Artist uses the microphone to record voice memos that your child can attach to their artwork."
- [ ] **Privacy Nutrition Labels** — Declare in App Store Connect: Photos (User Content), Audio (User Content), Name (Contact Info) — all "Not Linked to User"
- [ ] **Age Rating Questionnaire** — Complete in App Store Connect (likely qualifies for 4+)
- [ ] **Empty State Testing** — Test all permission denial paths, empty data states, and edge cases
- [x] **Date Override for Artwork** — Allow parents to set artwork creation date (not just capture date). Critical for importing older artwork.
- [x] **Batch Import from Photo Library** — Select multiple photos at once. Currently one-at-a-time.
- [x] **Implement Free Tier Limits** — 2 children, 50 artworks total. Gate for monetization.

### Kids Category Decision

**Recommendation: Do NOT list in Kids Category initially.**
- The app is for parents, not children directly
- Kids Category imposes severe restrictions (no third-party analytics ever, parental gates on everything)
- Target Lifestyle or Photo & Video category with family-friendly keywords
- Can move into Kids Category later if needed

---

## Phase 2 — Monetization (Week 2-3 Post-Launch)

### Subscription: "Little Artist Premium" — FINAL PRICING (July 2026, competitor-researched)

Decided after competitive research (Artkive, Keepy, Canvsly, KidArt, ArtKeep, Keepbox,
FamilyAlbum, Tinybeans, Qeepsake — see session research, July 2026):

| Plan | USD | GBP (set manually in ASC, not auto-converted) | Product ID |
|------|-----|-----|------------|
| Monthly | $4.99 | £4.49 | `uk.co.flutterly.littleartist.premium.monthly` |
| Yearly (anchor, ~42% off) | $34.99 | £29.99 | `uk.co.flutterly.littleartist.premium.yearly` |
| Lifetime (one-time, non-consumable) | $79.99 | £69.99 | `uk.co.flutterly.littleartist.premium.lifetime` |

Rationale:
- Lands under FamilyAlbum Premium ($59/yr) and Tinybeans ($74.99/yr) — priced as the affordable specialist.
- Lifetime converts subscription-fatigued parents; no major competitor offers it (only tiny ArtKeep at $79.99).
- Enable Family Sharing on all three products in App Store Connect (FamilyAlbum's family-wide unlock is its best-loved trait).
- Free tier is volume-capped, never time-bombed — explicit anti-Artkive trust positioning ("no surprise charges").
- Local StoreKit testing: `LittleArtist.storekit` at repo root (select in scheme → Run → Options → StoreKit Configuration).

**Free Tier (volume-capped, no time limits):**
- 1 child profile
- Up to 40 artworks total (a school term's worth)
- Camera + photo library capture
- Basic gallery, timeline, search
- Local storage only

**Premium Tier:**
- [x] **Unlimited children & artworks** — Families with 3+ kids hit the wall fast
- [x] **iCloud Backup & Sync** — Peace of mind + multi-device. This alone justifies the price.
- [x] **PDF Export / Photo Book** — Export child's portfolio as shareable PDF
- [x] **AI-Powered Captions** — Gate on-device AI features behind premium
- [ ] **Advanced Statistics** — Detailed per-child analytics, artwork frequency graphs
- [ ] **Widgets & Memories** — "On This Day" widget, artwork slideshow (Widget requires Xcode target)
- [ ] **Priority Support** — Email support channel

### Implementation Tasks

- [x] **Implement StoreKit 2 subscription** — Auto-renewable, 7+ day minimum period
- [x] **Add iCloud sync via CloudKit** — SwiftData + CloudKit integration
- [x] **Gate AI features behind premium**
- [x] **Add Restore Purchases button in Settings** — Required by App Store if any IAP exists
- [x] **PDF export of child portfolio**
- [x] **Paywall UI** — Clear pre-purchase disclosure of what's included. No dark patterns.

### Additional Revenue Streams

- [ ] **Photo Book Printing** — Partner with print service (physical goods exempt from Apple 30% cut per Guideline 3.1.3)
- [ ] **Custom Merchandise** — "Print on canvas/mug/t-shirt" via print-on-demand partner (also exempt from IAP)
- [ ] **Tip Jar** — Consumable IAP ($0.99-$4.99) "Buy the developer a coffee"

### What NOT to Do

- No ads (destroys premium feel; most ad SDKs banned in Kids Category)
- No selling user data (violates COPPA, privacy laws, instant rejection)
- No crypto/NFT artwork (heavy restrictions under Guideline 3.1.5b)
- No subscription without ongoing value (Apple requires ongoing value like cloud sync)

---

## Phase 3 — Retention & Growth (Month 2+)

### High-Value Features

- [ ] **Home Screen Widgets** — Random artwork or "On This Day" throwbacks. Drives daily re-engagement. (Requires Widget Extension Xcode target)
- [x] **Push Notification Reminders** — "You haven't captured artwork in 2 weeks" or "1 year ago, Emma drew this."
- [x] **Tags / Categories** — Tag by medium (paint, crayon, pencil), theme (animals, family), school project. Improves search.
- [x] **Artwork Comparison / Growth View** — Side-by-side comparison over time. Parents love seeing progression.
- [x] **Share to Family** — Share individual artwork or gallery link with grandparents (without requiring the app).
- [ ] **Multiple Photos Per Artwork** — Front + back, or multiple angles. Currently limited to one image.
- [x] **"On This Day" / Memories** — Surface old artwork anniversaries (like Apple Photos Memories).

### Nice-to-Have

- [ ] **Artwork Slideshow** — Auto-playing slideshow for family gatherings or Apple TV display.
- [ ] **iPad Support** — Adaptive layout. Parents often use iPad for viewing.
- [ ] **Artwork Collage / Year in Review** — Auto-generated annual collage of best artwork. Shareable.
- [ ] **Siri Shortcuts** — "Hey Siri, capture artwork" or "Show me Noah's latest artwork."
- [ ] **Apple Watch Complication** — Quick capture shortcut or random artwork on watch face.
- [ ] **Onboarding Permission Priming** — Pre-permission screens explaining why each permission is needed. Improves grant rates.

---

## App Store Compliance Notes

### COPPA Compliance (Strong Position)

- All data stored locally on-device (SwiftData)
- No data transmitted to third parties
- On-device AI (FoundationModels) — no server calls
- No analytics or advertising SDKs
- Document this clearly in privacy policy

### Subscription Guidelines (3.1.2)

- Must provide ongoing value (cloud sync qualifies)
- Minimum 7-day subscription period
- Must be available across all user's devices
- Clear pre-purchase disclosure required
- Revenue split: 70/30 year 1, then 85/15 year 2+

### Privacy Requirements (5.1)

- Privacy policy mandatory in-app AND App Store Connect
- Purpose strings must be clear and specific
- Data minimization — only request relevant data
- PhotosPicker (out-of-process) already used correctly
- If accounts added later: must offer in-app account deletion

### Comparable App Pricing (verified July 2026)

- Artkive: ~$2.75–9.99/month (restructured repeatedly; reputational damage from Box-service surprise invoicing)
- Keepy: $7.99/month or $29.99–99.99/year (abandoned — last update Oct 2020)
- FamilyAlbum: $5.99/month or $59/year (Premium), $10.99/month or $109/year (Pro) — family-wide unlock
- Tinybeans: $74.99/year (backlash after ~87% price hike)
- Qeepsake: $47.88/year (Essential), $95.88/year (Premium) — annual-only billing
- ArtKeep: $3.99/month, $24.99/year, $79.99 lifetime (new 2026 entrant)
- KidArt: $2.99 one-time (tiny solo-dev app)
- Our pricing: $4.99/month, $34.99/year, $79.99 lifetime (see Phase 2 table)
