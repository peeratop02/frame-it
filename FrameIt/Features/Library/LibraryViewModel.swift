import SwiftUI
import Photos

/// Drives the photo grid: authorization state and the list of assets. Depends on
/// the `PhotoLibraryService` protocol so it can be tested with a mock.
@MainActor
@Observable
final class LibraryViewModel {
    enum Phase: Equatable {
        case undetermined   // not yet asked for access
        case denied         // access refused — send the user to Settings
        case loading
        case loaded
    }

    private(set) var assets: [PhotoAsset] = []
    private(set) var phase: Phase = .undetermined

    private let library: any PhotoLibraryService

    init(library: any PhotoLibraryService = PhotoKitLibraryService()) {
        self.library = library
    }

    func onAppear() async {
        switch library.authorizationStatus() {
        case .authorized, .limited:
            await load()
        case .notDetermined:
            phase = .undetermined
        default:
            phase = .denied
        }
    }

    func requestAccess() async {
        switch await library.requestAuthorization() {
        case .authorized, .limited:
            await load()
        default:
            phase = .denied
        }
    }

    func thumbnail(for asset: PhotoAsset, size: CGSize) async -> UIImage? {
        await library.loadThumbnail(for: asset, targetSize: size)
    }

    private func load() async {
        phase = .loading
        assets = await library.fetchAssets()
        phase = .loaded
    }
}
