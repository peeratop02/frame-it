import Testing
@testable import FrameIt

/// The tier ladder and feature→tier mapping that all gating relies on.
struct AppTierTests {

    @Test func tiersAreOrdered() {
        #expect(AppTier.free < AppTier.oneTime)
        #expect(AppTier.oneTime < AppTier.subscription)
    }

    @Test func unlocksIsInclusiveOfEqualAndHigher() {
        #expect(AppTier.oneTime.unlocks(.oneTime))
        #expect(AppTier.subscription.unlocks(.oneTime))
        #expect(AppTier.free.unlocks(.oneTime) == false)
        #expect(AppTier.oneTime.unlocks(.subscription) == false)
    }

    @Test func freeUnlocksNothingPaid() {
        for feature in PremiumFeature.allCases {
            #expect(AppTier.free.unlocks(feature.requiredTier) == false)
        }
    }

    @Test func oneTimeUnlocksProFeaturesButNotStyledCredit() {
        let oneTime = AppTier.oneTime
        #expect(oneTime.unlocks(PremiumFeature.premiumFont.requiredTier))
        #expect(oneTime.unlocks(PremiumFeature.premiumPin.requiredTier))
        #expect(oneTime.unlocks(PremiumFeature.customCredit.requiredTier))
        #expect(oneTime.unlocks(PremiumFeature.unlimitedTemplates.requiredTier))
        #expect(oneTime.unlocks(PremiumFeature.styledCredit.requiredTier) == false)
    }

    @Test func subscriptionUnlocksEverything() {
        for feature in PremiumFeature.allCases {
            #expect(AppTier.subscription.unlocks(feature.requiredTier))
        }
    }

    @Test func productIDsMapToTiers() {
        #expect(StoreProductID.tier(for: StoreProductID.pro) == .oneTime)
        #expect(StoreProductID.tier(for: StoreProductID.studioYearly) == .subscription)
        #expect(StoreProductID.tier(for: StoreProductID.studioMonthly) == .subscription)
        #expect(StoreProductID.tier(for: "unknown") == .free)
    }
}
