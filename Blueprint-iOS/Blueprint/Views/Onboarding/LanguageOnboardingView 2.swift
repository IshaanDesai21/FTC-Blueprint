import SwiftUI

struct LanguageOnboardingView: View {
    @Environment(LanguageSettings.self) private var languageSettings
    @State private var selection: AppLanguage

    init() {
        _selection = State(initialValue: LanguageSettings.shared.language)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            HexagonMark()
                .stroke(HexagonMark.brandGradient, lineWidth: 3)
                .frame(width: 56, height: 56)
                .padding(.bottom, 20)

            Text("Choose Your Language")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            Text("You can change this anytime in Settings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 6)

            Spacer()

            VStack(spacing: 10) {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        selection = language
                    } label: {
                        HStack {
                            Text(language.nativeName)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            if selection == language {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.accentCyan)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(selection == language ? Theme.accentCyan : Theme.border, lineWidth: selection == language ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Button {
                languageSettings.choose(selection)
            } label: {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.textPrimary)
                    .foregroundStyle(Theme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
        .background(Theme.background)
    }
}
