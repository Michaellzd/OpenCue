import SwiftUI

struct TeleprompterOverlay: View {
    @Environment(AppSettings.self) private var settings
    @Environment(ScrollEngine.self) private var scrollEngine

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.white.opacity(settings.opacity)

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
        .frame(width: settings.overlayWidthCGFloat, height: settings.overlayHeightCGFloat)
    }

    private var scrollingTextView: some View {
        VStack(spacing: 0) {
            renderedText
                .font(.system(size: settings.fontSizeCGFloat))
                .foregroundColor(settings.textColor)
                .multilineTextAlignment(settings.swiftUITextAlignment)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: settings.contentFrameAlignment)
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

    @ViewBuilder
    private var renderedText: some View {
        if settings.richTextEnabled,
           let attributed = try? AttributedString(
               markdown: displayText,
               options: AttributedString.MarkdownParsingOptions(
                   interpretedSyntax: .inlineOnlyPreservingWhitespace
               )
           ) {
            Text(attributed)
        } else {
            Text(displayText)
        }
    }

    private var displayText: String {
        let baseText = scrollEngine.textContent.isEmpty ? "Select a note to begin." : scrollEngine.textContent

        guard settings.collapseEmptyLines else { return baseText }

        return baseText.replacingOccurrences(
            of: #"\n{2,}"#,
            with: "\n",
            options: .regularExpression
        )
    }
}
