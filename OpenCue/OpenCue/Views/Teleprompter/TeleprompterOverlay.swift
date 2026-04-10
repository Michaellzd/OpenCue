import SwiftUI

struct TeleprompterOverlay: View {
    @Environment(ScrollEngine.self) private var scrollEngine

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.white.opacity(Constants.defaultOpacity)

                if scrollEngine.state == .countdown {
                    CountdownView(number: scrollEngine.currentCountdown)
                } else {
                    scrollingTextView
                }
            }
            .clipped()
            .onAppear {
                scrollEngine.viewportHeight = proxy.size.height
                scrollEngine.clampOffsetToContent()
            }
            .onChange(of: proxy.size.height) { _, newHeight in
                scrollEngine.viewportHeight = newHeight
                scrollEngine.clampOffsetToContent()
            }
        }
        .frame(width: Constants.defaultOverlayWidth, height: Constants.defaultOverlayHeight)
    }

    private var scrollingTextView: some View {
        VStack(spacing: 0) {
            Text(displayText)
                .font(.system(size: Constants.defaultFontSize))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                scrollEngine.textHeight = geo.size.height
                                scrollEngine.clampOffsetToContent()
                            }
                            .onChange(of: geo.size.height) { _, newHeight in
                                scrollEngine.textHeight = newHeight
                                scrollEngine.clampOffsetToContent()
                            }
                    }
                )

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .offset(y: -scrollEngine.offset)
        .opacity(scrollEngine.state == .idle ? 0.9 : 1)
    }

    private var displayText: String {
        scrollEngine.textContent.isEmpty ? "Select a note to begin." : scrollEngine.textContent
    }
}
