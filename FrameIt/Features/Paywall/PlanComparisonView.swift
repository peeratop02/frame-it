import SwiftUI

/// A side-by-side Free / Pro / Studio comparison table. Each capability row marks
/// which tiers include it, derived from the same `AppTier` ladder used for gating
/// so the marketing never drifts from the actual entitlements.
struct PlanComparisonView: View {
    @Environment(\.dismiss) private var dismiss

    /// One comparison row: a capability and the lowest tier that includes it.
    private struct Capability: Identifiable {
        let id = UUID()
        let name: String
        let minTier: AppTier
    }

    private let capabilities: [Capability] = [
        Capability(name: "Core frames & layouts", minTier: .free),
        Capability(name: "4 system typefaces", minTier: .free),
        Capability(name: "Default map pin", minTier: .free),
        Capability(name: "Save up to 2 templates", minTier: .free),
        Capability(name: "All premium fonts", minTier: .oneTime),
        Capability(name: "All premium map pins", minTier: .oneTime),
        Capability(name: "Custom & hidden credit", minTier: .oneTime),
        Capability(name: "Unlimited templates", minTier: .oneTime),
        Capability(name: "Styled credit", minTier: .subscription),
        Capability(name: "Future font packs", minTier: .subscription),
        Capability(name: "iCloud sync (soon)", minTier: .subscription),
    ]

    private let tiers: [AppTier] = [.free, .oneTime, .subscription]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerRow
                    ForEach(Array(capabilities.enumerated()), id: \.element.id) { index, cap in
                        capabilityRow(cap, shaded: index.isMultiple(of: 2))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle("Compare Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("Feature")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(tiers, id: \.self) { tier in
                Text(tier.displayName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tier == .free ? .secondary : Theme.premiumGold)
                    .frame(width: 60)
            }
        }
        .padding(.vertical, 10)
    }

    private func capabilityRow(_ cap: Capability, shaded: Bool) -> some View {
        HStack(spacing: 0) {
            Text(cap.name)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(tiers, id: \.self) { tier in
                Image(systemName: tier.unlocks(cap.minTier) ? "checkmark.circle.fill" : "minus")
                    .font(.subheadline)
                    .foregroundStyle(tier.unlocks(cap.minTier)
                                     ? (tier == .free ? Color.secondary : Theme.accent)
                                     : Color(.tertiaryLabel))
                    .frame(width: 60)
                    .accessibilityLabel(tier.unlocks(cap.minTier) ? "Included" : "Not included")
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(shaded ? Color(.secondarySystemBackground) : Color.clear,
                    in: .rect(cornerRadius: 10))
    }
}

#Preview {
    PlanComparisonView()
}
