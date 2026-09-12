import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"
    case portuguese = "pt"
    case romanian = "ro"
    case hindi = "hi"

    var id: String { rawValue }

    /// Shown in its own language, so a user can find their language even if
    /// the picker is currently displaying in a language they don't read.
    var nativeName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .portuguese: return "Português"
        case .romanian: return "Română"
        case .hindi: return "हिन्दी"
        }
    }

    var locale: Locale { Locale(identifier: rawValue) }
}

@Observable
final class LanguageSettings {
    static let shared = LanguageSettings()

    var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Keys.language) }
    }

    var hasChosenLanguage: Bool {
        didSet { UserDefaults.standard.set(hasChosenLanguage, forKey: Keys.hasChosen) }
    }

    private enum Keys {
        static let language = "language.selected"
        static let hasChosen = "language.hasChosen"
    }

    private init() {
        let defaults = UserDefaults.standard
        hasChosenLanguage = defaults.bool(forKey: Keys.hasChosen)
        if let saved = defaults.string(forKey: Keys.language), let match = AppLanguage(rawValue: saved) {
            language = match
        } else {
            // First launch, before a choice is made: guess from the device's
            // preferred language if it's one we support, otherwise English.
            let preferred = Locale.preferredLanguages.first.flatMap { Locale(identifier: $0).language.languageCode?.identifier }
            language = AppLanguage(rawValue: preferred ?? "en") ?? .english
        }
    }

    func choose(_ language: AppLanguage) {
        self.language = language
        hasChosenLanguage = true
    }
}
