# Little Artist — App Store Growth Plan (Oct 2026)

**Why:** 3 months after launch the app has 0 ratings and does not rank in the
top ~200 for any category search ("kids artwork", "art keeper", "artwork
organizer", "kids art"). It is only found by its exact name, which it shares
with 8 kids' drawing/colouring apps. Competitors are thin: Keepy and Canvsly
have left the App Store, Artkive (1.6k ratings) is the only scaled player,
and every other keeper app has under 300 ratings.

The code changes for this plan are on branch `feature/app-store-growth`.
Everything below is App Store Connect work that must be done by hand.

---

## 1. Urgent checks (do first)

- [ ] **Confirm the 3 in-app purchases are attached to the live version.**
  The public App Store page lists no In-App Purchases. Your notes record them
  as `READY_TO_SUBMIT`, which means they may never have been submitted.
  In App Store Connect → the app → the next version → "In-App Purchases and
  Subscriptions", add all three products, then submit them *with* the build.
  (The products do load in the simulator, so they exist in App Store Connect.)
- [ ] **Deploy the CloudKit schema to Production** (CloudKit Console → Deploy
  Schema Changes). Still unticked in `metadata-and-submission.md`. If it was
  never done, iCloud sync fails for every store user.
- [ ] **Register the App Group** `group.uk.co.flutterly.Little-Artist` if
  `publish.sh` doesn't do it automatically (it runs with
  `-allowProvisioningUpdates`, which normally registers it). The widget needs it.

## 2. Listing (paste-ready)

Apple indexes title + subtitle + keywords together, so no word is repeated
across fields.

| Field | US English | UK English (add as a localisation) |
|---|---|---|
| **Name** (30) | `Little Artist: Save Kids' Art` | `Little Artist: Save Kids' Art` |
| **Subtitle** (30) | `Kids Artwork Scanner & Keeper` | `Kids Artwork Scanner & Keeper` |
| **Keywords** (100) | `drawings,school,keepsake,portfolio,organizer,memory,book,children,photo,voice,crafts,preschool` | `drawings,school,keepsake,portfolio,organiser,memory,book,children,photo,voice,crafts,nursery,archive` |

**Promotional text** (170):
> Every fridge-door masterpiece, safe forever. Scan in seconds, add your
> child's voice, and export everything free — your art is never locked away.

**Description — replace the opening and add one section:**

```
Save every drawing, painting and craft — and never lose access to them.

Little Artist is the private home for your kids' artwork. Scan a whole school bag in seconds, add their voice telling the story, and watch their creativity grow year by year.

YOUR ART IS ALWAYS YOURS
Export everything — every image, voice memo and caption — as a ZIP or straight to Photos. Free, for everyone, forever. Cancel Premium and you still keep and export it all. No hostage art, ever.
```

Then keep the existing sections (Capture in seconds, AI that organises,
Celebrate every milestone, Their voice forever) and add these bullets:

```
• Home Screen widget: "On This Day" anniversaries and favourites
• Print-ready 8×8 photo-book PDFs for any photo-book printer
```

Update "HONEST PRICING" to mention the free trial once it's live.

**What's New (v1.1):**
```
• New Home Screen widget — relive "On This Day" masterpieces
• Export Everything: download all art and voice memos, free forever
• Print-ready 8×8 photo-book PDFs
• Free trial on the yearly plan
```

## 3. Screenshots

Run the UI test `testCaptureStoreScreenshotsWithSampleArtwork` on the
iPhone 6.9" and iPad 13" simulators. It launches with procedurally drawn
sample artwork (`-uiTestSeedSampleArtwork`) and attaches
`01-gallery` … `05-settings-export` to the test report
(Xcode → Report navigator → Attachments). Suggested caption order:

1. Gallery — **"Every masterpiece, saved forever"**
2. Timeline — **"Watch them grow, year by year"**
3. Artwork detail — **"Their voice, telling the story"**
4. Milestones — **"Celebrate every first"**
5. Widget on Home Screen — **"On This Day, on your Home Screen"** (capture manually)
6. Settings export — **"Your art is yours. Export it all, free."**

Lead with the gallery. Don't use the onboarding or the paywall as store screenshots.

## 4. Pricing (App Store Connect → Subscriptions)

| Product | Now | Recommended |
|---|---|---|
| Yearly | $34.99 / £29.99, no trial | **$24.99 / £22.99 + 7-day free trial** (Introductory Offer → Free → 1 week) |
| Monthly | $4.99 / £4.49 | keep |
| Lifetime | $79.99 / £69.99 | keep (consider an A/B test at $49.99) |

The paywall detects a configured free trial automatically. It then shows
"7-day free trial" on the yearly card, changes the button to "Start 7-Day
Free Trial", and adds the "Free for 7 days, then …" disclosure. No code change needed.
The local `LittleArtist.storekit` file already mirrors these recommendations
for testing (attach it to the scheme under Run → Options → StoreKit Configuration).

## 5. Ongoing

- [ ] **In-App Event:** "Back-to-School Art Archive" (Aug–Sep) and "Holiday
  Art Book" (Nov–Dec). These show up in search results and in the Today tab.
- [ ] **Privacy policy URL:** the site only serves
  `/projects/artling/privacy-policy`; `/projects/little-artist/…` returns 404.
  Add the new path on flutterly.co.uk (keep the old one redirecting), then
  update the URL in `PaywallView.swift`, `PrivacyPolicyView.swift` and App Store Connect.
- [ ] **Accessibility nutrition label** in App Store Connect (currently blank).
- [ ] **Watch ratings weekly.** The in-app prompt asks after 5 saved artworks
  (and at least 2 days after install), at most once per version and at most
  every 60 days, and only after a happy moment: saving art, a milestone
  celebration, or opening an "On This Day" memory.
- [ ] **Next feature: a print partner.** Artkive and Keepbox make most of their
  money from printed books. The 8×8 PDF is the first step; an API print partner
  (physical goods are exempt from IAP) is the next.
