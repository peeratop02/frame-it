import SwiftUI

/// Headed groups of toggle chips for which metadata fields appear on the frame.
/// Fields are organised into Device / Exposure / Place sections, two chips per
/// row. Chips for fields with no data in the current photo are dimmed and
/// non-interactive, so the user understands why they can't be enabled.
struct MetadataControls: View {
    @Binding var style: FrameStyle
    let metadata: PhotoMetadata

    private let columns = [GridItem(.flexible(), spacing: 8),
                           GridItem(.flexible(), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(MetadataGroup.allCases) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.displayName.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(group.fields) { field in
                            chip(field)
                        }
                    }
                    // The Place column gains a Time/Map mode + pin picker in the
                    // advanced layout, where it can render a minimap widget.
                    if group == .place && style.layout == .advanced {
                        placeControls
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var placeControls: some View {
        Picker("Place as", selection: $style.placeStyle) {
            ForEach(PlaceStyle.allCases) { mode in
                Text(mode.displayName).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.top, 4)

        if style.placeStyle == .map {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PinCatalog.all) { pin in
                        pinButton(pin)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func pinButton(_ pin: PinIcon) -> some View {
        let isOn = style.pinIcon == pin.id
        return Button {
            style.pinIcon = pin.id
        } label: {
            Image(systemName: pin.systemName)
                .font(.title3)
                .foregroundStyle(isOn ? Color.white : .primary)
                .frame(width: 40, height: 40)
                .background(
                    Circle().fill(isOn ? Theme.accent : Color(.tertiarySystemFill))
                )
                .overlay(alignment: .topTrailing) {
                    if pin.isPremium {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.premiumGold)
                            .padding(2)
                            .background(Circle().fill(Color(.systemBackground)))
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(pin.displayName) pin")
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func chip(_ field: MetadataField) -> some View {
        let available = hasData(field)
        let isOn = available && style.enabledFields.contains(field)
        return Button {
            toggle(field)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.footnote)
                VStack(alignment: .leading, spacing: 0) {
                    Text(field.displayName)
                        .font(.subheadline)
                        .lineLimit(1)
                    if !available {
                        Text("No data")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(isOn ? Color.white : .primary)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isOn ? Theme.accent : Color(.tertiarySystemFill))
            )
            .contentShape(.rect(cornerRadius: 12))
            .opacity(available ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!available)
        .accessibilityLabel(field.displayName)
        .accessibilityValue(available ? (isOn ? "On" : "Off") : "Unavailable")
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func toggle(_ field: MetadataField) {
        var fields = style.enabledFields
        if fields.contains(field) {
            fields.removeAll { $0 == field }
        } else {
            fields.append(field)
        }
        style.enabledFields = fields
    }

    private func hasData(_ field: MetadataField) -> Bool {
        switch field {
        case .device: return metadata.deviceName != nil
        case .lens: return metadata.lensModel != nil
        case .dateTaken: return metadata.dateTaken != nil
        case .shutter: return metadata.exposureTime != nil
        case .aperture: return metadata.fNumber != nil
        case .iso: return metadata.isoSpeed != nil
        case .focalLength: return metadata.displayFocalLength != nil
        case .location: return metadata.placeName != nil || metadata.hasLocation
        case .app: return metadata.appName != nil
        }
    }
}
