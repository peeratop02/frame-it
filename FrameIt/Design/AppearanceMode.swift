import SwiftUI

/// The app's chrome appearance, overriding the device setting when not `.system`.
/// Persisted via `@AppStorage("appearanceMode")` and applied at `RootView` with
/// `.preferredColorScheme`. This affects only the app UI — the framed photo's colors
/// come from `FrameStyle`, so the exported image is unaffected.
enum AppearanceMode: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    /// The default — follow the device's appearance.
    static let storageKey = "appearanceMode"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    /// The scheme to force, or `nil` to follow the device.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
