import SwiftUI

struct PIDGameView: View {
    @State private var engine = PIDGameEngine()
    @State private var hintVisible = false

    private var errorSeries: [Sample] {
        var samples: [Sample] = []
        for (index, value) in engine.errHist.enumerated() {
            let clamped = min(value, engine.releaseErr)
            samples.append(Sample(t: Double(index), v: clamped))
        }
        return samples
    }

    var body: some View {
        Form {
            SwiftUI.Section {
                Text("Drag the robot away from the target, then let go. Tune the gains so it comes back quickly without overshooting.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                gameArea
                    .listRowInsets(EdgeInsets())
                if engine.isRunning {
                    HStack {
                        Label(String(format: "Error: %@px".localizedUI, engine.currentErr.formatted(.number.precision(.fractionLength(1)))), systemImage: "scope")
                        Spacer()
                        Label("\(engine.elapsedSec, format: .number.precision(.fractionLength(1)))s", systemImage: "timer")
                    }
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
                }

                HStack {
                    Button("Reset", role: .destructive) { engine.resetSim() }
                        .buttonStyle(.bordered)
                    Button(hintVisible ? "Hide Hint" : "Show Hint") { hintVisible.toggle() }
                        .buttonStyle(.bordered)
                }
                .listRowInsets(EdgeInsets())
                .padding(.horizontal, 16)
                .padding(.top, 4)

                if hintVisible {
                    Text(engine.robot.hint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            SwiftUI.Section("Configuration") {
                Button {
                    engine.newRobot()
                } label: {
                    HStack {
                        Circle().fill(engine.robot.color).frame(width: 14, height: 14)
                            .overlay(Circle().stroke(engine.robot.border, lineWidth: 1.5))
                        Text("Tune a New Robot")
                    }
                }
            }

            SwiftUI.Section("PIDF Constants") {
                LabeledSlider(label: "P", value: $engine.kP, range: 0...0.30, step: 0.001, format: "%.3f")
                VStack(alignment: .leading, spacing: 2) {
                    LabeledSlider(label: "I", value: .constant(0), range: 0...0.02, step: 0.0001, format: "%.2f")
                        .disabled(true)
                        .opacity(0.4)
                    Text("Locked. Integral windup makes this game unstable. Learn why in Common Practices.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                LabeledSlider(label: "D", value: $engine.kD, range: 0...0.80, step: 0.005, format: "%.3f")
                LabeledSlider(label: "F", value: $engine.kF, range: 0...0.10, step: 0.001, format: "%.3f")
            }

            if !engine.errHist.isEmpty {
                SwiftUI.Section("Error Over Time") {
                    TimeSeriesChart(
                        series: errorSeries,
                        yMin: 0, yMax: engine.releaseErr,
                        color: engine.robot.color, filled: false
                    )
                    .frame(height: 130)
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal, 16)
                }
            }

            SwiftUI.Section("How It Works") {
                bullet("Hidden Physics", "Each robot has a random mass, damping, and sometimes static friction \u{2014} you can't see these, only feel them through how it moves.")
                bullet("Proportional", "Pushes toward home proportional to distance. Too high and it overshoots and oscillates.")
                bullet("Derivative", "Dampens the approach to prevent overshoot. Too little and it bounces past the target.")
                bullet("Feedforward", "A constant push toward home once you're clearly off-target, helping overcome friction.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("PID Game")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { engine.resetSim() }
    }

    private var gameArea: some View {
        GeometryReader { geo in
            ZStack {
                Rectangle().fill(Theme.backgroundSecondary)

                dotGrid(size: geo.size)

                Circle()
                    .stroke(Theme.accentGreen.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    .frame(width: 56, height: 56)
                    .position(x: engine.homeX, y: engine.homeY)
                Circle()
                    .fill(Theme.accentGreen.opacity(0.7))
                    .frame(width: 10, height: 10)
                    .position(x: engine.homeX, y: engine.homeY)

                ForEach(engine.trail) { dot in
                    let fade: Double = max(0, 1 - dot.age / 1.8)
                    let dotSize: CGFloat = 7 * fade
                    Circle()
                        .fill(engine.robot.color.opacity(0.65 * fade))
                        .frame(width: dotSize, height: dotSize)
                        .position(x: dot.x, y: dot.y)
                }

                RoundedRectangle(cornerRadius: 10)
                    .fill(engine.robot.color.opacity(0.15))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(engine.robot.border, lineWidth: 2))
                    .frame(width: 44, height: 44)
                    .position(x: engine.rx, y: engine.ry)
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { value in
                                if !engine.isDragging { engine.beginDrag() }
                                engine.drag(translation: value.translation)
                            }
                            .onEnded { _ in engine.endDrag() }
                    )

                if engine.trail.isEmpty && !engine.isRunning && !engine.isDragging {
                    Text("Drag the robot, then let go")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .position(x: geo.size.width / 2, y: geo.size.height - 20)
                }
            }
            .onAppear { engine.setGameWidth(geo.size.width) }
            .onChange(of: geo.size.width) { _, newValue in engine.setGameWidth(newValue) }
            .clipped()
        }
        .frame(height: 320)
    }

    private func dotGrid(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let cols = 8, rows = 5
            for r in 0..<rows {
                for c in 0..<cols {
                    let x = canvasSize.width * (Double(c) + 0.5) / Double(cols)
                    let y = canvasSize.height * (Double(r) + 0.5) / Double(rows)
                    let rect = CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3)
                    context.fill(Path(ellipseIn: rect), with: .color(Theme.border.opacity(0.4)))
                }
            }
        }
    }

    private func bullet(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline.weight(.semibold))
            Text(text).font(.footnote).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
