import MapKit
import UIKit

/// Renders a static map image centered on a coordinate for the frame's minimap
/// widget. Kept separate so the view model and `FramePreview` stay free of MapKit
/// plumbing — MapKit views can't draw inside `ImageRenderer`, so the map must be a
/// pre-rendered bitmap.
///
/// Not `@MainActor`: `MKMapSnapshotter` must run off the main queue (delivering its
/// completion on `.main` deadlocks on the simulator), so the snapshot work happens
/// on a background queue and the result hops back via the continuation.
struct MapSnapshotRenderer: Sendable {
    /// Point size of the snapshot — a 2:1 landscape strip so the Place column reads
    /// wide and short (less white space beside the other columns). Rendered at @3x so
    /// it stays crisp when scaled up for full-resolution export.
    var size = CGSize(width: 320, height: 160)
    /// Latitude span — a tight, street-level view like the reference shot.
    var span: CLLocationDegrees = 0.008

    func snapshot(latitude: Double, longitude: Double, dark: Bool = false) async -> UIImage? {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span * 2)
        )
        options.size = size
        options.scale = 3
        options.traitCollection = UITraitCollection(userInterfaceStyle: dark ? .dark : .light)

        let snapshotter = MKMapSnapshotter(options: options)
        return await withCheckedContinuation { continuation in
            // Background queue: starting/finishing on .main can hang the snapshotter.
            snapshotter.start(with: DispatchQueue.global(qos: .userInitiated)) { snapshot, _ in
                continuation.resume(returning: snapshot?.image)
            }
        }
    }
}
