import SwiftUI

struct RootTabView: View {
    @Environment(AppNavigation.self) private var navEnvironment

    var body: some View {
        @Bindable var nav = navEnvironment

        TabView(selection: $nav.selectedTab) {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)

            NavigationStack(path: $nav.softwarePath) {
                SectionListView(section: .software)
            }
            .tabItem { Label("Software", systemImage: SiteSection.software.systemImage) }
            .tag(AppTab.software)

            NavigationStack { SimulatorsHomeView() }
                .tabItem { Label("Simulators", systemImage: "waveform.path.ecg") }
                .tag(AppTab.simulators)

            NavigationStack { ReviewView() }
                .tabItem { Label("Get a Review", systemImage: "checkmark.seal") }
                .tag(AppTab.review)

            NavigationStack(path: $nav.morePath) {
                MoreView()
            }
            .tabItem { Label("More", systemImage: "square.grid.2x2.fill") }
            .tag(AppTab.more)
        }
        .tint(Theme.accentCyan)
    }
}
