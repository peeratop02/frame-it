import Testing
@testable import FrameIt

/// `FrameStyle.requiresTier()` and `sanitized(for:)` — the pure functions that keep
/// the preview and export honest regardless of entitlement.
struct FrameStyleTierTests {

    private func premiumFontID() -> String {
        FontCatalog.all.first { $0.isPremium }!.id
    }
    private func premiumPinID() -> String {
        PinCatalog.all.first { $0.isPremium }!.id
    }

    // MARK: requiresTier

    @Test func defaultStyleRequiresFree() {
        #expect(FrameStyle.default.requiresTier() == .free)
    }

    @Test func premiumFontRequiresOneTime() {
        var style = FrameStyle.default
        style.fontID = premiumFontID()
        #expect(style.requiresTier() == .oneTime)
    }

    @Test func premiumPinRequiresOneTime() {
        var style = FrameStyle.default
        style.pinIcon = premiumPinID()
        #expect(style.requiresTier() == .oneTime)
    }

    @Test func customCreditRequiresOneTime() {
        var style = FrameStyle.default
        style.signature.customText = "@me"
        #expect(style.requiresTier() == .oneTime)
    }

    @Test func styledCreditRequiresSubscription() {
        var style = FrameStyle.default
        style.signature.matchesFrameStyle = true
        #expect(style.requiresTier() == .subscription)
    }

    // MARK: sanitized

    @Test func sanitizingForFreeStripsPremiumFontAndPin() {
        var style = FrameStyle.default
        style.fontID = premiumFontID()
        style.pinIcon = premiumPinID()

        let clean = style.sanitized(for: .free)
        #expect(clean.fontID == FontCatalog.defaultID)
        #expect(clean.pinIcon == PinCatalog.defaultID)
    }

    @Test func sanitizingForFreeResetsCredit() {
        var style = FrameStyle.default
        style.signature.customText = "@me"
        style.signature.isHidden = true

        let clean = style.sanitized(for: .free)
        #expect(clean.signature == .default)
    }

    @Test func sanitizingForOneTimeKeepsCreditButDropsStyledMatch() {
        var style = FrameStyle.default
        style.signature.customText = "@me"
        style.signature.matchesFrameStyle = true

        let clean = style.sanitized(for: .oneTime)
        #expect(clean.signature.customText == "@me")
        #expect(clean.signature.matchesFrameStyle == false)
    }

    @Test func sanitizingForSubscriptionIsNoOp() {
        var style = FrameStyle.default
        style.fontID = premiumFontID()
        style.pinIcon = premiumPinID()
        style.signature.customText = "@me"
        style.signature.matchesFrameStyle = true

        #expect(style.sanitized(for: .subscription) == style)
    }

    @Test func sanitizingKeepsFreeFontUntouched() {
        let style = FrameStyle.default   // system font, default pin
        #expect(style.sanitized(for: .free) == style)
    }
}
