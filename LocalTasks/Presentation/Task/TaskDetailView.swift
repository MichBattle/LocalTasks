import SwiftUI

struct TaskDetailView: View {
    let task: TaskItem

    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: TaskDetailViewModel

    let applicationRepository: ApplicationRepository
    let reviewRepository: ReviewRepository
    let userRepository: UserRepository
    let taskRepository: TaskRepository
    let onRequireAuth: () -> Void

    init(
        task: TaskItem,
        authViewModel: AuthViewModel,
        applicationRepository: ApplicationRepository,
        reviewRepository: ReviewRepository,
        userRepository: UserRepository,
        taskRepository: TaskRepository,
        onRequireAuth: @escaping () -> Void
    ) {
        self.task = task
        self.authViewModel = authViewModel
        self.applicationRepository = applicationRepository
        self.reviewRepository = reviewRepository
        self.userRepository = userRepository
        self.taskRepository = taskRepository
        self.onRequireAuth = onRequireAuth

        _viewModel = StateObject(
            wrappedValue: TaskDetailViewModel(
                task: task,
                repository: applicationRepository,
                reviewRepository: reviewRepository
            )
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                detailCard
                applyCard
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadApplicationState()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(task.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            HStack {
                Label(task.category.displayName, systemImage: task.category.iconName)

                Spacer()

                Text(task.city)
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(AppColors.textSecondary)

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Posted by \(task.creatorUsername)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)

                    NavigationLink {
                        PublicUserProfileView(
                            userId: task.creatorId,
                            userRepository: userRepository,
                            reviewRepository: reviewRepository,
                            taskRepository: taskRepository
                        )
                    } label: {
                        Text("View profile")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.primary)
                    }
                }

                Spacer()

                Text(relativeDateString(from: task.createdAt))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            detailRow(title: "Status", value: statusText(task.status))
            detailRow(title: "Price", value: task.price.map(priceString) ?? "Not specified")

            Divider()

            Text("Description")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Text(task.description)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
                .lineSpacing(4)
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var applyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Apply for this task")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Text("By applying, a conversation with the task creator will be opened automatically.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
                .lineSpacing(3)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.red)
            }

            if let successMessage = viewModel.successMessage {
                Text(successMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.green)
            }

            Button {
                if !authViewModel.isAuthenticated {
                    onRequireAuth()
                    return
                }

                Task {
                    await viewModel.apply()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            viewModel.hasAlreadyApplied
                            ? AnyShapeStyle(Color.gray.opacity(0.2))
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [AppColors.primaryLight, AppColors.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        )
                        .frame(height: 56)

                    if viewModel.isApplying {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(viewModel.hasAlreadyApplied ? "Already Applied" : "Apply")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(viewModel.hasAlreadyApplied ? .gray : .white)
                    }
                }
            }
            .disabled(viewModel.isApplying || viewModel.hasAlreadyApplied || !viewModel.canApply)
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(AppColors.textSecondary)

            Spacer()

            Text(value)
                .foregroundStyle(AppColors.textPrimary)
                .fontWeight(.semibold)
        }
        .font(.system(size: 15))
    }

    private func relativeDateString(from date: Date) -> String {
        RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }

    private func priceString(_ price: Double) -> String {
        let isWholeNumber = price.truncatingRemainder(dividingBy: 1) == 0
        let value = isWholeNumber
            ? String(Int(price))
            : String(format: "%.2f", price)

        return "€\(value)"
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
}
