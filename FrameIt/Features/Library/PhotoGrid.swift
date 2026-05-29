import SwiftUI
import UIKit

/// A pinch-to-zoom photo grid shared by the Library and album detail screens. Spreading
/// fingers (magnification > 1) zooms *in* — bigger photos, fewer columns; pinching closed
/// adds columns. Clamped to 3...8 and persisted across the app via `@AppStorage`.
struct PhotoGrid: View {
    let assets: [PhotoAsset]
    let loader: (PhotoAsset, CGSize) async -> UIImage?
    let onSelect: (PhotoAsset) -> Void

    /// Photos per row, shared with every grid in the app. 3 = fewest/largest (minimum).
    @AppStorage("libraryColumnCount") private var columnCount: Int = Self.minColumns
    /// Column count when the current pinch began, so deltas are relative.
    @State private var pinchBaseColumnCount: Int?

    private static let minColumns = 3
    private static let maxColumns = 8

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 2), count: columnCount)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(assets) { asset in
                    PhotoGridCell(asset: asset, loader: loader)
                        .onTapGesture { onSelect(asset) }
                        .accessibilityLabel("Photo")
                        .accessibilityAddTraits(.isButton)
                }
            }
            .padding(.horizontal, 2)
            .animation(.snappy, value: columnCount)
        }
        .gesture(zoomGesture)
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let base = pinchBaseColumnCount ?? columnCount
                if pinchBaseColumnCount == nil { pinchBaseColumnCount = base }
                let step = Int(((value.magnification - 1) * 4).rounded())
                let target = (base - step).clamped(to: Self.minColumns...Self.maxColumns)
                if target != columnCount {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.snappy) { columnCount = target }
                }
            }
            .onEnded { _ in pinchBaseColumnCount = nil }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
