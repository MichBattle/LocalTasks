import Foundation
import FirebaseFirestore

protocol ChatRepository {
    func fetchChats(for userId: String) async throws -> [ChatItem]
    func fetchMessages(chatId: String) async throws -> [MessageItem]
    func sendMessage(_ input: SendMessageInput) async throws

    func getOrCreateChat(
        taskId: String,
        creatorId: String,
        applicantId: String
    ) async throws -> ChatItem

    func observeChats(
        for userId: String,
        onChange: @escaping (Result<[ChatItem], Error>) -> Void
    ) -> any ListenerRegistration

    func observeMessages(
        chatId: String,
        onChange: @escaping (Result<[MessageItem], Error>) -> Void
    ) -> any ListenerRegistration
}
