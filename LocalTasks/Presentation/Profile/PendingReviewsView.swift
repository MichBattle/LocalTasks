import SwiftUI

struct PendingReviewsView: View {
    let currentUserId: String
    let reviewRepository: ReviewRepository
    let onExit: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PendingReviewsViewModel

    init(
        currentUserId: String,
        reviewRepository: ReviewRepository,
        onExit: @escaping () -> Void
    ) {
        self.currentUserId = currentUserId
        self.reviewRepository = reviewRepository
        self.onExit = onExit

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

            if viewModel.pendingReviews.isEmpty {
                ContentUnavailableView(
                    "No pending reviews",
                    systemImage: "star.bubble",
                    description: Text("Reviews you need to complete will appear here.")
                )
            } else {
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
        }
        .navigationTitle("Pending Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    onExit()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
