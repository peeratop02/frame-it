import Testing
import Photos
@testable import FrameIt

@MainActor
struct LibraryViewModelTests {

    @Test func authorizedLoadsAssetsOnAppear() async {
        let mock = MockPhotoLibraryService(status: .authorized, assets: [.sample()])
        let viewModel = LibraryViewModel(library: mock)

        await viewModel.onAppear()

        #expect(viewModel.phase == .loaded)
        #expect(viewModel.assets.count == 1)
    }

    @Test func notDeterminedStaysUndetermined() async {
        let mock = MockPhotoLibraryService(status: .notDetermined)
        let viewModel = LibraryViewModel(library: mock)

        await viewModel.onAppear()

        #expect(viewModel.phase == .undetermined)
        #expect(viewModel.assets.isEmpty)
    }

    @Test func deniedAccessShowsDeniedPhase() async {
        let mock = MockPhotoLibraryService(status: .denied)
        let viewModel = LibraryViewModel(library: mock)

        await viewModel.onAppear()

        #expect(viewModel.phase == .denied)
    }

    @Test func requestingAccessGrantsAndLoads() async {
        let mock = MockPhotoLibraryService(status: .notDetermined,
                                           requestResult: .authorized,
                                           assets: [.sample(), .sample(id: "sample-2")])
        let viewModel = LibraryViewModel(library: mock)

        await viewModel.requestAccess()

        #expect(viewModel.phase == .loaded)
        #expect(viewModel.assets.count == 2)
    }

    @Test func requestingAccessDeniedShowsDeniedPhase() async {
        let mock = MockPhotoLibraryService(status: .notDetermined, requestResult: .denied)
        let viewModel = LibraryViewModel(library: mock)

        await viewModel.requestAccess()

        #expect(viewModel.phase == .denied)
    }
}
