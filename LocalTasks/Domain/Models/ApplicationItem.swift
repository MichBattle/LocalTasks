import Foundation

enum ApplicationStatus: String, Codable {
    case pending
    case accepted
    case rejected
    case cancelled
}

struct ApplicationItem: Identifiable, Codable {
    let id: String
    let taskId: String
    let taskCreatorId: String
    let applicantId: String
    let status: ApplicationStatus
    let message: String?
    let createdAt: Date
    let updatedAt: Date
}
