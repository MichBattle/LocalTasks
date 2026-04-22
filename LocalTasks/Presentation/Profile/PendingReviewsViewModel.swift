import Foundation
import Combine

@MainActor
final class PendingReviewsViewModel: ObservableObject {
    @Published var pendingReviews: [PendingReviewDetailsItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let reviewRepository: ReviewRepository
    private let userId: String

    init(reviewRepository: ReviewRepository, userId: String) {
        self.reviewRepository = reviewRepository
        self.userId = userId
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            pendingReviews = try await reviewRepository.fetchPendingReviews(for: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
