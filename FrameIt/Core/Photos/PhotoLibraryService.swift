import Foundation
import Photos
import UIKit

/// Wraps PhotoKit behind a protocol so the Library/Editor view models can be
/// driven by a mock in tests (no real photo library access).
protocol PhotoLibraryService: Sendable {
    func authorizationStatus() -> PHAuthorizationStatus
    func requestAuthorization() async -> PHAuthorizationStatus
    func fetchAssets() async -> [PhotoAsset]
    /// User albums plus common smart albums (Favorites, Recents, …), empties excluded.
    func fetchAlbums() async -> [PhotoAlbum]
    /// Image assets inside one collection, newest first.
    func fetchAssets(inAlbum albumID: String) async -> [PhotoAsset]
    /// Resolve a single asset by its `localIdentifier`, e.g. from a photo picker.
    func asset(withID id: String) async -> PhotoAsset?
    func loadThumbnail(for asset: PhotoAsset, targetSize: CGSize) async -> UIImage?
    func loadFullImageData(for asset: PhotoAsset) async -> Data?
    /// Resolves the original filename (e.g. `IMG_1234.HEIC`) for one asset on demand.
    /// Kept off the grid path because it is expensive per-asset (see `fetchAssets`).
    func loadFilename(for asset: PhotoAsset) async -> String?
}

/// PhotoKit-backed implementation. An `actor` so the `PHCachingImageManager` and the
/// `PHAsset` lookup cache it owns are accessed serially without data races.
actor PhotoKitLibraryService: PhotoLibraryService {

    private let imageManager = PHCachingImageManager()
    /// `localIdentifier` → `PHAsset`, populated by `fetchAssets` so per-image requests
    /// don't re-run `PHAsset.fetchAssets(withLocalIdentifiers:)` on every cell.
    private var assetCache: [String: PHAsset] = [:]

    nonisolated func authorizationStatus() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    nonisolated func requestAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
    }

    func fetchAssets() async -> [PhotoAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: .image, options: options)

        return mapAndCache(fetchResult, resetCache: true)
    }

    func fetchAlbums() async -> [PhotoAlbum] {
        var albums: [PhotoAlbum] = []

        // Common smart albums, in a sensible order; PhotoKit returns one collection each.
        let smartSubtypes: [PHAssetCollectionSubtype] = [
            .smartAlbumFavorites, .smartAlbumRecentlyAdded, .smartAlbumUserLibrary,
            .smartAlbumSelfPortraits, .smartAlbumScreenshots, .smartAlbumPanoramas,
            .smartAlbumLivePhotos, .smartAlbumBursts
        ]
        for subtype in smartSubtypes {
            let collections = PHAssetCollection.fetchAssetCollections(
                with: .smartAlbum, subtype: subtype, options: nil)
            collections.enumerateObjects { collection, _, _ in
                if let album = self.makeAlbum(from: collection) { albums.append(album) }
            }
        }

        // User-created albums, alphabetical.
        let userOptions = PHFetchOptions()
        userOptions.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]
        let userAlbums = PHAssetCollection.fetchAssetCollections(
            with: .album, subtype: .any, options: userOptions)
        userAlbums.enumerateObjects { collection, _, _ in
            if let album = self.makeAlbum(from: collection) { albums.append(album) }
        }

        return albums
    }

    func fetchAssets(inAlbum albumID: String) async -> [PhotoAsset] {
        guard let collection = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [albumID], options: nil).firstObject else { return [] }
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(in: collection, options: options)
        return mapAndCache(result, resetCache: false)
    }

    func asset(withID id: String) async -> PhotoAsset? {
        guard let phAsset = phAsset(forID: id) else { return nil }
        return Self.makeAsset(phAsset)
    }

    /// Map a fetch result to `PhotoAsset`s while caching the `PHAsset`s for later image
    /// requests. Cheap property reads only — no `PHAssetResource` lookups (filename stays
    /// lazy via `loadFilename`). `resetCache` replaces the cache (full library) vs merges
    /// (album subsets, so library thumbnails stay cached).
    private func mapAndCache(_ result: PHFetchResult<PHAsset>, resetCache: Bool) -> [PhotoAsset] {
        var assets: [PhotoAsset] = []
        assets.reserveCapacity(result.count)
        if resetCache { assetCache.removeAll(keepingCapacity: true) }
        result.enumerateObjects { asset, _, _ in
            self.assetCache[asset.localIdentifier] = asset
            assets.append(Self.makeAsset(asset))
        }
        return assets
    }

    private static func makeAsset(_ asset: PHAsset) -> PhotoAsset {
        PhotoAsset(
            id: asset.localIdentifier,
            pixelWidth: asset.pixelWidth,
            pixelHeight: asset.pixelHeight,
            creationDate: asset.creationDate,
            filename: nil
        )
    }

    private func makeAlbum(from collection: PHAssetCollection) -> PhotoAlbum? {
        let imageOptions = PHFetchOptions()
        imageOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        imageOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let assets = PHAsset.fetchAssets(in: collection, options: imageOptions)
        guard assets.count > 0 else { return nil }   // skip empty albums
        return PhotoAlbum(
            id: collection.localIdentifier,
            title: collection.localizedTitle ?? "Album",
            count: assets.count,
            coverAssetID: assets.firstObject?.localIdentifier
        )
    }

    func loadThumbnail(for asset: PhotoAsset, targetSize: CGSize) async -> UIImage? {
        guard let phAsset = phAsset(for: asset) else { return nil }
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic   // fast low-res first, then a sharp pass
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true

        // `.opportunistic` calls back twice: a fast degraded image, then a sharp one.
        // Resume the continuation exactly once, on the final (non-degraded) result, so
        // the grid shows crisp thumbnails while the caching manager keeps the decode warm.
        return await withCheckedContinuation { continuation in
            var resumed = false
            imageManager.requestImage(
                for: phAsset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                guard !resumed, !isDegraded else { return }
                resumed = true
                continuation.resume(returning: image)
            }
        }
    }

    func loadFullImageData(for asset: PhotoAsset) async -> Data? {
        guard let phAsset = phAsset(for: asset) else { return nil }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        return await withCheckedContinuation { continuation in
            imageManager.requestImageDataAndOrientation(
                for: phAsset,
                options: options
            ) { data, _, _, _ in
                continuation.resume(returning: data)
            }
        }
    }

    func loadFilename(for asset: PhotoAsset) async -> String? {
        guard let phAsset = phAsset(for: asset) else { return nil }
        return PHAssetResource.assetResources(for: phAsset).first?.originalFilename
    }

    private func phAsset(for asset: PhotoAsset) -> PHAsset? { phAsset(forID: asset.id) }

    /// Cached lookup, falling back to a single-identifier fetch on a cache miss.
    private func phAsset(forID id: String) -> PHAsset? {
        if let cached = assetCache[id] { return cached }
        let fetched = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
        if let fetched { assetCache[id] = fetched }
        return fetched
    }
}
