import Testing
@testable import FrameIt

struct PinCatalogTests {

    @Test func everyPinIDIsUnique() {
        let ids = PinCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func unknownIDFallsBackToDefault() {
        #expect(PinCatalog.icon(id: "does-not-exist").id == PinCatalog.defaultID)
    }

    @Test func defaultPinIsFree() {
        #expect(PinCatalog.icon(id: PinCatalog.defaultID).isPremium == false)
    }

    @Test func systemNameResolvesForDefault() {
        #expect(PinCatalog.systemName(id: PinCatalog.defaultID) == "mappin.circle.fill")
    }
}
