import CoreSpotlight
import SwiftUI

@main
struct BlueprintApp: App {
    @State private var store = PostStore()
    @State private var a11y = AccessibilitySettings.shared
    @State private var languageSettings = LanguageSettings.shared
    @State private var nav = AppNavigation()

    var body: some Scene {
        WindowGroup {
            Group {
                if languageSettings.hasChosenLanguage {
                    RootTabView()
                } else {
                    LanguageOnboardingView()
                }
            }
            .environment(store)
            .environment(a11y)
            .environment(languageSettings)
            .environment(nav)
            .environment(\.locale, languageSettings.language.locale)
            .dynamicTypeSize(a11y.textSize.dynamicTypeSize)
            .task {
                SpotlightIndexer.indexAll(store.posts)
            }
            .onContinueUserActivity(CSSearchableItemActionType) { activity in
                guard let slug = SpotlightIndexer.slug(from: activity),
                      let post = store.post(slug: slug) else { return }
                nav.open(post)
            }
        }
    }
}
