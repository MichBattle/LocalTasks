import Foundation

struct ChatItem: Identifiable, Codable {
    let id: String
    let taskId: String
    let creatorId: String
    let applicantId: String
    let participantIds: [String]
    let lastMessageText: String?
    let lastMessageSenderId: String?
    let lastMessageAt: Date?
    let createdAt: Date
}
