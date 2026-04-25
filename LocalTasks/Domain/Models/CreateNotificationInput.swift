import Foundation

struct CreateNotificationInput {
    let recipientId: String
    let type: AppNotificationType
    let title: String
    let message: String
    let relatedTaskId: String?
    let relatedChatId: String?
}
