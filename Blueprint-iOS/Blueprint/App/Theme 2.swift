import SwiftUI

/// Native, system-driven palette. Structural colors map to UIKit's semantic
/// system colors so the app automatically matches platform conventions, contrast,
/// and light/dark appearance. The three brand accents are reserved for data
/// visualization (charts, tags), not general chrome/buttons, which use `.tint()`.
enum Theme {
    /// A neutral gray distinct from `systemGroupedBackground`, which is itself
    /// a very light, slightly blue-tinted gray already, too close to the
    /// default to read as a real alternative. These are flat, true grays.
    private static func flatGray(light: Double, dark: Double) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: dark, alpha: 1)
                : UIColor(white: light, alpha: 1)
        })
    }

    static var background: Color {
        switch AccessibilitySettings.shared.backgroundStyle {
        case .system: return Color(.systemGroupedBackground)
        case .gray: return flatGray(light: 0.88, dark: 0.11)
        }
    }
    static var backgroundSecondary: Color {
        switch AccessibilitySettings.shared.backgroundStyle {
        case .system: return Color(.secondarySystemGroupedBackground)
        case .gray: return flatGray(light: 0.94, dark: 0.16)
        }
    }
    static var card: Color {
        switch AccessibilitySettings.shared.backgroundStyle {
        case .system: return Color(.secondarySystemGroupedBackground)
        case .gray: return flatGray(light: 0.96, dark: 0.18)
        }
    }
    static var cardHover: Color {
        switch AccessibilitySettings.shared.backgroundStyle {
        case .system: return Color(.tertiarySystemGroupedBackground)
        case .gray: return flatGray(light: 0.91, dark: 0.23)
        }
    }
    static let border = Color(.separator)
    static let borderSubtle = Color(.separator).opacity(0.5)

    static let textPrimary = Color.primary
    static var textSecondary: Color {
        AccessibilitySettings.shared.highContrast ? Color.primary.opacity(0.85) : Color.secondary
    }
    static var textMuted: Color {
        AccessibilitySettings.shared.highContrast ? Color.primary.opacity(0.7) : Color(.tertiaryLabel)
    }
    static let textBody = Color.primary

    // Brand accents, used for charts, tags, and the app tint. Kept close to the
    // web palette but tuned so they read correctly against system backgrounds.
    static let accentCyan = Color(hue: 0.53, saturation: 0.55, brightness: 0.78)
    static let accentGreen = Color(hue: 0.39, saturation: 0.5, brightness: 0.65)
    static let accentYellow = Color(hue: 0.11, saturation: 0.55, brightness: 0.75)
}

extension Font {
    static func heading(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func mono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }

    static var caption2Mono: Font {
        .system(size: 10, weight: .semibold, design: .monospaced)
    }
}
