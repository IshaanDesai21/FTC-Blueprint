import Foundation
import Observation

struct MotionProfile {
    let accelTime: Double
    let cruiseTime: Double
    let decelTime: Double
    let totalTime: Double
    let peakVel: Double
    let accelDist: Double
    let cruiseDist: Double

    var isTriangular: Bool { cruiseTime <= 0 }
}

struct ProfileState {
    let pos: Double
    let vel: Double
    let acc: Double
}

/// Ports MotionProfileVisualizer.svelte's trapezoidal/triangular profile math exactly,
/// including the 50Hz (DT=0.02) fixed-timer playback.
@Observable
final class MotionProfileEngine {
    var distance: Double = 200
    var maxVel: Double = 80
    var maxAccel: Double = 40

    private(set) var isRunning = false
    private(set) var simTime: Double = 0
    private(set) var position: Double = 0
    private(set) var velocity: Double = 0
    private(set) var accel: Double = 0

    private let dt = 0.02
    private var timer: Timer?

    var profile: MotionProfile {
        Self.build(dist: distance, vMax: maxVel, aMax: maxAccel)
    }

    static func build(dist: Double, vMax: Double, aMax: Double) -> MotionProfile {
        let accelTime = vMax / aMax
        let accelDistFull = 0.5 * aMax * accelTime * accelTime

        let peakVel: Double
        let accelT: Double
        let cruiseDist: Double
        let cruiseTime: Double

        if 2 * accelDistFull > dist {
            peakVel = (aMax * dist).squareRoot()
            accelT = peakVel / aMax
            cruiseDist = 0
            cruiseTime = 0
        } else {
            peakVel = vMax
            accelT = accelTime
            cruiseDist = dist - 2 * accelDistFull
            cruiseTime = cruiseDist / vMax
        }

        let accelDist = 0.5 * aMax * accelT * accelT

        return MotionProfile(
            accelTime: accelT, cruiseTime: cruiseTime, decelTime: accelT,
            totalTime: 2 * accelT + cruiseTime,
            peakVel: peakVel, accelDist: accelDist, cruiseDist: cruiseDist
        )
    }

    func sample(_ t: Double) -> ProfileState {
        let p = profile
        if t <= 0 { return ProfileState(pos: 0, vel: 0, acc: 0) }
        if t >= p.totalTime {
            return ProfileState(pos: p.accelDist + p.cruiseDist + p.accelDist, vel: 0, acc: 0)
        }

        if t < p.accelTime {
            return ProfileState(pos: 0.5 * maxAccel * t * t, vel: maxAccel * t, acc: maxAccel)
        } else if t < p.accelTime + p.cruiseTime {
            let d = t - p.accelTime
            return ProfileState(pos: p.accelDist + p.peakVel * d, vel: p.peakVel, acc: 0)
        } else {
            let d = t - p.accelTime - p.cruiseTime
            let pos = p.accelDist + p.cruiseDist + p.peakVel * d - 0.5 * maxAccel * d * d
            return ProfileState(pos: pos, vel: p.peakVel - maxAccel * d, acc: -maxAccel)
        }
    }

    func start() {
        guard timer == nil else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: dt, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        timer?.invalidate(); timer = nil
        isRunning = false
    }

    func resetSim() {
        stop()
        simTime = 0; position = 0; velocity = 0; accel = 0
    }

    private func tick() {
        simTime += dt
        let s = sample(simTime)
        position = s.pos; velocity = s.vel; accel = s.acc
        if simTime >= profile.totalTime + 0.1 { stop() }
    }

    func curve(_ accessor: @escaping (ProfileState) -> Double) -> [Sample] {
        let p = profile
        let steps = 200
        return (0...steps).map { i in
            let t = (Double(i) / Double(steps)) * p.totalTime
            return Sample(t: t, v: accessor(sample(t)))
        }
    }
}
