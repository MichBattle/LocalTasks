import SwiftUI

struct MessagesListView: View {
    @StateObject private var viewModel: MessagesListViewModel
    @ObservedObject var authViewModel: AuthViewModel
    private let chatRepository: ChatRepository
    let onExit: () -> Void

    init(
        authViewModel: AuthViewModel,
        userRepository: UserRepository,
        taskRepository: TaskRepository,
        chatRepository: ChatRepository,
        onExit: @escaping () -> Void
    ) {
        self.authViewModel = authViewModel
        self.chatRepository = chatRepository
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
                                repository: chatRepository
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(row.otherUserName)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(AppColors.textPrimary)
                                    .lineLimit(1)

                                Text(row.taskCategoryName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AppColors.primary)
                                    .lineLimit(1)

                                Text(row.lastMessagePreview)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppColors.textSecondary)
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
                            .padding(.vertical, 6)
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
            }
            .onDisappear {
                viewModel.stopListening()
            }
        }
    }
}
