import SwiftUI

/// One album's photos as a pinch-to-zoom grid. Tapping a photo opens the editor, exactly
/// like the main Library grid.
struct AlbumDetailView: View {
    let album: PhotoAlbum
    let viewModel: AlbumsViewModel

    @State private var assets: [PhotoAsset] = []
    @State private var isLoaded = false
    @State private var selectedAsset: PhotoAsset?

    var body: some View {
        content
            .navigationTitle(album.title)
            .navigationBarTitleDisplayMode(.inline)
            .task(id: album.id) {
                assets = await viewModel.assets(in: album)
                isLoaded = true
            }
            .fullScreenCover(item: $selectedAsset) { asset in
                EditorView(asset: asset)
            }
    }

    @ViewBuilder
    private var content: some View {
        if !isLoaded {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if assets.isEmpty {
            ContentUnavailableView("No Photos", systemImage: "photo",
                                   description: Text("This album has no photos."))
        } else {
            PhotoGrid(assets: assets,
                      loader: viewModel.thumbnail,
                      onSelect: { selectedAsset = $0 })
        }
    }
}
