import SwiftUI

/// The Settings tab. Inset-grouped list (HIG default). Rows for the deferred
/// upgrade / iCloud features are present but disabled so the intended shape is
/// visible without pretending to do something they don't yet.
struct SettingsView: View {
    @AppStorage(AppearanceMode.storageKey) private var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage(FontCatalog.defaultSelectionKey) private var defaultFontID = FontCatalog.defaultID
    @Environment(\.entitlements) private var entitlements
    @State private var showFontPicker = false
    @State private var showPaywall = false
    @State private var showComparison = false
    @State private var isRestoring = false
    @State private var restoreMessage: String?

    private var defaultFont: FrameFont { FontCatalog.font(id: defaultFontID) }
    private var isPaid: Bool { entitlements.tier > .free }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Plan", value: entitlements.tier.displayName)
                    if !isPaid {
                        Button("Upgrade — Unlock Everything") { showPaywall = true }
                    }
                    Button("Compare Plans") { showComparison = true }
                    Button {
                        Task { await restore() }
                    } label: {
                        HStack {
                            Text("Restore Purchases")
                            if isRestoring {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isRestoring)
                } header: {
                    Text("Frame It")
                } footer: {
                    Text(isPaid
                         ? "Thanks for supporting Frame It — \(entitlements.tier.tagline.lowercased())."
                         : "Unlock every font, pin, custom credit, and unlimited templates.")
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

                if AppEnvironment.isTestBuild {
                    Section {
                        Picker("Simulated Plan", selection: tierOverrideBinding) {
                            Text("Real purchases").tag(AppTier?.none)
                            ForEach(AppTier.allCases, id: \.self) { tier in
                                Text(tier.displayName).tag(AppTier?.some(tier))
                            }
                        }
                    } header: {
                        Text("Testing")
                    } footer: {
                        Text("Preview each plan's gating without purchasing. Not shown on the App Store.")
                    }
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
            .sheet(isPresented: $showComparison) {
                PlanComparisonView()
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("Restore Purchases",
                   isPresented: Binding(get: { restoreMessage != nil },
                                        set: { if !$0 { restoreMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(restoreMessage ?? "")
            }
        }
    }

    /// Two-way binding to the tester tier override (test builds only).
    private var tierOverrideBinding: Binding<AppTier?> {
        Binding(get: { entitlements.tierOverride },
                set: { entitlements.tierOverride = $0 })
    }

    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await entitlements.restore()
            restoreMessage = entitlements.tier > .free
                ? "Your \(entitlements.tier.displayName) plan has been restored."
                : "No previous purchases were found to restore."
        } catch {
            restoreMessage = "Couldn't restore purchases. Please try again."
        }
    }

    /// A tappable row showing the current default font in its own typeface, with a
    /// gold crown marking it as a premium capability. Opens the shared font picker.
    private var defaultFontRow: some View {
        Button {
            // Choosing a default font is a premium capability — gate the entry point.
            if entitlements.isUnlocked(.premiumFont) {
                showFontPicker = true
            } else {
                showPaywall = true
            }
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
