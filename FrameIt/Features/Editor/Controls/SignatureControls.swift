import SwiftUI

/// Controls for the bottom-of-frame credit / watermark.
///
/// Capability is tiered by plan, but — following the pre-StoreKit pattern used for
/// premium fonts and pins — every control is functional and selectable today, with
/// paid capabilities marked by a gold crown. Real entitlement gating lands with
/// monetization. Free: fixed credit. One-time: custom text. Subscription: + styling.
struct SignatureControls: View {
    @Binding var style: FrameStyle

    /// Max length for the custom credit so it stays a one-line footer.
    private let maxLength = 60

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: showCreditBinding) {
                premiumLabel("Show credit")
            }

            VStack(alignment: .leading, spacing: 6) {
                premiumLabel("Custom text")
                TextField(FrameStyle.defaultCredit, text: customTextBinding)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
            }
            .disabled(style.signature.isHidden)
            .opacity(style.signature.isHidden ? 0.5 : 1)

            Toggle(isOn: $style.signature.matchesFrameStyle) {
                premiumLabel("Match frame style")
            }
            .disabled(style.signature.isHidden)

            Text("Customizing or removing the credit is a premium feature.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// A control label with a trailing gold crown marking a premium capability.
    private func premiumLabel(_ title: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
            Image(systemName: "crown.fill")
                .font(.caption2)
                .foregroundStyle(Theme.premiumGold)
        }
        .font(.subheadline)
    }

    /// `Show credit` is the inverse of the stored `isHidden`.
    private var showCreditBinding: Binding<Bool> {
        Binding(
            get: { !style.signature.isHidden },
            set: { style.signature.isHidden = !$0 }
        )
    }

    /// Custom text, capped to `maxLength` characters.
    private var customTextBinding: Binding<String> {
        Binding(
            get: { style.signature.customText },
            set: { style.signature.customText = String($0.prefix(maxLength)) }
        )
    }
}
