import SwiftUI

struct TeleprompterOverlay: View {
    @Environment(AppSettings.self) private var settings
    @Environment(ScrollEngine.self) private var scrollEngine
    @State private var hasAppeared = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.white.opacity(settings.opacity)

                if scrollEngine.state == .countdown {
                    CountdownView(number: scrollEngine.currentCountdown)
                } else {
                    scrollingTextView
                }

                if scrollEngine.state == .finished && scrollEngine.hasPlayableText {
                    finishedIndicator
                }
            }
            .overlay(edgeFadeOverlay.allowsHitTesting(false))
            .clipped()
            .opacity(hasAppeared ? 1 : 0)
            .onAppear {
                scrollEngine.viewportHeight = proxy.size.height
                scrollEngine.clampOffsetToContent()

                if !hasAppeared {
                    withAnimation(.easeOut(duration: 0.3)) {
                        hasAppeared = true
                    }
                }
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

    private var edgeFadeOverlay: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.white.opacity(settings.opacity), Color.white.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)

            Spacer(minLength: 0)

            LinearGradient(
                colors: [Color.white.opacity(0), Color.white.opacity(settings.opacity)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
        }
    }

    private var finishedIndicator: some View {
        Text("End")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.85), in: Capsule())
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .transition(.opacity)
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
        let baseText: String
        if !scrollEngine.hasSelectedNote {
            baseText = "Select a note to begin."
        } else if !scrollEngine.hasPlayableText {
            baseText = "Note is empty."
        } else {
            baseText = scrollEngine.textContent
        }

        guard settings.collapseEmptyLines else { return baseText }

        return baseText.replacingOccurrences(
            of: #"\n{2,}"#,
            with: "\n",
            options: .regularExpression
        )
    }
}
