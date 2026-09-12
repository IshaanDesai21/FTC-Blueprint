import CoreSpotlight
import Foundation

enum SpotlightIndexer {
    static let domainIdentifier = "com.ftcblueprint.app.guides"

    static func indexAll(_ posts: [Post]) {
        guard CSSearchableIndex.isIndexingAvailable() else { return }

        let items = posts.filter(\.isCompleted).map { post -> CSSearchableItem in
            let attributes = CSSearchableItemAttributeSet(contentType: .text)
            attributes.title = post.title
            attributes.contentDescription = post.description

            var keywords = [post.panelCategory]
            if let sectionTitle = post.section?.title { keywords.append(sectionTitle) }
            keywords.append(contentsOf: post.tags)
            attributes.keywords = keywords

            let item = CSSearchableItem(
                uniqueIdentifier: post.slug,
                domainIdentifier: domainIdentifier,
                attributeSet: attributes
            )
            item.expirationDate = .distantFuture
            return item
        }

        CSSearchableIndex.default().indexSearchableItems(items)
    }

    static func slug(from activity: NSUserActivity) -> String? {
        guard activity.activityType == CSSearchableItemActionType else { return nil }
        return activity.userInfo?[CSSearchableItemActivityIdentifier] as? String
    }
}
