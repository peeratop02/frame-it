import Testing
import Foundation
import SwiftData
@testable import FrameIt

/// Exercises `SwiftDataTemplateStore` against an in-memory `ModelContainer` so no
/// disk/iCloud state leaks between tests.
@MainActor
struct TemplateStoreTests {

    private func makeStore() throws -> SwiftDataTemplateStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Template.self, configurations: config)
        return SwiftDataTemplateStore(context: container.mainContext)
    }

    /// A non-default style to prove every field survives the Data round-trip.
    private var customStyle: FrameStyle {
        var style = FrameStyle.default
        style.layout = .advanced
        style.shadowStrength = 0.6
        style.pinIcon = "heart.fill"
        style.enabledFields = [.device, .iso, .location]
        style.signature = Signature(customText: "© Peera", matchesFrameStyle: true, isHidden: false)
        return style
    }

    @Test func savesAndFetches() throws {
        let store = try makeStore()
        try store.save(name: "Sunset", style: customStyle, thumbnail: nil)

        let all = try store.all()
        #expect(all.count == 1)
        #expect(all[0].name == "Sunset")
    }

    @Test func styleSurvivesRoundTrip() throws {
        let store = try makeStore()
        try store.save(name: "Custom", style: customStyle, thumbnail: nil)

        let restored = try store.all()[0].style
        #expect(restored == customStyle)
    }

    @Test func renameUpdatesName() throws {
        let store = try makeStore()
        try store.save(name: "Old", style: .default, thumbnail: nil)
        let id = try store.all()[0].id

        try store.rename(id: id, to: "New")
        #expect(try store.all()[0].name == "New")
    }

    @Test func deleteRemovesTemplate() throws {
        let store = try makeStore()
        try store.save(name: "A", style: .default, thumbnail: nil)
        let id = try store.all()[0].id

        try store.delete(id: id)
        #expect(try store.all().isEmpty)
    }

    @Test func reorderRewritesSortOrder() throws {
        let store = try makeStore()
        try store.save(name: "First", style: .default, thumbnail: nil)
        try store.save(name: "Second", style: .default, thumbnail: nil)
        try store.save(name: "Third", style: .default, thumbnail: nil)

        let ids = try store.all().map(\.id)               // [First, Second, Third]
        let reversed = Array(ids.reversed())
        try store.reorder(reversed)

        #expect(try store.all().map(\.name) == ["Third", "Second", "First"])
    }

    @Test func saveAppendsToEndOfOrder() throws {
        let store = try makeStore()
        try store.save(name: "One", style: .default, thumbnail: nil)
        try store.save(name: "Two", style: .default, thumbnail: nil)
        #expect(try store.all().map(\.name) == ["One", "Two"])
    }
}
