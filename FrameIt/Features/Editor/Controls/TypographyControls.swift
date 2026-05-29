import SwiftUI

/// Text controls: a category-grouped font dropdown, size, bold/italic, and text color.
///
/// Premium fonts show a lock badge but stay selectable in this pre-StoreKit
/// phase so the feature is testable; entitlement gating lands with monetization.
struct TypographyControls: View {
    @Binding var style: FrameStyle
    @State private var showFontPicker = false

    private let textPresets: [RGBAColor] = [.charcoal, .black, .white, .secondaryText]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LabeledControl("Font") { fontButton }
            LabeledControl("Size") {
                HStack(spacing: 12) {
                    Slider(value: $style.fontScale, in: 0.7...1.4)
                    Text("\(Int((style.fontScale * 100).rounded()))%")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 48, alignment: .trailing)
                }
            }
            LabeledControl("Style") { styleToggles }

            Divider()

            LabeledControl("Text color") {
                HStack(spacing: 10) {
                    ForEach(Array(textPresets.enumerated()), id: \.offset) { _, preset in
                        Button { style.textColor = preset } label: {
                            Circle()
                                .fill(preset.color)
                                .frame(width: 30, height: 30)
                                .overlay(Circle().strokeBorder(.separator, lineWidth: 1))
                        }
                        .accessibilityLabel("Text color")
                    }
                    ColorPicker("", selection: textColorBinding, supportsOpacity: false)
                        .labelsHidden()
                }
            }
        }
        .sheet(isPresented: $showFontPicker) {
            FontPickerSheet(selection: $style.fontID)
        }
    }

    // MARK: Font button

    /// Opens the custom font picker. The label renders the current font's name in
    /// its own typeface so the user sees what they've chosen at a glance. A system
    /// `Picker`/`Menu` can't render custom fonts or a colored trailing badge, hence
    /// the bespoke sheet.
    private var fontButton: some View {
        Button { showFontPicker = true } label: {
            HStack {
                Text(style.font.displayName)
                    .font(style.font.font(size: 17))
                    .foregroundStyle(.primary)
                if style.font.isPremium {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.premiumGold)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    // MARK: Style toggles

    private var styleToggles: some View {
        HStack(spacing: 10) {
            Toggle(isOn: $style.bold) {
                Text("B").fontWeight(.bold)
            }
            .toggleStyle(.button)
            .accessibilityLabel("Bold")

            Toggle(isOn: $style.italic) {
                Text("I").italic()
            }
            .toggleStyle(.button)
            .accessibilityLabel("Italic")

            Spacer()
        }
        .font(.body)
    }

    private var textColorBinding: Binding<Color> {
        Binding(
            get: { style.textColor.color },
            set: { style.textColor = RGBAColor($0) }
        )
    }
}
