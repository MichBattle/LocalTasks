import SwiftUI

struct MessagesListView: View {
    @StateObject private var viewModel: MessagesListViewModel
    @StateObject private var notificationsViewModel: NotificationsViewModel

    @ObservedObject var authViewModel: AuthViewModel

    private let userRepository: UserRepository
    private let taskRepository: TaskRepository
    private let chatRepository: ChatRepository
    private let reviewRepository: ReviewRepository
    private let notificationRepository: NotificationRepository

    let onExit: () -> Void

    init(
        authViewModel: AuthViewModel,
        userRepository: UserRepository,
        taskRepository: TaskRepository,
        chatRepository: ChatRepository,
        reviewRepository: ReviewRepository,
        notificationRepository: NotificationRepository,
        onExit: @escaping () -> Void
    ) {
        self.authViewModel = authViewModel
        self.userRepository = userRepository
        self.taskRepository = taskRepository
        self.chatRepository = chatRepository
        self.reviewRepository = reviewRepository
        self.notificationRepository = notificationRepository
        self.onExit = onExit

        let currentUserId = authViewModel.currentUser?.id ?? ""

        _viewModel = StateObject(
            wrappedValue: MessagesListViewModel(
                chatRepository: chatRepository,
                userRepository: userRepository,
                taskRepository: taskRepository,
                currentUserId: currentUserId
            )
        )

        _notificationsViewModel = StateObject(
            wrappedValue: NotificationsViewModel(
                repository: notificationRepository
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()

                } else if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Unable to load chats",
                        systemImage: "exclamationmark.bubble",
                        description: Text(errorMessage)
                    )

                } else if viewModel.rows.isEmpty {
                    ContentUnavailableView(
                        "No conversations yet",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Your chats will appear here.")
                    )

                } else {
                    List(viewModel.rows) { row in
                        NavigationLink {
                            ChatDetailView(
                                chat: row.chat,
                                currentUserId: authViewModel.currentUser?.id ?? "",
                                repository: chatRepository,
                                userRepository: userRepository,
                                reviewRepository: reviewRepository,
                                taskRepository: taskRepository,
                                notificationRepository: notificationRepository
                            )
                        } label: {
                            chatRow(row)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onExit()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(AppColors.primary)
                    }
                }
            }
            .onAppear {
                viewModel.startListening()

                if let userId = authViewModel.currentUser?.id {
                    notificationsViewModel.startListening(for: userId)
                }
            }
            .onDisappear {
                viewModel.stopListening()
                notificationsViewModel.stopListening()
            }
        }
    }

    private func chatRow(_ row: ChatListRowItem) -> some View {
        let hasUnread = hasUnreadMessages(for: row.chat.id)

        return HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(row.otherUserName)
                    .font(.system(size: 17, weight: hasUnread ? .bold : .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                Text(row.taskCategoryName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
                    .lineLimit(1)

                Text(row.lastMessagePreview)
                    .font(.system(size: 14, weight: hasUnread ? .bold : .medium))
                    .foregroundStyle(hasUnread ? AppColors.textPrimary : AppColors.textSecondary)
                    .lineLimit(1)

                if let lastDate = row.lastMessageAt {
                    Text(
                        RelativeDateTimeFormatter().localizedString(
                            for: lastDate,
                            relativeTo: Date()
                        )
                    )
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                }
            }

            Spacer()

            if hasUnread {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 6)
    }

    private func hasUnreadMessages(for chatId: String) -> Bool {
        notificationsViewModel.notifications.contains {
            !$0.isRead &&
            $0.type == .newMessage &&
            $0.relatedChatId == chatId
        }
    }
}
