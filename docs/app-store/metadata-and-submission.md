# Artling — App Store Metadata & Submission Checklist

Prepared 2026-07-06. Positioning informed by the July 2026 competitor
research (Artkive, Keepy, FamilyAlbum, Tinybeans, ArtKeep, Keepbox):
lead with privacy/on-device AI and no-surprise pricing — the two most
damaging documented complaints against incumbents.

---

## App Store Metadata

**Name** (30 chars max): `Artling — Save Kids' Art`
(matches the proven "[verb] kids art" title pattern in this niche)

**Subtitle** (30 chars max): `Scan, save & celebrate art`

**Primary category**: Lifestyle
**Secondary category**: Photo & Video
**Age rating**: 4+ (no objectionable content; app is for parents)

**Keywords** (100 chars max):
`kids art,artwork,children,scanner,keepsake,memories,archive,family,drawing,portfolio,milestones`

**Promotional text** (170 chars):
> Every fridge-door masterpiece, safe forever. Scan artwork in seconds,
> let on-device AI name it, and watch your little artist's gallery grow.
> No accounts. No surprises.

**Description**:

> **Your child's art never leaves your family.**
>
> Artling archives every drawing, painting, and craft your little artist
> creates — privately. Everything lives on your iPhone and in your own
> private iCloud. No accounts to create, no servers of ours to trust, and
> AI that runs on your device, not in someone else's cloud.
>
> **CAPTURE IN SECONDS**
> Scan artwork with edge-detecting document capture, snap it with the
> camera, or import a whole school-bag batch from your photo library.
>
> **AI THAT ORGANISES, NOT GIMMICKS**
> On-device Apple Intelligence suggests playful storybook titles and warm
> captions for every piece — so your gallery is a curated collection, not
> a photo dump. (Requires an Apple Intelligence-capable device.)
>
> **CELEBRATE EVERY MILESTONE**
> Confetti-worthy achievements mark the creative journey: first
> masterpiece, a year of art, every medium explored. Fire up Exhibition
> Mode — a full-screen slideshow — at family gatherings.
>
> **THEIR VOICE, FOREVER**
> Record your child describing their own artwork. In twenty years, that
> ten-second clip will be priceless.
>
> **EVERYTHING ELSE YOU'D EXPECT**
> • "On This Day" memories resurface past masterpieces
> • Timeline, search, and tags by medium and theme
> • PDF keepsake portfolios to print or share
> • Siri: "Save artwork in Artling"
> • iCloud sync across all your devices — free, automatic
>
> **HONEST PRICING**
> The free tier is yours forever: one artist profile and a school term's
> worth of artwork, with no time limits and no surprise charges. Artling
> Premium unlocks unlimited artists, unlimited artwork, AI captions,
> voice memos, and PDF export — $4.99/month, $34.99/year, or $79.99 once,
> forever. Cancel anytime.

**What's New (v1.0)**:
> Welcome to Artling! Scan, save, and celebrate your child's artwork —
> privately, with on-device AI, iCloud sync, milestones, and a
> full-screen exhibition mode.

**App Review notes**:
- No account or sign-in exists; data is stored in SwiftData and synced to
  the user's private CloudKit database (`iCloud.uk.co.flutterly.Little-Artist`).
- AI title/caption suggestions use Apple's FoundationModels framework
  exclusively (on-device / Private Cloud Compute). On devices without
  Apple Intelligence the AI button reports "AI Unavailable" — this is
  expected.
- Three IAPs: monthly + yearly auto-renewing subscriptions and a lifetime
  non-consumable (product IDs below). Free tier: 1 child profile, 40
  artworks.
- Camera/photo/microphone usage strings are set via build settings.

---

## Submission Checklist

### Code / build (done in repo)
- [x] Firebase & Gemini fully removed; pure Apple stack
- [x] Privacy manifest: zero data collected, required-reason APIs declared
- [x] Usage strings (camera, photos, microphone) in build settings
- [x] Entitlements: iCloud/CloudKit container + aps-environment
- [x] Build number bumped to 19 (marketing version 1.0)
- [x] 36 automated tests passing (30 unit + 6 UI)
- [x] Release build verified with **stable Xcode 26** (App Store cannot
      accept beta-SDK builds; the iOS 27 FoundationModels code is
      compiler-gated and drops out cleanly)

### App Store Connect — DONE via API (6 Jul 2026 session)
All configured programmatically with the ASC API key (Issuer ID read from
the owner's logged-in App Store Connect session):
- [x] Three IAPs live and READY_TO_SUBMIT with **manual GBP prices**:
      | Product ID | Type | USD | GBP |
      |---|---|---|---|
      | `com.flutterly.littleartist.premium.monthly` | Auto-renew sub | $4.99 | £4.49 |
      | `com.flutterly.littleartist.premium.yearly` | Auto-renew sub | $34.99 | £29.99 |
      | `com.flutterly.littleartist.premium.lifetime` | Non-consumable | $79.99 | £69.99 |
      (NOTE: ASC already had subscriptions under the com.flutterly.* prefix —
      code was aligned to match; Family Sharing already enabled)
- [x] Subscription group "Little Artist Premium" + en-GB localizations
- [x] Review screenshots uploaded for all three IAPs (paywall capture)
- [x] Listing updated: description/keywords/promo text (accurate to the
      Apple-stack app), support URL, copyright, Lifestyle primary category
- [x] Screenshots: iPhone 6.7" set (onboarding/milestones/paywall) and
      iPad 12.9" set (onboarding/home) — replace with richer artwork-filled
      shots post-launch
- [x] Build uploaded via scripts/publish.sh (cloud signing, zero local
      certs); export compliance declared (exempt encryption only)
- [x] Version 1.0 submitted for App Review (manual release)
- [ ] Age rating questionnaire — already 4+ in ASC ✓
- [ ] Privacy nutrition label — verify "Data Not Collected" in ASC web UI

### CloudKit (REQUIRED BEFORE PRESSING "RELEASE")
Release type is set to MANUAL for exactly this reason:
- [ ] Run the app once on a device/simulator signed into iCloud so the
      schema is created in the **Development** environment
- [ ] In CloudKit Console, **deploy schema to Production**
      (releasing without this makes sync fail for App Store users)
- [ ] Then press "Release" in App Store Connect after approval

### Submission history
- Build 26 (Xcode 26.6 / iOS 26.5 SDK): REJECTED — ITMS-90111, Apple now
  requires the latest SDK line. publish.sh switched to Xcode 27.
- Build 27+ (Xcode 27 / iOS 27 SDK): resubmitted with Apple Intelligence
  features fully enabled.

### Deferred (post-launch, documented)
- Cross-family profile sharing via CKShare (removed with Firebase;
  old dual-stack implementation recoverable from commit `44cde09`)
- Home Screen widget ("On This Day") — needs a widget extension target
- Physical print partner integration (books/merch) — use a print API,
  never in-house fulfilment (Artkive's failure mode)
- Richer store screenshots with sample artwork (app-store-screenshots
  skill or manual capture with real data)
