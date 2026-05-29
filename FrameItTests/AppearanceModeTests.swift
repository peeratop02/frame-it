import Testing
import SwiftUI
@testable import FrameIt

struct AppearanceModeTests {

    @Test func colorSchemeMapsToSystemLightDark() {
        #expect(AppearanceMode.system.colorScheme == nil)
        #expect(AppearanceMode.light.colorScheme == .light)
        #expect(AppearanceMode.dark.colorScheme == .dark)
    }

    @Test func rawValuesRoundTripForAllCases() {
        for mode in AppearanceMode.allCases {
            #expect(AppearanceMode(rawValue: mode.rawValue) == mode)
        }
    }

    @Test func unknownRawValueIsNil() {
        #expect(AppearanceMode(rawValue: "sepia") == nil)
    }
}
