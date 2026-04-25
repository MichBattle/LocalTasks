import SwiftUI

struct JobPostCandidatesView: View {
    let task: TaskItem
    let currentUserId: String

    @StateObject private var viewModel: JobPostCandidatesViewModel
    @State private var selectedChat: ChatItem?

    @State private var applicationToAccept: ApplicationDetailsItem?
    @State private var applicationToReject: ApplicationDetailsItem?
    @State private var applicationToReset: ApplicationDetailsItem?
    @State private var showCompleteConfirmation = false

    private let applicationRepository: ApplicationRepository
    private let chatRepository: ChatRepository
    private let reviewRepository: ReviewRepository
    private let userRepository: UserRepository
    private let taskRepository: TaskRepository
    private let notificationRepository: NotificationRepository

    init(
        task: TaskItem,
        currentUserId: String,
        applicationRepository: ApplicationRepository,
        chatRepository: ChatRepository,
        reviewRepository: ReviewRepository,
        userRepository: UserRepository,
        taskRepository: TaskRepository,
        notificationRepository: NotificationRepository
    ) {
        self.task = task
        self.currentUserId = currentUserId
        self.applicationRepository = applicationRepository
        self.chatRepository = chatRepository
        self.reviewRepository = reviewRepository
        self.userRepository = userRepository
        self.taskRepository = taskRepository
        self.notificationRepository = notificationRepository

        _viewModel = StateObject(
            wrappedValue: JobPostCandidatesViewModel(
                task: task,
                applicationRepository: applicationRepository,
                chatRepository: chatRepository,
                reviewRepository: reviewRepository
            )
        )
    }

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            if let successMessage = viewModel.successMessage {
                Text(successMessage)
                    .foregroundStyle(.green)
            }

            if task.status == .inProgress && task.creatorId == currentUserId {
                Button {
                    showCompleteConfirmation = true
                } label: {
                    Text("Mark task as completed")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            ForEach(viewModel.applications) { application in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(application.applicantUsername)
                                .font(.system(size: 17, weight: .bold))

                            Text(application.applicantCity)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppColors.textSecondary)
                        }

                        Spacer()

                        Text(ratingString(application.applicantRatingAvg, count: application.applicantRatingCount))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                    }

                    NavigationLink {
                        PublicUserProfileView(
                            userId: application.applicantId,
                            userRepository: userRepository,
                            reviewRepository: reviewRepository,
                            taskRepository: taskRepository
                        )
                    } label: {
                        Text("View profile")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.primary)
                    }

                    if let message = application.message, !message.isEmpty {
                        Text(message)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Text(statusText(application.status))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(statusColor(application.status))

                    HStack(spacing: 12) {
                        Button("Contact") {
                            Task {
                                if let chat = try? await viewModel.contact(application: application) {
                                    selectedChat = chat
                                }
                            }
                        }
                        .buttonStyle(.bordered)

                        Button("Accept") {
                            applicationToAccept = application
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(application.status != .pending || viewModel.isTaskCompleted)

                        Button("Reject") {
                            applicationToReject = application
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .disabled(application.status != .pending || viewModel.isTaskCompleted)

                        if application.status != .pending {
                            Button("Reset") {
                                applicationToReset = application
                            }
                            .buttonStyle(.bordered)
                            .disabled(viewModel.isTaskCompleted)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle(task.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .background(
            NavigationLink(
                destination: selectedChat.map {
                    ChatDetailView(
                        chat: $0,
                        currentUserId: currentUserId,
                        repository: chatRepository,
                        userRepository: userRepository,
                        reviewRepository: reviewRepository,
                        taskRepository: taskRepository,
                        notificationRepository: notificationRepository
                    )
                },
                isActive: Binding(
                    get: { selectedChat != nil },
                    set: { isActive in
                        if !isActive {
                            selectedChat = nil
                        }
                    }
                )
            ) {
                EmptyView()
            }
            .hidden()
        )
        .alert("Vuoi veramente accettare questa persona?", isPresented: Binding(
            get: { applicationToAccept != nil },
            set: { if !$0 { applicationToAccept = nil } }
        )) {
            Button("Annulla", role: .cancel) {
                applicationToAccept = nil
            }

            Button("Accetta") {
                if let application = applicationToAccept {
                    Task {
                        await viewModel.accept(application: application)
                    }
                }
                applicationToAccept = nil
            }
        }
        .alert("Vuoi veramente rifiutare questa persona?", isPresented: Binding(
            get: { applicationToReject != nil },
            set: { if !$0 { applicationToReject = nil } }
        )) {
            Button("Annulla", role: .cancel) {
                applicationToReject = nil
            }

            Button("Rifiuta", role: .destructive) {
                if let application = applicationToReject {
                    Task {
                        await viewModel.reject(application: application)
                    }
                }
                applicationToReject = nil
            }
        }
        .alert("Vuoi riportare questa candidatura in pending?", isPresented: Binding(
            get: { applicationToReset != nil },
            set: { if !$0 { applicationToReset = nil } }
        )) {
            Button("Annulla", role: .cancel) {
                applicationToReset = nil
            }

            Button("Reset") {
                if let application = applicationToReset {
                    Task {
                        await viewModel.reset(application: application)
                    }
                }
                applicationToReset = nil
            }
        }
        .alert("Vuoi veramente segnare il lavoro come completato?", isPresented: $showCompleteConfirmation) {
            Button("Annulla", role: .cancel) {}

            Button("Conferma") {
                Task {
                    await viewModel.completeTask(currentUserId: currentUserId)
                }
            }
        }
    }

    private func ratingString(_ value: Double, count: Int) -> String {
        let formatted = String(format: "%.1f", value)
        return "⭐ \(formatted) (\(count))"
    }

    private func statusText(_ status: ApplicationStatus) -> String {
        switch status {
        case .pending:
            return "Pending"
        case .accepted:
            return "Accepted"
        case .rejected:
            return "Rejected"
        case .cancelled:
            return "Cancelled"
        }
    }

    private func statusColor(_ status: ApplicationStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .accepted:
            return .green
        case .rejected:
            return .red
        case .cancelled:
            return .gray
        }
    }
}
