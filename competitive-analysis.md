# Frame It — Competitive Analysis & MVP Roadmap

_Last updated: 2026-05-30. Sources at the bottom. Treat ratings as a point-in-time snapshot._

## TL;DR

The EXIF-frame niche is **small, cheap, and lightly defended**. The two leaders
(EXIFrame, Cameramark) sit at 4.8–4.9★ but on tiny rating counts (~19 and ~66) — nobody
has combined **batch workflow + visual craft**. Frame It already owns three things rivals
can't match (map widget, deep typography, Liquid Glass). To be competitive we must close a
few **table-stakes gaps** (camera brand logos, batch export, custom logo/signature, manual
EXIF entry) and keep leaning on our moats.

---

## Competitor snapshot

| | **Frame It** (us) | **EXIFrame** | **Cameramark** |
|---|---|---|---|
| Price | Pro $9.99 one-time; Studio sub (cosmetics/QoS) | $0.99/mo or **$9.99 lifetime** | Free; **$6.99** unlock |
| Rating (count) | — (pre-launch) | 4.9★ (~19) | 4.8★ (~66) |
| Platforms | iPhone (iPad planned) | iPhone/iPad/**Mac**/**visionOS** | iPhone/iPad/**Mac**/**visionOS** |
| Languages | English | 7 languages | — |
| EXIF overlay | ✅ device, lens, shutter, aperture, ISO, focal, date, location, app | ✅ | ✅ |
| **Map / minimap widget** | ✅ **(unique)** | ✗ (text GPS) | ✗ (text/address) |
| **Font library** | ✅ **25+ curated** (serif → coding mono) | few | font-size/color only |
| **Liquid Glass (iOS 26) design** | ✅ **(unique)** | standard | standard |
| Reverse-geocode w/o location permission | ✅ | n/a | GPS→address |
| Camera **brand logos** | ✗ | ✅ | ✅ |
| **Custom logo / signature image** | ✗ (text credit only) | ✅ custom logo | ✅ handwritten/uploaded sig |
| **Batch / bulk export** | ✗ (1 photo at a time) | ✅ | profiles only |
| **Film support / manual EXIF entry** | ✗ (reads EXIF only) | ✅ 100+ bodies, film stock | partial |
| Photo editing (brightness/contrast/B&W…) | ✗ | ✅ | ✗ |
| Aspect ratios / crop | ✗ | ✅ (4:5, 16:9, 1:1…) | ✗ |
| Export format/quality tiers | single | JPEG/PNG/HEIC + hi-res gate | quality opt |
| HDR / Live Photo preservation | ✗ (flatten) | ✗ | ✅ |
| Templates / profiles | ✅ SwiftData templates | presets | profiles |

---

## Our moats (defend + market these)

1. **Map / minimap with a location pin.** Neither rival renders a map — they print GPS as
   text. Genuinely unique and visually distinctive.
2. **Typography depth.** 25+ curated fonts (elegant serifs to coder monos) vs a handful.
3. **iOS 26 Liquid Glass.** Rivals look utilitarian; we're the polished, modern one.
4. **Privacy-friendly place names.** Reverse-geocode from the photo's own EXIF GPS, no
   location permission requested.

## Gaps vs competitors (what they have, we don't)

- **P0 Camera brand logos** — table-stakes for the "shot on" aesthetic.
- **P0 Batch / bulk export** — the single loudest demand in the category.
- **P1 Custom logo / signature image upload** — personal branding; we only have text.
- **P1 Manual EXIF entry / editing** — film + scanned photos have no EXIF; today they
  can't use us at all.
- **P2** aspect-ratio/crop, basic photo adjustments, export format/quality, HDR/Live Photo,
  onboarding, localization, iPad/Mac.

## What users actually want (reviews + sibling apps OneLine, Reframe)

1. **Batch export with reused presets** — loudest ask (OneLine "100 photos, one click";
   Reframe batch templates).
2. **Reliable EXIF detection** — top *complaint* (Cameramark: "no info found, yet iOS
   Photos finds it"). Robustness is a differentiator.
3. **Manual entry fallback** when EXIF is missing — fixes the complaint *and* unlocks film.
4. **Camera brand logos** — expected, not optional.
5. **Custom logo / signature upload.**
6. **Onboarding / tutorial** — review: "wish it had a tutorial, found settings by accident."

---

## MVP roadmap

Ordered by impact. Tier placement follows the locked rule — **functionality → Pro
(one-time); cosmetics + QoS → Studio (subscription)** (see `monetization-strategy`).

### Phase 1 — Reach parity on the essentials (pre-launch blockers)

| Feature | Why | Tier | Build notes |
|---|---|---|---|
| **Camera brand logos** | Biggest table-stakes gap; pairs with our font strength | **Pro** | New `LogoCatalog` (brand SF-symbol-like vectors / bundled assets); add a `logo` field to `FrameStyle`; render in `FramePreview`. Mirror the `FontCatalog`/`PinCatalog` pattern (free default = none/your-device brand; premium = full set). |
| **Manual EXIF entry / edit** | Film + scanned photos have no EXIF → unusable today; also fixes the #1 complaint | **Pro** | Editable overlay of `PhotoMetadata`; persist overrides per-photo. Graceful "add it yourself" when a field is missing instead of hiding it. |
| **Onboarding pass** | Cheap retention win; reviewers ask for it | Free | 3–4 slide first-run + empty-state hints. Honor HIG. |

### Phase 2 — The headline differentiator

| Feature | Why | Tier | Build notes |
|---|---|---|---|
| **Batch apply + bulk export** | #1 category demand; nobody pairs it with craft | **Pro** (or Studio if you want a power-user/QoS flavor) | We already have templates + `FrameStyle.sanitized(for:)`. Add multi-select in the Photos tab → pick a template → render N → bulk save/share. Reuse `FrameRenderer`; run renders off the main actor; progress UI. |
| **Custom logo / signature image upload** | Personal branding beyond text credit | **Pro** | Extend the `Signature` model with an optional image (PhotosPicker import, store in app container); render alongside/instead of text credit. |

### Phase 3 — Polish & format coverage

| Feature | Why | Tier |
|---|---|---|
| Aspect-ratio / crop presets (4:5, 16:9, 1:1) | Social formats | Pro |
| Basic photo adjustments (brightness/contrast/B&W) | Match EXIFrame | Pro |
| Export format + quality (PNG/HEIC, hi-res) | Power users | Pro (hi-res) |
| HDR / Live Photo preservation | Cameramark parity | Free |

### Phase 4 — Reach expansion (post-MVP, already architected)

iCloud sync (Studio/QoS) → font & frame **packs** + premium app icons (Studio/cosmetics) →
localization (7 langs) → iPad (`NavigationSplitView`) → Mac Catalyst / visionOS.

---

## Marketing positioning

Lead with the three things rivals **can't** match:

> **A map of where you shot it. Typography that actually looks designed. iOS 26 glass.**

Secondary: one-time ownership of the full tool (subscription optional, only sync + ongoing
content) — undercuts subscription-fatigued users in a niche where $9.99-lifetime is the bar.

**ASO keywords:** EXIF, photo frame, camera metadata, shutter, ISO, film border, watermark,
shot on. **Differentiation line** for the listing: craft + map + one-time ownership.

---

## Sources

- [EXIFrame — App Store](https://apps.apple.com/us/app/exiframe-photo-frame-exif/id6738852892)
- [Cameramark — App Store](https://apps.apple.com/us/app/cameramark-photo-exif-frame/id6447237830)
- [Reframe — App Store](https://apps.apple.com/us/app/reframe-exif-frame/id6483865815)
- [OneLine: EXIF Frame & Watermark — App Store](https://apps.apple.com/us/app/oneline-exif-frame-watermark/id6476151887)
