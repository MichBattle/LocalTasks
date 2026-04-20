import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class MessagesListViewModel: ObservableObject {
    @Published var rows: [ChatListRowItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let chatRepository: ChatRepository
    private let userRepository: UserRepository
    private let taskRepository: TaskRepository
    private let currentUserId: String

    private var listener: (any ListenerRegistration)?

    init(
        chatRepository: ChatRepository,
        userRepository: UserRepository,
        taskRepository: TaskRepository,
        currentUserId: String
    ) {
        self.chatRepository = chatRepository
        self.userRepository = userRepository
        self.taskRepository = taskRepository
        self.currentUserId = currentUserId
    }

    func startListening() {
        guard !currentUserId.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        listener?.remove()
        listener = chatRepository.observeChats(for: currentUserId) { [weak self] result in
            guard let self else { return }

            Task { @MainActor in
                switch result {
                case .success(let chats):
                    do {
                        self.rows = try await self.buildRows(from: chats)
                        self.isLoading = false
                    } catch {
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                    }

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    deinit {
        listener?.remove()
    }

    private func buildRows(from chats: [ChatItem]) async throws -> [ChatListRowItem] {
        var result: [ChatListRowItem] = []

        for chat in chats {
            let otherUserId = chat.creatorId == currentUserId ? chat.applicantId : chat.creatorId
            let otherUser = try await userRepository.fetchUser(by: otherUserId)
            let task = try await taskRepository.fetchTask(by: chat.taskId)

            let row = ChatListRowItem(
                id: chat.id,
                chat: chat,
                otherUserName: otherUser?.username ?? "Unknown user",
                taskCategoryName: task?.category.displayName ?? "Unknown task",
                lastMessagePreview: chat.lastMessageText ?? "No messages yet",
                lastMessageAt: chat.lastMessageAt
            )

            result.append(row)
        }

        return result
    }
}
