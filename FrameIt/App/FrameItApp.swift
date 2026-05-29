import SwiftUI
import SwiftData

@main
struct FrameItApp: App {
    init() {
        // Register bundled custom fonts so the editor's premium typefaces resolve.
        FontRegistrar.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        // On-device store for saved templates. CloudKit sync is added in a later
        // phase (the model is already designed CloudKit-compatible).
        .modelContainer(for: Template.self)
    }
}
