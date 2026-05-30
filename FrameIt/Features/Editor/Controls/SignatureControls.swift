import SwiftUI

/// Controls for the bottom-of-frame credit / watermark.
///
/// Capability is tiered by plan, but — following the pre-StoreKit pattern used for
/// premium fonts and pins — every control is functional and selectable today, with
/// paid capabilities marked by a gold crown. Real entitlement gating lands with
/// monetization. Free: fixed credit. One-time: custom text. Subscription: + styling.
struct SignatureControls: View {
    @Binding var style: FrameStyle
    @Environment(\.entitlements) private var entitlements
    @State private var upsellFeature: PremiumFeature?

    /// Max length for the custom credit so it stays a one-line footer.
    private let maxLength = 60

    /// Custom / hidden credit needs one-time; matched styling needs subscription.
    private var creditLocked: Bool { !entitlements.isUnlocked(.customCredit) }
    private var styledLocked: Bool { !entitlements.isUnlocked(.styledCredit) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            gatedToggle("Show credit",
                        isOn: showCreditBinding,
                        locked: creditLocked,
                        feature: .customCredit)

            VStack(alignment: .leading, spacing: 6) {
                premiumLabel("Custom text", locked: creditLocked)
                TextField(FrameStyle.defaultCredit, text: customTextBinding)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .disabled(creditLocked || style.signature.isHidden)
            }
            .opacity((creditLocked || style.signature.isHidden) ? 0.5 : 1)
            // A locked tap on the field area routes to the upsell.
            .overlay {
                if creditLocked {
                    Color.clear.contentShape(.rect)
                        .onTapGesture { upsellFeature = .customCredit }
                }
            }

            gatedToggle("Match frame style",
                        isOn: $style.signature.matchesFrameStyle,
                        locked: styledLocked || style.signature.isHidden,
                        feature: .styledCredit)

            Text(creditLocked
                 ? "Customizing or removing the credit is a premium feature."
                 : "Match the credit to your frame's font and color with Studio.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .upsell($upsellFeature)
    }

    /// A toggle that, when locked, shows the crown and routes taps to the upsell
    /// instead of flipping. When unlocked it behaves as a normal toggle.
    @ViewBuilder
    private func gatedToggle(_ title: String,
                             isOn: Binding<Bool>,
                             locked: Bool,
                             feature: PremiumFeature) -> some View {
        if locked {
            Button {
                upsellFeature = feature
            } label: {
                HStack {
                    premiumLabel(title, locked: true)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        } else {
            Toggle(isOn: isOn) { premiumLabel(title, locked: false) }
        }
    }

    /// A control label with a trailing gold crown marking a premium capability.
    private func premiumLabel(_ title: String, locked: Bool) -> some View {
        HStack(spacing: 6) {
            Text(title)
            if locked {
                Image(systemName: "crown.fill")
                    .font(.caption2)
                    .foregroundStyle(Theme.premiumGold)
            }
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
