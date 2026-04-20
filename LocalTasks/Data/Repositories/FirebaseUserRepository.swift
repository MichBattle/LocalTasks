import Foundation
import FirebaseFirestore

final class FirebaseUserRepository: UserRepository {
    private let db = Firestore.firestore()

    func fetchUser(by id: String) async throws -> AppUser? {
        let snapshot = try await db.collection("users").document(id).getDocument()

        guard let data = snapshot.data() else { return nil }

        return AppUser(
            id: snapshot.documentID,
            email: data["email"] as? String ?? "",
            username: data["username"] as? String ?? "",
            city: data["city"] as? String ?? "",
            bio: data["bio"] as? String ?? "",
            profileImageURL: {
                let value = data["profileImageURL"] as? String ?? ""
                return value.isEmpty ? nil : value
            }(),
            ratingAvg: data["ratingAvg"] as? Double ?? 0.0,
            ratingCount: data["ratingCount"] as? Int ?? 0,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
