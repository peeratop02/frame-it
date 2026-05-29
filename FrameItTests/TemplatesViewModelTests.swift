import Testing
import Foundation
@testable import FrameIt

@MainActor
struct TemplatesViewModelTests {

    private func seededStore(_ names: [String]) -> MockTemplateStore {
        let store = MockTemplateStore()
        for name in names { try? store.save(name: name, style: .default, thumbnail: nil) }
        return store
    }

    @Test func loadPopulatesTemplates() {
        let vm = TemplatesViewModel(store: seededStore(["A", "B"]))
        vm.load()
        #expect(vm.templates.map(\.name) == ["A", "B"])
    }

    @Test func renameUpdatesState() {
        let vm = TemplatesViewModel(store: seededStore(["Old"]))
        vm.load()
        vm.rename(id: vm.templates[0].id, to: "New")
        #expect(vm.templates[0].name == "New")
    }

    @Test func blankRenameIsIgnored() {
        let vm = TemplatesViewModel(store: seededStore(["Keep"]))
        vm.load()
        vm.rename(id: vm.templates[0].id, to: "   ")
        #expect(vm.templates[0].name == "Keep")
    }

    @Test func deleteRemovesTemplate() {
        let vm = TemplatesViewModel(store: seededStore(["A", "B"]))
        vm.load()
        vm.delete(id: vm.templates[0].id)
        #expect(vm.templates.map(\.name) == ["B"])
    }

    @Test func moveReorders() {
        let vm = TemplatesViewModel(store: seededStore(["A", "B", "C"]))
        vm.load()
        vm.move(from: IndexSet(integer: 0), to: 3)   // move A to the end
        #expect(vm.templates.map(\.name) == ["B", "C", "A"])
    }

    @Test func loadErrorSurfacesAlert() {
        let store = MockTemplateStore()
        store.shouldThrow = true
        let vm = TemplatesViewModel(store: store)
        vm.load()
        #expect(vm.alert != nil)
    }
}
