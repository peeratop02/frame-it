import Foundation

/// A lightweight value-type reference to a PhotoKit collection (user album or smart
/// album). Identified by the collection's `localIdentifier` so it's a stable `ForEach` id.
struct PhotoAlbum: Identifiable, Hashable, Sendable {
    let id: String              // PHAssetCollection.localIdentifier
    let title: String
    let count: Int
    /// Identifier of an asset to show as the album's cover (most recent), if any.
    let coverAssetID: String?
}
