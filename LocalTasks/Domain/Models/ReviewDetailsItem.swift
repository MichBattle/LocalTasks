import Foundation

struct ReviewDetailsItem: Identifiable, Hashable {
    let id: String
    let taskId: String
    let reviewerId: String
    let reviewerUsername: String
    let reviewedUserId: String
    let rating: Int
    let comment: String
    let createdAt: Date
}
