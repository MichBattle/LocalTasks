import Foundation

struct TaskItem: Identifiable, Hashable {
    let id: UUID
    let authorName: String
    let authorAvatarName: String?
    let createdAtText: String
    let distanceText: String
    let title: String
    let description: String
    let priceText: String
    let imageName: String?
    let category: TaskCategory

    init(
        id: UUID = UUID(),
        authorName: String,
        authorAvatarName: String? = nil,
        createdAtText: String,
        distanceText: String,
        title: String,
        description: String,
        priceText: String,
        imageName: String? = nil,
        category: TaskCategory
    ) {
        self.id = id
        self.authorName = authorName
        self.authorAvatarName = authorAvatarName
        self.createdAtText = createdAtText
        self.distanceText = distanceText
        self.title = title
        self.description = description
        self.priceText = priceText
        self.imageName = imageName
        self.category = category
    }
}
