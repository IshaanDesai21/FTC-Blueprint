import SwiftUI

struct PIDSimulatorView: View {
    @State private var engine = PIDEngine()

    var body: some View {
        Form {
            SwiftUI.Section {
                Text("Drag the sliders and watch how the robot responds to a fixed target of 100 units.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                graph
                    .listRowInsets(EdgeInsets())
                    .padding(.top, 6)
                hintView
                Button("Reset Simulation", role: .destructive) { engine.resetSim() }
            }

            SwiftUI.Section("Gains") {
                LabeledSlider(label: "P", value: $engine.kp, range: 0...1, step: 0.01, format: "%.2f")
                LabeledSlider(label: "I", value: $engine.ki, range: 0...0.1, step: 0.001, format: "%.3f")
                LabeledSlider(label: "D", value: $engine.kd, range: 0...2, step: 0.05, format: "%.2f")
            }

            SwiftUI.Section("Auto-Reset") {
                Stepper(value: $engine.autoResetSeconds, in: 0.5...20, step: 0.5) {
                    HStack {
                        Text(String(format: "Every %@s".localizedUI, engine.autoResetSeconds.formatted(.number.precision(.fractionLength(1)))))
                        Spacer()
                        Text(String(format: "%@s left".localizedUI, (engine.countdownMs / 1000).formatted(.number.precision(.fractionLength(1)))))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .onChange(of: engine.autoResetSeconds) { engine.armAutoReset() }
            }

            SwiftUI.Section("How It Works") {
                Text("P pushes toward the target proportional to error. I accumulates error over time to fix steady-state offset. D dampens motion to prevent overshoot. Tune P first, then D, then I only if needed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("PID Tuner")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { engine.start() }
        .onDisappear { engine.stop() }
    }

    private var graph: some View {
        Canvas { context, size in
            let pad: CGFloat = 20
            let w = size.width
            let h = size.height

            func yFor(_ value: Double) -> CGFloat {
                h - ((value / 150) * (h - 2 * pad) + pad)
            }

            var border = Path()
            border.move(to: CGPoint(x: pad, y: pad))
            border.addLine(to: CGPoint(x: pad, y: h - pad))
            border.addLine(to: CGPoint(x: w - pad, y: h - pad))
            context.stroke(border, with: .color(Theme.border.opacity(0.6)), lineWidth: 1)

            var targetLine = Path()
            targetLine.move(to: CGPoint(x: pad, y: yFor(engine.target)))
            targetLine.addLine(to: CGPoint(x: w - pad, y: yFor(engine.target)))
            context.stroke(targetLine, with: .color(Theme.accentGreen.opacity(0.5)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))

            guard !engine.history.isEmpty else { return }
            let maxHistory = 100
            var response = Path()
            for (i, value) in engine.history.enumerated() {
                let x = (CGFloat(i) / CGFloat(maxHistory - 1)) * (w - 2 * pad) + pad
                let y = yFor(value)
                if i == 0 { response.move(to: CGPoint(x: x, y: y)) } else { response.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(response, with: .color(Theme.accentCyan), style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))

            let lastX = (CGFloat(engine.history.count - 1) / CGFloat(maxHistory - 1)) * (w - 2 * pad) + pad
            let lastY = yFor(engine.history.last ?? 0)
            let dotRect = CGRect(x: lastX - 5, y: lastY - 5, width: 10, height: 10)
            context.fill(Path(ellipseIn: dotRect), with: .color(Theme.accentCyan))
        }
        .frame(height: 200)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
    }

    private var hintView: some View {
        Label(engine.hint?.text ?? " ", systemImage: engine.hint.map { iconFor($0.kind) } ?? "circle")
            .font(.footnote.weight(.medium))
            .foregroundStyle(engine.hint.map { colorFor($0.kind) } ?? .clear)
            .opacity(engine.hint == nil ? 0 : 1)
            .lineLimit(1)
    }

    private func iconFor(_ kind: PIDEngine.HintKind) -> String {
        switch kind {
        case .warning: return "exclamationmark.triangle.fill"
        case .tip: return "lightbulb.fill"
        case .success: return "checkmark.circle.fill"
        }
    }

    private func colorFor(_ kind: PIDEngine.HintKind) -> Color {
        switch kind {
        case .warning: return Theme.accentYellow
        case .tip: return .secondary
        case .success: return Theme.accentGreen
        }
    }
}

struct LabeledSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(String(format: format, value))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.accentCyan)
            }
            Slider(value: $value, in: range, step: step)
                .tint(Theme.accentCyan)
        }
        .padding(.vertical, 2)
    }
}
