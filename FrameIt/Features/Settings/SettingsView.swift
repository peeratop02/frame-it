import SwiftUI

/// The Settings tab. Inset-grouped list (HIG default). Rows for the deferred
/// upgrade / iCloud features are present but disabled so the intended shape is
/// visible without pretending to do something they don't yet.
struct SettingsView: View {
    @AppStorage(AppearanceMode.storageKey) private var appearanceRaw = AppearanceMode.system.rawValue

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Plan", value: "Free")
                    Button("Upgrade — Unlock Everything") {}
                        .disabled(true)
                    Button("Restore Purchases") {}
                        .disabled(true)
                } header: {
                    Text("Frame It")
                } footer: {
                    Text("In-app purchases arrive in a future update.")
                }

                Section {
                    Picker("Appearance", selection: $appearanceRaw) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.displayName).tag(mode.rawValue)
                        }
                    }
                    Toggle("iCloud Sync", isOn: .constant(false))
                        .disabled(true)
                } header: {
                    Text("Preferences")
                } footer: {
                    Text("Sync your templates and settings across devices. Coming soon.")
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Apple Human Interface Guidelines",
                         destination: URL(string: "https://developer.apple.com/design/human-interface-guidelines")!)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
