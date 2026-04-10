import CoreGraphics
import Foundation
import Observation

enum ScrollState: Equatable {
    case idle
    case countdown
    case playing
    case paused
    case finished
}

@Observable
final class ScrollEngine {
    var state: ScrollState = .idle
    var offset: CGFloat = 0
    var currentCountdown: Int = Constants.defaultCountdownDuration

    var speed: Double = Constants.defaultScrollSpeed
    var countdownEnabled: Bool = true
    var countdownDuration: Int = Constants.defaultCountdownDuration

    var textContent: String = ""
    var textHeight: CGFloat = 0
    var viewportHeight: CGFloat = Constants.defaultOverlayHeight

    @ObservationIgnored
    private var scrollTimer: Timer?

    @ObservationIgnored
    private var countdownTimer: Timer?

    @ObservationIgnored
    private var maximumOffset: CGFloat {
        max(textHeight - viewportHeight, 0)
    }

    deinit {
        scrollTimer?.invalidate()
        countdownTimer?.invalidate()
    }

    func play() {
        guard !textContent.isEmpty else { return }

        switch state {
        case .playing, .countdown:
            return
        case .finished:
            reset()
        case .idle, .paused:
            break
        }

        if countdownEnabled && state == .idle {
            startCountdown()
        } else {
            startScrolling()
        }
    }

    func pause() {
        guard state == .playing else { return }
        scrollTimer?.invalidate()
        scrollTimer = nil
        state = .paused
    }

    func reset() {
        scrollTimer?.invalidate()
        countdownTimer?.invalidate()
        scrollTimer = nil
        countdownTimer = nil
        offset = 0
        currentCountdown = max(countdownDuration, 1)
        state = .idle
    }

    func setSpeed(_ newSpeed: Double) {
        speed = min(max(newSpeed, 1), 10)
    }

    func clampOffsetToContent() {
        offset = min(max(offset, 0), maximumOffset)
        if state == .finished && maximumOffset == 0 {
            offset = 0
        }
    }

    private func startCountdown() {
        scrollTimer?.invalidate()
        countdownTimer?.invalidate()

        currentCountdown = max(countdownDuration, 1)
        state = .countdown

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            if self.currentCountdown > 1 {
                self.currentCountdown -= 1
            } else {
                timer.invalidate()
                self.countdownTimer = nil
                self.currentCountdown = 0
                self.startScrolling()
            }
        }

        countdownTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func startScrolling() {
        countdownTimer?.invalidate()
        countdownTimer = nil

        let targetOffset = maximumOffset
        guard targetOffset > 0 else {
            offset = 0
            state = .finished
            return
        }

        state = .playing

        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            self.offset += CGFloat(self.speed * 0.5)
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
