import SwiftUI

struct PostRow: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(post.title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
            if !post.description.isEmpty {
                Text(post.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}

struct TagChip: View {
    let text: String

    var body: some View {
        Text(text.capitalized)
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.accentCyan.opacity(0.12))
            .foregroundStyle(Theme.accentCyan)
            .clipShape(Capsule())
    }
}
