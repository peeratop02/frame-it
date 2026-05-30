import StoreKit

/// Wraps an `EntitlementProvider` for the paywall UI: tracks the in-flight purchase,
/// surfaces user-facing errors, and reports when a purchase has raised the tier so
/// the view can dismiss. Holds the provider as `any EntitlementProvider` so it's
/// mockable in previews/tests.
@MainActor
@Observable
final class PaywallViewModel {
    /// The product id currently being purchased/restored, or nil when idle.
    private(set) var pendingProductID: String?
    private(set) var isRestoring = false
    var errorMessage: String?

    private let entitlements: any EntitlementProvider

    init(entitlements: any EntitlementProvider) {
        self.entitlements = entitlements
    }

    var tier: AppTier { entitlements.tier }
    var isReady: Bool { entitlements.isReady }
    var proProduct: Product? { entitlements.proProduct }
    var studioProducts: [Product] { entitlements.studioProducts }

    func isPurchasing(_ product: Product) -> Bool {
        pendingProductID == product.id
    }

    /// Whether this product's tier is already owned (button shows "Current Plan").
    func isOwned(_ product: Product) -> Bool {
        entitlements.tier >= StoreProductID.tier(for: product.id)
    }

    func buy(_ product: Product) async {
        guard pendingProductID == nil else { return }
        pendingProductID = product.id
        defer { pendingProductID = nil }
        do {
            try await entitlements.purchase(product)
        } catch {
            errorMessage = "The purchase couldn't be completed. Please try again."
        }
    }

    func restore() async {
        guard !isRestoring else { return }
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await entitlements.restore()
            if entitlements.tier == .free {
                errorMessage = "No previous purchases were found to restore."
            }
        } catch {
            errorMessage = "Couldn't restore purchases. Please try again."
        }
    }
}
