import SwiftUI
import SwiftData
import PhotosUI

/// The Templates tab: lists the user's saved frame styles for management. Templates
/// are *created* from the editor (⋯ → Save as Template) and *applied* there too; this
/// tab is for renaming, reordering, deleting, and editing a template's style (by
/// picking a photo to edit it against).
struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TemplatesViewModel?
    @State private var renameTarget: SavedTemplate?
    @State private var renameText = ""

    /// Drives the "Edit Style" flow: pick a photo, then open the editor in update-mode.
    @State private var editStyleTarget: SavedTemplate?
    @State private var pickerItem: PhotosPickerItem?
    @State private var editRequest: EditTemplateRequest?
    private let library: any PhotoLibraryService = PhotoKitLibraryService()

    /// A resolved photo + the template to update, used to present the editor.
    private struct EditTemplateRequest: Identifiable {
        let id = UUID()
        let asset: PhotoAsset
        let template: SavedTemplate
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Templates")
                .toolbar {
                    if let viewModel, !viewModel.templates.isEmpty {
                        ToolbarItem(placement: .topBarTrailing) { EditButton() }
                    }
                }
        }
        .task {
            if viewModel == nil {
                viewModel = TemplatesViewModel(store: SwiftDataTemplateStore(context: modelContext))
            }
            viewModel?.load()
        }
        .alert(item: alertBinding) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message),
                  dismissButton: .default(Text("OK")))
        }
        .alert("Rename Template", isPresented: renamePresented) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) { renameTarget = nil }
            Button("Save") {
                if let target = renameTarget {
                    viewModel?.rename(id: target.id, to: renameText)
                }
                renameTarget = nil
            }
        }
        .photosPicker(isPresented: photoPickerPresented, selection: $pickerItem,
                      matching: .images, photoLibrary: .shared())
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem, let template = editStyleTarget else { return }
            Task { await beginEditStyle(item: newItem, template: template) }
        }
        .fullScreenCover(item: $editRequest, onDismiss: { viewModel?.load() }) { request in
            EditorView(asset: request.asset, editingTemplate: request.template)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel, !viewModel.templates.isEmpty {
            List {
                ForEach(viewModel.templates) { template in
                    TemplateCard(template: template)
                        .contentShape(.rect)
                        .onTapGesture { beginRename(template) }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.delete(id: template.id)
                            } label: { Label("Delete", systemImage: "trash") }
                            Button {
                                beginRename(template)
                            } label: { Label("Rename", systemImage: "pencil") }
                            .tint(Theme.accent)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                beginEditStyle(template)
                            } label: { Label("Edit Style", systemImage: "slider.horizontal.3") }
                            .tint(.indigo)
                        }
                        .contextMenu {
                            Button { beginEditStyle(template) } label: {
                                Label("Edit Style", systemImage: "slider.horizontal.3")
                            }
                            Button { beginRename(template) } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            Button(role: .destructive) { viewModel.delete(id: template.id) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .onDelete { offsets in
                    offsets.map { viewModel.templates[$0].id }.forEach(viewModel.delete)
                }
                .onMove { viewModel.move(from: $0, to: $1) }
            }
        } else {
            ContentUnavailableView {
                Label("No Templates", systemImage: "square.stack")
            } description: {
                Text("Save a frame as a template from the editor (⋯ menu) to reuse its style.")
            }
        }
    }

    private func beginRename(_ template: SavedTemplate) {
        renameTarget = template
        renameText = template.name
    }

    /// Start the "Edit Style" flow by asking the user to pick a photo to edit against.
    private func beginEditStyle(_ template: SavedTemplate) {
        pickerItem = nil
        editStyleTarget = template
    }

    /// Resolve the picked photo to a `PhotoAsset` and open the editor in update-mode.
    private func beginEditStyle(item: PhotosPickerItem, template: SavedTemplate) async {
        defer { editStyleTarget = nil; pickerItem = nil }
        guard let id = item.itemIdentifier, let asset = await library.asset(withID: id) else {
            viewModel?.alert = EditorAlert(title: "Couldn't Open Photo",
                                           message: "That photo couldn't be loaded. Try another.")
            return
        }
        editRequest = EditTemplateRequest(asset: asset, template: template)
    }

    private var photoPickerPresented: Binding<Bool> {
        Binding(get: { editStyleTarget != nil && editRequest == nil },
                set: { if !$0 { editStyleTarget = nil } })
    }

    private var renamePresented: Binding<Bool> {
        Binding(get: { renameTarget != nil },
                set: { if !$0 { renameTarget = nil } })
    }

    private var alertBinding: Binding<EditorAlert?> {
        Binding(get: { viewModel?.alert },
                set: { viewModel?.alert = $0 })
    }
}
