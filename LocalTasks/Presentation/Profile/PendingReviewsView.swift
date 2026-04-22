import SwiftUI

struct PendingReviewsView: View {
    let currentUserId: String
    let reviewRepository: ReviewRepository

    @StateObject private var viewModel: PendingReviewsViewModel

    init(currentUserId: String, reviewRepository: ReviewRepository) {
        self.currentUserId = currentUserId
        self.reviewRepository = reviewRepository
        _viewModel = StateObject(
            wrappedValue: PendingReviewsViewModel(
                reviewRepository: reviewRepository,
                userId: currentUserId
            )
        )
    }

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            ForEach(viewModel.pendingReviews) { item in
                NavigationLink {
                    SubmitReviewView(
                        requirement: item,
                        currentUserId: currentUserId,
                        reviewRepository: reviewRepository
                    )
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.reviewedUsername)
                            .font(.system(size: 17, weight: .bold))

                        Text(item.taskTitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Pending Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }
}
