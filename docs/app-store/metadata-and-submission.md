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

### App Store Connect (requires account owner)
- [ ] Create the three IAPs and set **manual GBP prices** (don't accept
      the auto-converted tier — it overcharges UK users):
      | Product ID | Type | USD | GBP |
      |---|---|---|---|
      | `com.flutterly.littleartist.premium.monthly` | Auto-renew sub | $4.99 | £4.49 |
      | `com.flutterly.littleartist.premium.yearly` | Auto-renew sub | $34.99 | £29.99 |
      | `com.flutterly.littleartist.premium.lifetime` | Non-consumable | $79.99 | £69.99 |
- [ ] Put both subscriptions in one subscription group ("Premium")
- [ ] Enable **Family Sharing** on all three IAPs (research: FamilyAlbum's
      family-wide unlock is its best-loved trait)
- [ ] Privacy nutrition label: **Data Not Collected**
- [ ] Age rating questionnaire (expect 4+)
- [ ] Upload screenshots — lead with: AI title suggestion → milestones
      celebration → "On This Day" → exhibition mode → paywall trust line
- [ ] App Privacy policy URL: https://www.flutterly.co.uk/projects/artling/privacy-policy

### CloudKit (requires developer account, one-time)
- [ ] Run the app once on a device/simulator signed into iCloud so the
      schema is created in the **Development** environment
- [ ] In CloudKit Console, **deploy schema to Production** before release
      (releasing without this makes sync fail for App Store users)

### Final steps — ONE credential needed
An App Store Connect API key is already installed on this Mac
(`~/.appstoreconnect/private_keys/AuthKey_V9VT258MM6.p8`, added 2 Jul 2026).
The only missing piece is its **Issuer ID** — a UUID shown at
App Store Connect → Users and Access → Integrations → App Store Connect API
(it is not stored anywhere on this Mac and cannot be derived from the key).

- [ ] Copy the Issuer ID from App Store Connect, then run:
      `ASC_ISSUER_ID=<uuid> ./scripts/publish.sh`
      This archives with **cloud-managed signing** (no Xcode sign-in or
      local certificates needed — none exist on this Mac) using stable
      Xcode 26, exports, and uploads the build to App Store Connect.
- Alternative manual route: sign into Xcode (Settings → Accounts, team
  K6623R3GP5), then Product → Archive → Distribute.
- [ ] TestFlight internal pass: onboarding → add child → scan artwork →
      AI caption (on an AI-capable device) → milestone confetti →
      slideshow → paywall purchase in sandbox → restore purchases
- [ ] Submit for review

### Deferred (post-launch, documented)
- Cross-family profile sharing via CKShare (removed with Firebase;
  old dual-stack implementation recoverable from commit `44cde09`)
- Home Screen widget ("On This Day") — needs a widget extension target
- Physical print partner integration (books/merch) — use a print API,
  never in-house fulfilment (Artkive's failure mode)
