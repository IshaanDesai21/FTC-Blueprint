import SwiftUI

struct MotionProfileSimulatorView: View {
    @State private var engine = MotionProfileEngine()

    var body: some View {
        Form {
            SwiftUI.Section {
                Text("Shape acceleration and deceleration so your drivetrain moves smoothly instead of slamming full power.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                statRow
                track
                velocityChart
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal, 16)
                HStack(spacing: 12) {
                    labeledChart("POSITION", engine.curve { $0.pos }, 0, engine.distance, Theme.accentGreen, true)
                    labeledChart("ACCELERATION", engine.curve { $0.acc }, -engine.maxAccel, engine.maxAccel, Theme.accentYellow, false)
                }
                .listRowInsets(EdgeInsets())
                .padding(.horizontal, 16)

                HStack {
                    Button(engine.isRunning ? "Pause" : (engine.simTime > 0 ? "Run Again" : "Run Profile")) {
                        engine.isRunning ? engine.stop() : engine.start()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accentCyan)

                    Button("Reset", role: .destructive) { engine.resetSim() }
                        .buttonStyle(.bordered)
                }
                .listRowInsets(EdgeInsets())
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }

            SwiftUI.Section("Parameters") {
                LabeledSlider(label: "Distance", value: $engine.distance, range: 20...500, step: 5, format: "%.0f")
                    .onChange(of: engine.distance) { engine.resetSim() }
                LabeledSlider(label: "Max Velocity", value: $engine.maxVel, range: 5...200, step: 5, format: "%.0f")
                    .onChange(of: engine.maxVel) { engine.resetSim() }
                LabeledSlider(label: "Max Accel", value: $engine.maxAccel, range: 5...150, step: 5, format: "%.0f")
                    .onChange(of: engine.maxAccel) { engine.resetSim() }
            }

            SwiftUI.Section("How It Works") {
                bullet("Acceleration Phase", "Velocity ramps up from 0 to the max (or peak) velocity at a constant rate.", Theme.accentCyan)
                bullet("Cruise Phase", "Only present if the distance is large enough \u{2014} short moves skip straight to deceleration.", Theme.accentGreen)
                bullet("Deceleration Phase", "Mirrors acceleration: the motor decelerates at the same rate to arrive exactly at the target.", Theme.accentYellow)
                bullet("Triangular Profile", "If the distance is too short to reach max velocity, the profile becomes a triangle instead of a trapezoid.", .red)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Motion Profiling")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { engine.stop() }
    }

    private var statRow: some View {
        let p = engine.profile
        return HStack(spacing: 20) {
            stat("Total Time", String(format: "%.2fs", p.totalTime))
            stat("Peak Vel", String(format: "%.1f u/s", p.peakVel))
            stat("Type", p.isTriangular ? "Triangle" : "Trapezoid")
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased()).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            Text(value).font(.subheadline.monospacedDigit().weight(.bold))
        }
    }

    private var track: some View {
        GeometryReader { geo in
            let pct = min(engine.position / max(engine.distance, 1), 1)
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.backgroundSecondary)
                Capsule().fill(Theme.accentCyan.opacity(0.3)).frame(width: geo.size.width * pct)
                Circle().fill(Theme.accentCyan).frame(width: 14, height: 14)
                    .shadow(color: Theme.accentCyan.opacity(0.6), radius: 6)
                    .offset(x: geo.size.width * pct - 7)
            }
        }
        .frame(height: 14)
        .padding(.vertical, 8)
    }

    private var velocityChart: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("VELOCITY PROFILE").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            TimeSeriesChart(series: engine.curve { $0.vel }, yMin: 0, yMax: engine.maxVel, color: Theme.accentCyan, filled: true)
                .frame(height: 180)
        }
    }

    private func labeledChart(_ label: String, _ series: [Sample], _ yMin: Double, _ yMax: Double, _ color: Color, _ filled: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            TimeSeriesChart(series: series, yMin: yMin, yMax: yMax, color: color, filled: filled)
                .frame(height: 130)
        }
    }

    private func bullet(_ title: String, _ text: String, _ color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(color).frame(width: 8, height: 8).padding(.top, 5)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(text).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
