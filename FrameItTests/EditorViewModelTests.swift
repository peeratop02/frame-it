import Testing
import Foundation
@testable import FrameIt

/// The view model is `@MainActor`; these tests exercise its synchronous init logic
/// (seeding the default font) without touching PhotoKit.
@MainActor
struct EditorViewModelTests {

    /// Run `body` with the default-font key set to `value`, restoring it afterward.
    private func withDefaultFont(_ value: String?, _ body: () -> Void) {
        let defaults = UserDefaults.standard
        let key = FontCatalog.defaultSelectionKey
        let previous = defaults.string(forKey: key)
        if let value { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
        defer {
            if let previous { defaults.set(previous, forKey: key) } else { defaults.removeObject(forKey: key) }
        }
        body()
    }

    @Test func seedsOpeningFontFromStoredDefault() {
        withDefaultFont("georgia") {
            let vm = EditorViewModel(asset: .sample())
            #expect(vm.style.fontID == "georgia")
            #expect(vm.hasUnsavedChanges == false)
        }
    }

    @Test func ignoresUnknownStoredFont() {
        withDefaultFont("not-a-real-font") {
            let vm = EditorViewModel(asset: .sample())
            #expect(vm.style.fontID == FontCatalog.defaultID)
            #expect(vm.hasUnsavedChanges == false)
        }
    }

    @Test func usesSystemDefaultWhenUnset() {
        withDefaultFont(nil) {
            let vm = EditorViewModel(asset: .sample())
            #expect(vm.style.fontID == FontCatalog.defaultID)
        }
    }

    /// Build a `SavedTemplate` wrapping a style, for apply/edit tests.
    private func makeTemplate(name: String = "T", id: UUID = UUID(),
                             _ mutate: (inout FrameStyle) -> Void = { _ in }) -> SavedTemplate {
        var style = FrameStyle.default
        mutate(&style)
        return SavedTemplate(id: id, name: name, createdAt: .now, sortIndex: 0,
                             style: style, thumbnail: nil)
    }

    @Test func applyReplacesStyleAndMarksUnsaved() {
        let vm = EditorViewModel(asset: .sample())
        let template = makeTemplate {
            $0.layout = .advanced
            $0.shadowStrength = 0.5
        }
        vm.apply(template)
        #expect(vm.style == template.style)
        #expect(vm.appliedTemplate?.id == template.id)
        #expect(vm.hasUnsavedChanges)
    }

    @Test func editingTemplateSeedsStyleWithoutUnsavedChanges() {
        let template = makeTemplate(name: "Vintage") { $0.shadowStrength = 0.9 }
        let vm = EditorViewModel(asset: .sample(), editingTemplate: template)
        #expect(vm.style == template.style)
        #expect(vm.appliedTemplate?.id == template.id)
        #expect(vm.hasUnsavedChanges == false)
    }

    @Test func saveWithExistingNameUpdatesInsteadOfDuplicating() {
        let vm = EditorViewModel(asset: .sample())
        let store = MockTemplateStore()
        vm.attach(store: store)
        vm.saveAsTemplate(named: "Sunset")
        #expect(store.saved.count == 1)

        // Re-saving with the same name updates the existing template, not a duplicate.
        vm.style.shadowStrength = 0.42
        vm.saveAsTemplate(named: "sunset")   // case-insensitive match
        #expect(store.saved.count == 1)
        #expect(store.saved[0].style.shadowStrength == 0.42)
    }

    @Test func updateAppliedTemplateOverwritesIt() {
        let store = MockTemplateStore()
        try? store.save(name: "Base", style: .default, thumbnail: nil)
        let existing = (try? store.all())!.first!

        let vm = EditorViewModel(asset: .sample(), editingTemplate: existing)
        vm.attach(store: store)
        vm.style.shadowStrength = 0.33
        vm.updateAppliedTemplate()

        #expect(store.saved.count == 1)
        #expect(store.saved[0].id == existing.id)
        #expect(store.saved[0].style.shadowStrength == 0.33)
    }

    @Test func saveAsTemplatePersistsCurrentStyle() {
        let vm = EditorViewModel(asset: .sample())
        let store = MockTemplateStore()
        vm.attach(store: store)
        vm.style.shadowStrength = 0.7

        vm.saveAsTemplate(named: "My Style")
        #expect(store.saved.count == 1)
        #expect(store.saved[0].name == "My Style")
        #expect(store.saved[0].style.shadowStrength == 0.7)
    }

    @Test func saveAsTemplateFallsBackToSuggestedName() {
        let vm = EditorViewModel(asset: .sample())
        let store = MockTemplateStore()
        vm.attach(store: store)
        vm.saveAsTemplate(named: "   ")
        #expect(store.saved.first?.name == "Template 1")
    }

    // MARK: - Entitlement gating

    private func premiumFontID() -> String { FontCatalog.all.first { $0.isPremium }!.id }

    @Test func freeTierBlocksThirdTemplateSave() {
        let vm = EditorViewModel(asset: .sample(),
                                 entitlements: MockEntitlementProvider(tier: .free))
        let store = MockTemplateStore()
        vm.attach(store: store)

        vm.saveAsTemplate(named: "One")
        vm.saveAsTemplate(named: "Two")
        #expect(store.saved.count == 2)

        vm.saveAsTemplate(named: "Three")   // exceeds the free cap
        #expect(store.saved.count == 2)
        #expect(vm.pendingUpsell == .unlimitedTemplates)
    }

    @Test func freeTierStillUpdatesExistingTemplateAtCap() {
        let vm = EditorViewModel(asset: .sample(),
                                 entitlements: MockEntitlementProvider(tier: .free))
        let store = MockTemplateStore()
        vm.attach(store: store)
        vm.saveAsTemplate(named: "One")
        vm.saveAsTemplate(named: "Two")

        // Re-saving an existing name updates rather than inserting — never gated.
        vm.style.shadowStrength = 0.5
        vm.saveAsTemplate(named: "Two")
        #expect(store.saved.count == 2)
        #expect(vm.pendingUpsell == nil)
    }

    @Test func paidTierAllowsUnlimitedTemplates() {
        let vm = EditorViewModel(asset: .sample(),
                                 entitlements: MockEntitlementProvider(tier: .oneTime))
        let store = MockTemplateStore()
        vm.attach(store: store)
        vm.saveAsTemplate(named: "One")
        vm.saveAsTemplate(named: "Two")
        vm.saveAsTemplate(named: "Three")
        #expect(store.saved.count == 3)
        #expect(vm.pendingUpsell == nil)
    }

    @Test func applyingPremiumTemplateWhileFreeDowngrades() {
        let vm = EditorViewModel(asset: .sample(),
                                 entitlements: MockEntitlementProvider(tier: .free))
        let template = makeTemplate { $0.fontID = self.premiumFontID() }
        vm.apply(template)
        #expect(vm.lastApplyWasDowngraded)
        #expect(vm.style.fontID == FontCatalog.defaultID)
    }

    @Test func applyingPremiumTemplateWhilePaidKeepsIt() {
        let vm = EditorViewModel(asset: .sample(),
                                 entitlements: MockEntitlementProvider(tier: .oneTime))
        let premium = premiumFontID()
        let template = makeTemplate { $0.fontID = premium }
        vm.apply(template)
        #expect(vm.lastApplyWasDowngraded == false)
        #expect(vm.style.fontID == premium)
    }
}
