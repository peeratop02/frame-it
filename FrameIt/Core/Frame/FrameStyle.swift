import SwiftUI

/// A Codable, value-type RGBA color so `FrameStyle` can be persisted and (later)
/// saved as a template / synced via SwiftData + CloudKit.
struct RGBAColor: Codable, Equatable, Sendable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    init(_ color: Color) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(red: r, green: g, blue: b, opacity: a)
    }

    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }

    static let white = RGBAColor(red: 1, green: 1, blue: 1)
    static let black = RGBAColor(red: 0, green: 0, blue: 0)
    static let charcoal = RGBAColor(red: 0.11, green: 0.11, blue: 0.12)
    static let secondaryText = RGBAColor(red: 0.45, green: 0.45, blue: 0.47)
}

/// A metadata field the user can toggle on/off in the caption.
enum MetadataField: String, Codable, CaseIterable, Identifiable, Sendable {
    case device
    case lens
    case dateTaken
    case shutter
    case aperture
    case iso
    case focalLength
    case location
    case app

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .device: return "Device"
        case .lens: return "Lens"
        case .dateTaken: return "Date"
        case .shutter: return "Shutter"
        case .aperture: return "Aperture"
        case .iso: return "ISO"
        case .focalLength: return "Focal length"
        case .location: return "Location"
        case .app: return "App"
        }
    }
}

/// Logical grouping of `MetadataField`s into the headed sections shown in the
/// Details panel. Every field belongs to exactly one group.
enum MetadataGroup: String, CaseIterable, Identifiable, Sendable {
    case device
    case exposure
    case place

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .device: return "Device"
        case .exposure: return "Exposure"
        case .place: return "Place"
        }
    }

    /// The fields in this group, in display order.
    var fields: [MetadataField] {
        switch self {
        case .device: return [.device, .app, .lens]
        case .exposure: return [.focalLength, .aperture, .shutter, .iso]
        case .place: return [.dateTaken, .location]
        }
    }
}

/// How the advanced layout's Place column presents location.
enum PlaceStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case time   // place text + date + time
    case map    // a minimap widget (map + pin) with a place caption

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .time: return "Time"
        case .map: return "Map"
        }
    }
}

/// The credit / watermark shown at the bottom of the frame. Capability is tiered:
/// free users get the fixed default credit; paid users can hide it or set custom
/// text; subscribers can additionally style it. Entitlement gating is applied in the
/// editor (pre-StoreKit: controls stay usable, marked premium); this model only
/// records the chosen values.
struct Signature: Codable, Equatable, Sendable {
    /// Custom credit text. Empty/blank ⇒ render the default credit.
    var customText: String
    /// When true the credit adopts the frame's font + text color (subscription); when
    /// false it renders in a neutral watermark style.
    var matchesFrameStyle: Bool
    /// When true the credit is not drawn at all (paid capability).
    var isHidden: Bool

    static let `default` = Signature(customText: "", matchesFrameStyle: false, isHidden: false)

    /// The text to render: the trimmed custom text, or `defaultText` when it's empty.
    func displayText(default defaultText: String) -> String {
        let trimmed = customText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultText : trimmed
    }
}

/// The complete description of a frame's appearance. `Codable` from day one so it
/// drops straight into a SwiftData `Template` model in a later phase.
struct FrameStyle: Codable, Equatable, Sendable {
    var layout: FrameLayout
    var background: RGBAColor
    /// Margin around the photo, as a fraction of the frame width (0...0.18).
    var padding: Double
    /// Extra margin added to the bottom only, on top of `padding` (0...0.18).
    var bottomPadding: Double
    var cornerRadius: Double
    var borderWidth: Double
    var borderColor: RGBAColor
    /// Soft shadow cast by the photo onto the frame, 0 (none) … 1 (strongest).
    var shadowStrength: Double
    /// The selected typeface, persisted by `FontCatalog` id.
    var fontID: String
    /// Multiplier applied to all caption text sizes (0.7…1.4, default 1.0).
    var fontScale: Double
    var bold: Bool
    var italic: Bool
    var textColor: RGBAColor
    var enabledFields: [MetadataField]
    /// How the advanced layout's Place column renders location: as text+time, or a minimap.
    var placeStyle: PlaceStyle
    /// The pin glyph drawn on the minimap widget — premium glyphs gated in a later phase.
    var pinIcon: String
    /// The bottom-of-frame credit / watermark.
    var signature: Signature

    /// The free-tier credit shown when the signature isn't customized.
    static let defaultCredit = "Crafted with Frame It"

    static let `default` = FrameStyle(
        layout: .minimal,
        background: .white,
        padding: 0.06,
        bottomPadding: 0,
        cornerRadius: 0,
        borderWidth: 0,
        borderColor: .black,
        shadowStrength: 0,
        fontID: FontCatalog.defaultID,
        fontScale: 1.0,
        bold: false,
        italic: false,
        textColor: .charcoal,
        enabledFields: [.device, .shutter, .aperture, .iso, .focalLength],
        placeStyle: .time,
        pinIcon: PinCatalog.defaultID,
        signature: .default
    )

    /// The resolved typeface for the current `fontID`.
    var font: FrameFont { FontCatalog.font(id: fontID) }

    func isFieldEnabled(_ field: MetadataField) -> Bool {
        enabledFields.contains(field)
    }
}
