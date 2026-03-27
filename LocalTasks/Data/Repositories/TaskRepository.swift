import Foundation

protocol TaskRepository {
    func fetchFeaturedTasks() async throws -> [TaskItem]
}
