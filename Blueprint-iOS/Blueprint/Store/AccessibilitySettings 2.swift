import SwiftUI

enum TextSizeOption: String, CaseIterable, Identifiable {
    case standard, large, extraLarge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: return "Default".localizedUI
        case .large: return "Large".localizedUI
        case .extraLarge: return "Extra Large".localizedUI
        }
    }

    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .standard: return .large
        case .large: return .xLarge
        case .extraLarge: return .xxxLarge
        }
    }
}

enum AppBackgroundStyle: String, CaseIterable, Identifiable {
    case system, gray

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Default".localizedUI
        case .gray: return "Gray".localizedUI
        }
    }
}

@Observable
final class AccessibilitySettings {
    static let shared = AccessibilitySettings()

    var textSize: TextSizeOption {
        didSet { UserDefaults.standard.set(textSize.rawValue, forKey: Keys.textSize) }
    }

    var highContrast: Bool {
        didSet { UserDefaults.standard.set(highContrast, forKey: Keys.highContrast) }
    }

    var reduceMotion: Bool {
        didSet { UserDefaults.standard.set(reduceMotion, forKey: Keys.reduceMotion) }
    }

    var backgroundStyle: AppBackgroundStyle {
        didSet { UserDefaults.standard.set(backgroundStyle.rawValue, forKey: Keys.backgroundStyle) }
    }

    private enum Keys {
        static let textSize = "a11y.textSize"
        static let highContrast = "a11y.highContrast"
        static let reduceMotion = "a11y.reduceMotion"
        static let backgroundStyle = "a11y.backgroundStyle"
    }

    private init() {
        let defaults = UserDefaults.standard
        textSize = TextSizeOption(rawValue: defaults.string(forKey: Keys.textSize) ?? "") ?? .standard
        highContrast = defaults.bool(forKey: Keys.highContrast)
        reduceMotion = defaults.bool(forKey: Keys.reduceMotion)
        backgroundStyle = AppBackgroundStyle(rawValue: defaults.string(forKey: Keys.backgroundStyle) ?? "") ?? .system
    }
}
