import SwiftUI

struct PublicUserProfileView: View {
    @StateObject private var viewModel: PublicUserProfileViewModel

    init(
        userId: String,
        userRepository: UserRepository,
        reviewRepository: ReviewRepository,
        taskRepository: TaskRepository
    ) {
        _viewModel = StateObject(
            wrappedValue: PublicUserProfileViewModel(
                userId: userId,
                userRepository: userRepository,
                reviewRepository: reviewRepository,
                taskRepository: taskRepository
            )
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                if viewModel.isLoading {
                    ProgressView()
                } else if let user = viewModel.user {
                    profileHeader(user)
                    reviewsSection
                    tasksSection
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .padding(20)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle(viewModel.user?.username ?? "Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    private func profileHeader(_ user: AppUser) -> some View {
        VStack(spacing: 12) {
            Circle()
                .fill(AppColors.primary.opacity(0.15))
                .frame(width: 96, height: 96)
                .overlay(
                    Text(String(user.username.prefix(1)).uppercased())
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(AppColors.primary)
                )

            Text(user.username)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Text(user.city)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)

            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)

                Text(String(format: "%.1f", user.ratingAvg))
                    .font(.system(size: 16, weight: .bold))

                Text("(\(user.ratingCount) reviews)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Reviews")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            if viewModel.reviews.isEmpty {
                emptyCard("No reviews yet")
            } else {
                ForEach(viewModel.reviews) { review in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(review.reviewerUsername)
                                .font(.system(size: 16, weight: .bold))

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
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Active Tasks")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            if viewModel.activeTasks.isEmpty {
                emptyCard("No active tasks")
            } else {
                ForEach(viewModel.activeTasks) { task in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(task.title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)

                        HStack {
                            Text(task.category.displayName)
                            Spacer()
                            Text(statusText(task.status))
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)

                        Text(task.city)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
    }

    private func emptyCard(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(AppColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func statusText(_ status: TaskStatus) -> String {
        switch status {
        case .open:
            return "Open"
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        }
    }

    private func relativeDate(_ date: Date) -> String {
        RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }
}
