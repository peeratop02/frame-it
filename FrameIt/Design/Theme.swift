import SwiftUI

/// Shared visual constants. Colors lean on semantic system colors so Dark Mode,
/// Increase Contrast, and tinted appearances are handled for free.
enum Theme {
    /// The single accent color for interactive elements (defined in the asset catalog).
    static let accent = Color.accentColor

    /// Marks premium (pay-to-unlock) options, e.g. the crown on locked fonts.
    static let premiumGold = Color(red: 0.85, green: 0.65, blue: 0.13)

    /// Neutral canvas behind the editor preview so any frame background reads clearly.
    static let editorCanvas = Color(.systemGroupedBackground)

    /// Standard corner radius for glass control surfaces.
    static let controlCornerRadius: CGFloat = 26
}
