import SwiftUI

struct VisualTab: View {
    @Environment(AppSettings.self) private var settings

    private enum AlignmentOption: String, CaseIterable, Identifiable {
        case left
        case center
        case right
        case justified

        var id: String { rawValue }

        var title: String {
            switch self {
            case .left:
                return "Left"
            case .center:
                return "Center"
            case .right:
                return "Right"
            case .justified:
                return "Justified"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    sliderRow(
                        title: "Font Size",
                        valueText: "\(Int(settings.fontSize))"
                    ) {
                        Slider(value: fontSizeBinding, in: 12...36, step: 1)
                    }

                    sliderRow(
                        title: "Width",
                        valueText: "\(Int(settings.overlayWidth))px"
                    ) {
                        Slider(value: overlayWidthBinding, in: 200...500, step: 10)
                    }

                    sliderRow(
                        title: "Height",
                        valueText: "\(Int(settings.overlayHeight))px"
                    ) {
                        Slider(value: overlayHeightBinding, in: 80...300, step: 10)
                    }

                    sliderRow(
                        title: "Opacity",
                        valueText: "\(Int(settings.opacity * 100))%"
                    ) {
                        Slider(value: opacityPercentBinding, in: 50...100, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Text Alignment")
                        Picker("Text Alignment", selection: textAlignmentBinding) {
                            ForEach(AlignmentOption.allCases) { option in
                                Text(option.title).tag(option.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }
                .padding(8)
            } label: {
                Label("Appearance", systemImage: "paintbrush.fill")
                    .font(.headline)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable Rich Text Formatting", isOn: richTextBinding)

                    Toggle("Collapse Empty Lines", isOn: collapseEmptyLinesBinding)

                    HStack {
                        Text("Text Color")
                        Spacer()
                        ColorPicker(
                            "",
                            selection: textColorBinding,
                            supportsOpacity: false
                        )
                        .labelsHidden()
                    }
                }
                .padding(8)
            } label: {
                Label("Formatting", systemImage: "textformat")
                    .font(.headline)
            }
        }
    }

    private var fontSizeBinding: Binding<Double> {
        Binding(
            get: { settings.fontSize },
            set: { settings.fontSize = $0 }
        )
    }

    private var overlayWidthBinding: Binding<Double> {
        Binding(
            get: { settings.overlayWidth },
            set: { settings.overlayWidth = $0 }
        )
    }

    private var overlayHeightBinding: Binding<Double> {
        Binding(
            get: { settings.overlayHeight },
            set: { settings.overlayHeight = $0 }
        )
    }

    private var opacityPercentBinding: Binding<Double> {
        Binding(
            get: { settings.opacity * 100 },
            set: { settings.opacity = $0 / 100 }
        )
    }

    private var textAlignmentBinding: Binding<String> {
        Binding(
            get: { settings.textAlignment },
            set: { settings.textAlignment = $0 }
        )
    }

    private var richTextBinding: Binding<Bool> {
        Binding(
            get: { settings.richTextEnabled },
            set: { settings.richTextEnabled = $0 }
        )
    }

    private var collapseEmptyLinesBinding: Binding<Bool> {
        Binding(
            get: { settings.collapseEmptyLines },
            set: { settings.collapseEmptyLines = $0 }
        )
    }

    private var textColorBinding: Binding<Color> {
        Binding(
            get: { settings.textColor },
            set: { settings.textColor = $0 }
        )
    }

    @ViewBuilder
    private func sliderRow(
        title: String,
        valueText: String,
        @ViewBuilder slider: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(valueText)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            slider()
        }
    }
}
