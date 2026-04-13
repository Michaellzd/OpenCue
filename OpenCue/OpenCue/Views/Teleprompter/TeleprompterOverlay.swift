import AppKit
import SwiftUI

struct TeleprompterOverlay: View {
    @Environment(AppSettings.self) private var settings
    @Environment(ScrollEngine.self) private var scrollEngine
    @State private var hasAppeared = false

    private var horizontalPadding: CGFloat { 12 }
    private var verticalPadding: CGFloat { 12 }
    private var contentWidth: CGFloat {
        max(settings.overlayWidthCGFloat - (horizontalPadding * 2), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.white.opacity(settings.opacity)

                scrollingTextView
                    .allowsHitTesting(false)

                interactionLayer

                if scrollEngine.state == .finished && scrollEngine.hasPlayableText {
                    finishedIndicator
                        .allowsHitTesting(false)
                }

                controlsBar
            }
            .overlay(edgeFadeOverlay.allowsHitTesting(false))
            .clipped()
            .opacity(hasAppeared ? 1 : 0)
            .onAppear {
                scrollEngine.viewportHeight = proxy.size.height
                updateMeasuredTextHeight()
                scrollEngine.clampOffsetToContent()

                if !hasAppeared {
                    withAnimation(.easeOut(duration: 0.3)) {
                        hasAppeared = true
                    }
                }
            }
            .onChange(of: proxy.size.height) { _, newHeight in
                scrollEngine.viewportHeight = newHeight
                updateMeasuredTextHeight()
                scrollEngine.clampOffsetToContent()
            }
            .onChange(of: measurementContext) { _, _ in
                updateMeasuredTextHeight()
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
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: contentWidth, alignment: settings.contentFrameAlignment)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .offset(y: -scrollEngine.offset)
        .opacity(scrollEngine.state == .idle ? 0.9 : 1)
    }

    private var interactionLayer: some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                handleOverlayTap()
            }
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

    private var controlsBar: some View {
        VStack {
            HStack {
                Spacer()

                if scrollEngine.state == .playing || scrollEngine.state == .paused {
                    Button(action: toggleOverlayPlayback) {
                        Image(systemName: scrollEngine.state == .playing ? "pause.fill" : "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.88), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help(scrollEngine.state == .playing ? "Pause" : "Resume")
                }

                Button(action: closePresentation) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.88), in: Circle())
                }
                .buttonStyle(.plain)
                .help("Close Presentation")
            }
            .padding(.top, 8)
            .padding(.trailing, 8)

            Spacer()
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

    private var measurementContext: MeasurementContext {
        MeasurementContext(
            text: displayText,
            width: contentWidth,
            fontSize: settings.fontSizeCGFloat
        )
    }

    private func handleOverlayTap() {
        switch scrollEngine.state {
        case .playing:
            scrollEngine.pause()
        case .paused:
            scrollEngine.play()
        case .idle, .finished:
            break
        }
    }

    private func closePresentation() {
        scrollEngine.reset()
    }

    private func toggleOverlayPlayback() {
        scrollEngine.togglePlayback()
    }

    private func updateMeasuredTextHeight() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = settings.nsTextAlignment
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: settings.fontSizeCGFloat),
            .paragraphStyle: paragraphStyle
        ]

        let boundingRect = NSString(string: displayText).boundingRect(
            with: NSSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes
        )

        scrollEngine.textHeight = ceil(boundingRect.height) + (verticalPadding * 2)
    }
}

private struct MeasurementContext: Equatable {
    let text: String
    let width: CGFloat
    let fontSize: CGFloat
}
