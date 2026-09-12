import SwiftUI

struct LanguageSettingsView: View {
    @Environment(LanguageSettings.self) private var languageSettings

    var body: some View {
        @Bindable var languageSettings = languageSettings

        Form {
            SwiftUI.Section {
                Picker("Language", selection: $languageSettings.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.nativeName).tag(language)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
                // The Picker's own checkmark doesn't reliably re-sync when
                // `language` changes from somewhere other than this exact
                // Picker (e.g. another instance, or a fresh app launch that
                // restores a persisted value), forcing its identity to key
                // off the current value guarantees the visible selection
                // always matches the real one.
                .id(languageSettings.language)
            } footer: {
                Text("Guide articles stay in English. The rest of the app follows your chosen language.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }
}
