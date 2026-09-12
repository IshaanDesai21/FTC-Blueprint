import SwiftUI

struct SearchView: View {
    @Environment(PostStore.self) private var store
    @Environment(AppNavigation.self) private var nav
    @State private var query = ""

    private var results: [Post] {
        store.search(query)
    }

    var body: some View {
        List {
            ForEach(results) { post in
                Button {
                    nav.open(post)
                } label: {
                    HStack {
                        PostRow(post: post)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.textMuted)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Search")
        .searchable(text: $query, prompt: "Search all guides")
        .overlay {
            if query.isEmpty {
                ContentUnavailableView("Search Blueprint", systemImage: "magnifyingglass", description: Text("Find software, hardware, and outreach guides."))
            } else if results.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
    }
}
