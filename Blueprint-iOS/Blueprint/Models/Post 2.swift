import Foundation

enum SiteSection: String, CaseIterable, Identifiable {
    case software
    case hardware
    case outreach

    var id: String { rawValue }

    var title: String {
        switch self {
        case .software: return "Software".localizedUI
        case .hardware: return "Hardware".localizedUI
        case .outreach: return "Outreach".localizedUI
        }
    }

    var systemImage: String {
        switch self {
        case .software: return "chevron.left.forwardslash.chevron.right"
        case .hardware: return "wrench.and.screwdriver"
        case .outreach: return "person.3"
        }
    }
}

struct Post: Identifiable, Hashable {
    var id: String { slug }
    let slug: String
    let title: String
    let description: String
    let panelCategory: String
    let date: String
    let author: String?
    let tags: [String]
    let published: Bool
    let section: SiteSection?
    let body: String

    var isCompleted: Bool {
        tags.contains { $0.lowercased() == "completed" }
    }

    var isComingSoon: Bool {
        tags.contains { $0.lowercased() == "coming soon" }
    }

    var visibleTags: [String] {
        tags.filter { $0.lowercased() != "completed" }
    }
}
