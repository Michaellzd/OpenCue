import SwiftUI

struct TeleprompterOverlay: View {
    var body: some View {
        ScrollView {
            Text("This is a test teleprompter text. OpenCue displays your script right here in the notch area. This text will eventually scroll automatically when you hit play.")
                .font(.system(size: Constants.defaultFontSize))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(12)
                .frame(maxWidth: .infinity)
        }
        .scrollDisabled(true)
        .frame(width: Constants.defaultOverlayWidth, height: Constants.defaultOverlayHeight)
        .background(Color.white.opacity(Constants.defaultOpacity))
    }
}
