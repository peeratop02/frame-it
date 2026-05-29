import SwiftUI
import SwiftData

/// Full-screen editor: live preview in the center, a Liquid Glass control dock
/// pinned to the bottom (thumb zone), and a close/share header on top.
struct EditorView: View {
    enum Panel: String, CaseIterable, Identifiable {
        case background = "Frame"
        case text = "Text"
        case details = "Details"
        case credit = "Credit"
        var id: String { rawValue }
        var systemImage: String {
            switch self {
            case .background: return "square.on.square"
            case .text: return "textformat"
            case .details: return "list.bullet"
            case .credit: return "signature"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: EditorViewModel
    @State private var panel: Panel = .background
    @State private var showDiscardConfirm = false
    @State private var showSaveTemplate = false
    @State private var templateName = ""

    init(asset: PhotoAsset) {
        _viewModel = State(initialValue: EditorViewModel(asset: asset))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            Theme.editorCanvas.ignoresSafeArea()

            VStack(spacing: 12) {
                header
                previewArea
                controlDock(viewModel: viewModel)
            }
        }
        .task {
            viewModel.attach(store: SwiftDataTemplateStore(context: modelContext))
            await viewModel.load()
        }
        .onChange(of: viewModel.style.placeStyle) { _, mode in
            if mode == .map { Task { await viewModel.ensureMapSnapshot() } }
        }
        .sensoryFeedback(.success, trigger: viewModel.exportSuccessCount)
        .alert(item: $viewModel.alert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message),
                  dismissButton: .default(Text("OK")))
        }
        .sheet(item: $viewModel.shareItem) { item in
            ShareSheet(items: [item.image])
        }
        .confirmationDialog("Discard your changes?",
                            isPresented: $showDiscardConfirm,
                            titleVisibility: .visible) {
            Button("Discard Changes", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("Your edits to this frame haven't been saved.")
        }
        .alert("Save as Template", isPresented: $showSaveTemplate) {
            TextField("Name", text: $templateName)
            Button("Cancel", role: .cancel) {}
            Button("Save") { viewModel.saveAsTemplate(named: templateName) }
        } message: {
            Text("Reuse this frame's style on other photos.")
        }
    }

    private func attemptClose() {
        if viewModel.hasUnsavedChanges {
            showDiscardConfirm = true
        } else {
            dismiss()
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            if let filename = viewModel.photoFilename {
                Text(filename)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 100)   // keep clear of the side buttons
            }

            HStack(spacing: 0) {
                GlassIconButton(systemImage: "xmark", accessibilityLabel: "Close") {
                    attemptClose()
                }
                Spacer()
                actionButtons
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    /// Template menu, Share, and Save, paired as a single glass cluster in the top-right.
    private var actionButtons: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                GlassMenuButton(systemImage: "ellipsis", accessibilityLabel: "More") {
                    templateMenu
                }
                .disabled(viewModel.sourceImage == nil)

                GlassIconButton(systemImage: "square.and.arrow.up",
                                accessibilityLabel: "Share") {
                    viewModel.share()
                }
                .disabled(viewModel.sourceImage == nil)

                GlassIconButton(accessibilityLabel: "Save to Photos",
                                prominent: true) {
                    Task { await viewModel.exportToPhotos() }
                } label: {
                    if viewModel.isExporting {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
                .disabled(viewModel.sourceImage == nil || viewModel.isExporting)
            }
        }
    }

    /// Contents of the ⋯ menu: save the current style as a template, and apply an
    /// existing one to this photo.
    @ViewBuilder
    private var templateMenu: some View {
        Button {
            templateName = viewModel.suggestedTemplateName
            showSaveTemplate = true
        } label: {
            Label("Save as Template…", systemImage: "square.stack.badge.plus")
        }

        if !viewModel.savedTemplates.isEmpty {
            Menu {
                ForEach(viewModel.savedTemplates) { template in
                    Button(template.name) { viewModel.apply(template.style) }
                }
            } label: {
                Label("Apply Template", systemImage: "square.stack")
            }
        }
    }

    // MARK: Preview

    private var previewArea: some View {
        GeometryReader { geo in
            ZStack {
                if let image = viewModel.sourceImage {
                    FittedFramePreview(image: image,
                                       style: viewModel.style,
                                       metadata: viewModel.metadata,
                                       available: geo.size,
                                       mapSnapshot: viewModel.mapSnapshot)
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: Control dock

    private func controlDock(viewModel: EditorViewModel) -> some View {
        @Bindable var viewModel = viewModel

        return VStack(spacing: 16) {
            Picker("Panel", selection: $panel) {
                ForEach(Panel.allCases) { panel in
                    Label(panel.rawValue, systemImage: panel.systemImage).tag(panel)
                }
            }
            .pickerStyle(.segmented)

            ScrollView {
                activePanel(style: $viewModel.style)
                    .padding(.horizontal, 2)
            }
            .frame(maxHeight: 240)
        }
        .padding(20)
        .glassCard()
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func activePanel(style: Binding<FrameStyle>) -> some View {
        switch panel {
        case .background:
            BackgroundControls(style: style)
        case .text:
            TypographyControls(style: style)
        case .details:
            MetadataControls(style: style, metadata: viewModel.metadata)
        case .credit:
            SignatureControls(style: style)
        }
    }
}
