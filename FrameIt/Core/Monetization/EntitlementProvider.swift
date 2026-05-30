import StoreKit

/// Abstraction over "what has the user paid for". Views and view models depend on
/// this protocol (not the concrete StoreKit service) so they're testable with a
/// mock. `@MainActor` because UI reads `tier`/`products` directly.
@MainActor
protocol EntitlementProvider: AnyObject {
    /// The highest tier the user currently holds.
    var tier: AppTier { get }
    /// Products available for purchase, loaded from the store (may be empty while loading).
    var products: [Product] { get }
    /// Whether the load of products/entitlements has completed at least once.
    var isReady: Bool { get }

    /// Buy a product and refresh entitlements. Throws on failure (not on user cancel).
    func purchase(_ product: Product) async throws
    /// Restore prior purchases (e.g. after reinstall).
    func restore() async throws
}

extension EntitlementProvider {
    /// A feature is unlocked when the current tier meets the feature's required tier.
    func isUnlocked(_ feature: PremiumFeature) -> Bool {
        tier.unlocks(feature.requiredTier)
    }

    /// The Pro (non-consumable) product, if loaded.
    var proProduct: Product? {
        products.first { $0.id == StoreProductID.pro }
    }

    /// The Studio subscription products (yearly + monthly), if loaded.
    var studioProducts: [Product] {
        products.filter { StoreProductID.subscriptionIDs.contains($0.id) }
    }
}

/// A fixed-tier provider for SwiftUI previews and unit tests. Purchase/restore are
/// no-ops that simply raise the tier so flows can be exercised without StoreKit.
@MainActor
final class PreviewEntitlements: EntitlementProvider {
    private(set) var tier: AppTier
    private(set) var products: [Product] = []
    let isReady = true

    init(tier: AppTier = .free) {
        self.tier = tier
    }

    func purchase(_ product: Product) async throws {
        tier = max(tier, StoreProductID.tier(for: product.id))
    }

    func restore() async throws {}
}
