import SwiftUI

struct FeedforwardSimulatorView: View {
    @State private var engine = FeedforwardEngine()
    @State private var selectedMode: FeedforwardMode = .ffPlusPid

    var body: some View {
        Form {
            SwiftUI.Section {
                Text("Track a cyclic velocity profile using feedforward (kS, kV, kA), feedback (PID), or both.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                statRow
                modePicker
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal, 16)
                velocityChart
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal, 16)
                HStack(spacing: 12) {
                    labeledChart("VOLTAGE", engine.voltageHistory, -13, 13, Theme.accentYellow)
                    labeledChart("ERROR", engine.errorHistory, -engine.targetVel * 0.4, engine.targetVel * 0.4, .red)
                }
                .listRowInsets(EdgeInsets())
                .padding(.horizontal, 16)

                HStack {
                    Button(engine.isRunning ? "Pause" : "Run") {
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

            SwiftUI.Section("Feedforward Gains") {
                LabeledSlider(label: "kS", value: $engine.kS, range: 0...0.3, step: 0.005, format: "%.3f")
                LabeledSlider(label: "kV", value: $engine.kV, range: 0...0.08, step: 0.001, format: "%.3f")
                LabeledSlider(label: "kA", value: $engine.kA, range: 0...0.02, step: 0.0002, format: "%.4f")
            }

            SwiftUI.Section {
                LabeledSlider(label: "kP", value: $engine.kP, range: 0...2, step: 0.02, format: "%.2f")
                LabeledSlider(label: "kD", value: $engine.kD, range: 0...0.5, step: 0.01, format: "%.2f")
            } header: {
                Text("Feedback Gains (PID)")
            } footer: {
                if selectedMode == .ffOnly {
                    Text("Disabled in FF Only mode.")
                }
            }
            .disabled(selectedMode == .ffOnly)
            .opacity(selectedMode == .ffOnly ? 0.4 : 1)

            SwiftUI.Section("Setpoint Profile") {
                LabeledSlider(label: "Target Vel", value: $engine.targetVel, range: 10...150, step: 5, format: "%.0f")
                    .onChange(of: engine.targetVel) { engine.resetSim() }
                LabeledSlider(label: "Ramp Accel", value: $engine.targetAccel, range: 5...100, step: 5, format: "%.0f")
                    .onChange(of: engine.targetAccel) { engine.resetSim() }
            }

            SwiftUI.Section("The Equation") {
                Text("V = kS\u{00B7}sgn(v) + kV\u{00B7}v + kA\u{00B7}a")
                    .font(.callout.monospaced().weight(.semibold))
                Text("kS overcomes static friction, kV counteracts back-EMF proportional to velocity, kA compensates for the force needed to accelerate. Feedback (PID) cleans up whatever feedforward can't predict.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Feedforward")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { selectedMode = engine.mode }
        .onChange(of: selectedMode) { _, newValue in engine.setMode(newValue) }
        .onDisappear { engine.stop() }
    }

    private var statRow: some View {
        HStack(spacing: 20) {
            stat("Vel Error", String(format: "%.1f", engine.currentError), errorColor(engine.currentError))
            stat("RMS Error", String(format: "%.1f", engine.rmsError()), errorColor(engine.rmsError()))
            stat("Voltage", String(format: "%.1fV", engine.currentVoltage), .primary)
        }
    }

    private func stat(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased()).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            Text(value).font(.subheadline.monospacedDigit().weight(.bold)).foregroundStyle(color)
        }
    }

    private func errorColor(_ v: Double) -> Color {
        let a = abs(v)
        if a < 3 { return Theme.accentGreen }
        if a < 10 { return Theme.accentYellow }
        return .red
    }

    private var modePicker: some View {
        Picker("Mode", selection: $selectedMode) {
            ForEach(FeedforwardMode.allCases, id: \.self) { mode in
                Text(mode.label).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    private var velocityChart: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("VELOCITY TRACKING").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            TimeSeriesChart(
                series: engine.velHistory,
                yMin: 0, yMax: engine.targetVel * 1.3,
                color: Theme.accentCyan, filled: true,
                secondSeries: engine.targetHistory, secondColor: Theme.accentGreen
            )
            .frame(height: 180)
        }
    }

    private func labeledChart(_ label: String, _ series: [Sample], _ yMin: Double, _ yMax: Double, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            TimeSeriesChart(series: series, yMin: yMin, yMax: yMax, color: color, filled: false)
                .frame(height: 110)
        }
    }
}
