import SwiftUI

/// A compact, contextual sheet shown when a user taps a locked control. It explains
/// the one feature they reached for and routes to the full paywall. Presented
/// uniformly across the app via the `.upsell(_:)` view modifier.
struct UpsellSheet: View {
    let feature: PremiumFeature
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)

            ZStack {
                Circle()
                    .fill(Theme.premiumGold.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: feature.symbolName)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(Theme.premiumGold)
            }
            .padding(.bottom, 20)

            Text(feature.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text(feature.blurb)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.top, 8)

            tierBadge
                .padding(.top, 16)

            Spacer(minLength: 16)

            VStack(spacing: 12) {
                Button {
                    showPaywall = true
                } label: {
                    Text("See Plans")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accent, in: .rect(cornerRadius: 16))
                        .foregroundStyle(.white)
                }

                Button("Not Now") { dismiss() }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(minHeight: 44)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .padding(.top, 8)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(highlight: feature)
        }
    }

    private var tierBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "crown.fill")
                .font(.caption)
            Text("Included in \(feature.requiredTier.displayName)")
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(Theme.premiumGold)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Theme.premiumGold.opacity(0.12), in: .capsule)
    }
}

extension View {
    /// Presents the contextual upsell sheet for a feature. Binding to a
    /// `PremiumFeature?` so a control can set the feature it tried to use and the
    /// sheet appears (and clears on dismiss).
    func upsell(_ feature: Binding<PremiumFeature?>) -> some View {
        sheet(item: feature) { UpsellSheet(feature: $0) }
    }
}
