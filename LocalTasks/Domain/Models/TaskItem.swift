import Foundation

struct TaskItem: Identifiable, Codable, Hashable {
    let id: String
    let creatorId: String
    let creatorUsername: String
    let title: String
    let description: String
    let category: TaskCategory
    let city: String
    let price: Double?
    let photoURLs: [String]
    let status: TaskStatus
    let acceptedUserId: String?
    let approxLatitude: Double?
    let approxLongitude: Double?
    let createdAt: Date
    let updatedAt: Date
}
