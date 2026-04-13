import CoreGraphics
import Foundation
import Observation

enum ScrollState: Equatable {
    case idle
    case playing
    case paused
    case finished
}

@Observable
final class ScrollEngine {
    var state: ScrollState = .idle {
        didSet {
            guard oldValue != state else { return }
            NotificationCenter.default.post(name: .scrollEngineStateDidChange, object: self)
        }
    }
    var offset: CGFloat = 0
    var hasSelectedNote: Bool = false

    var speed: Double = Constants.defaultScrollSpeed

    var textContent: String = ""
    var textHeight: CGFloat = 0
    var viewportHeight: CGFloat = Constants.defaultOverlayHeight

    @ObservationIgnored
    private var scrollTimer: Timer?

    @ObservationIgnored
    private var maximumOffset: CGFloat {
        max(textHeight - viewportHeight, 0)
    }

    @ObservationIgnored
    private var pointsPerSecond: CGFloat {
        let normalized = min(max((speed - 1) / 9, 0), 1)
        let eased = pow(normalized, 1.85)
        return 1.5 + CGFloat(eased * 42)
    }

    var hasPlayableText: Bool {
        !textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    deinit {
        scrollTimer?.invalidate()
    }

    func play() {
        guard hasPlayableText else { return }

        switch state {
        case .playing:
            return
        case .finished:
            reset()
        case .idle, .paused:
            break
        }

        startScrolling()
    }

    func pause() {
        guard state == .playing else { return }
        scrollTimer?.invalidate()
        scrollTimer = nil
        state = .paused
    }

    func reset() {
        scrollTimer?.invalidate()
        scrollTimer = nil
        offset = 0
        state = .idle
    }

    func setSpeed(_ newSpeed: Double) {
        speed = min(max(newSpeed, 1), 10)
    }

    func togglePlayback() {
        switch state {
        case .idle, .finished:
            reset()
            play()
        case .playing:
            pause()
        case .paused:
            play()
        }
    }

    func updateConfiguration(speed: Double) {
        setSpeed(speed)
    }

    func clampOffsetToContent() {
        offset = min(max(offset, 0), maximumOffset)
        if state == .finished && maximumOffset == 0 {
            offset = 0
        }
    }

    private func startScrolling() {
        state = .playing
        beginScrollingWhenReady()
    }

    private func beginScrollingWhenReady(retryCount: Int = 0) {
        guard state == .playing else { return }

        guard textHeight > 0, viewportHeight > 0 else {
            guard retryCount < 20 else {
                offset = 0
                state = .finished
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.beginScrollingWhenReady(retryCount: retryCount + 1)
            }
            return
        }

        let targetOffset = maximumOffset
        guard targetOffset > 0 else {
            offset = 0
            state = .finished
            return
        }

        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            self.offset += self.pointsPerSecond / 60.0
            self.checkFinished()
        }

        scrollTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func checkFinished() {
        let targetOffset = maximumOffset
        guard targetOffset > 0 else {
            offset = 0
            scrollTimer?.invalidate()
            scrollTimer = nil
            state = .finished
            return
        }

        guard offset >= targetOffset else { return }

        offset = targetOffset
        scrollTimer?.invalidate()
        scrollTimer = nil
        state = .finished
    }
}

extension Notification.Name {
    static let scrollEngineStateDidChange = Notification.Name("scrollEngineStateDidChange")
}
