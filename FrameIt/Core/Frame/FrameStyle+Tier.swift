import Foundation

/// Tier-awareness for `FrameStyle`. Pure functions — no StoreKit — so they're fully
/// unit-testable and can be applied identically on screen and at export time.
extension FrameStyle {
    /// The highest tier any of this style's choices requires. Drives the
    /// "this template uses Pro features" prompt when applying a saved template.
    func requiresTier() -> AppTier {
        var required: AppTier = .free

        if FontCatalog.font(id: fontID).isPremium {
            required = max(required, PremiumFeature.premiumFont.requiredTier)
        }
        if PinCatalog.icon(id: pinIcon).isPremium {
            required = max(required, PremiumFeature.premiumPin.requiredTier)
        }
        if signature.isCustomized {
            required = max(required, PremiumFeature.customCredit.requiredTier)
        }
        if signature.matchesFrameStyle {
            required = max(required, PremiumFeature.styledCredit.requiredTier)
        }
        return required
    }

    /// A copy forced down to what `tier` is allowed to use. Guarantees the on-screen
    /// preview and the exported image never show a locked look (preview == export).
    /// For a fully-entitled user this is a no-op.
    func sanitized(for tier: AppTier) -> FrameStyle {
        var copy = self

        if !tier.unlocks(PremiumFeature.premiumFont.requiredTier),
           FontCatalog.font(id: copy.fontID).isPremium {
            copy.fontID = FontCatalog.defaultID
        }
        if !tier.unlocks(PremiumFeature.premiumPin.requiredTier),
           PinCatalog.icon(id: copy.pinIcon).isPremium {
            copy.pinIcon = PinCatalog.defaultID
        }
        // Custom / hidden credit requires one-time; below it, reset to the default credit.
        if !tier.unlocks(PremiumFeature.customCredit.requiredTier) {
            copy.signature = .default
        }
        // Styled credit requires subscription; below it, force the neutral watermark.
        if !tier.unlocks(PremiumFeature.styledCredit.requiredTier) {
            copy.signature.matchesFrameStyle = false
        }
        return copy
    }
}

extension Signature {
    /// Whether the user has changed the credit from the free default (custom text or hidden).
    var isCustomized: Bool {
        isHidden || !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
