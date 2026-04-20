import Foundation
import Combine

@MainActor
final class ProfileJobPostsViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let taskRepository: TaskRepository
    private let userId: String

    init(taskRepository: TaskRepository, userId: String) {
        self.taskRepository = taskRepository
        self.userId = userId
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            tasks = try await taskRepository.fetchTasksCreatedByUser(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
