import SwiftUI

struct MyReviewsView: View {
    let currentUserId: String
    let reviewRepository: ReviewRepository

    @State private var reviews: [ReviewDetailsItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()

            } else if let errorMessage {
                ContentUnavailableView(
                    "Unable to load reviews",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )

            } else if reviews.isEmpty {
                ContentUnavailableView(
                    "No reviews yet",
                    systemImage: "star",
                    description: Text("Reviews other users leave about you will appear here.")
                )

            } else {
                List(reviews) { review in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(review.reviewerUsername)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(AppColors.textPrimary)

                            Spacer()

                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { index in
                                    Image(systemName: index <= review.rating ? "star.fill" : "star")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.yellow)
                                }
                            }
                        }

                        if !review.comment.isEmpty {
                            Text(review.comment)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppColors.textSecondary)
                        }

                        Text(relativeDate(review.createdAt))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .padding(.vertical, 6)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("My Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadReviews()
        }
    }

    private func loadReviews() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            reviews = try await reviewRepository.fetchReviews(for: currentUserId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func relativeDate(_ date: Date) -> String {
        RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }
}
