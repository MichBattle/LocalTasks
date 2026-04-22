import Foundation

struct ReviewItem: Identifiable, Codable {
    let id: String
    let taskId: String
    let reviewerId: String
    let reviewedUserId: String
    let rating: Int
    let comment: String
    let createdAt: Date
}
