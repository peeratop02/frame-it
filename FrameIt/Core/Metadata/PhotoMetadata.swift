import Foundation

/// The capture metadata extracted from a photo. Every field is optional — many
/// photos (screenshots, stripped exports, third-party images) carry only a
/// subset, and the UI degrades gracefully when a value is missing.
struct PhotoMetadata: Equatable, Sendable {
    var cameraMake: String?          // "Apple"
    var cameraModel: String?         // "iPhone 15 Pro"
    var lensModel: String?           // "iPhone 15 Pro back triple camera 6.86mm f/1.78"
    var dateTaken: Date?
    var exposureTime: Double?        // seconds (e.g. 0.008 → 1/125)
    var fNumber: Double?             // f-stop (e.g. 1.78)
    var isoSpeed: Int?               // e.g. 100
    var focalLength: Double?         // mm
    var focalLengthIn35mm: Int?      // 35mm-equivalent mm
    var latitude: Double?
    var longitude: Double?
    var altitude: Double?
    var locality: String?            // city, reverse-geocoded
    var administrativeArea: String?  // province/state, reverse-geocoded
    var country: String?             // reverse-geocoded
    var software: String?            // capture app / EXIF Software tag, e.g. "No Fusion"

    static let empty = PhotoMetadata()

    var hasLocation: Bool {
        latitude != nil && longitude != nil
    }

    /// A concise "City, Country" place string composed from the geocoded
    /// components, falling back to province when there is no city. `nil` until
    /// reverse-geocoding has filled at least one component.
    var placeName: String? {
        let primary = locality ?? administrativeArea
        let parts = [primary, country].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    /// A human-friendly device name that avoids redundant make/model repetition.
    /// "Apple" + "iPhone 15 Pro" → "iPhone 15 Pro"; otherwise "<make> <model>".
    var deviceName: String? {
        switch (cameraMake, cameraModel) {
        case let (make?, model?):
            if make.caseInsensitiveCompare("Apple") == .orderedSame
                || model.localizedCaseInsensitiveContains(make) {
                return model
            }
            return "\(make) \(model)"
        case let (nil, model?):
            return model
        case let (make?, nil):
            return make
        default:
            return nil
        }
    }
}
