import SwiftUI

struct AccessibilitySettingsView: View {
    @Environment(AccessibilitySettings.self) private var a11y

    var body: some View {
        @Bindable var a11y = a11y

        Form {
            SwiftUI.Section {
                Text("These settings apply throughout Blueprint, including guides and simulators.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }

            SwiftUI.Section("Text Size") {
                Picker("Text Size", selection: $a11y.textSize) {
                    ForEach(TextSizeOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            SwiftUI.Section {
                Toggle("High Contrast Text", isOn: $a11y.highContrast)
                    .accessibilityHint("Increases the contrast of secondary and muted text")
                Toggle("Reduce Motion", isOn: $a11y.reduceMotion)
                    .accessibilityHint("Turns off non-essential animations in simulators")
            } footer: {
                Text("Blueprint also respects your device's system Dynamic Type, Bold Text, and Reduce Motion settings in Settings > Accessibility.")
            }

            SwiftUI.Section("Background") {
                Picker("Background", selection: $a11y.backgroundStyle) {
                    ForEach(AppBackgroundStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }
}
