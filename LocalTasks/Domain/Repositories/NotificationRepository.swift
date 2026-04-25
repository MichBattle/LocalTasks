import Foundation
import FirebaseFirestore

protocol NotificationRepository {
    func createNotification(_ input: CreateNotificationInput) async throws

    func observeNotifications(
        for userId: String,
        onChange: @escaping (Result<[AppNotification], Error>) -> Void
    ) -> any ListenerRegistration

    func markAsRead(notificationId: String) async throws
    func markAllAsRead(for userId: String) async throws

    func markChatMessagesAsRead(for userId: String, chatId: String) async throws
}
