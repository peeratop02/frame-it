import Testing
@testable import FrameIt

struct PhotoMetadataTests {

    @Test func deviceNameDropsRedundantAppleMake() {
        var m = PhotoMetadata()
        m.cameraMake = "Apple"
        m.cameraModel = "iPhone 15 Pro"
        #expect(m.deviceName == "iPhone 15 Pro")
    }

    @Test func deviceNameDropsMakeContainedInModel() {
        var m = PhotoMetadata()
        m.cameraMake = "FUJIFILM"
        m.cameraModel = "FUJIFILM X-T5"
        #expect(m.deviceName == "FUJIFILM X-T5")
    }

    @Test func deviceNameJoinsDistinctMakeAndModel() {
        var m = PhotoMetadata()
        m.cameraMake = "SONY"
        m.cameraModel = "ILCE-7M4"
        #expect(m.deviceName == "SONY ILCE-7M4")
    }

    @Test func deviceNameNilWhenBothMissing() {
        #expect(PhotoMetadata.empty.deviceName == nil)
    }

    @Test func hasLocationReflectsCoordinates() {
        var m = PhotoMetadata()
        #expect(m.hasLocation == false)
        m.latitude = 37.3
        m.longitude = -122.0
        #expect(m.hasLocation == true)
    }

    @Test func placeNameComposesCityAndCountry() {
        var m = PhotoMetadata()
        #expect(m.placeName == nil)
        m.locality = "Bangkok"
        m.country = "Thailand"
        #expect(m.placeName == "Bangkok, Thailand")
    }

    @Test func placeNameFallsBackToAdminAreaWithoutCity() {
        var m = PhotoMetadata()
        m.administrativeArea = "California"
        m.country = "United States"
        #expect(m.placeName == "California, United States")
    }
}
