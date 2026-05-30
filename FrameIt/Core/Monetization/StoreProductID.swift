import Foundation

/// App Store product identifiers and their tier grants. Kept in one place so the
/// StoreKit service, the local `.storekit` config, and any tests agree on the ids.
enum StoreProductID {
    /// Non-consumable "Pro" — unlocks the one-time tier forever.
    static let pro = "com.peeratop02.frameit.pro"
    /// Auto-renewable "Studio" — yearly. Grants the subscription tier.
    static let studioYearly = "com.peeratop02.frameit.studio.yearly"
    /// Auto-renewable "Studio" — monthly. Grants the subscription tier.
    static let studioMonthly = "com.peeratop02.frameit.studio.monthly"

    /// Every id the app loads from the store.
    static let all: [String] = [pro, studioYearly, studioMonthly]

    /// The subscription product ids (used to detect an active Studio plan).
    static let subscriptionIDs: Set<String> = [studioYearly, studioMonthly]

    /// The tier a given product grants when its transaction is active.
    static func tier(for productID: String) -> AppTier {
        if subscriptionIDs.contains(productID) { return .subscription }
        if productID == pro { return .oneTime }
        return .free
    }
}
