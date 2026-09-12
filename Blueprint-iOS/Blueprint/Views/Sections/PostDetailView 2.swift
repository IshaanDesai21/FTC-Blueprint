import SwiftUI

struct PostDetailView: View {
    let post: Post
    @Environment(PostStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                SimpleMarkdownText(markdown: post.body)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Theme.background)
        .navigationTitle(post.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.recordView(post.slug) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(post.panelCategory.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.accentCyan)

            Text(post.title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if !post.description.isEmpty {
                Text(post.description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }

            if post.author != nil || !post.visibleTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if let author = post.author, !author.isEmpty {
                            Label(author, systemImage: "person.fill")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                                .fixedSize()
                        }
                        ForEach(post.visibleTags, id: \.self) { TagChip(text: $0) }
                    }
                }
                .padding(.top, 4)
            }

            Divider().padding(.top, 10)
        }
    }
}
