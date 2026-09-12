import SwiftUI

struct HomeView: View {
    @Environment(PostStore.self) private var store
    @Environment(AppNavigation.self) private var nav

    var body: some View {
        List {
            SwiftUI.Section {
                VStack(alignment: .leading, spacing: 16) {
                    HexagonMark()
                        .stroke(HexagonMark.brandGradient, lineWidth: 2)
                        .frame(width: 38, height: 38)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("The complete\nFTC guide.")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Guides, interactive simulators, and real code examples built by FTC teams for FTC competitors.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 22)
            }
            .listRowBackground(
                LinearGradient(
                    colors: [Theme.accentCyan.opacity(0.12), Theme.accentGreen.opacity(0.07)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .listRowSeparator(.hidden)

            SwiftUI.Section("Browse") {
                ForEach(SiteSection.allCases) { section in
                    Button {
                        nav.openSection(section)
                    } label: {
                        HStack {
                            Label {
                                Text(section.title).foregroundStyle(Theme.textPrimary)
                            } icon: {
                                Image(systemName: section.systemImage).foregroundStyle(Theme.accentCyan)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Theme.textMuted)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            if !store.recentlyViewed.isEmpty {
                SwiftUI.Section("Recently Viewed") {
                    ForEach(store.recentlyViewed) { post in
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
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Blueprint")
        .navigationBarTitleDisplayMode(.inline)
    }
}
