import SwiftUI

struct GeneralTab: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    sliderRow(
                        title: "Scroll Speed",
                        valueText: scrollSpeedValueText
                    ) {
                        Slider(value: scrollSpeedBinding, in: 1...10, step: 0.25)
                        HStack {
                            Text("Very Slow")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("Fast")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                }
                .padding(8)
            } label: {
                Label("Scroll", systemImage: "speedometer")
                    .font(.headline)
            }
        }
    }

    private var scrollSpeedBinding: Binding<Double> {
        Binding(
            get: { settings.scrollSpeed },
            set: { settings.scrollSpeed = $0 }
        )
    }

    private var scrollSpeedValueText: String {
        "\(scrollSpeedDescriptor) · \(String(format: "%.2f", settings.scrollSpeed))"
    }

    private var scrollSpeedDescriptor: String {
        switch settings.scrollSpeed {
        case ..<2.5:
            return "Very Slow"
        case ..<4.5:
            return "Slow"
        case ..<7.0:
            return "Normal"
        default:
            return "Fast"
        }
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
