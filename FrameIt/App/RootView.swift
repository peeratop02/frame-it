import SwiftUI

/// Top-level shell. A bottom `TabView` with three sections: Photos, Templates, and
/// Settings. The Editor is not a tab — it opens as a `fullScreenCover` from a photo
/// tap inside the Photos tab (HIG: editor is a focused task, not a top-level
/// destination).
struct RootView: View {
    enum Section: Hashable {
        case photos
        case templates
        case settings
    }

    @State private var selection: Section = .photos
    @AppStorage(AppearanceMode.storageKey) private var appearanceRaw = AppearanceMode.system.rawValue

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Photos", systemImage: "photo.on.rectangle.angled", value: Section.photos) {
                LibraryView()
            }
            Tab("Templates", systemImage: "square.stack", value: Section.templates) {
                TemplatesView()
            }
            Tab("Settings", systemImage: "gearshape", value: Section.settings) {
                SettingsView()
            }
        }
        .preferredColorScheme(appearance.colorScheme)
    }
}

#Preview {
    RootView()
}
