import Foundation
import SwiftData

/// A saved frame style the user can reuse. Stored with SwiftData so it persists
/// on-device today and syncs unchanged when CloudKit is enabled later — hence every
/// attribute has a default and there is **no** `@Attribute(.unique)` (CloudKit's
/// private database forbids unique constraints).
///
/// `FrameStyle` is persisted as a JSON `Data` blob rather than a nested-Codable
/// attribute: SwiftData is unreliable storing composite Codable structs that contain
/// arrays/enums, and a blob is trivially CloudKit-syncable.
@Model
final class Template {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date.now
    /// Position in the user's ordered list; lower sorts first.
    var sortIndex: Int = 0
    /// JSON-encoded `FrameStyle`.
    var styleData: Data = Data()
    /// Small PNG preview (~300pt) shown in the Templates grid.
    var thumbnail: Data?

    init(id: UUID = UUID(),
         name: String,
         createdAt: Date = .now,
         sortIndex: Int = 0,
         style: FrameStyle,
         thumbnail: Data? = nil) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.sortIndex = sortIndex
        self.thumbnail = thumbnail
        self.style = style
    }

    /// The decoded frame style. Falls back to `.default` if the blob can't be read.
    var style: FrameStyle {
        get { (try? JSONDecoder().decode(FrameStyle.self, from: styleData)) ?? .default }
        set { styleData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
}
