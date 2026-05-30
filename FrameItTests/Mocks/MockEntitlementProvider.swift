import StoreKit
@testable import FrameIt

/// A deterministic `EntitlementProvider` for unit tests: the tier is set directly,
/// no StoreKit involved. `purchase` raises the tier to the product's grant; the
/// product list stays empty (gating logic never needs concrete `Product`s).
@MainActor
final class MockEntitlementProvider: EntitlementProvider {
    /// The real (purchased) tier; `tier` applies any override on top.
    var baseTier: AppTier
    var tierOverride: AppTier?
    var tier: AppTier { tierOverride ?? baseTier }
    var products: [Product] = []
    var isReady = true
    private(set) var restoreCallCount = 0

    init(tier: AppTier = .free) {
        self.baseTier = tier
    }

    func purchase(_ product: Product) async throws {
        baseTier = max(baseTier, StoreProductID.tier(for: product.id))
    }

    func restore() async throws {
        restoreCallCount += 1
    }
}
