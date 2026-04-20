import Foundation

final class MockTaskRepository: TaskRepository {
    private var tasks: [TaskItem] = [
        TaskItem(
            id: UUID().uuidString,
            creatorId: "user_1",
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
            creatorId: "user_2",
            creatorUsername: "Jennifer Chen",
            title: "Babysitting Needed",
            description: "Looking for a babysitter tonight.",
            category: .babysitting,
            city: "Trento",
            price: 25,
            photoURLs: [],
            status: .open,
            acceptedUserId: nil,
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: Date().addingTimeInterval(-3600)
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
            creatorId: "mock_current_user",
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

    func fetchTasksCreatedByUser(userId: String) async throws -> [TaskItem] {
        return tasks
            .filter { $0.creatorId == userId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func fetchTask(by id: String) async throws -> TaskItem? {
        return tasks.first(where: { $0.id == id })
    }
}
