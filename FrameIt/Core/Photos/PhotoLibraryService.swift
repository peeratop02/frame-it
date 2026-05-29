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
}

struct PhotoKitLibraryService: PhotoLibraryService {

    private let imageManager = PHImageManager.default()

    func authorizationStatus() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization() async -> PHAuthorizationStatus {
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
        assets.reserveCapacity(fetchResult.count)
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(
                PhotoAsset(
                    id: asset.localIdentifier,
                    pixelWidth: asset.pixelWidth,
                    pixelHeight: asset.pixelHeight,
                    creationDate: asset.creationDate,
                    filename: Self.originalFilename(for: asset)
                )
            )
        }
        return assets
    }

    private static func originalFilename(for asset: PHAsset) -> String? {
        PHAssetResource.assetResources(for: asset).first?.originalFilename
    }

    func loadThumbnail(for asset: PhotoAsset, targetSize: CGSize) async -> UIImage? {
        guard let phAsset = phAsset(for: asset) else { return nil }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat   // single callback, no degraded pass
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true

        return await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: phAsset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
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

    private func phAsset(for asset: PhotoAsset) -> PHAsset? {
        PHAsset.fetchAssets(withLocalIdentifiers: [asset.id], options: nil).firstObject
    }
}
