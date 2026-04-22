import Foundation

protocol ReviewRepository {
    func completeTask(task: TaskItem, currentUserId: String) async throws
    func fetchPendingReviews(for userId: String) async throws -> [PendingReviewDetailsItem]
    func submitReview(
        requirementId: String,
        taskId: String,
        reviewerId: String,
        reviewedUserId: String,
        rating: Int,
        comment: String
    ) async throws

    func hasPendingReviews(userId: String) async throws -> Bool
}
