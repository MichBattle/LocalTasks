import Foundation

struct AppUser: Identifiable, Codable {
    let id: String
    let email: String
    let username: String
    let city: String
    let bio: String
    let profileImageURL: String?
    let ratingAvg: Double
    let ratingCount: Int
    let createdAt: Date
    let updatedAt: Date
}
