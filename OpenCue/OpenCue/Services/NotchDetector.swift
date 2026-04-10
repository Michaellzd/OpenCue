import AppKit

struct NotchGeometry {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let screenWidth: CGFloat
    let screenFrame: NSRect
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
        let visibleFrame = screen.visibleFrame

        // auxiliaryTopLeftArea / auxiliaryTopRightArea (macOS 14+)
        // The notch is the gap between these two rects.
        if let leftArea = screen.auxiliaryTopLeftArea,
           let rightArea = screen.auxiliaryTopRightArea {
            let notchX = leftArea.maxX
            let notchWidth = rightArea.minX - leftArea.maxX
            // Y is the top of the visible frame (just below the menu bar / notch)
            let notchY = frame.maxY - topInset
            return NotchGeometry(
                x: notchX,
                y: notchY,
                width: notchWidth,
                screenWidth: frame.width,
                screenFrame: frame
            )
        }

        // Fallback: estimate notch dimensions from known hardware
        // All current notch MacBooks have roughly a 180-200px notch at Retina scale.
        let estimatedNotchWidth: CGFloat = 190
        let notchX = frame.midX - estimatedNotchWidth / 2
        let notchY = frame.maxY - topInset

        return NotchGeometry(
            x: notchX,
            y: notchY,
            width: estimatedNotchWidth,
            screenWidth: frame.width,
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
