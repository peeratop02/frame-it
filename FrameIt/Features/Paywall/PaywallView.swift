import SwiftUI
import StoreKit

/// The dedicated paywall: hero, benefit highlights, and the purchasable plans
/// (Pro one-time + Studio yearly/monthly). Drives purchase/restore through
/// `PaywallViewModel` and dismisses automatically once the tier rises above free.
struct PaywallView: View {
    /// Optional feature to spotlight (set when reached from a contextual upsell).
    var highlight: PremiumFeature?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.entitlements) private var entitlements
    @State private var model: PaywallViewModel?
    @State private var showComparison = false

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    content(model)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(backdrop)
            .navigationTitle("Frame It Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Restore") {
                        Task { await model?.restore() }
                    }
                    .disabled(model?.isRestoring ?? true)
                }
            }
            .sheet(isPresented: $showComparison) {
                PlanComparisonView()
            }
        }
        .onAppear {
            if model == nil { model = PaywallViewModel(entitlements: entitlements) }
        }
        .onChange(of: entitlements.tier) { _, newTier in
            // A successful purchase raised the tier — celebrate then dismiss.
            if newTier > .free { dismiss() }
        }
    }

    private var backdrop: some View {
        LinearGradient(
            colors: [Theme.premiumGold.opacity(0.18), Color(.systemBackground)],
            startPoint: .top, endPoint: .center
        )
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func content(_ model: PaywallViewModel) -> some View {
        ScrollView {
            VStack(spacing: 28) {
                hero
                benefits
                plans(model)
                comparisonLink
                legal
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .alert("Something Went Wrong",
               isPresented: Binding(get: { model.errorMessage != nil },
                                    set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(Theme.premiumGold)
                .frame(width: 104, height: 104)
                .glassEffect(.regular.tint(Theme.premiumGold.opacity(0.18)), in: .circle)
            Text("Unlock the Full Frame It")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("Every typeface, every pin, your own credit line, and unlimited saved styles.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .padding(.top, 8)
    }

    // MARK: Benefits

    private var benefits: some View {
        VStack(spacing: 14) {
            ForEach(PremiumFeature.allCases) { feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.symbolName)
                        .font(.title3)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 34, height: 34)
                        .background(Theme.accent.opacity(0.12), in: .rect(cornerRadius: 9))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.subheadline.weight(.semibold))
                        Text(feature.blurb)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(highlight == feature
                            ? Theme.premiumGold.opacity(0.12)
                            : Color(.secondarySystemBackground),
                            in: .rect(cornerRadius: 14))
                .overlay {
                    if highlight == feature {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Theme.premiumGold, lineWidth: 1.5)
                    }
                }
            }
        }
    }

    // MARK: Plans

    @ViewBuilder
    private func plans(_ model: PaywallViewModel) -> some View {
        if !model.isReady {
            ProgressView().padding()
        } else if model.proProduct == nil && model.studioProducts.isEmpty {
            Text("Plans are unavailable right now. Please check your connection and try again.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        } else {
            VStack(spacing: 14) {
                if let pro = model.proProduct {
                    PlanCard(product: pro,
                             tagline: "One payment, yours forever",
                             badge: nil,
                             model: model)
                }
                ForEach(model.studioProducts, id: \.id) { sub in
                    PlanCard(product: sub,
                             tagline: subscriptionTagline(sub),
                             badge: isYearly(sub) ? "Best Value" : nil,
                             model: model)
                }
            }
        }
    }

    private func isYearly(_ product: Product) -> Bool {
        product.id == StoreProductID.studioYearly
    }

    private func subscriptionTagline(_ product: Product) -> String {
        isYearly(product) ? "Everything, billed yearly" : "Everything, billed monthly"
    }

    // MARK: Comparison + legal

    private var comparisonLink: some View {
        Button {
            showComparison = true
        } label: {
            Label("Compare all plans", systemImage: "checklist")
                .font(.subheadline.weight(.medium))
        }
    }

    private var legal: some View {
        VStack(spacing: 4) {
            Text("Subscriptions renew automatically until cancelled. Manage in Settings.")
            HStack(spacing: 4) {
                Link("Terms", destination: URL(string: "https://example.com/terms")!)
                Text("·")
                Link("Privacy", destination: URL(string: "https://example.com/privacy")!)
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
}

/// A single purchasable plan with its localized price and a buy button. Shows
/// "Current Plan" (disabled) when the user already holds that tier or higher.
private struct PlanCard: View {
    let product: Product
    let tagline: String
    let badge: String?
    let model: PaywallViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(product.displayName)
                    .font(.headline)
                Spacer()
                Text(product.displayPrice)
                    .font(.headline.monospacedDigit())
            }
            Text(tagline)
                .font(.caption)
                .foregroundStyle(.secondary)

            buyButton
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 16))
        .overlay(alignment: .topTrailing) {
            if let badge {
                Text(badge)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.premiumGold, in: .capsule)
                    .offset(x: -12, y: -10)
            }
        }
        // One coherent VoiceOver element: name, price, tagline, and button state.
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var buyButton: some View {
        let owned = model.isOwned(product)
        Button {
            Task { await model.buy(product) }
        } label: {
            Group {
                if model.isPurchasing(product) {
                    ProgressView().tint(.white)
                } else {
                    Text(owned ? "Current Plan" : "Get")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .tint(owned ? .gray : Theme.accent)
        .disabled(owned || model.isPurchasing(product))
    }
}
