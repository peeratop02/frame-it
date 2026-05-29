import SwiftUI

/// A square thumbnail cell. Loads its image lazily and cancels automatically
/// when scrolled offscreen (via `.task(id:)`).
struct PhotoGridCell: View {
    let asset: PhotoAsset
    let loader: (PhotoAsset, CGSize) async -> UIImage?

    @State private var image: UIImage?

    private let targetSize = CGSize(width: 400, height: 400)

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color(.secondarySystemFill))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .contentShape(.rect)
            .task(id: asset.id) {
                image = await loader(asset, targetSize)
            }
    }
}
