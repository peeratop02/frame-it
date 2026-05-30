import StoreKit
import os

/// The single source of truth for entitlements, backed by StoreKit 2. Computes the
/// active `tier` from `Transaction.currentEntitlements`, keeps it fresh with a
/// long-lived `Transaction.updates` listener (renewals, refunds, family sharing),
/// and drives purchase/restore. One shared instance owns the one listener task.
@MainActor
@Observable
final class StoreKitEntitlementService: EntitlementProvider {
    static let shared = StoreKitEntitlementService()

    private(set) var tier: AppTier = .free
    private(set) var products: [Product] = []
    private(set) var isReady = false

    private var updatesTask: Task<Void, Never>?
    private let logger = Logger(subsystem: "com.peeratop02.frameit", category: "StoreKit")

    private init() {
        // Begin listening before any purchase so we never miss a transaction.
        updatesTask = listenForTransactions()
        Task { await refresh() }
    }

    /// Load products and recompute the current tier. Safe to call repeatedly.
    func refresh() async {
        await loadProducts()
        await recomputeTier()
        isReady = true
    }

    private func loadProducts() async {
        do {
            let loaded = try await Product.products(for: StoreProductID.all)
            // Stable order: Pro first, then subscriptions by price ascending.
            products = loaded.sorted { lhs, rhs in
                if lhs.id == StoreProductID.pro { return true }
                if rhs.id == StoreProductID.pro { return false }
                return lhs.price < rhs.price
            }
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Walk active entitlements and take the highest tier any of them grants.
    private func recomputeTier() async {
        var resolved: AppTier = .free
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.revocationDate != nil { continue }
            if let exp = transaction.expirationDate, exp < .now { continue }
            resolved = max(resolved, StoreProductID.tier(for: transaction.productID))
        }
        tier = resolved
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                logger.error("Purchase returned an unverified transaction")
                throw StoreError.unverified
            }
            await transaction.finish()
            await recomputeTier()
        case .userCancelled:
            break // Not an error.
        case .pending:
            break // Ask-to-buy / SCA — entitlements update later via the listener.
        @unknown default:
            break
        }
    }

    func restore() async throws {
        try await AppStore.sync()
        await recomputeTier()
    }

    /// Long-lived listener that refreshes the tier whenever a transaction lands
    /// outside an explicit `purchase` (renewals, refunds, other devices).
    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await self?.recomputeTier()
            }
        }
    }

    enum StoreError: Error {
        case unverified
    }
}
