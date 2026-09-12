import SwiftUI

struct MecanumSimulatorView: View {
    @State private var engine = MecanumEngine()
    @Environment(AccessibilitySettings.self) private var a11y

    var body: some View {
        Form {
            SwiftUI.Section {
                Text("Use the pad to strafe and translate, and the rotate buttons to spin. Watch the wheel powers update live.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                chassis
                    .listRowInsets(EdgeInsets())
            }

            SwiftUI.Section("Controls") {
                HStack {
                    Spacer()
                    dpad
                    Spacer()
                    rotateButtons
                    Spacer()
                }
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets())

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Acceleration Smoothing")
                        Spacer()
                        Text("\(Int(engine.accel * 100))%").foregroundStyle(Theme.accentCyan).monospacedDigit()
                    }
                    Slider(value: $engine.accel, in: 0.05...1, step: 0.01).tint(Theme.accentCyan)
                    HStack {
                        Text("Smooth").font(.caption2).foregroundStyle(.secondary)
                        Spacer()
                        Text("Instant").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }

            SwiftUI.Section("Live Kinematics") {
                equationRow("fl", "y + x + rx", engine.wheels.fl)
                equationRow("fr", "y \u{2212} x \u{2212} rx", engine.wheels.fr)
                equationRow("bl", "y \u{2212} x + rx", engine.wheels.bl)
                equationRow("br", "y + x \u{2212} rx", engine.wheels.br)
            }

            SwiftUI.Section {
                Toggle("Field-Centric Mode", isOn: $engine.isFieldCentric)
                    .tint(Theme.accentCyan)

                if engine.isFieldCentric {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("IMU Heading")
                            Spacer()
                            Text("\(Int(engine.imuNormalized))\u{00B0}").foregroundStyle(Theme.accentCyan).monospacedDigit()
                        }
                        Slider(
                            value: Binding(get: { engine.imuNormalized }, set: { engine.setHeading($0) }),
                            in: -180...180
                        )
                        .tint(Theme.accentCyan)
                    }
                }
            }

            SwiftUI.Section("How It Works") {
                bullet("The Kinematics", "Each mecanum wheel has rollers at 45\u{00B0}, so forces decompose into X and Y components. The equations combine your translational inputs (x, y) and rotation (rx) into per-wheel powers.")
                bullet("Field-Centric Mode", "In robot-centric mode, up always drives the robot forward. In field-centric, the IMU heading rotates the input vector so up always drives away from the driver.")
                bullet("Power Normalization", "When the raw sum exceeds 1, all four wheels are scaled down proportionally so the fastest wheel always runs at full power, never clipped.")
                bullet("Diagonal Strafing", "Press up + right together: two wheels drive forward, two receive zero power, and the robot slides diagonally \u{2014} impossible with standard tank drive.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Mecanum Drive")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { engine.start() }
        .onDisappear { engine.stop() }
    }

    private var chassis: some View {
        ZStack {
            if engine.isFieldCentric {
                VStack(spacing: 2) {
                    Image(systemName: "arrowtriangle.up.fill").font(.system(size: 10))
                    Text("N").font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(.secondary)
                .offset(y: -110)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.card)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 1.5))
                    .frame(width: 110, height: 150)

                if engine.moveVectorMagnitude > 0.01 {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.accentCyan)
                        .rotationEffect(.degrees(engine.moveVectorAngleDeg))
                }

                if abs(engine.smoothRx) > 0.01 {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.accentGreen)
                        .scaleEffect(x: engine.smoothRx < 0 ? 1 : -1)
                }

                wheelBar(engine.wheels.fl, "FL").offset(x: -70, y: -60)
                wheelBar(engine.wheels.fr, "FR").offset(x: 70, y: -60)
                wheelBar(engine.wheels.bl, "BL").offset(x: -70, y: 60)
                wheelBar(engine.wheels.br, "BR").offset(x: 70, y: 60)
            }
            .rotationEffect(.degrees(engine.isFieldCentric ? engine.imuAngle : 0))
            .animation(a11y.reduceMotion ? nil : .linear(duration: 0.08), value: engine.imuAngle)
        }
        .frame(height: 260)
        .frame(maxWidth: .infinity)
    }

    private func wheelBar(_ value: Double, _ label: String) -> some View {
        VStack(spacing: 3) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3).fill(Theme.backgroundSecondary).frame(width: 10, height: 40)
                RoundedRectangle(cornerRadius: 3)
                    .fill(value > 0.05 ? Theme.accentGreen : (value < -0.05 ? .red : Color.secondary))
                    .frame(width: 10, height: max(2, abs(value) * 40))
            }
            Text(label).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.secondary)
            Text(String(format: "%.2f", value)).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
        }
    }

    private func equationRow(_ name: String, _ eq: String, _ value: Double) -> some View {
        HStack {
            Text(name).font(.system(size: 13, weight: .bold, design: .monospaced)).frame(width: 24, alignment: .leading)
            Text(eq).font(.system(size: 12, design: .monospaced)).foregroundStyle(.secondary)
            Spacer()
            Text(String(format: "%.2f", value)).font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundStyle(Theme.accentCyan)
        }
    }

    private var dpad: some View {
        VStack(spacing: 6) {
            padButton("chevron.up", $engine.pressW)
            HStack(spacing: 6) {
                padButton("chevron.left", $engine.pressA)
                padButton("chevron.down", $engine.pressS)
                padButton("chevron.right", $engine.pressD)
            }
        }
    }

    private var rotateButtons: some View {
        VStack(spacing: 10) {
            padButton("arrow.counterclockwise", $engine.pressQ, wide: true)
            padButton("arrow.clockwise", $engine.pressE, wide: true)
        }
    }

    private func padButton(_ icon: String, _ binding: Binding<Bool>, wide: Bool = false) -> some View {
        Image(systemName: icon)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(binding.wrappedValue ? Color.white : Color.primary)
            .frame(width: wide ? 70 : 52, height: 52)
            .background(binding.wrappedValue ? Theme.accentCyan : Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in binding.wrappedValue = true }
                    .onEnded { _ in binding.wrappedValue = false }
            )
    }

    private func bullet(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline.weight(.semibold))
            Text(text).font(.footnote).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
