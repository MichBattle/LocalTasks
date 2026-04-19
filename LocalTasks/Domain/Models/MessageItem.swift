import Foundation

struct MessageItem: Identifiable, Codable {
    let id: String
    let senderId: String
    let text: String
    let createdAt: Date
    let isRead: Bool
}
