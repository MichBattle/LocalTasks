import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseAuthRepository: AuthRepository {
    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    func getCurrentUserId() -> String? {
        auth.currentUser?.uid
    }

    func signOut() throws {
        try auth.signOut()
    }

    func fetchCurrentUserProfile() async throws -> AppUser? {
        guard let uid = auth.currentUser?.uid else { return nil }

        let snapshot = try await db.collection("users").document(uid).getDocument()

        guard let data = snapshot.data() else { return nil }
        return try mapUser(id: uid, data: data)
    }

    func signIn(email: String, password: String) async throws -> AppUser {
        let result = try await auth.signIn(withEmail: email, password: password)
        let uid = result.user.uid

        let snapshot = try await db.collection("users").document(uid).getDocument()

        guard let data = snapshot.data() else {
            throw NSError(
                domain: "AuthRepository",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "User profile not found"]
            )
        }

        return try mapUser(id: uid, data: data)
    }

    func signUp(email: String, password: String, username: String, city: String) async throws -> AppUser {
        let usernameKey = username.lowercased()
        let usernameRef = db.collection("usernames").document(usernameKey)

        let createdUser = try await auth.createUser(withEmail: email, password: password)
        let uid = createdUser.user.uid
        let now = Date()

        let userData: [String: Any] = [
            "email": email,
            "username": username,
            "city": city,
            "bio": "",
            "profileImageURL": "",
            "ratingAvg": 0.0,
            "ratingCount": 0,
            "createdAt": Timestamp(date: now),
            "updatedAt": Timestamp(date: now)
        ]

        do {
            try await db.runTransaction { transaction, errorPointer in
                let usernameDoc: DocumentSnapshot
                do {
                    try usernameDoc = transaction.getDocument(usernameRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }

                if usernameDoc.exists {
                    let error = NSError(
                        domain: "AuthRepository",
                        code: 409,
                        userInfo: [NSLocalizedDescriptionKey: "Username already in use"]
                    )
                    errorPointer?.pointee = error
                    return nil
                }

                let userRef = self.db.collection("users").document(uid)
                transaction.setData(["userId": uid], forDocument: usernameRef)
                transaction.setData(userData, forDocument: userRef)
                return nil
            }

            return AppUser(
                id: uid,
                email: email,
                username: username,
                city: city,
                bio: "",
                profileImageURL: nil,
                ratingAvg: 0.0,
                ratingCount: 0,
                createdAt: now,
                updatedAt: now
            )
        } catch {
            if let user = auth.currentUser {
                try? await user.delete()
            }
            throw error
        }
    }

    private func mapUser(id: String, data: [String: Any]) throws -> AppUser {
        AppUser(
            id: id,
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
