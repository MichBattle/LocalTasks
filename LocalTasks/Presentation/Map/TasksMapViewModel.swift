import Foundation
import Combine

@MainActor
final class TasksMapViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let taskRepository: TaskRepository

    init(taskRepository: TaskRepository) {
        self.taskRepository = taskRepository
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            tasks = try await taskRepository.fetchFeedTasks(city: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
