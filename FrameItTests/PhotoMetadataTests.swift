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

    @Test func placeNamePrefersProvinceWhenCityIsDistrict() {
        var m = PhotoMetadata()
        m.locality = "Phra Khanong District"
        m.administrativeArea = "Bangkok"
        m.country = "Thailand"
        #expect(m.placeName == "Bangkok, Thailand")
    }

    @Test func placeNameKeepsRealCityOverProvince() {
        var m = PhotoMetadata()
        m.locality = "San Francisco"
        m.administrativeArea = "California"
        m.country = "United States"
        #expect(m.placeName == "San Francisco, United States")
    }

    @Test func placeNameUsesDistrictWhenNoProvince() {
        var m = PhotoMetadata()
        m.locality = "Phra Khanong District"
        m.country = "Thailand"
        // No province to fall back to — better the district than nothing.
        #expect(m.placeName == "Phra Khanong District, Thailand")
    }

    @Test func displayFocalLengthPrefers35mmEquivalent() {
        var m = PhotoMetadata()
        m.focalLength = 6.86
        m.focalLengthIn35mm = 24
        // Apple shows the 35mm-equivalent (24mm), not the physical 6.86mm.
        #expect(m.displayFocalLength == 24)
    }

    @Test func displayFocalLengthFallsBackToPhysical() {
        var m = PhotoMetadata()
        m.focalLength = 50
        #expect(m.displayFocalLength == 50)
        #expect(PhotoMetadata.empty.displayFocalLength == nil)
    }

    @Test func isDistrictLikeDetectsAdministrativeDivisions() {
        #expect(PhotoMetadata.isDistrictLike("Phra Khanong District"))
        #expect(PhotoMetadata.isDistrictLike("Santa Clara County"))
        #expect(PhotoMetadata.isDistrictLike("Khet Watthana"))
        #expect(!PhotoMetadata.isDistrictLike("San Francisco"))
        #expect(!PhotoMetadata.isDistrictLike("Bangkok"))
    }
}
