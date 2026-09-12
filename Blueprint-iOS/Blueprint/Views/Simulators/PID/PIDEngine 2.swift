import Foundation
import Observation

/// Ports the exact physics/tuning-hint behavior of PIDVisualizer.svelte:
/// a fixed 40ms tick, target=100, anti-windup, 0.9 velocity damping per tick.
@Observable
final class PIDEngine {
    var kp: Double = 0.5
    var ki: Double = 0.01
    var kd: Double = 0.3
    var autoResetSeconds: Double = 4.5
    var countdownMs: Double = 4500

    private(set) var currentPos: Double = 0
    private(set) var history: [Double] = []

    let target: Double = 100
    private let maxHistory = 100

    private var velocity: Double = 0
    private var integralSum: Double = 0
    private var lastError: Double = 0

    private var tickTimer: Timer?
    private var autoResetTimer: Timer?
    private var countdownTimer: Timer?

    func start() {
        stop()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { [weak self] _ in
            self?.step()
        }
        armAutoReset()
    }

    func stop() {
        tickTimer?.invalidate(); tickTimer = nil
        autoResetTimer?.invalidate(); autoResetTimer = nil
        countdownTimer?.invalidate(); countdownTimer = nil
    }

    func resetSim() {
        currentPos = 0
        velocity = 0
        integralSum = 0
        lastError = 0
        history = []
    }

    func armAutoReset() {
        autoResetTimer?.invalidate()
        countdownTimer?.invalidate()
        guard autoResetSeconds > 0 else { return }
        let ms = autoResetSeconds * 1000
        countdownMs = ms
        autoResetTimer = Timer.scheduledTimer(withTimeInterval: autoResetSeconds, repeats: true) { [weak self] _ in
            self?.resetSim()
            self?.countdownMs = ms
        }
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.countdownMs = max(0, self.countdownMs - 100)
            if self.countdownMs <= 0 { self.countdownMs = ms }
        }
    }

    private func step() {
        let error = target - currentPos
        let derivative = error - lastError
        integralSum += error

        if abs(error) < 0.1 { integralSum = 0 }
        integralSum = max(-100, min(100, integralSum))

        let output = kp * error + ki * integralSum + kd * derivative

        velocity += output
        velocity *= 0.9
        currentPos += velocity

        lastError = error

        history.append(currentPos)
        if history.count > maxHistory { history.removeFirst() }
    }

    var hint: (text: String, kind: HintKind)? {
        if kp > 0.8 {
            return ("High P might cause overshoot!", .warning)
        } else if kd < 0.1 && kp > 0.2 {
            return ("Try increasing D to stop the oscillation.", .tip)
        } else if abs(currentPos - target) < 1 {
            return ("Stable target lock reached.", .success)
        }
        return nil
    }

    enum HintKind {
        case warning, tip, success
    }
}
