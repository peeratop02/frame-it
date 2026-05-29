import SwiftUI

/// The Photos tab: an adaptive grid gallery with a Library / Albums segmented
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

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 2)]

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
        }
    }
}

#Preview {
    LibraryView()
}
