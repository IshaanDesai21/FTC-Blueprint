import SwiftUI

struct MoreView: View {
    var body: some View {
        List {
            SwiftUI.Section("Guides") {
                NavigationLink(value: SiteSection.hardware) {
                    Label("Hardware", systemImage: SiteSection.hardware.systemImage)
                }
                .accessibilityLabel("Hardware guides")
                .accessibilityHint("Browse CAD, drivetrain, and mechanism guides")

                NavigationLink(value: SiteSection.outreach) {
                    Label("Outreach", systemImage: SiteSection.outreach.systemImage)
                }
                .accessibilityLabel("Outreach guides")
                .accessibilityHint("Browse community, STEM, and judging guides")
            }

            SwiftUI.Section {
                NavigationLink {
                    SearchView()
                } label: {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .accessibilityLabel("Search")
                .accessibilityHint("Search all guides across software, hardware, and outreach")
            }

            SwiftUI.Section {
                NavigationLink {
                    AccessibilitySettingsView()
                } label: {
                    Label("Accessibility", systemImage: "accessibility")
                }
                .accessibilityLabel("Accessibility settings")
                .accessibilityHint("Adjust text size, contrast, and motion")

                NavigationLink {
                    LanguageSettingsView()
                } label: {
                    Label("Language", systemImage: "globe")
                }
                .accessibilityLabel("Language settings")
                .accessibilityHint("Change the app's display language")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("More")
        .navigationDestination(for: SiteSection.self) { SectionListView(section: $0) }
    }
}
