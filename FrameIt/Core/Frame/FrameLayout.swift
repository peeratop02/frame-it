import Foundation

/// How the photo and its metadata are arranged within the frame.
enum FrameLayout: String, Codable, CaseIterable, Identifiable, Sendable {
    case minimal    // photo on top, one centered metadata block (the classic caption look)
    case advanced   // photo on top, metadata split into Exposure | Device | Place columns

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .minimal: return "Minimal"
        case .advanced: return "Advanced"
        }
    }

    var systemImage: String {
        switch self {
        case .minimal: return "text.below.photo"
        case .advanced: return "rectangle.split.3x1"
        }
    }
}
