import SwiftUI

/// Albums (Collections) tab. The MVP focuses on the all-photos Library; browsing
/// PhotoKit collections is the first follow-up, so this is an honest placeholder.
struct AlbumsView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Albums", systemImage: "rectangle.stack")
        } description: {
            Text("Browsing your albums is coming soon. For now, pick any photo from your Library.")
        }
    }
}
