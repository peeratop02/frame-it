import SwiftUI

/// Albums tab: lists user + smart albums with a cover thumbnail. Tapping an album pushes
/// its photo grid. Rendered inside the Photos tab's `NavigationStack` (see `LibraryView`).
struct AlbumsView: View {
    @State private var viewModel = AlbumsViewModel()

    var body: some View {
        content
            .navigationDestination(for: PhotoAlbum.self) { album in
                AlbumDetailView(album: album, viewModel: viewModel)
            }
            .task { if !viewModel.isLoaded { await viewModel.load() } }
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.isLoaded {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.albums.isEmpty {
            ContentUnavailableView {
                Label("No Albums", systemImage: "rectangle.stack")
            } description: {
                Text("Albums you create in Photos will appear here. For now, pick any photo from your Library.")
            }
        } else {
            List(viewModel.albums) { album in
                NavigationLink(value: album) {
                    AlbumRow(album: album, viewModel: viewModel)
                }
            }
            .listStyle(.plain)
        }
    }
}

/// One album row: cover thumbnail, title, and photo count.
private struct AlbumRow: View {
    let album: PhotoAlbum
    let viewModel: AlbumsViewModel

    @State private var cover: UIImage?
    private let coverSize = CGSize(width: 120, height: 120)

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.secondarySystemFill))
                .frame(width: 56, height: 56)
                .overlay {
                    if let cover {
                        Image(uiImage: cover).resizable().scaledToFill()
                    } else {
                        Image(systemName: "photo").foregroundStyle(.secondary)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(album.title).font(.body)
                Text("\(album.count)").font(.caption).foregroundStyle(.secondary)
            }
        }
        .task(id: album.id) {
            cover = await viewModel.coverImage(for: album, size: coverSize)
        }
    }
}
