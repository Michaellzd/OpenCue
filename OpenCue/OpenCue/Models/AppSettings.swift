import AppKit
import Observation
import SwiftUI

@Observable
final class AppSettings {
    static let shared = AppSettings()

    @ObservationIgnored
    private let userDefaults: UserDefaults

    var fontSize: Double {
        didSet { store(fontSize, key: Keys.fontSize, oldValue: oldValue) }
    }

    var overlayWidth: Double {
        didSet { store(overlayWidth, key: Keys.overlayWidth, oldValue: oldValue) }
    }

    var overlayHeight: Double {
        didSet { store(overlayHeight, key: Keys.overlayHeight, oldValue: oldValue) }
    }

    var opacity: Double {
        didSet { store(opacity, key: Keys.opacity, oldValue: oldValue) }
    }

    var textAlignment: String {
        didSet { store(textAlignment, key: Keys.textAlignment, oldValue: oldValue) }
    }

    var richTextEnabled: Bool {
        didSet { store(richTextEnabled, key: Keys.richTextEnabled, oldValue: oldValue) }
    }

    var collapseEmptyLines: Bool {
        didSet { store(collapseEmptyLines, key: Keys.collapseEmptyLines, oldValue: oldValue) }
    }

    var textColorData: Data {
        didSet { store(textColorData, key: Keys.textColor, oldValue: oldValue) }
    }

    var scrollSpeed: Double {
        didSet { store(scrollSpeed, key: Keys.scrollSpeed, oldValue: oldValue) }
    }

    var countdownEnabled: Bool {
        didSet { store(countdownEnabled, key: Keys.countdownEnabled, oldValue: oldValue) }
    }

    var countdownDuration: Int {
        didSet { store(countdownDuration, key: Keys.countdownDuration, oldValue: oldValue) }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        fontSize = userDefaults.object(forKey: Keys.fontSize) as? Double ?? Double(Constants.defaultFontSize)
        overlayWidth = userDefaults.object(forKey: Keys.overlayWidth) as? Double ?? Double(Constants.defaultOverlayWidth)
        overlayHeight = userDefaults.object(forKey: Keys.overlayHeight) as? Double ?? Double(Constants.defaultOverlayHeight)
        opacity = userDefaults.object(forKey: Keys.opacity) as? Double ?? Constants.defaultOpacity
        textAlignment = userDefaults.string(forKey: Keys.textAlignment) ?? "center"
        richTextEnabled = userDefaults.object(forKey: Keys.richTextEnabled) as? Bool ?? true
        collapseEmptyLines = userDefaults.object(forKey: Keys.collapseEmptyLines) as? Bool ?? false
        textColorData = userDefaults.data(forKey: Keys.textColor) ?? Self.archivedColor(NSColor.black)
        scrollSpeed = userDefaults.object(forKey: Keys.scrollSpeed) as? Double ?? Constants.defaultScrollSpeed
        countdownEnabled = userDefaults.object(forKey: Keys.countdownEnabled) as? Bool ?? true
        countdownDuration = userDefaults.object(forKey: Keys.countdownDuration) as? Int ?? Constants.defaultCountdownDuration
    }

    var textColor: Color {
        get {
            guard let nsColor = try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: NSColor.self,
                from: textColorData
            ) else {
                return .black
            }

            return Color(nsColor)
        }
        set {
            textColorData = Self.archivedColor(NSColor(newValue))
        }
    }

    var fontSizeCGFloat: CGFloat {
        CGFloat(fontSize)
    }

    var overlayWidthCGFloat: CGFloat {
        CGFloat(overlayWidth)
    }

    var overlayHeightCGFloat: CGFloat {
        CGFloat(overlayHeight)
    }

    var swiftUITextAlignment: TextAlignment {
        switch textAlignment {
        case "left":
            return .leading
        case "right":
            return .trailing
        case "center":
            return .center
        case "justified":
            return .leading
        default:
            return .center
        }
    }

    var contentFrameAlignment: Alignment {
        switch textAlignment {
        case "left", "justified":
            return .leading
        case "right":
            return .trailing
        default:
            return .center
        }
    }

    var nsTextAlignment: NSTextAlignment {
        switch textAlignment {
        case "left":
            return .left
        case "right":
            return .right
        case "justified":
            return .justified
        default:
            return .center
        }
    }

    private func store(_ value: Double, key: String, oldValue: Double) {
        guard value != oldValue else { return }
        userDefaults.set(value, forKey: key)
        postChange(for: key)
    }

    private func store(_ value: Int, key: String, oldValue: Int) {
        guard value != oldValue else { return }
        userDefaults.set(value, forKey: key)
        postChange(for: key)
    }

    private func store(_ value: Bool, key: String, oldValue: Bool) {
        guard value != oldValue else { return }
        userDefaults.set(value, forKey: key)
        postChange(for: key)
    }

    private func store(_ value: String, key: String, oldValue: String) {
        guard value != oldValue else { return }
        userDefaults.set(value, forKey: key)
        postChange(for: key)
    }

    private func store(_ value: Data, key: String, oldValue: Data) {
        guard value != oldValue else { return }
        userDefaults.set(value, forKey: key)
        postChange(for: key)
    }

    private func postChange(for key: String) {
        NotificationCenter.default.post(
            name: .appSettingsDidChange,
            object: self,
            userInfo: [AppSettings.changeKeyUserInfoKey: key]
        )
    }

    private static func archivedColor(_ color: NSColor) -> Data {
        (try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)) ?? Data()
    }
}

extension AppSettings {
    static let changeKeyUserInfoKey = "AppSettings.changedKey"

    enum Keys {
        static let fontSize = "opencue.fontSize"
        static let overlayWidth = "opencue.overlayWidth"
        static let overlayHeight = "opencue.overlayHeight"
        static let opacity = "opencue.opacity"
        static let textAlignment = "opencue.textAlignment"
        static let textColor = "opencue.textColor"
        static let richTextEnabled = "opencue.richTextEnabled"
        static let collapseEmptyLines = "opencue.collapseEmptyLines"
        static let scrollSpeed = "opencue.scrollSpeed"
        static let countdownEnabled = "opencue.countdownEnabled"
        static let countdownDuration = "opencue.countdownDuration"
    }
}

extension Notification.Name {
    static let appSettingsDidChange = Notification.Name("AppSettings.didChange")
}
