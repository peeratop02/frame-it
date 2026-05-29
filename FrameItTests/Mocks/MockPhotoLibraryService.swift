import Foundation
import Photos
import UIKit
@testable import FrameIt

/// In-memory `PhotoLibraryService` for testing view models without PhotoKit.
struct MockPhotoLibraryService: PhotoLibraryService {
    var status: PHAuthorizationStatus = .authorized
    var requestResult: PHAuthorizationStatus = .authorized
    var assets: [PhotoAsset] = []
    var fullData: Data?

    func authorizationStatus() -> PHAuthorizationStatus { status }
    func requestAuthorization() async -> PHAuthorizationStatus { requestResult }
    func fetchAssets() async -> [PhotoAsset] { assets }
    func loadThumbnail(for asset: PhotoAsset, targetSize: CGSize) async -> UIImage? { nil }
    func loadFullImageData(for asset: PhotoAsset) async -> Data? { fullData }
}

extension PhotoAsset {
    static func sample(id: String = "sample-1") -> PhotoAsset {
        PhotoAsset(id: id, pixelWidth: 4032, pixelHeight: 3024,
                   creationDate: Date(), filename: "IMG_0001.HEIC")
    }
}
