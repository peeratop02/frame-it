import Foundation

/// A gated capability. Each case knows the minimum `AppTier` that unlocks it plus
/// the marketing copy used by the contextual upsell sheet and the paywall's
/// benefit list. Pure value type — no StoreKit, fully unit-testable.
enum PremiumFeature: String, CaseIterable, Identifiable, Sendable {
    case premiumFont
    case premiumPin
    case customCredit
    case styledCredit
    case unlimitedTemplates

    var id: String { rawValue }

    /// The lowest tier that unlocks this feature.
    var requiredTier: AppTier {
        switch self {
        case .premiumFont, .premiumPin, .customCredit, .unlimitedTemplates:
            return .oneTime
        case .styledCredit:
            return .subscription
        }
    }

    /// Headline shown on the upsell sheet.
    var title: String {
        switch self {
        case .premiumFont: return "Unlock Every Typeface"
        case .premiumPin: return "Unlock Every Map Pin"
        case .customCredit: return "Make the Credit Yours"
        case .styledCredit: return "Style the Credit"
        case .unlimitedTemplates: return "Save Unlimited Templates"
        }
    }

    /// One-line benefit copy.
    var blurb: String {
        switch self {
        case .premiumFont:
            return "Dozens of premium fonts — from elegant serifs to coder monos — for a frame that's unmistakably yours."
        case .premiumPin:
            return "Hearts, stars, cameras and more to mark where the shot was taken."
        case .customCredit:
            return "Write your own credit line, your handle, or hide it entirely."
        case .styledCredit:
            return "Match the credit to your frame's font and color for a seamless finish."
        case .unlimitedTemplates:
            return "Save as many frame styles as you like and apply them in a tap."
        }
    }

    /// SF Symbol representing the feature in benefit rows.
    var symbolName: String {
        switch self {
        case .premiumFont: return "textformat"
        case .premiumPin: return "mappin.and.ellipse"
        case .customCredit: return "signature"
        case .styledCredit: return "paintbrush.pointed.fill"
        case .unlimitedTemplates: return "square.stack.3d.up.fill"
        }
    }
}
