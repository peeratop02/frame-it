import SwiftUI
import UIKit

/// Renders a `FramePreview` to a full-resolution `UIImage` for export. Lays out
/// at a manageable point width then scales up so the photo region is reproduced
/// at roughly its native pixel resolution.
@MainActor
struct FrameRenderer {
    /// Logical layout width; export scale is derived from this.
    private let baseWidth: CGFloat = 1200

    func render(photo: UIImage, style: FrameStyle, metadata: PhotoMetadata,
                mapSnapshot: UIImage? = nil) -> UIImage? {
        let content = FramePreview(image: photo, style: style, metadata: metadata,
                                   width: baseWidth, mapSnapshot: mapSnapshot)
        let renderer = ImageRenderer(content: content)

        let photoPixelWidth = photo.size.width * photo.scale
        renderer.scale = max(photoPixelWidth / baseWidth, 1)
        renderer.isOpaque = style.background.opacity >= 1

        return renderer.uiImage
    }
}
