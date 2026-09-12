import Foundation
import Observation

@Observable
final class PostStore {
    private(set) var posts: [Post] = []
    private(set) var recentlyViewedSlugs: [String] = []

    private let recentKey = "recentlyViewedSlugs"
    private let recentLimit = 8

    init() {
        load()
        recentlyViewedSlugs = UserDefaults.standard.stringArray(forKey: recentKey) ?? []
    }

    var recentlyViewed: [Post] {
        recentlyViewedSlugs.compactMap { post(slug: $0) }
    }

    func recordView(_ slug: String) {
        recentlyViewedSlugs.removeAll { $0 == slug }
        recentlyViewedSlugs.insert(slug, at: 0)
        if recentlyViewedSlugs.count > recentLimit {
            recentlyViewedSlugs.removeLast(recentlyViewedSlugs.count - recentLimit)
        }
        UserDefaults.standard.set(recentlyViewedSlugs, forKey: recentKey)
    }

    private func load() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "md", subdirectory: nil) else {
            posts = []
            return
        }

        var loaded: [Post] = []
        for url in urls {
            guard let raw = try? String(contentsOf: url, encoding: .utf8) else { continue }
            let slug = url.deletingPathExtension().lastPathComponent
            let parsed = FrontmatterParser.parse(raw)
            let fields = parsed.fields

            guard let title = fields["title"], !title.isEmpty else { continue }
            let published = fields["published"] != "false"
            guard published else { continue }

            let section = SiteSection(rawValue: parsed.tags.first(where: { SiteSection(rawValue: $0.lowercased()) != nil })?.lowercased() ?? "")

            let post = Post(
                slug: slug,
                title: title,
                description: fields["description"] ?? "",
                panelCategory: fields["panelCategory"] ?? "General",
                date: fields["date"] ?? "",
                author: fields["author"],
                tags: parsed.tags,
                published: published,
                section: section,
                body: BodyCleaner.clean(parsed.body)
            )
            loaded.append(post)
        }

        posts = loaded.sorted { $0.date > $1.date }
    }

    func posts(in section: SiteSection) -> [Post] {
        posts.filter { $0.section == section && $0.isCompleted }
    }

    func categories(in section: SiteSection) -> [String] {
        let cats = posts(in: section).map(\.panelCategory)
        var seen = Set<String>()
        var ordered: [String] = []
        for c in cats where !seen.contains(c) {
            seen.insert(c)
            ordered.append(c)
        }
        return orderCategories(ordered)
    }

    func posts(in section: SiteSection, category: String) -> [Post] {
        posts(in: section).filter { $0.panelCategory == category }.sorted { $0.title < $1.title }
    }

    private func orderCategories(_ cats: [String]) -> [String] {
        cats.sorted { a, b in
            if a == "Basics" { return true }
            if b == "Basics" { return false }
            if a == "Sensors" || a == "Vision" { return b != "Sensors" && b != "Vision" ? true : a < b }
            return a < b
        }
    }

    func post(slug: String) -> Post? {
        posts.first { $0.slug == slug }
    }

    func search(_ query: String) -> [Post] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return posts.filter { $0.isCompleted }.filter { post in
            post.title.lowercased().contains(q)
                || post.description.lowercased().contains(q)
                || post.tags.contains { $0.lowercased().contains(q) }
        }
    }
}
