import Foundation
import Combine

@MainActor
final class ProfileApplicationsViewModel: ObservableObject {
    @Published var applications: [ApplicationItem] = []
    @Published var linkedTasks: [String: TaskItem] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let applicationRepository: ApplicationRepository
    private let taskRepository: TaskRepository
    private let userId: String

    init(
        applicationRepository: ApplicationRepository,
        taskRepository: TaskRepository,
        userId: String
    ) {
        self.applicationRepository = applicationRepository
        self.taskRepository = taskRepository
        self.userId = userId
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let applications = try await applicationRepository.fetchApplicationsByApplicant(userId: userId)
            self.applications = applications

            var tasksMap: [String: TaskItem] = [:]
            for application in applications {
                if let task = try await taskRepository.fetchTask(by: application.taskId) {
                    tasksMap[application.taskId] = task
                }
            }
            self.linkedTasks = tasksMap
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
