import Foundation
import Photos
import UIKit

enum ExportError: LocalizedError {
    case notAuthorized
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Frame It needs permission to add photos to your library. Enable it in Settings."
        case .saveFailed(let error):
            return "Couldn't save the photo: \(error.localizedDescription)"
        }
    }
}

/// Saves a rendered framed photo back to the user's library using add-only
/// authorization (we never need to read existing photos to write a new one).
struct ExportService {
    func saveToPhotos(_ image: UIImage) async throws {
        let status = await ensureAddAuthorization()
        guard status == .authorized || status == .limited else {
            throw ExportError.notAuthorized
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        } catch {
            throw ExportError.saveFailed(error)
        }
    }

    private func ensureAddAuthorization() async -> PHAuthorizationStatus {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        guard current == .notDetermined else { return current }
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
    }
}
