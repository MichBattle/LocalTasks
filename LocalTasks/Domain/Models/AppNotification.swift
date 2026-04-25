import Foundation

struct AppNotification: Identifiable, Codable, Hashable {
    let id: String
    let recipientId: String
    let type: AppNotificationType
    let title: String
    let message: String
    let relatedTaskId: String?
    let relatedChatId: String?
    let isRead: Bool
    let createdAt: Date
}
