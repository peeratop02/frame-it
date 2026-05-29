import SwiftUI
import SwiftData

/// The Templates tab: lists the user's saved frame styles for management. Templates
/// are *created* from the editor (⋯ → Save as Template) and *applied* there too; this
/// tab is for renaming, reordering, and deleting them.
struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TemplatesViewModel?
    @State private var renameTarget: SavedTemplate?
    @State private var renameText = ""

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

    private var renamePresented: Binding<Bool> {
        Binding(get: { renameTarget != nil },
                set: { if !$0 { renameTarget = nil } })
    }

    private var alertBinding: Binding<EditorAlert?> {
        Binding(get: { viewModel?.alert },
                set: { viewModel?.alert = $0 })
    }
}
