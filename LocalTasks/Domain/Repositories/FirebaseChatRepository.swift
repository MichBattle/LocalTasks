import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseChatRepository: ChatRepository {
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    private let notificationRepository: NotificationRepository

    init(notificationRepository: NotificationRepository) {
        self.notificationRepository = notificationRepository
    }

    func fetchChats(for userId: String) async throws -> [ChatItem] {
        let snapshot = try await db.collection("chats")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? mapChat($0) }
    }

    func fetchMessages(chatId: String) async throws -> [MessageItem] {
        let snapshot = try await db.collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "createdAt", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { try? mapMessage($0) }
    }

    func observeChats(
        for userId: String,
        onChange: @escaping (Result<[ChatItem], Error>) -> Void
    ) -> any ListenerRegistration {
        db.collection("chats")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                let chats = snapshot?.documents.compactMap { try? self.mapChat($0) } ?? []
                onChange(.success(chats))
            }
    }

    func observeMessages(
        chatId: String,
        onChange: @escaping (Result<[MessageItem], Error>) -> Void
    ) -> any ListenerRegistration {
        db.collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                let messages = snapshot?.documents.compactMap { try? self.mapMessage($0) } ?? []
                onChange(.success(messages))
            }
    }

    func sendMessage(_ input: SendMessageInput) async throws {
        guard let currentUser = auth.currentUser else {
            throw NSError(
                domain: "FirebaseChatRepository",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Authentication required"]
            )
        }

        let trimmedText = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let chatRef = db.collection("chats").document(input.chatId)
        let messageRef = chatRef.collection("messages").document()
        let now = Date()

        let batch = db.batch()

        batch.setData([
            "senderId": currentUser.uid,
            "text": trimmedText,
            "createdAt": Timestamp(date: now),
            "isRead": false
        ], forDocument: messageRef)

        batch.updateData([
            "lastMessageText": trimmedText,
            "lastMessageSenderId": currentUser.uid,
            "lastMessageAt": Timestamp(date: now)
        ], forDocument: chatRef)

        try await batch.commit()

        try await notifyOtherParticipants(
            chatId: input.chatId,
            senderId: currentUser.uid
        )
    }

    func getOrCreateChat(
        taskId: String,
        creatorId: String,
        applicantId: String
    ) async throws -> ChatItem {
        let snapshot = try await db.collection("chats")
            .whereField("taskId", isEqualTo: taskId)
            .whereField("creatorId", isEqualTo: creatorId)
            .whereField("applicantId", isEqualTo: applicantId)
            .limit(to: 1)
            .getDocuments()

        if let existing = snapshot.documents.first {
            return try mapChat(existing)
        }

        let chatRef = db.collection("chats").document()
        let now = Date()

        let data: [String: Any] = [
            "taskId": taskId,
            "creatorId": creatorId,
            "applicantId": applicantId,
            "participantIds": [creatorId, applicantId],
            "lastMessageText": "",
            "lastMessageSenderId": "",
            "lastMessageAt": Timestamp(date: now),
            "createdAt": Timestamp(date: now)
        ]

        try await chatRef.setData(data)

        return ChatItem(
            id: chatRef.documentID,
            taskId: taskId,
            creatorId: creatorId,
            applicantId: applicantId,
            participantIds: [creatorId, applicantId],
            lastMessageText: nil,
            lastMessageSenderId: nil,
            lastMessageAt: now,
            createdAt: now
        )
    }

    private func notifyOtherParticipants(chatId: String, senderId: String) async throws {
        let chatSnapshot = try await db.collection("chats")
            .document(chatId)
            .getDocument()

        let chatData = chatSnapshot.data() ?? [:]

        let participantIds = chatData["participantIds"] as? [String] ?? []
        let recipientIds = participantIds.filter { $0 != senderId }

        guard !recipientIds.isEmpty else { return }

        let senderSnapshot = try await db.collection("users")
            .document(senderId)
            .getDocument()

        let senderData = senderSnapshot.data() ?? [:]
        let senderUsername = senderData["username"] as? String ?? "Someone"

        let taskId = chatData["taskId"] as? String

        for recipientId in recipientIds {
            try await notificationRepository.createNotification(
                CreateNotificationInput(
                    recipientId: recipientId,
                    type: .newMessage,
                    title: "New message",
                    message: "\(senderUsername) sent you a message",
                    relatedTaskId: taskId,
                    relatedChatId: chatId
                )
            )
        }
    }

    private func mapChat(_ document: QueryDocumentSnapshot) throws -> ChatItem {
        let data = document.data()

        return ChatItem(
            id: document.documentID,
            taskId: data["taskId"] as? String ?? "",
            creatorId: data["creatorId"] as? String ?? "",
            applicantId: data["applicantId"] as? String ?? "",
            participantIds: data["participantIds"] as? [String] ?? [],
            lastMessageText: emptyToNil(data["lastMessageText"] as? String),
            lastMessageSenderId: emptyToNil(data["lastMessageSenderId"] as? String),
            lastMessageAt: (data["lastMessageAt"] as? Timestamp)?.dateValue(),
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    private func mapMessage(_ document: QueryDocumentSnapshot) throws -> MessageItem {
        let data = document.data()

        return MessageItem(
            id: document.documentID,
            senderId: data["senderId"] as? String ?? "",
            text: data["text"] as? String ?? "",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            isRead: data["isRead"] as? Bool ?? false
        )
    }

    private func emptyToNil(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value
    }
}
