import SwiftUI

/// A presented font picker that lists every catalog font grouped by category.
/// Each row renders its name in its own typeface (a live preview), marks premium
/// fonts with a trailing gold crown, and checks the current selection. Premium
/// fonts stay selectable in this pre-StoreKit phase; entitlement gating lands
/// with monetization.
///
/// Built as a custom sheet because a system `Picker`/`Menu` (a UIKit menu) can
/// render neither custom per-row fonts nor a colored trailing badge.
struct FontPickerSheet: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.entitlements) private var entitlements
    @State private var upsellFeature: PremiumFeature?

    var body: some View {
        NavigationStack {
            List {
                ForEach(FontCategory.allCases) { category in
                    Section(category.displayName) {
                        ForEach(FontCatalog.fonts(in: category)) { font in
                            row(font)
                        }
                    }
                }
            }
            .navigationTitle("Font")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .upsell($upsellFeature)
    }

    /// Premium fonts route a locked user to the upsell instead of selecting.
    private var isFontLocked: Bool { !entitlements.isUnlocked(.premiumFont) }

    private func row(_ font: FrameFont) -> some View {
        Button {
            if font.isPremium && isFontLocked {
                upsellFeature = .premiumFont
            } else {
                selection = font.id
                dismiss()
            }
        } label: {
            HStack(spacing: 10) {
                Text(font.displayName)
                    .font(font.font(size: 18))
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                if font.isPremium {
                    Image(systemName: "crown.fill")
                        .font(.footnote)
                        .foregroundStyle(Theme.premiumGold)
                }
                if font.id == selection {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(font.displayName)
        .accessibilityValue(font.isPremium ? "Premium" : "")
        .accessibilityAddTraits(font.id == selection ? .isSelected : [])
    }
}
