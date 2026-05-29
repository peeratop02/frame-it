import SwiftUI

/// Drives the Templates tab: loads saved templates and edits them (rename / delete /
/// reorder). Depends on the `TemplateStore` protocol so it's testable with a mock.
@MainActor
@Observable
final class TemplatesViewModel {
    private(set) var templates: [SavedTemplate] = []
    var alert: EditorAlert?

    private let store: any TemplateStore

    init(store: any TemplateStore) {
        self.store = store
    }

    func load() {
        do {
            templates = try store.all()
        } catch {
            present(error, title: "Couldn't Load Templates")
        }
    }

    func rename(id: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try store.rename(id: id, to: trimmed)
            load()
        } catch {
            present(error, title: "Couldn't Rename")
        }
    }

    func delete(id: UUID) {
        do {
            try store.delete(id: id)
            load()
        } catch {
            present(error, title: "Couldn't Delete")
        }
    }

    /// Reorder for a SwiftUI `.onMove`: apply the move locally, then persist the new order.
    func move(from source: IndexSet, to destination: Int) {
        var reordered = templates
        reordered.move(fromOffsets: source, toOffset: destination)
        do {
            try store.reorder(reordered.map(\.id))
            load()
        } catch {
            present(error, title: "Couldn't Reorder")
        }
    }

    private func present(_ error: Error, title: String) {
        alert = EditorAlert(title: title, message: error.localizedDescription)
    }
}
