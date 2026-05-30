import Testing
@testable import FrameIt

/// Feature gating through the `EntitlementProvider` protocol, exercised with a mock.
@MainActor
struct EntitlementGatingTests {

    @Test func freeProviderLocksAllPremiumFeatures() {
        let provider = MockEntitlementProvider(tier: .free)
        for feature in PremiumFeature.allCases {
            #expect(provider.isUnlocked(feature) == false)
        }
    }

    @Test func oneTimeUnlocksProFeaturesOnly() {
        let provider = MockEntitlementProvider(tier: .oneTime)
        #expect(provider.isUnlocked(.premiumFont))
        #expect(provider.isUnlocked(.premiumPin))
        #expect(provider.isUnlocked(.customCredit))
        #expect(provider.isUnlocked(.unlimitedTemplates))
        #expect(provider.isUnlocked(.styledCredit) == false)
    }

    @Test func subscriptionUnlocksAll() {
        let provider = MockEntitlementProvider(tier: .subscription)
        for feature in PremiumFeature.allCases {
            #expect(provider.isUnlocked(feature))
        }
    }

    @Test func restoreIsForwarded() async throws {
        let provider = MockEntitlementProvider(tier: .free)
        try await provider.restore()
        #expect(provider.restoreCallCount == 1)
    }

    // MARK: - Tester tier override

    @Test func overrideRaisesEffectiveTierAndUnlocksEverything() {
        let provider = MockEntitlementProvider(tier: .free)
        provider.tierOverride = .subscription
        #expect(provider.tier == .subscription)
        for feature in PremiumFeature.allCases {
            #expect(provider.isUnlocked(feature))
        }
    }

    @Test func overrideCanSimulateFreeWhilePaid() {
        let provider = MockEntitlementProvider(tier: .subscription)
        provider.tierOverride = .free
        #expect(provider.tier == .free)
        #expect(provider.isUnlocked(.premiumFont) == false)
    }

    @Test func clearingOverrideFallsBackToRealTier() {
        let provider = MockEntitlementProvider(tier: .oneTime)
        provider.tierOverride = .free
        provider.tierOverride = nil
        #expect(provider.tier == .oneTime)
    }
}
