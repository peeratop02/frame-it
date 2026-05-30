import SwiftUI

/// Makes the shared entitlement provider available to any view via
/// `@Environment(\.entitlements)`. Defaults to the live StoreKit service; tests and
/// previews inject a `PreviewEntitlements` (or any mock) with `.environment(\.entitlements, …)`.
private struct EntitlementProviderKey: EnvironmentKey {
    @MainActor static let defaultValue: any EntitlementProvider = StoreKitEntitlementService.shared
}

extension EnvironmentValues {
    var entitlements: any EntitlementProvider {
        get { self[EntitlementProviderKey.self] }
        set { self[EntitlementProviderKey.self] = newValue }
    }
}
