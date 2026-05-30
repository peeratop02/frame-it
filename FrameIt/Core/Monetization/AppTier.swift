import Foundation

/// The three monetization tiers, ordered by capability. Raw `Int` ordering makes
/// the ladder `Comparable`: `free < oneTime < subscription`. Subscription is a
/// strict superset of one-time, so a `>=` check is all gating ever needs.
enum AppTier: Int, Comparable, Codable, Sendable, CaseIterable {
    case free = 0
    case oneTime = 1
    case subscription = 2

    static func < (lhs: AppTier, rhs: AppTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Whether this tier satisfies a required minimum tier.
    func unlocks(_ required: AppTier) -> Bool {
        self >= required
    }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .oneTime: return "Pro"
        case .subscription: return "Studio"
        }
    }

    /// Short marketing tagline shown next to the tier name.
    var tagline: String {
        switch self {
        case .free: return "The essentials, free forever"
        case .oneTime: return "Own every frame, one payment"
        case .subscription: return "Everything, always evolving"
        }
    }
}
