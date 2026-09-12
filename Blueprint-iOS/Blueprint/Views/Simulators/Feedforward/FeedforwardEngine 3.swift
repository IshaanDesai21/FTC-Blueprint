import Foundation
import Observation

enum FeedforwardMode: String, CaseIterable {
    case ffOnly = "ff-only"
    case pidOnly = "pid-only"
    case ffPlusPid = "ff+pid"

    var label: String {
        switch self {
        case .ffOnly: return "FF Only".localizedUI
        case .pidOnly: return "PID Only".localizedUI
        case .ffPlusPid: return "FF + PID".localizedUI
        }
    }

    var icon: String {
        switch self {
        case .ffOnly: return "bolt.fill"
        case .pidOnly: return "arrow.triangle.2.circlepath"
        case .ffPlusPid: return "bolt.badge.a.fill"
        }
    }
}

struct Sample: Hashable {
    let t: Double
    let v: Double
}

/// Ports FeedforwardVisualizer.svelte: DT=0.02, a cyclic trapezoidal velocity setpoint,
/// a hidden "plant" (PLANT_KV/KA/KS) the user's kS/kV/kA are estimating, and optional PD feedback.
@Observable
final class FeedforwardEngine {
    var kS: Double = 0.05
    var kV: Double = 0.02
    var kA: Double = 0.003
    var kP: Double = 0.4
    var kD: Double = 0.1
    var targetVel: Double = 80
    var targetAccel: Double = 40
    var mode: FeedforwardMode = .ffPlusPid

    private(set) var isRunning = false
    private(set) var velHistory: [Sample] = []
    private(set) var targetHistory: [Sample] = []
    private(set) var voltageHistory: [Sample] = []
    private(set) var errorHistory: [Sample] = []

    private let dt = 0.02
    private let maxH = 250
    private let plantKV = 0.018
    private let plantKA = 0.004
    private let plantKS = 0.06

    private var t: Double = 0
    private var pos: Double = 0
    private var vel: Double = 0
    private var lastError: Double = 0
    private var timer: Timer?

    var currentError: Double {
        (targetHistory.last?.v ?? 0) - (velHistory.last?.v ?? 0)
    }

    var currentVoltage: Double {
        voltageHistory.last?.v ?? 0
    }

    func rmsError() -> Double {
        guard errorHistory.count >= 5 else { return 0 }
        let recent = errorHistory.suffix(50)
        let sumSq = recent.reduce(0) { $0 + $1.v * $1.v }
        return (sumSq / Double(min(errorHistory.count, 50))).squareRoot()
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        lastError = 0
        timer = Timer.scheduledTimer(withTimeInterval: dt, repeats: true) { [weak self] _ in
            self?.step()
        }
    }

    func stop() {
        timer?.invalidate(); timer = nil
        isRunning = false
    }

    func resetSim() {
        stop()
        t = 0; pos = 0; vel = 0; lastError = 0
        velHistory = []; targetHistory = []; voltageHistory = []; errorHistory = []
    }

    func setMode(_ m: FeedforwardMode) {
        mode = m
        resetSim()
    }

    private func targetVelAtTime(_ time: Double) -> Double {
        let rampTime = targetVel / targetAccel
        let holdTime = 1.5
        let totalCycle = 2 * rampTime + holdTime + 0.5
        let tc = time.truncatingRemainder(dividingBy: totalCycle)

        if tc < rampTime { return targetAccel * tc }
        if tc < rampTime + holdTime { return targetVel }
        if tc < 2 * rampTime + holdTime { return targetVel - targetAccel * (tc - rampTime - holdTime) }
        return 0
    }

    private func targetAccelAtTime(_ time: Double) -> Double {
        let rampTime = targetVel / targetAccel
        let holdTime = 1.5
        let totalCycle = 2 * rampTime + holdTime + 0.5
        let tc = time.truncatingRemainder(dividingBy: totalCycle)

        if tc < rampTime { return targetAccel }
        if tc < rampTime + holdTime { return 0 }
        if tc < 2 * rampTime + holdTime { return -targetAccel }
        return 0
    }

    private func computeVoltage(_ tNow: Double, _ currentVel: Double) -> Double {
        let tv = targetVelAtTime(tNow)
        let ta = targetAccelAtTime(tNow)
        let error = tv - currentVel

        var ff = 0.0
        var fb = 0.0

        if mode == .ffOnly || mode == .ffPlusPid {
            ff = kS * sign(tv) + kV * tv + kA * ta
        }

        if mode == .pidOnly || mode == .ffPlusPid {
            let deriv = (error - lastError) / dt
            fb = kP * error + kD * deriv
        }

        lastError = error
        return max(-12, min(12, ff + fb))
    }

    private func stepPlant(_ voltage: Double, _ currentVel: Double) -> Double {
        let backEmf = plantKV * currentVel
        let netVoltage = voltage - backEmf - plantKS * sign(currentVel == 0 ? 0.001 : currentVel)
        let accelOut = netVoltage / (plantKA * (1 / dt + 1))
        return currentVel + accelOut * dt * 0.6
    }

    private func sign(_ x: Double) -> Double {
        x > 0 ? 1 : (x < 0 ? -1 : 0)
    }

    private func step() {
        t += dt
        let voltage = computeVoltage(t, vel)
        vel = stepPlant(voltage, vel)
        pos += vel * dt
        let tv = targetVelAtTime(t)

        appendCapped(&velHistory, Sample(t: t, v: vel))
        appendCapped(&targetHistory, Sample(t: t, v: tv))
        appendCapped(&voltageHistory, Sample(t: t, v: voltage))
        appendCapped(&errorHistory, Sample(t: t, v: tv - vel))
    }

    private func appendCapped(_ array: inout [Sample], _ sample: Sample) {
        array.append(sample)
        if array.count > maxH { array.removeFirst() }
    }
}
