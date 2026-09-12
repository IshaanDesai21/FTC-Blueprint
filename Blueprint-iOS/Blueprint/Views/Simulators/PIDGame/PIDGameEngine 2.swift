import SwiftUI
import Observation
import QuartzCore

struct RobotConfig {
    let color: Color
    let border: Color
    let mass: Double
    let damping: Double
    let stiction: Double
    let hint: String
}

struct TrailDot: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var age: Double
}

/// Ports the PID Game's exact physics: drag-and-release, hidden per-round robot
/// physical properties (mass/damping/stiction), and the same P_SCALE/I_SCALE/
/// D_SCALE/F_SCALE constants used to turn slider gains into forces.
@Observable
final class PIDGameEngine {
    var kP: Double = 0.08
    var kI: Double = 0
    var kD: Double = 0.16
    var kF: Double = 0

    private(set) var robot: RobotConfig
    private(set) var rx: Double = 0
    private(set) var ry: Double = 0
    private(set) var isRunning = false
    private(set) var isDragging = false
    private(set) var trail: [TrailDot] = []
    private(set) var errHist: [Double] = []
    private(set) var releaseErr: Double = 100
    private(set) var elapsedSec: Double = 0
    private(set) var gameWidth: Double = 320

    let gameHeight: Double = 320
    private let robotSize: Double = 44
    private let trailMax = 80
    private let errMax = 200
    private let pScale = 0.08, iScale = 0.004, dScale = 0.22, fScale = 30.0
    private let maxInteg = 2000.0

    private var vx: Double = 0
    private var vy: Double = 0
    private var integX: Double = 0
    private var integY: Double = 0
    private var prevEX: Double = 0
    private var prevEY: Double = 0
    private var simTick = 0
    private var runStart: CFTimeInterval?
    private var lastTime: CFTimeInterval = 0
    private var displayLink: CADisplayLink?
    private var linkTarget: DisplayLinkTarget?

    static let colorPalette: [(Color, Color)] = [
        (Color(red: 0.455, green: 0.843, blue: 0.929), Color(red: 0.239, green: 0.722, blue: 0.835)),
        (Color(red: 0.988, green: 0.827, blue: 0.302), Color(red: 0.918, green: 0.702, blue: 0.031)),
        (Color(red: 0.204, green: 0.827, blue: 0.6), Color(red: 0.020, green: 0.588, blue: 0.412)),
        (Color(red: 0.655, green: 0.545, blue: 0.980), Color(red: 0.545, green: 0.361, blue: 0.965)),
        (Color(red: 0.984, green: 0.443, blue: 0.522), Color(red: 0.882, green: 0.110, blue: 0.278)),
        (Color(red: 0.376, green: 0.647, blue: 0.980), Color(red: 0.145, green: 0.388, blue: 0.922)),
        (Color(red: 0.976, green: 0.451, blue: 0.086), Color(red: 0.918, green: 0.345, blue: 0.047)),
        (Color(red: 0.133, green: 0.773, blue: 0.369), Color(red: 0.086, green: 0.639, blue: 0.290))
    ]

    var homeX: Double { gameWidth / 2 }
    var homeY: Double { gameHeight / 2 }

    var currentErr: Double { errHist.last ?? 0 }

    init() {
        robot = Self.randomRobot()
    }

    func setGameWidth(_ w: Double) {
        guard w > 0 else { return }
        gameWidth = w
        if !isRunning && !isDragging {
            rx = homeX; ry = homeY
        }
    }

    static func randomRobot() -> RobotConfig {
        let (fill, border) = colorPalette.randomElement()!
        let mass = Double.random(in: 0.5...3.0)
        let damping = Double.random(in: 0.78...0.93)
        let stiction = Double.random(in: 0...1) < 0.35 ? Double.random(in: 0.03...0.14) : 0

        let hints = [
            "Try increasing P until it starts to oscillate, then add D to calm it down.",
            "Small P changes can make a huge difference on this configuration.",
            "If it stops short, a touch of P may help it settle.",
            "This setup responds fast, but can get unstable if overdriven.",
            "The best tuning usually comes from balancing P and D first."
        ]

        return RobotConfig(color: fill, border: border, mass: mass, damping: damping, stiction: stiction, hint: hints.randomElement()!)
    }

    func newRobot() {
        robot = Self.randomRobot()
        resetSim()
    }

    func resetSim() {
        stopLoop()
        isRunning = false
        rx = homeX; ry = homeY
        vx = 0; vy = 0; integX = 0; integY = 0; prevEX = 0; prevEY = 0
        trail = []; errHist = []
        simTick = 0
        runStart = nil
        elapsedSec = 0
    }

    private(set) var dragAnchorX: Double = 0
    private(set) var dragAnchorY: Double = 0

    func beginDrag() {
        isDragging = true
        isRunning = false
        vx = 0; vy = 0; integX = 0; integY = 0; prevEX = 0; prevEY = 0
        trail = []; errHist = []
        simTick = 0
        runStart = nil
        elapsedSec = 0
        dragAnchorX = rx
        dragAnchorY = ry
        startLoop()
    }

    /// `translation` is the DragGesture's cumulative offset from the drag's start,
    /// so the new position is always anchor + translation, never the current
    /// position + translation, which would compound every frame and fly off-screen.
    func drag(translation: CGSize) {
        let point = CGPoint(x: dragAnchorX + translation.width, y: dragAnchorY + translation.height)
        rx = min(max(point.x, -60), gameWidth + 60)
        ry = min(max(point.y, -60), gameHeight + 60)
        appendTrail()
    }

    func endDrag() {
        isDragging = false
        let mag = hypot(homeX - rx, homeY - ry)
        if mag > 8 {
            releaseErr = mag
            isRunning = true
            runStart = CACurrentMediaTime()
            elapsedSec = 0
        } else {
            rx = homeX; ry = homeY
            stopLoop()
        }
    }

    private func startLoop() {
        stopLoop()
        let target = DisplayLinkTarget { [weak self] in self?.frame() }
        linkTarget = target
        let link = CADisplayLink(target: target, selector: #selector(DisplayLinkTarget.tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
        lastTime = 0
    }

    private func stopLoop() {
        displayLink?.invalidate(); displayLink = nil; linkTarget = nil
    }

    private func frame() {
        let now = CACurrentMediaTime()
        let dt = lastTime == 0 ? 16.67 : (now - lastTime) * 1000
        lastTime = now

        trail = trail.map { var d = $0; d.age += dt / 1000; return d }.filter { $0.age < 1.8 }

        if isRunning {
            let steps = max(1, min(3, Int((dt / 16.67).rounded())))
            for _ in 0..<steps { pidStep() }
            if let start = runStart {
                elapsedSec = now - start
            }
        }

        if !isRunning && !isDragging {
            stopLoop()
        }
    }

    private func appendTrail() {
        trail.append(TrailDot(x: rx, y: ry, age: 0))
        if trail.count > trailMax { trail.removeFirst(trail.count - trailMax) }
    }

    private func pidStep() {
        let ex = homeX - rx
        let ey = homeY - ry
        let mag = hypot(ex, ey)

        if mag < 0.8 && hypot(vx, vy) < 0.3 {
            rx = homeX; ry = homeY; vx = 0; vy = 0
            isRunning = false
            integX = 0; integY = 0
            runStart = nil
            elapsedSec = (elapsedSec * 10).rounded() / 10
            return
        }

        integX = max(-maxInteg, min(maxInteg, integX + ex))
        integY = max(-maxInteg, min(maxInteg, integY + ey))

        let dEx = ex - prevEX
        let dEy = ey - prevEY
        prevEX = ex; prevEY = ey

        let ffActive: Double = mag > 2 ? 1 : 0
        let nx = ex / max(mag, 0.01)
        let ny = ey / max(mag, 0.01)
        let ffX = ffActive * kF * fScale * nx
        let ffY = ffActive * kF * fScale * ny

        let outX = kP * ex * pScale + kI * integX * iScale + kD * dEx * dScale + ffX
        let outY = kP * ey * pScale + kI * integY * iScale + kD * dEy * dScale + ffY

        let speed = hypot(vx, vy)
        let force = hypot(outX, outY)

        if !(speed < 0.2 && robot.stiction > 0 && force < robot.stiction) {
            vx += outX / robot.mass
            vy += outY / robot.mass
            vx *= robot.damping
            vy *= robot.damping
            rx += vx
            ry += vy
            rx = max(robotSize / 2, min(gameWidth - robotSize / 2, rx))
            ry = max(robotSize / 2, min(gameHeight - robotSize / 2, ry))
        }

        appendTrail()
        simTick += 1
        if simTick % 2 == 0 {
            errHist.append(mag)
            if errHist.count > errMax { errHist.removeFirst(errHist.count - errMax) }
        }
    }
}

private final class DisplayLinkTarget {
    let onTick: () -> Void
    init(_ onTick: @escaping () -> Void) { self.onTick = onTick }
    @objc func tick() { onTick() }
}
