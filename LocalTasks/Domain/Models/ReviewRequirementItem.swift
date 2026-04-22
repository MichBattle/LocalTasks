import Foundation

struct ReviewRequirementItem: Identifiable, Codable {
    let id: String
    let taskId: String
    let reviewerId: String
    let reviewedUserId: String
    let status: ReviewRequirementStatus
    let createdAt: Date
    let completedAt: Date?
}
