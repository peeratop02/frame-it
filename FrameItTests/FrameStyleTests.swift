import Testing
import Foundation
@testable import FrameIt

struct FrameStyleTests {

    @Test func defaultStyleEncodesAndDecodes() throws {
        let original = FrameStyle.default
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FrameStyle.self, from: data)
        #expect(decoded == original)
    }

    @Test func customStyleRoundTrips() throws {
        var style = FrameStyle.default
        style.layout = .minimal
        style.background = RGBAColor(red: 0.2, green: 0.4, blue: 0.6, opacity: 0.9)
        style.fontID = "georgia"
        style.fontScale = 1.25
        style.bold = true
        style.italic = true
        style.bottomPadding = 0.1
        style.enabledFields = [.device, .location, .app]
        style.borderWidth = 3
        style.shadowStrength = 0.6
        style.placeStyle = .map
        style.pinIcon = "heart"
        style.signature = Signature(customText: "© 2024 PeeraStudio",
                                    matchesFrameStyle: true, isHidden: true)

        let data = try JSONEncoder().encode(style)
        let decoded = try JSONDecoder().decode(FrameStyle.self, from: data)
        #expect(decoded == style)
        #expect(decoded.font.id == "georgia")
        #expect(decoded.fontScale == 1.25)
        #expect(decoded.bold)
        #expect(decoded.italic)
        #expect(decoded.placeStyle == .map)
        #expect(decoded.pinIcon == "heart")
        #expect(decoded.signature == style.signature)
        #expect(decoded.shadowStrength == 0.6)
    }

    @Test func defaultStyleHasNoShadow() {
        #expect(FrameStyle.default.shadowStrength == 0)
    }

    @Test func defaultStyleHasDefaultSignature() {
        #expect(FrameStyle.default.signature == .default)
        #expect(FrameStyle.default.signature.isHidden == false)
        #expect(FrameStyle.defaultCredit == "Crafted with Frame It")
    }

    @Test func signatureDisplayTextFallsBackToDefault() {
        #expect(Signature.default.displayText(default: "Crafted with Frame It")
                == "Crafted with Frame It")
        #expect(Signature(customText: "   ", matchesFrameStyle: false, isHidden: false)
                .displayText(default: "Crafted with Frame It") == "Crafted with Frame It")
        #expect(Signature(customText: "  © Peera  ", matchesFrameStyle: false, isHidden: false)
                .displayText(default: "Crafted with Frame It") == "© Peera")
    }

    @Test func defaultStyleUsesMinimalLayout() {
        #expect(FrameStyle.default.layout == .minimal)
        #expect(FrameStyle.default.placeStyle == .time)
        #expect(FrameStyle.default.pinIcon == PinCatalog.defaultID)
    }

    @Test func defaultStyleResolvesFont() {
        #expect(FrameStyle.default.font.id == FontCatalog.defaultID)
        #expect(FrameStyle.default.font.isPremium == false)
    }

    @Test func defaultStyleHasSquareCorners() {
        #expect(FrameStyle.default.cornerRadius == 0)
    }

    @Test func metadataGroupsPartitionAllFields() {
        let grouped = MetadataGroup.allCases.flatMap(\.fields)
        // Every field is covered exactly once across the groups.
        #expect(Set(grouped) == Set(MetadataField.allCases))
        #expect(grouped.count == MetadataField.allCases.count)
    }

    @Test func rgbaColorPreservesComponents() throws {
        let color = RGBAColor(red: 0.1, green: 0.2, blue: 0.3, opacity: 0.4)
        let decoded = try JSONDecoder().decode(RGBAColor.self,
                                               from: JSONEncoder().encode(color))
        #expect(decoded == color)
    }

    @Test func isFieldEnabledMatchesArray() {
        var style = FrameStyle.default
        style.enabledFields = [.iso, .shutter]
        #expect(style.isFieldEnabled(.iso))
        #expect(style.isFieldEnabled(.shutter))
        #expect(!style.isFieldEnabled(.location))
    }
}
