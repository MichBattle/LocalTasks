import Foundation
import Combine

@MainActor
final class PublicUserProfileViewModel: ObservableObject {
    @Published var user: AppUser?
    @Published var reviews: [ReviewDetailsItem] = []
    @Published var activeTasks: [TaskItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let userId: String
    private let userRepository: UserRepository
    private let reviewRepository: ReviewRepository
    private let taskRepository: TaskRepository

    init(
        userId: String,
        userRepository: UserRepository,
        reviewRepository: ReviewRepository,
        taskRepository: TaskRepository
    ) {
        self.userId = userId
        self.userRepository = userRepository
        self.reviewRepository = reviewRepository
        self.taskRepository = taskRepository
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let userResult = userRepository.fetchUser(by: userId)
            async let reviewsResult = reviewRepository.fetchReviews(for: userId)
            async let tasksResult = taskRepository.fetchTasksCreatedByUser(userId: userId)

            user = try await userResult
            reviews = try await reviewsResult

            let allTasks = try await tasksResult
            activeTasks = allTasks.filter { $0.status != .completed }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
