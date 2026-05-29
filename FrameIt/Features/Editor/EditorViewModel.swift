import SwiftUI

/// Identifiable wrapper so a rendered image can drive a `.sheet(item:)` share sheet.
struct ShareImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// Identifiable alert payload for success/error messaging.
struct EditorAlert: Identifiable {
    let id = UUID()
    var title: String
    var message: String
}

/// Owns the editing session for one photo: loads the source image + metadata,
/// holds the mutable `FrameStyle`, and renders/exports the result.
@MainActor
@Observable
final class EditorViewModel {
    let asset: PhotoAsset

    private(set) var sourceImage: UIImage?
    private(set) var metadata: PhotoMetadata = .empty
    /// A pre-rendered minimap for the Place column's map mode (nil until generated).
    private(set) var mapSnapshot: UIImage?
    var style: FrameStyle = .default

    /// The style the editor opened with; used to detect unsaved edits on close.
    private var initialStyle: FrameStyle = .default
    /// Whether the user has changed the frame since opening the editor.
    var hasUnsavedChanges: Bool { style != initialStyle }
    /// Filename shown in the editor header.
    var photoFilename: String? { asset.filename }

    private(set) var isLoading = true
    private(set) var isExporting = false
    var alert: EditorAlert?
    var shareItem: ShareImage?
    /// Bumped on a successful export to trigger success haptics.
    private(set) var exportSuccessCount = 0

    private let library: any PhotoLibraryService
    private let metadataService: any MetadataService
    private let exporter: ExportService
    private let renderer = FrameRenderer()
    private let mapRenderer = MapSnapshotRenderer()

    init(
        asset: PhotoAsset,
        library: any PhotoLibraryService = PhotoKitLibraryService(),
        metadataService: any MetadataService = ImageIOMetadataService(),
        exporter: ExportService = ExportService()
    ) {
        self.asset = asset
        self.library = library
        self.metadataService = metadataService
        self.exporter = exporter

        // Seed the opening typeface from the user's chosen default font (a paid
        // setting). A view model isn't a View, so read UserDefaults directly. Unknown
        // or missing ids leave the system default. Both the live and baseline styles
        // get the seed so it doesn't count as an unsaved change.
        if let storedFontID = UserDefaults.standard.string(forKey: FontCatalog.defaultSelectionKey),
           FontCatalog.all.contains(where: { $0.id == storedFontID }) {
            style.fontID = storedFontID
            initialStyle.fontID = storedFontID
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        guard let data = await library.loadFullImageData(for: asset) else {
            alert = EditorAlert(title: "Couldn't Load Photo",
                                message: "This photo couldn't be opened. Try another one.")
            return
        }
        sourceImage = UIImage(data: data)
        metadata = metadataService.metadata(from: data)

        // Reverse-geocode in the background; refresh the place name when ready.
        if metadata.hasLocation {
            metadata = await metadataService.reverseGeocode(metadata)
            // Generate the minimap eagerly so switching to map mode is instant.
            await ensureMapSnapshot()
        }
    }

    /// Render the minimap once (coordinates are fixed for a photo). Safe to call
    /// repeatedly — returns immediately if already rendered or there's no location.
    func ensureMapSnapshot() async {
        guard mapSnapshot == nil,
              let lat = metadata.latitude, let lon = metadata.longitude else { return }
        mapSnapshot = await mapRenderer.snapshot(latitude: lat, longitude: lon)
    }

    func exportToPhotos() async {
        // Safety net: ensure the minimap exists before rendering in map mode.
        if style.placeStyle == .map { await ensureMapSnapshot() }
        guard let rendered = renderCurrent() else { return }
        isExporting = true
        defer { isExporting = false }
        do {
            try await exporter.saveToPhotos(rendered)
            exportSuccessCount += 1
            alert = EditorAlert(title: "Saved", message: "Your framed photo is in your library.")
        } catch {
            alert = EditorAlert(title: "Couldn't Save",
                                message: error.localizedDescription)
        }
    }

    func share() {
        guard let rendered = renderCurrent() else { return }
        shareItem = ShareImage(image: rendered)
    }

    private func renderCurrent() -> UIImage? {
        guard let source = sourceImage else { return nil }
        guard let image = renderer.render(photo: source, style: style, metadata: metadata,
                                          mapSnapshot: mapSnapshot) else {
            alert = EditorAlert(title: "Render Failed",
                                message: "Something went wrong creating the framed image.")
            return nil
        }
        return image
    }
}
