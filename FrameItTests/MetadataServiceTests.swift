import Testing
import Foundation
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers
@testable import FrameIt

struct MetadataServiceTests {

    /// Build real JPEG data carrying the given image properties so the parser is
    /// exercised end-to-end against the actual ImageIO pipeline.
    private func makeImageData(properties: [CFString: Any]) -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        let cgImage = context.makeImage()!

        let mutableData = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            mutableData, UTType.jpeg.identifier as CFString, 1, nil
        )!
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        CGImageDestinationFinalize(destination)
        return mutableData as Data
    }

    @Test func parsesCameraExposureAndGPS() {
        let properties: [CFString: Any] = [
            kCGImagePropertyTIFFDictionary: [
                kCGImagePropertyTIFFMake: "Apple",
                kCGImagePropertyTIFFModel: "iPhone 15 Pro",
                kCGImagePropertyTIFFSoftware: "No Fusion",
            ],
            kCGImagePropertyExifDictionary: [
                kCGImagePropertyExifISOSpeedRatings: [100],
                kCGImagePropertyExifFNumber: 1.78,
                kCGImagePropertyExifExposureTime: 0.008,
                kCGImagePropertyExifFocalLength: 6.86,
                kCGImagePropertyExifLensModel: "Test Lens 6.86mm f/1.78",
            ],
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude: 37.3349,
                kCGImagePropertyGPSLatitudeRef: "N",
                kCGImagePropertyGPSLongitude: 122.0090,
                kCGImagePropertyGPSLongitudeRef: "W",
            ],
        ]
        let data = makeImageData(properties: properties)
        let metadata = ImageIOMetadataService().metadata(from: data)

        #expect(metadata.cameraMake == "Apple")
        #expect(metadata.cameraModel == "iPhone 15 Pro")
        #expect(metadata.software == "No Fusion")
        #expect(metadata.isoSpeed == 100)
        #expect(metadata.lensModel == "Test Lens 6.86mm f/1.78")
        #expect(abs((metadata.fNumber ?? 0) - 1.78) < 0.01)
        #expect(abs((metadata.exposureTime ?? 0) - 0.008) < 0.001)
        #expect(abs((metadata.focalLength ?? 0) - 6.86) < 0.01)
        // West longitude must be negated.
        #expect(abs((metadata.latitude ?? 0) - 37.3349) < 0.001)
        #expect(abs((metadata.longitude ?? 0) - (-122.0090)) < 0.001)
        #expect(metadata.hasLocation)
    }

    @Test func parsesAppCreditFromImageDescription() {
        let properties: [CFString: Any] = [
            kCGImagePropertyTIFFDictionary: [
                kCGImagePropertyTIFFMake: "Apple",
                kCGImagePropertyTIFFModel: "iPhone 16 Pro Max",
                // Software is just the OS version on this shot.
                kCGImagePropertyTIFFSoftware: "18.1",
                kCGImagePropertyTIFFImageDescription: "Shot with No Fusion by \u{201C}K4\u{201D}.",
            ],
        ]
        let metadata = ImageIOMetadataService().metadata(from: makeImageData(properties: properties))
        #expect(metadata.captureDescription == "Shot with No Fusion by \u{201C}K4\u{201D}.")
        // The displayed app comes from the description, not the OS version.
        #expect(metadata.appName == "No Fusion")
    }

    @Test func returnsEmptyForNonImageData() {
        let metadata = ImageIOMetadataService().metadata(from: Data([0x00, 0x01, 0x02]))
        #expect(metadata == .empty)
    }

    @Test func handlesMissingFieldsGracefully() {
        let data = makeImageData(properties: [
            kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFModel: "Pixel 8"]
        ])
        let metadata = ImageIOMetadataService().metadata(from: data)
        #expect(metadata.cameraModel == "Pixel 8")
        #expect(metadata.isoSpeed == nil)
        #expect(metadata.hasLocation == false)
    }
}
