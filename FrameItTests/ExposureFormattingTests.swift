import Testing
@testable import FrameIt

struct ExposureFormattingTests {

    @Test func shutterSpeedSubSecondIsFraction() {
        #expect(ExposureFormatting.shutterSpeed(0.008) == "1/125")
        #expect(ExposureFormatting.shutterSpeed(0.5) == "1/2")
        #expect(ExposureFormatting.shutterSpeed(1.0 / 60.0) == "1/60")
    }

    @Test func shutterSpeedOneSecondAndLonger() {
        #expect(ExposureFormatting.shutterSpeed(1.0) == "1s")
        #expect(ExposureFormatting.shutterSpeed(2.0) == "2s")
        #expect(ExposureFormatting.shutterSpeed(1.3) == "1.3s")
    }

    @Test func shutterSpeedRejectsNonPositive() {
        #expect(ExposureFormatting.shutterSpeed(0) == nil)
        #expect(ExposureFormatting.shutterSpeed(-1) == nil)
    }

    @Test func apertureFormatting() {
        #expect(ExposureFormatting.aperture(1.8) == "f/1.8")
        #expect(ExposureFormatting.aperture(8.0) == "f/8")
        #expect(ExposureFormatting.aperture(0) == nil)
    }

    @Test func isoFormatting() {
        #expect(ExposureFormatting.iso(100) == "ISO 100")
        #expect(ExposureFormatting.iso(0) == nil)
    }

    @Test func focalLengthFormatting() {
        #expect(ExposureFormatting.focalLength(24.0) == "24mm")
        #expect(ExposureFormatting.focalLength(6.86) == "7mm")
        #expect(ExposureFormatting.focalLength(0) == nil)
    }

    @Test func captureAppStripsTrailingVersion() {
        #expect(ExposureFormatting.captureApp("Photomator 3.4.14") == "Photomator")
        #expect(ExposureFormatting.captureApp("No Fusion") == "No Fusion")
        #expect(ExposureFormatting.captureApp("Pixelmator Pro 3.6") == "Pixelmator Pro")
    }

    @Test func captureAppReturnsNilForVersionOnly() {
        #expect(ExposureFormatting.captureApp("16.5") == nil)
        #expect(ExposureFormatting.captureApp("  ") == nil)
    }

    @Test func cameraNameByFocalLength() {
        #expect(ExposureFormatting.cameraName(lensModel: nil, focalLength35mm: 13) == "Ultra-Wide Camera")
        #expect(ExposureFormatting.cameraName(lensModel: nil, focalLength35mm: 24) == "Main Camera")
        #expect(ExposureFormatting.cameraName(lensModel: nil, focalLength35mm: 120) == "Telephoto Camera")
        #expect(ExposureFormatting.cameraName(lensModel: nil, focalLength35mm: nil) == nil)
    }

    @Test func cameraNameDetectsFrontLens() {
        let front = "iPhone 16 Pro Max front camera 2.69mm f/1.9"
        #expect(ExposureFormatting.cameraName(lensModel: front, focalLength35mm: 23) == "Front Camera")
    }
}
