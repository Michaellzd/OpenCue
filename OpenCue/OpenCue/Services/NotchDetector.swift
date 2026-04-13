import AppKit

struct NotchGeometry {
    let rect: NSRect
    let screenFrame: NSRect

    var centerX: CGFloat {
        rect.midX
    }

    var bottomY: CGFloat {
        rect.minY
    }
}

class NotchDetector {

    /// Detect the notch on the built-in display.
    /// Returns nil if no notch is found.
    static func detect() -> NotchGeometry? {
        guard let screen = builtInScreen() else { return nil }

        // macOS 12+ exposes safeAreaInsets; a top inset > 0 means a notch exists
        let topInset = screen.safeAreaInsets.top
        guard topInset > 0 else { return nil }

        let frame = screen.frame
        // auxiliaryTopLeftArea / auxiliaryTopRightArea (macOS 14+)
        // The notch is the gap between these two rects.
        if let leftArea = screen.auxiliaryTopLeftArea,
           let rightArea = screen.auxiliaryTopRightArea {
            let notchRect = NSRect(
                x: leftArea.maxX,
                y: min(leftArea.minY, rightArea.minY),
                width: max(rightArea.minX - leftArea.maxX, 0),
                height: max(leftArea.height, rightArea.height)
            )
            return NotchGeometry(
                rect: notchRect,
                screenFrame: frame
            )
        }

        // Fallback: estimate notch dimensions from known hardware
        let estimatedNotchWidth = min(max(frame.width * 0.12, 180), 220)
        let notchRect = NSRect(
            x: frame.midX - estimatedNotchWidth / 2,
            y: frame.maxY - topInset,
            width: estimatedNotchWidth,
            height: topInset
        )

        return NotchGeometry(
            rect: notchRect,
            screenFrame: frame
        )
    }

    /// Find the built-in display (the one that can have a notch).
    private static func builtInScreen() -> NSScreen? {
        for screen in NSScreen.screens {
            let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
            if CGDisplayIsBuiltin(screenNumber) != 0 {
                return screen
            }
        }
        // If we can't identify the built-in display, fall back to main screen
        return NSScreen.main
    }
}
