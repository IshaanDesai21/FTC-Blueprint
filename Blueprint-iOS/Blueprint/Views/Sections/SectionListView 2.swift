import SwiftUI

struct SectionListView: View {
    let section: SiteSection
    @Environment(PostStore.self) private var store
    @State private var searchText = ""

    private var categories: [String] {
        store.categories(in: section)
    }

    private func filteredPosts(for category: String) -> [Post] {
        let posts = store.posts(in: section, category: category)
        guard !searchText.isEmpty else { return posts }
        let q = searchText.lowercased()
        return posts.filter { $0.title.lowercased().contains(q) || $0.description.lowercased().contains(q) }
    }

    var body: some View {
        List {
            ForEach(categories, id: \.self) { category in
                let posts = filteredPosts(for: category)
                if !posts.isEmpty {
                    Section(category) {
                        ForEach(posts) { post in
                            NavigationLink(value: post) {
                                PostRow(post: post)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle(section.title)
        .searchable(text: $searchText, prompt: String(format: "Search %@".localizedUI, section.title.lowercased()))
        .navigationDestination(for: Post.self) { post in
            PostDetailView(post: post)
        }
        .overlay {
            if categories.allSatisfy({ filteredPosts(for: $0).isEmpty }) {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }
}
