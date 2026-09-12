import Foundation

extension String {
    /// Looks up `self` as a key in Localizable.xcstrings using the app's
    /// chosen language (not the system locale). `Text("literal")` in SwiftUI
    /// already does this automatically via `.environment(\.locale, ...)`, but
    /// plain `String`-returning computed properties (enum `.title` etc.) need
    /// an explicit, locale-aware lookup.
    ///
    /// Uses a directly-loaded `.lproj` bundle rather than
    /// `String(localized:locale:)`, since the latter appears to cache lookups
    /// per-key across locale changes rather than per-(key, locale), calling
    /// it again with a different `locale:` for the same key can silently
    /// return the first-ever result instead of a fresh one.
    var localizedUI: String {
        guard let path = Bundle.main.path(forResource: LanguageSettings.shared.language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return self
        }
        return bundle.localizedString(forKey: self, value: self, table: "Localizable")
    }
}
