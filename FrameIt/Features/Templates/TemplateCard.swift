import SwiftUI

/// A single template row in the Templates list: its rendered thumbnail, name, and a
/// gold crown marking it a paid capability (pre-StoreKit: functional, crown-marked).
struct TemplateCard: View {
    let template: SavedTemplate

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            Text(template.name)
                .font(.body)
                .lineLimit(1)
            Spacer(minLength: 8)
            Image(systemName: "crown.fill")
                .font(.caption)
                .foregroundStyle(Theme.premiumGold)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(template.name) template")
    }

    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.secondarySystemBackground))
            if let image = template.thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(4)
            } else {
                Image(systemName: "square.stack")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
