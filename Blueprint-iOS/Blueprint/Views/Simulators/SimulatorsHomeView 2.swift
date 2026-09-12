import SwiftUI

struct SimulatorsHomeView: View {
    var body: some View {
        List {
            NavigationLink("PID Tuner") { PIDSimulatorView() }
            NavigationLink("Feedforward") { FeedforwardSimulatorView() }
            NavigationLink("Motion Profiling") { MotionProfileSimulatorView() }
            NavigationLink("Mecanum Drive") { MecanumSimulatorView() }
            NavigationLink("PID Game") { PIDGameView() }
            NavigationLink("Model Converter") { ModelConverterView() }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Simulators")
    }
}
