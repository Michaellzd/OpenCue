import SwiftUI

struct CountdownView: View {
    let number: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)

            VStack(spacing: 6) {
                Text("Starting In")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.82))
                    .textCase(.uppercase)
                    .tracking(1.6)

                Text("\(number)")
                    .id(number)
                    .font(.system(size: 80, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 18)
            .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.3), value: number)
    }
}
