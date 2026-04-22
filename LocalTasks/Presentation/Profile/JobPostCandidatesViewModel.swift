import Foundation
import Combine

@MainActor
final class JobPostCandidatesViewModel: ObservableObject {
    @Published var applications: [ApplicationDetailsItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let task: TaskItem
    private let applicationRepository: ApplicationRepository
    private let chatRepository: ChatRepository
    private let reviewRepository: ReviewRepository

    init(
        task: TaskItem,
        applicationRepository: ApplicationRepository,
        chatRepository: ChatRepository,
        reviewRepository: ReviewRepository
    ) {
        self.task = task
        self.applicationRepository = applicationRepository
        self.chatRepository = chatRepository
        self.reviewRepository = reviewRepository
    }

    var isTaskCompleted: Bool {
        task.status == .completed
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            applications = try await applicationRepository.fetchApplicationsForTask(taskId: task.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func accept(application: ApplicationDetailsItem) async {
        do {
            try await applicationRepository.updateApplicationStatus(
                applicationId: application.id,
                taskId: task.id,
                applicantId: application.applicantId,
                status: .accepted
            )
            successMessage = "Candidate accepted"
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reject(application: ApplicationDetailsItem) async {
        do {
            try await applicationRepository.updateApplicationStatus(
                applicationId: application.id,
                taskId: task.id,
                applicantId: application.applicantId,
                status: .rejected
            )
            successMessage = "Candidate rejected"
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reset(application: ApplicationDetailsItem) async {
        do {
            try await applicationRepository.resetApplicationStatus(
                applicationId: application.id,
                taskId: task.id,
                applicantId: application.applicantId
            )
            successMessage = "Application reset to pending"
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func contact(application: ApplicationDetailsItem) async throws -> ChatItem {
        return try await chatRepository.getOrCreateChat(
            taskId: task.id,
            creatorId: task.creatorId,
            applicantId: application.applicantId
        )
    }

    func completeTask(currentUserId: String) async {
        do {
            try await reviewRepository.completeTask(task: task, currentUserId: currentUserId)
            successMessage = "Task marked as completed. Reviews are now required."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
