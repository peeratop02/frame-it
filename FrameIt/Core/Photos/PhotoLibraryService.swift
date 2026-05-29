import Foundation
import Photos
import UIKit

/// Wraps PhotoKit behind a protocol so the Library/Editor view models can be
/// driven by a mock in tests (no real photo library access).
protocol PhotoLibraryService: Sendable {
    func authorizationStatus() -> PHAuthorizationStatus
    func requestAuthorization() async -> PHAuthorizationStatus
    func fetchAssets() async -> [PhotoAsset]
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

        var assets: [PhotoAsset] = []
        var cache: [String: PHAsset] = [:]
        assets.reserveCapacity(fetchResult.count)
        cache.reserveCapacity(fetchResult.count)
        // Cheap property reads only — no `PHAssetResource` lookups here. The original
        // filename is resolved lazily by `loadFilename` when a photo opens in the editor.
        fetchResult.enumerateObjects { asset, _, _ in
            cache[asset.localIdentifier] = asset
            assets.append(
                PhotoAsset(
                    id: asset.localIdentifier,
                    pixelWidth: asset.pixelWidth,
                    pixelHeight: asset.pixelHeight,
                    creationDate: asset.creationDate,
                    filename: nil
                )
            )
        }
        assetCache = cache
        return assets
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

    /// Cached lookup, falling back to a single-identifier fetch on a cache miss.
    private func phAsset(for asset: PhotoAsset) -> PHAsset? {
        if let cached = assetCache[asset.id] { return cached }
        let fetched = PHAsset.fetchAssets(withLocalIdentifiers: [asset.id], options: nil).firstObject
        if let fetched { assetCache[asset.id] = fetched }
        return fetched
    }
}
