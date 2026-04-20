import SwiftUI

struct MyApplicationsView: View {
    @StateObject private var viewModel: ProfileApplicationsViewModel

    init(
        applicationRepository: ApplicationRepository,
        taskRepository: TaskRepository,
        userId: String
    ) {
        _viewModel = StateObject(
            wrappedValue: ProfileApplicationsViewModel(
                applicationRepository: applicationRepository,
                taskRepository: taskRepository,
                userId: userId
            )
        )
    }

    var body: some View {
        List {
            ForEach(viewModel.applications) { application in
                if let task = viewModel.linkedTasks[application.taskId] {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(task.title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)

                        Text(task.city)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)

                        Text(statusText(application.status))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(statusColor(application.status))
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("My Applications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    private func statusText(_ status: ApplicationStatus) -> String {
        switch status {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .rejected: return "Rejected"
        case .cancelled: return "Cancelled"
        }
    }

    private func statusColor(_ status: ApplicationStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .accepted: return .green
        case .rejected: return .red
        case .cancelled: return .gray
        }
    }
}
