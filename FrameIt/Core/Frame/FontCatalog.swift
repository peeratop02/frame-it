import SwiftUI

/// Typeface families are grouped under four categories the user filters by in the
/// editor. Each category maps to a system `Font.Design` used by its free entry.
enum FontCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case sans
    case serif
    case rounded
    case mono

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sans: return "Sans"
        case .serif: return "Serif"
        case .rounded: return "Rounded"
        case .mono: return "Mono"
        }
    }

    var systemDesign: Font.Design {
        switch self {
        case .sans: return .default
        case .serif: return .serif
        case .rounded: return .rounded
        case .mono: return .monospaced
        }
    }
}

/// A single selectable typeface. Persisted in `FrameStyle` by `id` only (via
/// `FrameStyle.fontID`); the full record is resolved from `FontCatalog`.
///
/// `familyName == nil` means "use the category's system design" — the four free
/// fonts. Named families resolve through `Font.custom`, which works for any font
/// already installed on iOS. Bundled premium font packs drop in later by adding
/// entries with their own `familyName`.
struct FrameFont: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String
    let displayName: String
    let category: FontCategory
    let isPremium: Bool
    /// A concrete iOS font family name, or `nil` to use the category's system design.
    let familyName: String?

    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let familyName {
            return Font.custom(familyName, size: size).weight(weight)
        }
        return Font.system(size: size, weight: weight, design: category.systemDesign)
    }
}

/// The curated set of typefaces offered in the editor. The free tier is one
/// system-design font per category; everything else is `isPremium` (unlocked by
/// the one-time / subscription tier in a later monetization phase). All families
/// listed here ship with iOS, so no bundling or licensing is required yet.
enum FontCatalog {
    /// Default selection — the free system sans font.
    static let defaultID = "system"

    /// `@AppStorage` / `UserDefaults` key for the user's chosen default font (paid).
    static let defaultSelectionKey = "defaultFontID"

    static let all: [FrameFont] = [
        // Sans
        FrameFont(id: "system", displayName: "System", category: .sans, isPremium: false, familyName: nil),
        // Bundled Google Fonts (OFL) — registered at launch by `FontRegistrar`.
        FrameFont(id: "poppins", displayName: "Poppins", category: .sans, isPremium: true, familyName: "Poppins"),
        FrameFont(id: "montserrat", displayName: "Montserrat", category: .sans, isPremium: true, familyName: "Montserrat"),
        FrameFont(id: "oswald", displayName: "Oswald", category: .sans, isPremium: true, familyName: "Oswald"),
        FrameFont(id: "avenir-next", displayName: "Avenir Next", category: .sans, isPremium: true, familyName: "Avenir Next"),
        FrameFont(id: "helvetica-neue", displayName: "Helvetica Neue", category: .sans, isPremium: true, familyName: "Helvetica Neue"),
        FrameFont(id: "gill-sans", displayName: "Gill Sans", category: .sans, isPremium: true, familyName: "Gill Sans"),
        FrameFont(id: "futura", displayName: "Futura", category: .sans, isPremium: true, familyName: "Futura"),
        FrameFont(id: "verdana", displayName: "Verdana", category: .sans, isPremium: true, familyName: "Verdana"),

        // Serif
        FrameFont(id: "serif", displayName: "New York", category: .serif, isPremium: false, familyName: nil),
        FrameFont(id: "lora", displayName: "Lora", category: .serif, isPremium: true, familyName: "Lora"),
        FrameFont(id: "playfair-display", displayName: "Playfair Display", category: .serif, isPremium: true, familyName: "Playfair Display"),
        FrameFont(id: "georgia", displayName: "Georgia", category: .serif, isPremium: true, familyName: "Georgia"),
        FrameFont(id: "palatino", displayName: "Palatino", category: .serif, isPremium: true, familyName: "Palatino"),
        FrameFont(id: "baskerville", displayName: "Baskerville", category: .serif, isPremium: true, familyName: "Baskerville"),
        FrameFont(id: "hoefler-text", displayName: "Hoefler Text", category: .serif, isPremium: true, familyName: "Hoefler Text"),

        // Rounded
        FrameFont(id: "rounded", displayName: "SF Rounded", category: .rounded, isPremium: false, familyName: nil),
        FrameFont(id: "quicksand", displayName: "Quicksand", category: .rounded, isPremium: true, familyName: "Quicksand"),
        FrameFont(id: "comfortaa", displayName: "Comfortaa", category: .rounded, isPremium: true, familyName: "Comfortaa"),
        FrameFont(id: "arial-rounded", displayName: "Arial Rounded", category: .rounded, isPremium: true, familyName: "Arial Rounded MT Bold"),

        // Mono
        FrameFont(id: "monospaced", displayName: "SF Mono", category: .mono, isPremium: false, familyName: nil),
        FrameFont(id: "space-mono", displayName: "Space Mono", category: .mono, isPremium: true, familyName: "Space Mono"),
        FrameFont(id: "menlo", displayName: "Menlo", category: .mono, isPremium: true, familyName: "Menlo"),
        FrameFont(id: "courier", displayName: "Courier", category: .mono, isPremium: true, familyName: "Courier"),
        FrameFont(id: "american-typewriter", displayName: "American Typewriter", category: .mono, isPremium: true, familyName: "American Typewriter"),
    ]

    /// The default font record.
    static let `default`: FrameFont = font(id: defaultID)

    /// Resolve a font by id, falling back to the default when unknown (e.g. a
    /// persisted style that referenced a font removed from a later build).
    static func font(id: String) -> FrameFont {
        all.first { $0.id == id } ?? all.first { $0.id == defaultID }!
    }

    /// Fonts belonging to a category, in catalog order (free entry first).
    static func fonts(in category: FontCategory) -> [FrameFont] {
        all.filter { $0.category == category }
    }
}
