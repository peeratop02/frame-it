import SwiftUI
import UIKit

/// Drives the Albums tab: loads PhotoKit collections and resolves cover/grid thumbnails.
/// Depends on the `PhotoLibraryService` protocol so it's testable with a mock.
@MainActor
@Observable
final class AlbumsViewModel {
    private(set) var albums: [PhotoAlbum] = []
    private(set) var isLoaded = false

    private let library: any PhotoLibraryService

    init(library: any PhotoLibraryService = PhotoKitLibraryService()) {
        self.library = library
    }

    func load() async {
        albums = await library.fetchAlbums()
        isLoaded = true
    }

    /// The album's cover thumbnail (resolved from its cover asset id).
    func coverImage(for album: PhotoAlbum, size: CGSize) async -> UIImage? {
        guard let coverID = album.coverAssetID,
              let asset = await library.asset(withID: coverID) else { return nil }
        return await library.loadThumbnail(for: asset, targetSize: size)
    }

    func assets(in album: PhotoAlbum) async -> [PhotoAsset] {
        await library.fetchAssets(inAlbum: album.id)
    }

    func thumbnail(for asset: PhotoAsset, size: CGSize) async -> UIImage? {
        await library.loadThumbnail(for: asset, targetSize: size)
    }
}
