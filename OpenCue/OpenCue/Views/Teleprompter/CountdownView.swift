import SwiftUI

struct CountdownView: View {
    let number: Int

    var body: some View {
        ZStack {
            Text("\(number)")
                .id(number)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.black.opacity(0.8))
                .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.3), value: number)
    }
}
