import Foundation
import ImageIO
import CoreLocation

/// Extracts capture metadata from raw image data and (optionally) turns embedded
/// GPS coordinates into a place name. Protocol-based so view models can be tested
/// against a mock without real image data.
protocol MetadataService: Sendable {
    /// Parse EXIF/TIFF/GPS from encoded image data. Pure and synchronous.
    func metadata(from data: Data) -> PhotoMetadata
    /// Return a copy of `metadata` with `placeName` filled from its coordinates.
    /// Returns the input unchanged when there is no location or geocoding fails.
    func reverseGeocode(_ metadata: PhotoMetadata) async -> PhotoMetadata
}

struct ImageIOMetadataService: MetadataService {

    func metadata(from data: Data) -> PhotoMetadata {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else { return .empty }

        var result = PhotoMetadata()

        if let tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
            result.cameraMake = tiff[kCGImagePropertyTIFFMake] as? String
            result.cameraModel = tiff[kCGImagePropertyTIFFModel] as? String
            if let software = (tiff[kCGImagePropertyTIFFSoftware] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines), !software.isEmpty {
                result.software = software
            }
        }

        if let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any] {
            result.exposureTime = exif[kCGImagePropertyExifExposureTime] as? Double
            result.fNumber = exif[kCGImagePropertyExifFNumber] as? Double
            result.focalLength = exif[kCGImagePropertyExifFocalLength] as? Double
            result.focalLengthIn35mm = (exif[kCGImagePropertyExifFocalLenIn35mmFilm] as? NSNumber)?.intValue
            if let isoArray = exif[kCGImagePropertyExifISOSpeedRatings] as? [NSNumber] {
                result.isoSpeed = isoArray.first?.intValue
            }
            result.lensModel = exif[kCGImagePropertyExifLensModel] as? String
            if let original = exif[kCGImagePropertyExifDateTimeOriginal] as? String {
                result.dateTaken = Self.exifDateFormatter.date(from: original)
            }
        }

        // Lens model sometimes lives in the Aux dictionary instead.
        if result.lensModel == nil,
           let aux = props[kCGImagePropertyExifAuxDictionary] as? [CFString: Any] {
            result.lensModel = aux[kCGImagePropertyExifAuxLensModel] as? String
        }

        if let gps = props[kCGImagePropertyGPSDictionary] as? [CFString: Any] {
            if let lat = gps[kCGImagePropertyGPSLatitude] as? Double {
                let ref = gps[kCGImagePropertyGPSLatitudeRef] as? String
                result.latitude = (ref == "S") ? -lat : lat
            }
            if let lon = gps[kCGImagePropertyGPSLongitude] as? Double {
                let ref = gps[kCGImagePropertyGPSLongitudeRef] as? String
                result.longitude = (ref == "W") ? -lon : lon
            }
            if let alt = gps[kCGImagePropertyGPSAltitude] as? Double {
                let ref = gps[kCGImagePropertyGPSAltitudeRef] as? Int
                result.altitude = (ref == 1) ? -alt : alt
            }
        }

        return result
    }

    func reverseGeocode(_ metadata: PhotoMetadata) async -> PhotoMetadata {
        guard let lat = metadata.latitude, let lon = metadata.longitude else {
            return metadata
        }
        let location = CLLocation(latitude: lat, longitude: lon)
        // `CLGeocoder` returns a `CLPlacemark` with discrete city / region / country
        // components — exactly what the Place column needs. Reverse-geocoding fixed
        // coordinates requires no location permission.
        guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first
        else { return metadata }

        var updated = metadata
        updated.locality = placemark.locality
        updated.administrativeArea = placemark.administrativeArea
        updated.country = placemark.country
        return updated
    }

    private static let exifDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        return formatter
    }()
}
