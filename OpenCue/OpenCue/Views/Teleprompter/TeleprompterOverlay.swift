import SwiftUI

struct TeleprompterOverlay: View {
    @Environment(AppSettings.self) private var settings

    private let placeholderText = """
    This is **test teleprompter** text.

    OpenCue displays your *script* right here in the notch area.


    The text will eventually scroll automatically when you hit play.
    """

    var body: some View {
        ScrollView {
            renderedText
                .font(.system(size: settings.fontSize))
                .foregroundColor(settings.textColor)
                .multilineTextAlignment(settings.swiftUITextAlignment)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: settings.contentFrameAlignment)
        }
        .scrollDisabled(true)
        .frame(width: settings.overlayWidth, height: settings.overlayHeight)
        .background(Color.white.opacity(settings.opacity))
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
        guard settings.collapseEmptyLines else { return placeholderText }

        return placeholderText.replacingOccurrences(
            of: #"\n{2,}"#,
            with: "\n",
            options: .regularExpression
        )
    }
}
