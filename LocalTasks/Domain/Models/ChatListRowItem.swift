import Foundation

struct ChatListRowItem: Identifiable {
    let id: String
    let chat: ChatItem
    let otherUserName: String
    let taskCategoryName: String
    let lastMessagePreview: String
    let lastMessageAt: Date?
}
