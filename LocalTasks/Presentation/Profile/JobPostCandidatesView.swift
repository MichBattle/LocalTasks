import SwiftUI

struct JobPostCandidatesView: View {
    let task: TaskItem

    @StateObject private var viewModel: JobPostCandidatesViewModel
    @State private var selectedChat: ChatItem?

    private let chatRepository: ChatRepository

    init(
        task: TaskItem,
        applicationRepository: ApplicationRepository,
        chatRepository: ChatRepository
    ) {
        self.task = task
        self.chatRepository = chatRepository
        _viewModel = StateObject(
            wrappedValue: JobPostCandidatesViewModel(
                task: task,
                applicationRepository: applicationRepository,
                chatRepository: chatRepository
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
                            Task { await viewModel.accept(application: application) }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(application.status == .accepted)

                        Button("Reject") {
                            Task { await viewModel.reject(application: application) }
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
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
                        currentUserId: task.creatorId,
                        repository: chatRepository
                    )
                },
                isActive: Binding(
                    get: { selectedChat != nil },
                    set: { isActive in
                        if !isActive { selectedChat = nil }
                    }
                )
            ) {
                EmptyView()
            }
            .hidden()
        )
    }

    private func ratingString(_ value: Double, count: Int) -> String {
        let formatted = String(format: "%.1f", value)
        return "⭐ \(formatted) (\(count))"
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
