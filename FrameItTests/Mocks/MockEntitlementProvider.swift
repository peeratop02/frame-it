import StoreKit
@testable import FrameIt

/// A deterministic `EntitlementProvider` for unit tests: the tier is set directly,
/// no StoreKit involved. `purchase` raises the tier to the product's grant; the
/// product list stays empty (gating logic never needs concrete `Product`s).
@MainActor
final class MockEntitlementProvider: EntitlementProvider {
    var tier: AppTier
    var products: [Product] = []
    var isReady = true
    private(set) var restoreCallCount = 0

    init(tier: AppTier = .free) {
        self.tier = tier
    }

    func purchase(_ product: Product) async throws {
        tier = max(tier, StoreProductID.tier(for: product.id))
    }

    func restore() async throws {
        restoreCallCount += 1
    }
}
