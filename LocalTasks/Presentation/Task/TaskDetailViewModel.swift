import Foundation
import Combine
import FirebaseAuth

@MainActor
final class TaskDetailViewModel: ObservableObject {
    @Published var isApplying = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var hasAlreadyApplied = false

    private let task: TaskItem
    private let repository: ApplicationRepository
    private let reviewRepository: ReviewRepository

    init(
        task: TaskItem,
        repository: ApplicationRepository,
        reviewRepository: ReviewRepository
    ) {
        self.task = task
        self.repository = repository
        self.reviewRepository = reviewRepository
    }

    var canApply: Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return uid != task.creatorId && task.status == .open && !hasAlreadyApplied
    }

    func loadApplicationState() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            hasAlreadyApplied = try await repository.hasApplied(
                taskId: task.id,
                applicantId: uid
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func apply() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Authentication required"
            return
        }

        isApplying = true
        errorMessage = nil
        successMessage = nil
        defer { isApplying = false }

        do {
            let hasPending = try await reviewRepository.hasPendingReviews(userId: uid)
            if hasPending {
                errorMessage = "You must complete your pending reviews before applying to a new task. Profile > Pending Reviews"
                return
            }

            try await repository.apply(
                to: CreateApplicationInput(
                    taskId: task.id,
                    taskCreatorId: task.creatorId,
                    message: nil
                )
            )

            hasAlreadyApplied = true
            successMessage = "Application sent successfully"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
