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
}
