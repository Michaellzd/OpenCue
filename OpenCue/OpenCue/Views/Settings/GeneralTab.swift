import SwiftUI

struct GeneralTab: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    sliderRow(
                        title: "Scroll Speed",
                        valueText: "\(Int(settings.scrollSpeed))"
                    ) {
                        Slider(value: scrollSpeedBinding, in: 1...10, step: 1)
                    }
                }
                .padding(8)
            } label: {
                Label("Scroll", systemImage: "speedometer")
                    .font(.headline)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Countdown Before Start", isOn: countdownEnabledBinding)

                    sliderRow(
                        title: "Countdown Duration",
                        valueText: "\(settings.countdownDuration)s"
                    ) {
                        Slider(value: countdownDurationBinding, in: 1...10, step: 1)
                            .disabled(!settings.countdownEnabled)
                    }
                    .opacity(settings.countdownEnabled ? 1 : 0.55)
                }
                .padding(8)
            } label: {
                Label("Countdown", systemImage: "timer")
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

    private var countdownEnabledBinding: Binding<Bool> {
        Binding(
            get: { settings.countdownEnabled },
            set: { settings.countdownEnabled = $0 }
        )
    }

    private var countdownDurationBinding: Binding<Double> {
        Binding(
            get: { Double(settings.countdownDuration) },
            set: { settings.countdownDuration = Int($0) }
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
