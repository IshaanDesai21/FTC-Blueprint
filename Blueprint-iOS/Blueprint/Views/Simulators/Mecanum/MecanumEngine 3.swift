import Foundation
import Observation
import QuartzCore

struct WheelPowers {
    let fl: Double, fr: Double, bl: Double, br: Double
}

/// Ports the mecanum simulator's `+page.svelte` logic: exponential-smoothed inputs,
/// field-centric heading integration, and the standard mecanum wheel equations.
/// Touch buttons replace WASD/QE (no physical keyboard on iOS), driving the same
/// `keys` booleans the original derives targets from.
@Observable
final class MecanumEngine {
    var pressW = false
    var pressA = false
    var pressS = false
    var pressD = false
    var pressQ = false
    var pressE = false
    var accel: Double = 0.26
    var isFieldCentric = false

    private(set) var smoothX: Double = 0
    private(set) var smoothY: Double = 0
    private(set) var smoothRx: Double = 0
    private(set) var imuAngle: Double = 0

    private var lastTime: CFTimeInterval = 0
    private var displayLink: CADisplayLink?
    private var linkTarget: DisplayLinkTarget?

    private let rotSpeed = 120.0

    var imuNormalized: Double {
        (((imuAngle.truncatingRemainder(dividingBy: 360)) + 540).truncatingRemainder(dividingBy: 360)) - 180
    }

    var wheels: WheelPowers {
        let rad = (-imuAngle * .pi) / 180
        let x = isFieldCentric ? smoothX * cos(rad) - smoothY * sin(rad) : smoothX
        let y = isFieldCentric ? smoothX * sin(rad) + smoothY * cos(rad) : smoothY
        let rx = smoothRx

        let fl = y + x + rx
        let fr = y - x - rx
        let bl = y - x + rx
        let br = y + x - rx

        let maxMag = max(abs(fl), abs(fr), abs(bl), abs(br), 1)
        return WheelPowers(fl: fl / maxMag, fr: fr / maxMag, bl: bl / maxMag, br: br / maxMag)
    }

    var moveVectorAngleDeg: Double {
        atan2(smoothX, smoothY) * (180 / .pi) + (isFieldCentric ? -imuAngle : 0)
    }

    var moveVectorMagnitude: Double {
        max(abs(smoothX), abs(smoothY))
    }

    func start() {
        stop()
        let target = DisplayLinkTarget { [weak self] in self?.frame() }
        linkTarget = target
        let link = CADisplayLink(target: target, selector: #selector(DisplayLinkTarget.tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
        lastTime = 0
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        linkTarget = nil
    }

    func setHeading(_ degrees: Double) {
        let delta = degrees - imuNormalized
        let unwrapped = ((delta + 540).truncatingRemainder(dividingBy: 360)) - 180
        imuAngle += unwrapped
    }

    private func frame() {
        let now = CACurrentMediaTime()
        let dt = lastTime == 0 ? 0 : min(now - lastTime, 0.1)
        lastTime = now

        let targetX = (pressD ? 1.0 : 0) + (pressA ? -1.0 : 0)
        let targetY = (pressW ? 1.0 : 0) + (pressS ? -1.0 : 0)
        let targetRx = (pressE ? 1.0 : 0) + (pressQ ? -1.0 : 0)

        let k = min(accel, 1)
        smoothX += (targetX - smoothX) * k
        smoothY += (targetY - smoothY) * k
        smoothRx += (targetRx - smoothRx) * k

        if abs(smoothX) < 0.001 { smoothX = 0 }
        if abs(smoothY) < 0.001 { smoothY = 0 }
        if abs(smoothRx) < 0.001 { smoothRx = 0 }

        imuAngle += smoothRx * rotSpeed * dt
    }
}

private final class DisplayLinkTarget {
    let onTick: () -> Void
    init(_ onTick: @escaping () -> Void) { self.onTick = onTick }
    @objc func tick() { onTick() }
}
