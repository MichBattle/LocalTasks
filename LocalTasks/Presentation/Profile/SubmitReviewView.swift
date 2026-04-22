import SwiftUI

struct SubmitReviewView: View {
    let requirement: PendingReviewDetailsItem
    let currentUserId: String
    let reviewRepository: ReviewRepository

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SubmitReviewViewModel

    init(
        requirement: PendingReviewDetailsItem,
        currentUserId: String,
        reviewRepository: ReviewRepository
    ) {
        self.requirement = requirement
        self.currentUserId = currentUserId
        self.reviewRepository = reviewRepository
        _viewModel = StateObject(
            wrappedValue: SubmitReviewViewModel(
                requirement: requirement,
                currentUserId: currentUserId,
                reviewRepository: reviewRepository
            )
        )
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Review \(requirement.reviewedUsername)")
                        .font(.system(size: 26, weight: .bold))

                    Text(requirement.taskTitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)

                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { value in
                            Button {
                                viewModel.selectedRating = value
                            } label: {
                                Image(systemName: value <= viewModel.selectedRating ? "star.fill" : "star")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.yellow)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Comment")
                            .font(.system(size: 15, weight: .semibold))

                        TextEditor(text: $viewModel.comment)
                            .frame(height: 160)
                            .padding(8)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }

                    if let successMessage = viewModel.successMessage {
                        Text(successMessage)
                            .foregroundStyle(.green)
                    }

                    Button {
                        Task {
                            let submitted = await viewModel.submit()
                            if submitted {
                                dismiss()
                            }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppColors.primary)
                                .frame(height: 56)

                            if viewModel.isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text("Submit Review")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Leave a Review")
        .navigationBarTitleDisplayMode(.inline)
    }
}
