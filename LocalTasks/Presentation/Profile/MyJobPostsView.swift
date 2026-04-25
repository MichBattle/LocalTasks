import SwiftUI

struct MyJobPostsView: View {
    @StateObject private var viewModel: ProfileJobPostsViewModel

    let authViewModel: AuthViewModel
    let applicationRepository: ApplicationRepository
    let chatRepository: ChatRepository
    let reviewRepository: ReviewRepository
    let userRepository: UserRepository
    let taskRepository: TaskRepository
    let currentUserId: String

    init(
        taskRepository: TaskRepository,
        userRepository: UserRepository,
        applicationRepository: ApplicationRepository,
        chatRepository: ChatRepository,
        reviewRepository: ReviewRepository,
        authViewModel: AuthViewModel,
        userId: String
    ) {
        self.authViewModel = authViewModel
        self.applicationRepository = applicationRepository
        self.chatRepository = chatRepository
        self.reviewRepository = reviewRepository
        self.userRepository = userRepository
        self.taskRepository = taskRepository
        self.currentUserId = userId

        _viewModel = StateObject(
            wrappedValue: ProfileJobPostsViewModel(
                taskRepository: taskRepository,
                userId: userId
            )
        )
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()

            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Text("Error loading your job posts")
                        .font(.system(size: 18, weight: .bold))

                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
                .padding()

            } else if viewModel.tasks.isEmpty {
                ContentUnavailableView(
                    "No job posts yet",
                    systemImage: "briefcase",
                    description: Text("Create a task and it will appear here.")
                )

            } else {
                List(viewModel.tasks) { task in
                    NavigationLink {
                        JobPostCandidatesView(
                            task: task,
                            currentUserId: currentUserId,
                            applicationRepository: applicationRepository,
                            chatRepository: chatRepository,
                            reviewRepository: reviewRepository,
                            userRepository: userRepository,
                            taskRepository: taskRepository
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(task.title)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(AppColors.textPrimary)

                            Text(task.city)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppColors.textSecondary)

                            Text(statusText(task.status))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(statusColor(task.status))
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("My Job Posts")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    private func statusText(_ status: TaskStatus) -> String {
        switch status {
        case .open: return "Open"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        }
    }

    private func statusColor(_ status: TaskStatus) -> Color {
        switch status {
        case .open: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        }
    }
}
