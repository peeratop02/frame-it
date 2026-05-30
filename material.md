# Frame It — Marketing & UI Graphics Brief

The monetization surfaces (paywall, upsell, plan comparison) are **fully functional
today using SF Symbols and gradients** — no graphics are *required* to ship. But the
paywall is the one screen designed to convert, and real artwork would lift it from
"clean" to "premium". Below is what to source/produce, by priority.

If you can supply any of these, drop them in `FrameIt/Resources/Assets.xcassets`
(image sets, @1x/@2x/@3x or a single PDF/SVG vector). Tell me the asset names you
use and I'll wire them into the views. Until then the SF-Symbol fallbacks stay.

---

## Design concept & theme

- **Product feeling:** a quiet, premium photo-framing studio. The hero is always the
  *user's photo inside a frame* — chrome stays out of the way.
- **Aesthetic:** iOS 26 **Liquid Glass** — translucent, blurred, light-reactive
  surfaces. Soft depth, generous whitespace, rounded geometry (matches the app's
  `controlCornerRadius = 26`).
- **Palette:**
  - Accent: the app `AccentColor` (asset catalog) — used for primary buttons/checks.
  - **Premium gold:** `#D9A621` (RGB 0.85, 0.65, 0.13) — `Theme.premiumGold`. This is
    the "pay to unlock" signal (crowns, badges, Studio highlights). Keep gold *sparing*
    — accents only, never large fills. **Contrast caveat:** `#D9A621` is ~2.6:1 on white,
    so it's safe for icons, badges, and large/bold glyphs but **fails WCAG for body text**
    — never set gold on small text. Add a **lighter gold** (e.g. `#E8C24A`) as a
    dark-mode variant so badges stay legible on dark backgrounds.
  - Neutrals: system backgrounds (auto light/dark). **Every asset needs to read on
    both light and dark** — prefer transparent PNG/PDF, avoid baked-in white panels.
- **Type:** system San Francisco (already in-app). Marketing art should not bake in
  text (localization + Dynamic Type live in SwiftUI).
- **Tone:** aspirational but honest — show the actual frame styles the app produces,
  not mockups that overpromise.

---

## Priority 1 — Paywall hero (highest impact)

**Where:** top of `PaywallView` (currently a gold crown in a circle).
**Concept:** a single beautifully framed sample photo, floating on glass, with a few
premium touches visibly applied (a premium serif credit line, a heart map-pin minimap
corner). Sells the outcome in one glance.

- **Asset:** `paywall-hero` — transparent PNG/PDF, ~1200×900 @3x, centered subject,
  soft shadow, no background panel.
- **Variant idea:** 2–3 stacked framed photos fanned like cards (shows variety →
  "unlimited templates").
- Must look right at ~340pt wide on both light/dark.

## Priority 2 — Feature benefit icons (5)

**Where:** the benefit rows in `PaywallView` + the circular icon on `UpsellSheet`.
Today these use SF Symbols (`textformat`, `mappin.and.ellipse`, `signature`,
`paintbrush.pointed.fill`, `square.stack.3d.up.fill`).

Custom duotone glyphs (accent + gold) would feel more bespoke. One per feature:

| Feature | Concept |
|---|---|
| Premium fonts | "Aa" specimen in an elegant serif, gold flourish |
| Premium pins | a map pin morphing into a heart/star cluster |
| Custom credit | a signature flourish / pen nib on a caption line |
| Styled credit | the credit line picking up the frame's color (paintbrush) |
| Unlimited templates | a fanned stack of mini-frames |

- **Assets:** `feature-fonts`, `feature-pins`, `feature-credit`, `feature-styled`,
  `feature-templates` — square vector PDFs, ~120×120, transparent, 2-color max.

## Priority 3 — Tier badges (3)

**Where:** plan cards in `PaywallView`, `PlanComparisonView` column headers, Settings
plan row.
**Concept:** small emblem per tier to make the ladder instantly legible.

- **Free** — simple outline frame.
- **Pro** — filled frame with a single gold corner.
- **Studio** — gold crown / star-rosette (the flagship).
- **Assets:** `tier-free`, `tier-pro`, `tier-studio` — ~64×64 vector PDF, transparent.

## Priority 4 — App Store / external marketing (not in-app)

For listing & socials once we publish. Not wired into code — purely for the store.

- **Screenshots (6.9" + 6.1"):** before/after (raw photo → framed), the editor with
  the control dock, the font gallery, the paywall. Add short caption bars.
- **Promo banner / social card:** 1200×630 — a framed photo on a gold-flecked glass
  backdrop, tagline space top-left.
- **App preview video (optional):** 15–30s screen capture: pick photo → frame →
  swap font/pin → export. I can script the exact beats if useful.

---

## Low-cost wins (do these before commissioning art)

- **SF Symbols, richer rendering:** before custom glyphs, try
  `.symbolRenderingMode(.hierarchical)` or `.palette` (accent + gold) on the existing
  benefit/feature symbols. Closes most of the Priority-2 gap for free and stays on-brand.
- **Don't bake prices into art:** prices are localized at runtime via StoreKit
  (`product.displayPrice`). Marketing art and screenshots should leave price as live text.
- **Test every asset in light + dark + tinted** appearance (Liquid Glass reacts to its
  backdrop) and at large Dynamic Type.

## App Store / ASO (text, not graphics)

- **Keyword targets** for this niche: *EXIF, photo frame, camera metadata, shutter, ISO,
  film border, watermark, shot on*. Direct competitors: **EXIFrame** ($9.99 lifetime /
  $0.99 mo), **Cameramark** (free), **Reframe**, **FramePic**.
- **Differentiation line** to lead the listing: iOS 26 Liquid Glass design, a large
  curated font library, and one-time ownership of the full tool (subscription is optional,
  only for sync + ongoing content). Most rivals look utilitarian — lean on craft + polish.

## What I do NOT need

- Icons that duplicate existing SF Symbols at equal quality — fallbacks are fine.
- Anything with baked-in text, fixed light/dark backgrounds, or non-@3x raster.
- A new app icon (one already ships as `AppIcon`).

## Hand-off

Reply with either:
1. **"skip graphics"** — I'll polish the SF-Symbol/gradient versions and we ship as-is, or
2. drop assets in `Assets.xcassets` and list the names — I'll swap them into
   `PaywallView`, `UpsellSheet`, `PlanComparisonView`, and the Settings plan row.
