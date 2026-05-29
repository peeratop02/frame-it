import CoreText
import Foundation
import os

/// Registers bundled custom fonts at launch so `Font.custom(_:size:)` can resolve them.
///
/// Drop a `.ttf`/`.otf` into `FrameIt/Resources/Fonts/`, add a matching `FrameFont` entry to
/// `FontCatalog`, and it works — no `UIAppFonts` Info.plist editing and no per-font code. This
/// scans the bundle and registers every font file it finds, so new font packs are pure data.
enum FontRegistrar {
    private static let logger = Logger(subsystem: "com.peeratop02.frameit", category: "Fonts")

    /// Register all bundled font files. Idempotent — "already registered" is treated as success.
    static func registerBundledFonts(in bundle: Bundle = .main) {
        let urls = ["ttf", "otf"].flatMap { ext in
            bundle.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? []
        }
        for url in urls {
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                let cfError = error?.takeRetainedValue()
                let code = (cfError as Error?).map { ($0 as NSError).code }
                // 105 == kCTFontManagerErrorAlreadyRegistered — harmless on a warm relaunch.
                if code != 105 {
                    logger.error("Failed to register font \(url.lastPathComponent, privacy: .public): \(String(describing: cfError), privacy: .public)")
                }
            }
        }
    }
}
