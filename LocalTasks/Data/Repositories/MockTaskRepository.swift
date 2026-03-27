import Foundation

final class MockTaskRepository: TaskRepository {
    func fetchFeaturedTasks() async throws -> [TaskItem] {
        return [
            TaskItem(
                authorName: "Maria Rodriguez",
                authorAvatarName: nil,
                createdAtText: "2h ago",
                distanceText: "1.2km",
                title: "Help Moving to New Apartment",
                description: "Need help moving furniture and boxes from a 2-bedroom apartment. Heavy lifting required.",
                priceText: "$50/hr",
                imageName: nil,
                category: .moving
            ),
            TaskItem(
                authorName: "Jennifer Chen",
                authorAvatarName: nil,
                createdAtText: "5h ago",
                distanceText: "0.8km",
                title: "Need a Babysitter Tonight",
                description: "Looking for someone reliable to take care of my child from 7 PM to 11 PM.",
                priceText: "$25/hr",
                imageName: nil,
                category: .babysitting
            ),
            TaskItem(
                authorName: "Lucas Green",
                authorAvatarName: nil,
                createdAtText: "1d ago",
                distanceText: "2.4km",
                title: "Garden Cleanup Needed",
                description: "Help trimming bushes, collecting leaves, and tidying up the backyard.",
                priceText: "$30/hr",
                imageName: nil,
                category: .gardening
            )
        ]
    }
}
