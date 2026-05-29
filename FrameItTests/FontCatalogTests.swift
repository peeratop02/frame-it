import Testing
@testable import FrameIt

struct FontCatalogTests {

    @Test func everyFontIDIsUnique() {
        let ids = FontCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func unknownIDFallsBackToDefault() {
        #expect(FontCatalog.font(id: "does-not-exist").id == FontCatalog.defaultID)
    }

    @Test func defaultFontIsFree() {
        #expect(FontCatalog.font(id: FontCatalog.defaultID).isPremium == false)
    }

    @Test func everyCategoryHasAtLeastOneFreeFont() {
        for category in FontCategory.allCases {
            let free = FontCatalog.fonts(in: category).filter { !$0.isPremium }
            #expect(!free.isEmpty, "\(category.displayName) has no free font")
        }
    }

    @Test func freeFontsUseSystemDesign() {
        for font in FontCatalog.all where !font.isPremium {
            #expect(font.familyName == nil)
        }
    }
}
