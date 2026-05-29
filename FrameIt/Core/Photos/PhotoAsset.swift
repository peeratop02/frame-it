import Foundation

/// A lightweight, value-type reference to a photo in the user's library.
/// Identified by the PhotoKit `localIdentifier` so it is a stable `ForEach` id.
struct PhotoAsset: Identifiable, Hashable, Sendable {
    let id: String          // PHAsset.localIdentifier
    let pixelWidth: Int
    let pixelHeight: Int
    let creationDate: Date?
    /// Original filename (e.g. `IMG_1234.HEIC`) when PhotoKit can resolve it.
    var filename: String?

    var aspectRatio: Double {
        guard pixelHeight > 0 else { return 1 }
        return Double(pixelWidth) / Double(pixelHeight)
    }
}
