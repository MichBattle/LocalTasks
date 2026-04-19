import Foundation

final class MockTaskRepository: TaskRepository {
    private var tasks: [TaskItem] = [
        TaskItem(
            id: UUID().uuidString,
            creatorId: "1",
            creatorUsername: "Maria Rodriguez",
            title: "Help Moving to New Apartment",
            description: "Need help moving furniture and boxes from a 2-bedroom apartment.",
            category: .moving,
            city: "Trento",
            price: 50,
            photoURLs: [],
            status: .open,
            acceptedUserId: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        TaskItem(
            id: UUID().uuidString,
            creatorId: "2",
            creatorUsername: "Jennifer Chen",
            title: "Babysitting Needed",
            description: "Looking for a babysitter tonight.",
            category: .babysitting,
            city: "Trento",
            price: 25,
            photoURLs: [],
            status: .open,
            acceptedUserId: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]

    func fetchFeedTasks(city: String?) async throws -> [TaskItem] {
        guard let city, !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return tasks.sorted { $0.createdAt > $1.createdAt }
        }

        return tasks
            .filter { $0.city.lowercased() == city.lowercased() }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func createTask(input: CreateTaskInput, imageDataList: [Data]) async throws {
        let newTask = TaskItem(
            id: UUID().uuidString,
            creatorId: UUID().uuidString,
            creatorUsername: "Mock User",
            title: input.title,
            description: input.description,
            category: input.category,
            city: input.city,
            price: input.price,
            photoURLs: [],
            status: .open,
            acceptedUserId: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        tasks.insert(newTask, at: 0)
    }
}
