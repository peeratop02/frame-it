import UIKit
@testable import FrameIt

/// In-memory `TemplateStore` for view-model tests. Optionally throws to exercise
/// error paths.
@MainActor
final class MockTemplateStore: TemplateStore {
    private(set) var saved: [SavedTemplate] = []
    var shouldThrow = false

    struct StoreError: Error {}

    func all() throws -> [SavedTemplate] {
        if shouldThrow { throw StoreError() }
        return saved.sorted { $0.sortIndex < $1.sortIndex }
    }

    func save(name: String, style: FrameStyle, thumbnail: UIImage?) throws {
        if shouldThrow { throw StoreError() }
        saved.append(SavedTemplate(id: UUID(), name: name, createdAt: .now,
                                   sortIndex: saved.count, style: style, thumbnail: thumbnail))
    }

    func rename(id: UUID, to name: String) throws {
        if shouldThrow { throw StoreError() }
        guard let index = saved.firstIndex(where: { $0.id == id }) else { return }
        let old = saved[index]
        saved[index] = SavedTemplate(id: old.id, name: name, createdAt: old.createdAt,
                                     sortIndex: old.sortIndex, style: old.style,
                                     thumbnail: old.thumbnail)
    }

    func delete(id: UUID) throws {
        if shouldThrow { throw StoreError() }
        saved.removeAll { $0.id == id }
    }

    func reorder(_ orderedIDs: [UUID]) throws {
        if shouldThrow { throw StoreError() }
        for (index, id) in orderedIDs.enumerated() {
            guard let pos = saved.firstIndex(where: { $0.id == id }) else { continue }
            let old = saved[pos]
            saved[pos] = SavedTemplate(id: old.id, name: old.name, createdAt: old.createdAt,
                                       sortIndex: index, style: old.style, thumbnail: old.thumbnail)
        }
    }
}
