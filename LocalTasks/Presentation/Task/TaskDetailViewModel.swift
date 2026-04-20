import Foundation
import Combine
import FirebaseAuth

@MainActor
final class TaskDetailViewModel: ObservableObject {
    @Published var applicationMessage = ""
    @Published var isApplying = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var hasAlreadyApplied = false

    private let task: TaskItem
    private let repository: ApplicationRepository

    init(task: TaskItem, repository: ApplicationRepository) {
        self.task = task
        self.repository = repository
    }

    var canApply: Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return uid != task.creatorId && task.status == .open && !hasAlreadyApplied
    }

    func loadApplicationState() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            hasAlreadyApplied = try await repository.hasApplied(taskId: task.id, applicantId: uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func apply() async {
        isApplying = true
        errorMessage = nil
        successMessage = nil
        defer { isApplying = false }

        do {
            try await repository.apply(
                to: CreateApplicationInput(
                    taskId: task.id,
                    taskCreatorId: task.creatorId,
                    message: applicationMessage
                )
            )
            hasAlreadyApplied = true
            successMessage = "Application sent successfully"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
