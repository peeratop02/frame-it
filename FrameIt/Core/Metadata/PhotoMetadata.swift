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
    var captureDescription: String?  // image description / caption, e.g. "Shot with No Fusion by \"K4\"."

    static let empty = PhotoMetadata()

    /// The capture-app name to display, derived from the description/caption first
    /// (third-party apps stamp a "Shot with …" credit there) then the Software tag.
    /// `nil` when neither yields a real app (e.g. only an OS version is present).
    var appName: String? {
        ExposureFormatting.captureApp(software: software, description: captureDescription)
    }

    var hasLocation: Bool {
        latitude != nil && longitude != nil
    }

    /// A concise "City, Country" place string composed from the geocoded
    /// components. `nil` until reverse-geocoding has filled at least one component.
    var placeName: String? {
        let parts = [cityOrRegion, country].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    /// The most appropriate place name above country level. Prefers the city
    /// (`locality`), but when the city is actually a district/county (e.g. Apple
    /// returns "Phra Khanong District" for a Bangkok pin) it falls back to the
    /// province/state (`administrativeArea`) so the result reads "Bangkok, Thailand".
    private var cityOrRegion: String? {
        if let locality, !locality.isEmpty, !Self.isDistrictLike(locality) {
            return locality
        }
        return administrativeArea ?? locality
    }

    /// Whether a place name reads as a sub-city administrative division rather than a
    /// city. Heuristic over common English and Thai district markers.
    static func isDistrictLike(_ name: String) -> Bool {
        let markers = ["district", "county", "borough", "subdistrict", "ward",
                       "amphoe", "khet", "tambon", "khwaeng"]
        let lower = name.lowercased()
        return markers.contains { lower.contains($0) }
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
