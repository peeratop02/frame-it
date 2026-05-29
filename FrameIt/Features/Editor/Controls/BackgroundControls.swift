import SwiftUI

/// Frame-shape controls: layout, background color, padding, corner radius, border.
struct BackgroundControls: View {
    @Binding var style: FrameStyle

    private let backgroundPresets: [RGBAColor] = [.white, .black, .charcoal,
                                                  RGBAColor(red: 0.96, green: 0.94, blue: 0.89)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Layout", selection: $style.layout) {
                ForEach(FrameLayout.allCases) { layout in
                    Label(layout.displayName, systemImage: layout.systemImage).tag(layout)
                }
            }
            .pickerStyle(.segmented)

            LabeledControl("Background") {
                HStack(spacing: 10) {
                    ForEach(Array(backgroundPresets.enumerated()), id: \.offset) { _, preset in
                        swatch(preset) { style.background = preset }
                    }
                    ColorPicker("", selection: colorBinding(\.background), supportsOpacity: false)
                        .labelsHidden()
                }
            }

            slider("Padding", value: $style.padding, range: 0...0.18, format: percent)
            slider("Bottom padding", value: $style.bottomPadding, range: 0...0.18, format: percent)
            slider("Corner radius", value: $style.cornerRadius, range: 0...30, format: points)
            slider("Shadow", value: $style.shadowStrength, range: 0...1, format: percent)

            LabeledControl("Border") {
                HStack(spacing: 12) {
                    Slider(value: $style.borderWidth, in: 0...8)
                    valueLabel(points(style.borderWidth))
                    ColorPicker("", selection: colorBinding(\.borderColor), supportsOpacity: false)
                        .labelsHidden()
                        .disabled(style.borderWidth == 0)
                }
            }
        }
    }

    // MARK: Value formatting

    private func percent(_ value: Double) -> String { "\(Int((value * 100).rounded()))%" }
    private func points(_ value: Double) -> String { "\(Int(value.rounded()))" }

    /// A trailing, monospaced slider value readout (matches the Text panel's Size row).
    private func valueLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(.secondary)
            .frame(width: 44, alignment: .trailing)
    }

    private func swatch(_ color: RGBAColor, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(color.color)
                .frame(width: 30, height: 30)
                .overlay(Circle().strokeBorder(.separator, lineWidth: 1))
        }
        .accessibilityLabel("Background color")
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>,
                        format: @escaping (Double) -> String) -> some View {
        LabeledControl(title) {
            HStack(spacing: 12) {
                Slider(value: value, in: range)
                valueLabel(format(value.wrappedValue))
            }
        }
    }

    private func colorBinding(_ keyPath: WritableKeyPath<FrameStyle, RGBAColor>) -> Binding<Color> {
        Binding(
            get: { style[keyPath: keyPath].color },
            set: { style[keyPath: keyPath] = RGBAColor($0) }
        )
    }
}

/// A small label + trailing control row used across the editor panels.
struct LabeledControl<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .leading)
            content
        }
    }
}
