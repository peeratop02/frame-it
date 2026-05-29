import SwiftUI
import UIKit

/// The Photos tab: a pinch-to-zoom grid gallery with a Library / Albums segmented
/// control. Tapping a photo opens the Editor as a full-screen cover.
struct LibraryView: View {
    enum Section: String, CaseIterable, Identifiable {
        case library = "Library"
        case albums = "Albums"
        var id: String { rawValue }
    }

    @State private var viewModel = LibraryViewModel()
    @State private var section: Section = .library
    @State private var selectedAsset: PhotoAsset?

    /// Photos per row. 3 = fewest/largest (minimum), up to 8 = most/smallest.
    /// Persisted so the chosen density survives relaunches.
    @AppStorage("libraryColumnCount") private var columnCount: Int = Self.minColumns
    /// Column count when the current pinch began, so deltas are relative.
    @State private var pinchBaseColumnCount: Int?

    private static let minColumns = 3
    private static let maxColumns = 8

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 2), count: columnCount)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Frame It")
                .toolbarTitleDisplayMode(.inlineLarge)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Picker("Section", selection: $section) {
                            ForEach(Section.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 240)
                    }
                }
        }
        .task { await viewModel.onAppear() }
        .fullScreenCover(item: $selectedAsset) { asset in
            EditorView(asset: asset)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch section {
        case .albums:
            AlbumsView()
        case .library:
            libraryContent
        }
    }

    @ViewBuilder
    private var libraryContent: some View {
        switch viewModel.phase {
        case .undetermined:
            PhotoPermissionView(denied: false) {
                Task { await viewModel.requestAccess() }
            }
        case .denied:
            PhotoPermissionView(denied: true, onRequest: {})
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded:
            if viewModel.assets.isEmpty {
                ContentUnavailableView("No Photos", systemImage: "photo",
                                       description: Text("Your photo library looks empty."))
            } else {
                grid
            }
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(viewModel.assets) { asset in
                    PhotoGridCell(asset: asset, loader: viewModel.thumbnail)
                        .onTapGesture { selectedAsset = asset }
                        .accessibilityLabel("Photo")
                        .accessibilityAddTraits(.isButton)
                }
            }
            .padding(.horizontal, 2)
            .animation(.snappy, value: columnCount)
        }
        .gesture(zoomGesture)
    }

    /// Pinch to change grid density. Spreading fingers (magnification > 1) zooms *in* —
    /// bigger photos, fewer columns; pinching closed adds columns. Clamped to 3...8.
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

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    LibraryView()
}
