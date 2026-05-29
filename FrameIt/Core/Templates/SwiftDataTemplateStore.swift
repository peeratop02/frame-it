import UIKit
import SwiftData

/// SwiftData-backed `TemplateStore`. Maps the `Template` `@Model` to/from the
/// value-type `SavedTemplate` the rest of the app consumes, and saves the context
/// after each mutation.
@MainActor
final class SwiftDataTemplateStore: TemplateStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func all() throws -> [SavedTemplate] {
        try fetchModels().map(Self.snapshot)
    }

    func save(name: String, style: FrameStyle, thumbnail: UIImage?) throws {
        let nextIndex = (try fetchModels().map(\.sortIndex).max() ?? -1) + 1
        let template = Template(name: name,
                                sortIndex: nextIndex,
                                style: style,
                                thumbnail: thumbnail?.pngData())
        context.insert(template)
        try context.save()
    }

    func update(id: UUID, name: String, style: FrameStyle, thumbnail: UIImage?) throws {
        guard let model = try model(for: id) else { return }
        model.name = name
        model.style = style
        model.thumbnail = thumbnail?.pngData()
        try context.save()
    }

    func rename(id: UUID, to name: String) throws {
        guard let model = try model(for: id) else { return }
        model.name = name
        try context.save()
    }

    func delete(id: UUID) throws {
        guard let model = try model(for: id) else { return }
        context.delete(model)
        try context.save()
    }

    func reorder(_ orderedIDs: [UUID]) throws {
        let models = try fetchModels()
        let byID = Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0) })
        for (index, id) in orderedIDs.enumerated() {
            byID[id]?.sortIndex = index
        }
        try context.save()
    }

    // MARK: - Helpers

    private func fetchModels() throws -> [Template] {
        let descriptor = FetchDescriptor<Template>(
            sortBy: [SortDescriptor(\.sortIndex, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    private func model(for id: UUID) throws -> Template? {
        var descriptor = FetchDescriptor<Template>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private static func snapshot(_ model: Template) -> SavedTemplate {
        SavedTemplate(
            id: model.id,
            name: model.name,
            createdAt: model.createdAt,
            sortIndex: model.sortIndex,
            style: model.style,
            thumbnail: model.thumbnail.flatMap(UIImage.init(data:))
        )
    }
}
