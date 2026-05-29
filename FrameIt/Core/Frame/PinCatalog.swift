import Foundation

/// A selectable map pin glyph. Persisted in `FrameStyle.pinIcon` by `id`. Mirrors
/// the `FontCatalog` shape: one free default plus premium glyphs that are
/// selectable today and entitlement-gated in the monetization phase.
struct PinIcon: Identifiable, Equatable, Sendable {
    let id: String
    let displayName: String
    /// The SF Symbol drawn over the minimap.
    let systemName: String
    let isPremium: Bool
}

enum PinCatalog {
    /// Default selection — the free standard pin.
    static let defaultID = "pin"

    static let all: [PinIcon] = [
        PinIcon(id: "pin", displayName: "Pin", systemName: "mappin.circle.fill", isPremium: false),
        PinIcon(id: "heart", displayName: "Heart", systemName: "heart.circle.fill", isPremium: true),
        PinIcon(id: "star", displayName: "Star", systemName: "star.circle.fill", isPremium: true),
        PinIcon(id: "flag", displayName: "Flag", systemName: "flag.circle.fill", isPremium: true),
        PinIcon(id: "camera", displayName: "Camera", systemName: "camera.circle.fill", isPremium: true),
        PinIcon(id: "bolt", displayName: "Bolt", systemName: "bolt.circle.fill", isPremium: true),
        PinIcon(id: "leaf", displayName: "Leaf", systemName: "leaf.circle.fill", isPremium: true),
    ]

    /// Resolve a pin by id, falling back to the default for an unknown id (e.g. a
    /// persisted style that referenced a glyph removed from a later build).
    static func icon(id: String) -> PinIcon {
        all.first { $0.id == id } ?? all.first { $0.id == defaultID }!
    }

    /// The SF Symbol name for the given pin id.
    static func systemName(id: String) -> String {
        icon(id: id).systemName
    }
}
