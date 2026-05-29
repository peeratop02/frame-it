import SwiftUI

/// Reusable Liquid Glass building blocks. Glass is reserved for interactive
/// surfaces — the editor control dock, control panels, and floating buttons —
/// not applied to every view (per the Liquid Glass guidelines).

/// Wraps content in a regular glass surface with a rounded-rect shape.
private struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat
    func body(content: Content) -> some View {
        content.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
    }
}

extension View {
    /// A glass card background, e.g. for the editor control dock and panels.
    func glassCard(cornerRadius: CGFloat = Theme.controlCornerRadius) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

/// A circular, interactive glass icon button — used for floating actions
/// (close, share, save). Applying `.glassEffect(in: .circle)` directly (rather
/// than `.buttonStyle(.glass)`, which renders a capsule on a square frame)
/// guarantees a true circle. Meets the 44pt minimum touch target.
struct GlassIconButton<Label: View>: View {
    var accessibilityLabel: String
    /// When true, tints the glass with the accent color to signal a primary action.
    var prominent: Bool = false
    let action: () -> Void
    @ViewBuilder var label: Label

    init(accessibilityLabel: String,
         prominent: Bool = false,
         action: @escaping () -> Void,
         @ViewBuilder label: () -> Label) {
        self.accessibilityLabel = accessibilityLabel
        self.prominent = prominent
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: action) {
            label
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 44, height: 44)
                .contentShape(.circle)
                .glassEffect(glass, in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var glass: Glass {
        prominent ? .regular.tint(Theme.accent).interactive() : .regular.interactive()
    }
}

extension GlassIconButton where Label == Image {
    /// Convenience for the common case of an SF Symbol glyph.
    init(systemImage: String,
         accessibilityLabel: String,
         prominent: Bool = false,
         action: @escaping () -> Void) {
        self.init(accessibilityLabel: accessibilityLabel,
                  prominent: prominent,
                  action: action) {
            Image(systemName: systemImage)
        }
    }
}

/// A circular glass button that presents a `Menu` instead of firing an action —
/// matches `GlassIconButton`'s look so it reads as a peer in a button cluster.
struct GlassMenuButton<Content: View>: View {
    var systemImage: String
    var accessibilityLabel: String
    @ViewBuilder var content: Content

    var body: some View {
        Menu {
            content
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 44, height: 44)
                .contentShape(.circle)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
