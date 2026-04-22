import Foundation

protocol TaskRepository {
    func fetchFeedTasks(city: String?) async throws -> [TaskItem]
    func createTask(input: CreateTaskInput, imageDataList: [Data]) async throws
    func fetchTasksCreatedByUser(userId: String) async throws -> [TaskItem]
    func fetchTask(by id: String) async throws -> TaskItem?
}
