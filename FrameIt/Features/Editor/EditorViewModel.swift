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

    /// Saved templates available to apply to the current photo. Loaded once the
    /// store is attached (see `attach(store:)`).
    private(set) var savedTemplates: [SavedTemplate] = []
    /// On-device template persistence, injected by the view once the SwiftData
    /// `ModelContext` from the environment is available.
    var templateStore: (any TemplateStore)?

    /// The style the editor opened with; used to detect unsaved edits on close.
    private var initialStyle: FrameStyle = .default
    /// The template this session derives from (applied here or opened for editing), or nil.
    /// When set, the editor offers "Update '<name>'" and Save targets that template.
    private(set) var appliedTemplate: SavedTemplate?
    /// Whether the user has changed the frame since opening the editor.
    var hasUnsavedChanges: Bool { style != initialStyle }
    /// Filename shown in the editor header. Resolved lazily in `load()` (kept off the
    /// Photos grid path, where per-asset filename lookups cost seconds).
    private(set) var photoFilename: String?

    private(set) var isLoading = true
    private(set) var isExporting = false
    var alert: EditorAlert?
    var shareItem: ShareImage?
    /// Bumped on a successful export to trigger success haptics.
    private(set) var exportSuccessCount = 0
    /// Set when an action is blocked by entitlements; the view presents the upsell.
    var pendingUpsell: PremiumFeature?
    /// True when the last applied template had premium features stripped because the
    /// current tier doesn't unlock them. The view shows an inline "upgrade" note.
    var lastApplyWasDowngraded = false

    private let library: any PhotoLibraryService
    private let metadataService: any MetadataService
    private let exporter: ExportService
    private let entitlements: any EntitlementProvider
    private let renderer = FrameRenderer()
    private let mapRenderer = MapSnapshotRenderer()

    /// Free tier may keep at most this many saved templates.
    static let freeTemplateLimit = 2

    init(
        asset: PhotoAsset,
        editingTemplate: SavedTemplate? = nil,
        library: any PhotoLibraryService = PhotoKitLibraryService(),
        metadataService: any MetadataService = ImageIOMetadataService(),
        exporter: ExportService = ExportService(),
        entitlements: any EntitlementProvider = StoreKitEntitlementService.shared
    ) {
        self.asset = asset
        self.library = library
        self.metadataService = metadataService
        self.exporter = exporter
        self.entitlements = entitlements

        if let editingTemplate {
            // Opened to edit an existing template: start from its style and target it on Save.
            style = editingTemplate.style
            initialStyle = editingTemplate.style
            appliedTemplate = editingTemplate
        } else if let storedFontID = UserDefaults.standard.string(forKey: FontCatalog.defaultSelectionKey),
                  FontCatalog.all.contains(where: { $0.id == storedFontID }) {
            // Seed the opening typeface from the user's chosen default font (a paid
            // setting). A view model isn't a View, so read UserDefaults directly. Unknown
            // or missing ids leave the system default. Both the live and baseline styles
            // get the seed so it doesn't count as an unsaved change.
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
        photoFilename = await library.loadFilename(for: asset)

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

    // MARK: - Templates

    /// Attach the persistence store and load saved templates. Called by the view
    /// once the SwiftData `ModelContext` from the environment is available.
    func attach(store: any TemplateStore) {
        templateStore = store
        loadTemplates()
    }

    func loadTemplates() {
        savedTemplates = (try? templateStore?.all()) ?? []
    }

    /// Apply a saved template to the current photo. Keeps the photo and its metadata;
    /// counts as an unsaved change so the close prompt still appears. Remembers the source
    /// template so Save can offer to update it instead of creating a duplicate.
    func apply(_ template: SavedTemplate) {
        // A template built with premium features is sanitized down to what the
        // current tier allows, so the preview (and export) never show a locked look.
        let needed = template.style.requiresTier()
        lastApplyWasDowngraded = needed > entitlements.tier
        style = lastApplyWasDowngraded
            ? template.style.sanitized(for: entitlements.tier)
            : template.style
        appliedTemplate = template
        if style.placeStyle == .map { Task { await ensureMapSnapshot() } }
    }

    /// A reasonable default name for a new template ("Template 1", "Template 2", …).
    var suggestedTemplateName: String { "Template \(savedTemplates.count + 1)" }

    /// Save the current style as a reusable template, rendering a small thumbnail.
    /// If a template with the same name already exists, it is updated rather than
    /// duplicated — so "apply → edit → save with the same name" overwrites the original.
    func saveAsTemplate(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? suggestedTemplateName : trimmed
        guard let store = templateStore else { return }
        let existing = savedTemplates.first {
            $0.name.caseInsensitiveCompare(finalName) == .orderedSame
        }
        // Free tier is capped: creating a *new* template beyond the limit is gated.
        // Updating an existing template (same name) is always allowed.
        if existing == nil,
           !entitlements.isUnlocked(.unlimitedTemplates),
           savedTemplates.count >= Self.freeTemplateLimit {
            pendingUpsell = .unlimitedTemplates
            return
        }
        let thumbnail = templateThumbnail()
        do {
            if let existing {
                try store.update(id: existing.id, name: finalName, style: style, thumbnail: thumbnail)
                appliedTemplate = existing
                loadTemplates()
                alert = EditorAlert(title: "Template Updated",
                                    message: "“\(finalName)” was updated.")
            } else {
                try store.save(name: finalName, style: style, thumbnail: thumbnail)
                loadTemplates()
                appliedTemplate = savedTemplates.first {
                    $0.name.caseInsensitiveCompare(finalName) == .orderedSame
                }
                alert = EditorAlert(title: "Template Saved",
                                    message: "“\(finalName)” is in your Templates tab.")
            }
        } catch {
            alert = EditorAlert(title: "Couldn't Save Template",
                                message: error.localizedDescription)
        }
    }

    /// Update the template this session derives from with the current style + a fresh
    /// thumbnail. No-op if the editor isn't tied to a template.
    func updateAppliedTemplate() {
        guard let store = templateStore, let target = appliedTemplate else { return }
        let thumbnail = templateThumbnail()
        do {
            try store.update(id: target.id, name: target.name, style: style, thumbnail: thumbnail)
            loadTemplates()
            // Refresh the cached snapshot so a subsequent update keeps targeting it.
            appliedTemplate = savedTemplates.first { $0.id == target.id }
            alert = EditorAlert(title: "Template Updated",
                                message: "“\(target.name)” was updated.")
        } catch {
            alert = EditorAlert(title: "Couldn't Update Template",
                                message: error.localizedDescription)
        }
    }

    /// The style actually rendered/exported: forced down to what the current tier
    /// allows. A no-op for a normally-gated session (the UI already prevents picking
    /// locked options) — a safety net so a lapsed entitlement can't leak a paid look.
    private var exportStyle: FrameStyle { style.sanitized(for: entitlements.tier) }

    /// A downscaled (~300pt) framed preview for the template grid.
    private func templateThumbnail() -> UIImage? {
        guard let source = sourceImage,
              let full = renderer.render(photo: source, style: exportStyle, metadata: metadata,
                                         mapSnapshot: mapSnapshot) else { return nil }
        let maxSide: CGFloat = 300
        let scale = min(maxSide / max(full.size.width, full.size.height), 1)
        let target = CGSize(width: full.size.width * scale, height: full.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            full.draw(in: CGRect(origin: .zero, size: target))
        }
    }

    private func renderCurrent() -> UIImage? {
        guard let source = sourceImage else { return nil }
        guard let image = renderer.render(photo: source, style: exportStyle, metadata: metadata,
                                          mapSnapshot: mapSnapshot) else {
            alert = EditorAlert(title: "Render Failed",
                                message: "Something went wrong creating the framed image.")
            return nil
        }
        return image
    }
}
