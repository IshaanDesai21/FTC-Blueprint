import SwiftUI

enum AppTab: Hashable {
    case home, software, simulators, review, more
}

/// Coordinates cross-tab navigation. Software has its own tab, so a software
/// guide switches to that tab; Hardware and Outreach live inside "More", so
/// those guides switch to More and push the section + post onto its path.
@Observable
final class AppNavigation {
    var selectedTab: AppTab = .home
    var softwarePath = NavigationPath()
    var morePath = NavigationPath()

    func openSection(_ section: SiteSection) {
        switch section {
        case .software:
            selectedTab = .software
            softwarePath = NavigationPath()
        case .hardware, .outreach:
            selectedTab = .more
            morePath = NavigationPath()
            morePath.append(section)
        }
    }

    func open(_ post: Post) {
        guard let section = post.section else { return }
        switch section {
        case .software:
            selectedTab = .software
            softwarePath = NavigationPath()
            softwarePath.append(post)
        case .hardware, .outreach:
            selectedTab = .more
            morePath = NavigationPath()
            morePath.append(section)
            morePath.append(post)
        }
    }
}
