import SwiftUI

struct ChatDetailView: View {
    let chat: ChatItem
    let currentUserId: String

    let repository: ChatRepository
    let userRepository: UserRepository
    let reviewRepository: ReviewRepository
    let taskRepository: TaskRepository
    let notificationRepository: NotificationRepository

    @StateObject private var viewModel: ChatDetailViewModel

    init(
        chat: ChatItem,
        currentUserId: String,
        repository: ChatRepository,
        userRepository: UserRepository,
        reviewRepository: ReviewRepository,
        taskRepository: TaskRepository,
        notificationRepository: NotificationRepository
    ) {
        self.chat = chat
        self.currentUserId = currentUserId
        self.repository = repository
        self.userRepository = userRepository
        self.reviewRepository = reviewRepository
        self.taskRepository = taskRepository
        self.notificationRepository = notificationRepository

        let otherUserId = chat.creatorId == currentUserId
            ? chat.applicantId
            : chat.creatorId

        _viewModel = StateObject(
            wrappedValue: ChatDetailViewModel(
                chatId: chat.id,
                repository: repository,
                userRepository: userRepository,
                otherUserId: otherUserId
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            HStack {
                                if message.senderId == currentUserId {
                                    Spacer()
                                }

                                VStack(
                                    alignment: message.senderId == currentUserId ? .trailing : .leading,
                                    spacing: 4
                                ) {
                                    Text(message.text)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(
                                            message.senderId == currentUserId
                                            ? AppColors.primary
                                            : Color.gray.opacity(0.15)
                                        )
                                        .foregroundStyle(
                                            message.senderId == currentUserId
                                            ? Color.white
                                            : AppColors.textPrimary
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                                    Text(timeString(from: message.createdAt))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                .id(message.id)

                                if message.senderId != currentUserId {
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    guard let lastId = viewModel.messages.last?.id else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
                .onAppear {
                    if let lastId = viewModel.messages.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }

            Divider()

            HStack(spacing: 12) {
                TextField("Write a message...", text: $viewModel.messageText)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button {
                    Task {
                        await viewModel.sendMessage()
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(AppColors.primary)
                        .clipShape(Circle())
                }
                .disabled(viewModel.isSending)
            }
            .padding()
            .background(AppColors.background)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavigationLink {
                    PublicUserProfileView(
                        userId: otherUserId,
                        userRepository: userRepository,
                        reviewRepository: reviewRepository,
                        taskRepository: taskRepository
                    )
                } label: {
                    HStack(spacing: 6) {
                        Text(viewModel.otherUsername ?? "User")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
        }
        .task {
            await viewModel.loadOtherUser()
        }
        .onAppear {
            viewModel.startListening()

            Task {
                try? await notificationRepository.markChatMessagesAsRead(
                    for: currentUserId,
                    chatId: chat.id
                )
            }
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }

    private var otherUserId: String {
        chat.creatorId == currentUserId
            ? chat.applicantId
            : chat.creatorId
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}
