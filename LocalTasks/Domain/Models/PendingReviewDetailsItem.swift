import Foundation

struct PendingReviewDetailsItem: Identifiable {
    let id: String
    let taskId: String
    let reviewedUserId: String
    let reviewedUsername: String
    let taskTitle: String
    let createdAt: Date
}
