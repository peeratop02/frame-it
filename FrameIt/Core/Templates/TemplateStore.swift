import UIKit

/// Persistence boundary for saved templates (repository pattern). View models depend
/// on this protocol so they're unit-testable with an in-memory mock; the production
/// impl is `SwiftDataTemplateStore`. `@MainActor` because the SwiftData `ModelContext`
/// it wraps is main-actor bound.
@MainActor
protocol TemplateStore {
    /// All saved templates, ordered by `sortIndex` ascending.
    func all() throws -> [SavedTemplate]
    /// Persist a new template; it's appended to the end of the order.
    func save(name: String, style: FrameStyle, thumbnail: UIImage?) throws
    /// Overwrite an existing template's name, style, and thumbnail (keeps its order/date).
    func update(id: UUID, name: String, style: FrameStyle, thumbnail: UIImage?) throws
    func rename(id: UUID, to name: String) throws
    func delete(id: UUID) throws
    /// Rewrite `sortIndex` to match the given id order.
    func reorder(_ orderedIDs: [UUID]) throws
}
