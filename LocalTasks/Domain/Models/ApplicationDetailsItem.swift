import Foundation

struct ApplicationDetailsItem: Identifiable {
    let id: String
    let taskId: String
    let taskCreatorId: String
    let applicantId: String
    let applicantUsername: String
    let applicantCity: String
    let applicantRatingAvg: Double
    let applicantRatingCount: Int
    let message: String?
    let status: ApplicationStatus
    let createdAt: Date
}
