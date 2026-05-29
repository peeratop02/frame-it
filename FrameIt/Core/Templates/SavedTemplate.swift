import UIKit

/// An immutable value snapshot of a `Template`, decoupling the UI and view models
/// from the SwiftData `@Model`'s reference identity and context lifetime.
struct SavedTemplate: Identifiable {
    let id: UUID
    let name: String
    let createdAt: Date
    let sortIndex: Int
    let style: FrameStyle
    let thumbnail: UIImage?
}
