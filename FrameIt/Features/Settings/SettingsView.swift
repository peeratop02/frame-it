import SwiftUI

/// The Settings tab. Inset-grouped list (HIG default). Rows for the deferred
/// upgrade / iCloud features are present but disabled so the intended shape is
/// visible without pretending to do something they don't yet.
struct SettingsView: View {
    @AppStorage(AppearanceMode.storageKey) private var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage(FontCatalog.defaultSelectionKey) private var defaultFontID = FontCatalog.defaultID
    @State private var showFontPicker = false

    private var defaultFont: FrameFont { FontCatalog.font(id: defaultFontID) }

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
                    defaultFontRow
                } header: {
                    Text("Editor Defaults")
                } footer: {
                    Text("New frames open with this typeface. Choosing a default font is a premium feature.")
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
            .sheet(isPresented: $showFontPicker) {
                FontPickerSheet(selection: $defaultFontID)
            }
        }
    }

    /// A tappable row showing the current default font in its own typeface, with a
    /// gold crown marking it as a premium capability. Opens the shared font picker.
    private var defaultFontRow: some View {
        Button {
            showFontPicker = true
        } label: {
            HStack(spacing: 8) {
                Text("Default font")
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                Text(defaultFont.displayName)
                    .font(defaultFont.font(size: 17))
                    .foregroundStyle(.secondary)
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.premiumGold)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
}
