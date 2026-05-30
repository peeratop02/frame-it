import Foundation

/// Build/runtime environment checks. Used to expose tester-only affordances (the
/// Settings plan switcher) in DEBUG and TestFlight, while keeping them invisible in
/// App Store production builds.
enum AppEnvironment {
    /// True for builds where testing affordances should be available: any DEBUG build,
    /// or a TestFlight build (which ships a sandbox App Store receipt). False on the
    /// public App Store, where the receipt filename is `receipt`, not `sandboxReceipt`.
    static var isTestBuild: Bool {
        #if DEBUG
        return true
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }
}
