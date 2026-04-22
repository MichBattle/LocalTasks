import Foundation
import Combine

@MainActor
final class SubmitReviewViewModel: ObservableObject {
    @Published var selectedRating: Int = 0
    @Published var comment: String = ""
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let reviewRepository: ReviewRepository
    private let requirement: PendingReviewDetailsItem
    private let currentUserId: String

    init(
        requirement: PendingReviewDetailsItem,
        currentUserId: String,
        reviewRepository: ReviewRepository
    ) {
        self.requirement = requirement
        self.currentUserId = currentUserId
        self.reviewRepository = reviewRepository
    }

    func submit() async -> Bool {
        guard (1...5).contains(selectedRating) else {
            errorMessage = "Please select a rating"
            return false
        }

        isSubmitting = true
        errorMessage = nil
        successMessage = nil
        defer { isSubmitting = false }

        do {
            try await reviewRepository.submitReview(
                requirementId: requirement.id,
                taskId: requirement.taskId,
                reviewerId: currentUserId,
                reviewedUserId: requirement.reviewedUserId,
                rating: selectedRating,
                comment: comment.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            successMessage = "Review submitted successfully"
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
