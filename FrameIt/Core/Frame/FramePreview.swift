import SwiftUI

/// The single source of truth for how a framed photo looks. Rendered both on
/// screen (in the editor) and during export (via `FrameRenderer`), so what the
/// user sees always matches the saved image.
///
/// All absolute style metrics (corner radius, border width) are authored against
/// a 400pt reference width and scaled by the actual `width`, so the frame looks
/// identical whether drawn at screen size or full export resolution.
struct FramePreview: View {
    let image: UIImage
    let style: FrameStyle
    let metadata: PhotoMetadata
    var width: CGFloat = 400
    /// A pre-rendered map image for the advanced Place column's map mode. Passed in
    /// because MapKit cannot draw inside `ImageRenderer`; see `EditorViewModel`.
    var mapSnapshot: UIImage? = nil

    private var scale: CGFloat { width / 400 }
    private var pad: CGFloat { width * style.padding }
    private var bottomPad: CGFloat { width * style.bottomPadding }
    private var bodySize: CGFloat { width * 0.035 }
    private var captionSize: CGFloat { width * 0.028 }

    /// Small, constant gap between the photo and the metadata block — independent of
    /// the padding slider so the text always hugs the photo with minimal breathing room.
    private var textTopGap: CGFloat { width * 0.04 }
    /// Gap above the credit line. Floored to a small constant (so it never crowds the
    /// caption) and grown by the Bottom-padding slider, which pushes the credit down.
    private var captionToCreditGap: CGFloat { max(width * 0.04, bottomPad) }
    /// Distance from the credit to the frame's bottom edge — clamped so the credit
    /// always sticks near the bottom with a capped margin, never floating.
    private var creditBottomMargin: CGFloat { min(max(pad, width * 0.025), width * 0.05) }
    /// The frame's bottom margin: capped when the credit shows (it owns the bottom),
    /// otherwise the regular padding plus the Bottom-padding slider.
    private var bottomMargin: CGFloat {
        style.signature.isHidden ? pad + bottomPad : creditBottomMargin
    }

    /// Resolves the chosen typeface at a size scaled by `fontScale`, applying the
    /// bold/italic toggles. The single place text styling is composed.
    private func styledFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let resolved = style.font.font(size: size * style.fontScale,
                                       weight: style.bold ? .bold : weight)
        return style.italic ? resolved.italic() : resolved
    }

    var body: some View {
        Group {
            switch style.layout {
            case .minimal: minimalLayout
            case .advanced: advancedLayout
            }
        }
        .frame(width: width)
        .background(style.background.color)
    }

    // MARK: Layouts

    /// Photo on top, one centered metadata block below (the classic caption look).
    private var minimalLayout: some View {
        framedContent { captionBlock }
    }

    /// Photo on top, metadata split into Exposure | Device | Place columns.
    private var advancedLayout: some View {
        framedContent { advancedColumns }
    }

    /// Shared frame skeleton: the photo, the metadata block hugging it, and the credit
    /// pinned near the bottom. The padding slider controls the photo's border (top +
    /// sides); the vertical text gaps are decoupled from it so the text stays tight.
    private func framedContent<Metadata: View>(@ViewBuilder metadata: () -> Metadata) -> some View {
        VStack(spacing: 0) {
            photoView
            metadata()
                .padding(.top, textTopGap)
            if !style.signature.isHidden {
                signatureLine
                    .padding(.top, captionToCreditGap)
            }
        }
        .padding(.horizontal, pad)
        .padding(.top, pad)
        .padding(.bottom, bottomMargin)
    }

    /// The small credit line at the bottom of the frame. Styled (frame font + color)
    /// for subscribers, or a neutral system watermark otherwise.
    private var signatureLine: some View {
        let text = style.signature.displayText(default: FrameStyle.defaultCredit)
        let font: Font = style.signature.matchesFrameStyle
            ? styledFont(captionSize * 0.8)
            : .system(size: captionSize * 0.8)
        return Text(text)
            .font(font)
            .foregroundStyle(style.textColor.color.opacity(0.4))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }

    // MARK: Advanced columns

    private var advancedColumns: some View {
        HStack(alignment: .top, spacing: pad * 0.6) {
            exposureColumn
            deviceColumn
            placeColumn
        }
        .frame(maxWidth: .infinity)
        .lineLimit(2)
        .minimumScaleFactor(0.5)
    }

    /// One metadata line at a given point in the column type scale.
    private func line(_ text: String, size: CGFloat,
                      weight: Font.Weight = .regular, opacity: Double) -> some View {
        Text(text)
            .font(styledFont(size, weight: weight))
            .foregroundStyle(style.textColor.color.opacity(opacity))
    }

    /// Left column — the exposure values are peers (medium weight).
    private var exposureColumn: some View {
        VStack(alignment: .leading, spacing: pad * 0.16) {
            ForEach(Array(settingParts.enumerated()), id: \.offset) { _, value in
                line(value, size: bodySize, weight: .medium, opacity: 0.85)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .multilineTextAlignment(.leading)
    }

    /// Middle column — the device name is the hero; camera + app are supporting.
    private var deviceColumn: some View {
        VStack(alignment: .center, spacing: pad * 0.16) {
            if let title = titleText {
                line(title, size: bodySize * 1.05, weight: .semibold, opacity: 1)
            }
            if let lens = lensText {
                line(lens, size: captionSize, opacity: 0.6)
            }
            if let app = appText {
                line(app, size: captionSize * 0.95, opacity: 0.5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .multilineTextAlignment(.center)
    }

    /// Right column — place text + date/time, or the minimap widget + caption.
    private var placeColumn: some View {
        VStack(alignment: .trailing, spacing: pad * 0.16) {
            if style.placeStyle == .map, let snapshot = mapSnapshot {
                mapWidget(snapshot)
                if style.isFieldEnabled(.location), let place = metadata.placeName {
                    line(place, size: captionSize, opacity: 0.6)
                }
            } else {
                if style.isFieldEnabled(.location), let place = metadata.placeName {
                    line(place, size: bodySize, weight: .medium, opacity: 0.9)
                }
                if style.isFieldEnabled(.dateTaken), let date = metadata.dateTaken {
                    line(ExposureFormatting.date(date), size: captionSize, opacity: 0.6)
                    line(ExposureFormatting.time(date), size: captionSize, opacity: 0.6)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topTrailing)
        .multilineTextAlignment(.trailing)
    }

    /// The minimap: the pre-rendered snapshot with the chosen pin centered on top.
    /// The pin is drawn here (not baked into the snapshot) so it stays crisp and
    /// supports custom glyphs.
    private func mapWidget(_ snapshot: UIImage) -> some View {
        let mapWidth = width * 0.30
        let mapHeight = mapWidth / 2   // 2:1 landscape strip
        return Image(uiImage: snapshot)
            .resizable()
            .scaledToFill()
            .frame(width: mapWidth, height: mapHeight)
            .clipShape(RoundedRectangle(cornerRadius: width * 0.02, style: .continuous))
            .overlay(
                Image(systemName: PinCatalog.systemName(id: style.pinIcon))
                    .font(.system(size: mapHeight * 0.4))
                    .foregroundStyle(Theme.accent)
                    .shadow(color: .black.opacity(0.35), radius: mapHeight * 0.03)
            )
    }

    // MARK: Pieces

    private var photoView: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius * scale, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius * scale, style: .continuous)
                    .strokeBorder(style.borderColor.color, lineWidth: style.borderWidth * scale)
            )
    }

    private var captionBlock: some View {
        VStack(spacing: width * 0.014) {
            if let title = titleText {
                Text(title)
                    .font(styledFont(bodySize * 1.15, weight: .semibold))
                    .foregroundStyle(style.textColor.color)
            }
            if let lens = lensText {
                Text(lens)
                    .font(styledFont(captionSize))
                    .foregroundStyle(style.textColor.color.opacity(0.65))
            }
            if !settingParts.isEmpty {
                Text(settingParts.joined(separator: "  ·  "))
                    .font(styledFont(bodySize, weight: .medium))
                    .foregroundStyle(style.textColor.color.opacity(0.9))
            }
            if !contextParts.isEmpty {
                Text(contextParts.joined(separator: "  ·  "))
                    .font(styledFont(captionSize))
                    .foregroundStyle(style.textColor.color.opacity(0.65))
            }
            if let app = appText {
                Text(app)
                    .font(styledFont(captionSize))
                    .foregroundStyle(style.textColor.color.opacity(0.5))
            }
        }
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.6)
    }

    // MARK: Caption content

    private var titleText: String? {
        style.isFieldEnabled(.device) ? metadata.deviceName : nil
    }

    private var lensText: String? {
        guard style.isFieldEnabled(.lens) else { return nil }
        return ExposureFormatting.cameraName(lensModel: metadata.lensModel,
                                             focalLength35mm: metadata.focalLengthIn35mm)
    }

    /// Camera-setting cluster: focal length · aperture · shutter · ISO.
    private var settingParts: [String] {
        var parts: [String] = []
        if style.isFieldEnabled(.focalLength), let v = metadata.focalLength,
           let s = ExposureFormatting.focalLength(v) { parts.append(s) }
        if style.isFieldEnabled(.aperture), let v = metadata.fNumber,
           let s = ExposureFormatting.aperture(v) { parts.append(s) }
        if style.isFieldEnabled(.shutter), let v = metadata.exposureTime,
           let s = ExposureFormatting.shutterSpeed(v) { parts.append(s) }
        if style.isFieldEnabled(.iso), let v = metadata.isoSpeed,
           let s = ExposureFormatting.iso(v) { parts.append(s) }
        return parts
    }

    /// Context cluster: date · place.
    private var contextParts: [String] {
        var parts: [String] = []
        if style.isFieldEnabled(.dateTaken), let date = metadata.dateTaken {
            parts.append(ExposureFormatting.date(date))
        }
        if style.isFieldEnabled(.location), let place = metadata.placeName {
            parts.append(place)
        }
        return parts
    }

    /// "Shot with <app>" line from the EXIF Software tag, version stripped.
    private var appText: String? {
        guard style.isFieldEnabled(.app), let software = metadata.software,
              let app = ExposureFormatting.captureApp(software) else { return nil }
        return "Shot with \(app)"
    }
}

// MARK: - Fitted preview

/// Reads the size of its content so `FittedFramePreview` can scale the frame to fit.
private struct FrameSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

/// Renders a `FramePreview` sized so the **entire** frame (photo + caption) fits
/// inside `available`, no scrolling.
///
/// The fit is measured with a **hidden probe** rendered at a constant `baseWidth`,
/// not at the live render width. Earlier the render width was derived from the size
/// it produced — a measure → width → re-measure loop that converges for the Minimal
/// caption but oscillates for the Advanced columns (their text reflows non-linearly
/// with width), crashing SwiftUI's layout engine on a layout toggle. A fixed-width
/// probe makes the measurement stable, so the visible frame's width can never feed
/// back into the measurement. The exporter renders at full res separately, so
/// on-screen fitting never affects output quality.
struct FittedFramePreview: View {
    let image: UIImage
    let style: FrameStyle
    let metadata: PhotoMetadata
    let available: CGSize
    var mapSnapshot: UIImage? = nil

    /// Horizontal inset so the frame doesn't touch the screen edges.
    private let horizontalInset: CGFloat = 32
    /// Vertical breathing room above/below the frame.
    private let verticalInset: CGFloat = 24

    /// Natural size of the frame measured at `baseWidth` (constant ⇒ stable).
    @State private var probeSize: CGSize = .zero

    private var baseWidth: CGFloat {
        max(1, available.width - horizontalInset)
    }

    /// Shrink-to-fit factor: only scales down when the frame is taller than the area.
    private var fitScale: CGFloat {
        guard probeSize.height > 0 else { return 1 }
        let availableHeight = max(1, available.height - verticalInset)
        return min(1, availableHeight / probeSize.height)
    }

    var body: some View {
        FramePreview(image: image, style: style, metadata: metadata,
                     width: baseWidth * fitScale, mapSnapshot: mapSnapshot)
            .fixedSize(horizontal: false, vertical: true)
            .shadow(color: .black.opacity(0.12), radius: 14, y: 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(probe)
    }

    /// Off-screen copy at a fixed width; only used to measure the natural height.
    private var probe: some View {
        FramePreview(image: image, style: style, metadata: metadata,
                     width: baseWidth, mapSnapshot: mapSnapshot)
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: baseWidth)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: FrameSizeKey.self, value: proxy.size)
                }
            )
            .onPreferenceChange(FrameSizeKey.self) { probeSize = $0 }
            .hidden()
            .allowsHitTesting(false)
    }
}
