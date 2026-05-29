import SwiftUI

/// Shown before/instead of the grid when photo access hasn't been granted.
/// Explains *why* access is needed in context (HIG) before the system prompt.
struct PhotoPermissionView: View {
    var denied: Bool
    var onRequest: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Access Your Photos", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text(denied
                 ? "Frame It can't see your photos yet. Enable photo access in Settings to choose images to frame."
                 : "Frame It uses your photos so you can pick an image and wrap it in a frame. Nothing leaves your device.")
        } actions: {
            Button(denied ? "Open Settings" : "Allow Access") {
                if denied {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } else {
                    onRequest()
                }
            }
            .buttonStyle(.glassProminent)
        }
    }
}
