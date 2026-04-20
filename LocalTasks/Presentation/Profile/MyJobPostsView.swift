import SwiftUI

struct MyJobPostsView: View {
    @StateObject private var viewModel: ProfileJobPostsViewModel

    let authViewModel: AuthViewModel
    let applicationRepository: ApplicationRepository
    let chatRepository: ChatRepository

    init(
        taskRepository: TaskRepository,
        applicationRepository: ApplicationRepository,
        chatRepository: ChatRepository,
        authViewModel: AuthViewModel,
        userId: String
    ) {
        self.authViewModel = authViewModel
        self.applicationRepository = applicationRepository
        self.chatRepository = chatRepository

        _viewModel = StateObject(
            wrappedValue: ProfileJobPostsViewModel(
                taskRepository: taskRepository,
                userId: userId
            )
        )
    }

    var body: some View {
        List(viewModel.tasks) { task in
            NavigationLink {
                JobPostCandidatesView(
                    task: task,
                    applicationRepository: applicationRepository,
                    chatRepository: chatRepository
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
