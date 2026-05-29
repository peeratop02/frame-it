import Foundation

/// Pure formatters turning raw EXIF numbers into the strings shown on a frame.
/// Kept free of UIKit/SwiftUI so they can be unit-tested directly.
enum ExposureFormatting {

    /// Shutter speed. Sub-second values render as a `1/x` fraction; one second
    /// and longer render as seconds. Returns `nil` for non-positive input.
    static func shutterSpeed(_ seconds: Double) -> String? {
        guard seconds > 0 else { return nil }
        if seconds >= 1 {
            // 2.0 → "2s", 1.3 → "1.3s"
            let rounded = (seconds * 10).rounded() / 10
            if rounded == rounded.rounded() {
                return "\(Int(rounded))s"
            }
            return "\(rounded)s"
        }
        let denominator = Int((1 / seconds).rounded())
        return "1/\(denominator)"
    }

    /// Aperture as an f-number, e.g. 1.8 → "f/1.8", 8.0 → "f/8".
    static func aperture(_ fNumber: Double) -> String? {
        guard fNumber > 0 else { return nil }
        let rounded = (fNumber * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return "f/\(Int(rounded))"
        }
        return "f/\(rounded)"
    }

    /// ISO sensitivity, e.g. 100 → "ISO 100".
    static func iso(_ value: Int) -> String? {
        guard value > 0 else { return nil }
        return "ISO \(value)"
    }

    /// Focal length in millimetres, e.g. 24.0 → "24mm".
    static func focalLength(_ mm: Double) -> String? {
        guard mm > 0 else { return nil }
        let rounded = mm.rounded()
        return "\(Int(rounded))mm"
    }

    /// A localized medium-style date, e.g. "Jan 5, 2026".
    static func date(_ date: Date, locale: Locale = .current) -> String {
        date.formatted(.dateTime.locale(locale).day().month(.abbreviated).year())
    }

    /// A localized time of day, e.g. "6:48 PM".
    static func time(_ date: Date, locale: Locale = .current) -> String {
        date.formatted(.dateTime.locale(locale).hour().minute())
    }

    /// A non-technical camera name derived from the lens model + 35mm-equivalent
    /// focal length. Best-effort: front-facing lenses are detected by name; the rear
    /// lens is classified by its equivalent focal length. Returns `nil` when there
    /// is nothing to go on.
    static func cameraName(lensModel: String?, focalLength35mm: Int?) -> String? {
        if let lens = lensModel, lens.localizedCaseInsensitiveContains("front") {
            return "Front Camera"
        }
        guard let eq = focalLength35mm else { return nil }
        switch eq {
        case ..<19: return "Ultra-Wide Camera"
        case 19...35: return "Main Camera"
        default: return "Telephoto Camera"
        }
    }

    /// The capture app name from the EXIF Software tag, with any trailing version
    /// dropped: "Photomator 3.4.14" → "Photomator", "No Fusion" → "No Fusion".
    /// Returns `nil` when nothing readable remains (e.g. an OS version like "16.5"),
    /// so Apple photos that store only a version string render no "Shot with" line.
    static func captureApp(_ software: String) -> String? {
        var tokens = software.split(separator: " ").map(String.init)
        // Strip trailing tokens that are purely a version (digits and dots).
        while let last = tokens.last,
              last.allSatisfy({ $0.isNumber || $0 == "." }),
              last.contains(where: \.isNumber) {
            tokens.removeLast()
        }
        let name = tokens.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? nil : name
    }
}
