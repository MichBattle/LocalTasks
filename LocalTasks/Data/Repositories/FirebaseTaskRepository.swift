import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseTaskRepository: TaskRepository {
    private let db = Firestore.firestore()
    private let auth = Auth.auth()

    func fetchFeedTasks(city: String?) async throws -> [TaskItem] {
        var query: Query = db.collection("tasks")
            .order(by: "createdAt", descending: true)

        if let city, !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            query = query.whereField("city", isEqualTo: city)
        }

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { try? mapTask(document: $0) }
    }

    func createTask(input: CreateTaskInput, imageDataList: [Data]) async throws {
        guard let currentUser = auth.currentUser else {
            throw NSError(
                domain: "FirebaseTaskRepository",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user"]
            )
        }

        let userSnapshot = try await db.collection("users").document(currentUser.uid).getDocument()

        guard let userData = userSnapshot.data(),
              let username = userData["username"] as? String else {
            throw NSError(
                domain: "FirebaseTaskRepository",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "User profile not found"]
            )
        }

        let taskRef = db.collection("tasks").document()
        let privateTaskRef = db.collection("tasks_private").document(taskRef.documentID)
        let now = Date()

        let publicData: [String: Any] = [
            "creatorId": currentUser.uid,
            "creatorUsername": username,
            "title": input.title,
            "description": input.description,
            "category": input.category.rawValue,
            "city": input.city,
            "price": input.price as Any,
            "photoURLs": [],
            "status": TaskStatus.open.rawValue,
            "acceptedUserId": NSNull(),
            "createdAt": Timestamp(date: now),
            "updatedAt": Timestamp(date: now)
        ]

        let privateData: [String: Any] = [
            "taskId": taskRef.documentID,
            "fullAddress": input.fullAddress
        ]

        let batch = db.batch()
        batch.setData(publicData, forDocument: taskRef)
        batch.setData(privateData, forDocument: privateTaskRef)
        try await batch.commit()
    }

    func fetchTasksCreatedByUser(userId: String) async throws -> [TaskItem] {
        let snapshot = try await db.collection("tasks")
            .whereField("creatorId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? mapTask(document: $0) }
    }

    func fetchTask(by id: String) async throws -> TaskItem? {
        let snapshot = try await db.collection("tasks").document(id).getDocument()
        guard snapshot.exists, let data = snapshot.data() else { return nil }

        guard
            let creatorId = data["creatorId"] as? String,
            let creatorUsername = data["creatorUsername"] as? String,
            let title = data["title"] as? String,
            let description = data["description"] as? String,
            let categoryRawValue = data["category"] as? String,
            let category = TaskCategory(rawValue: categoryRawValue),
            let city = data["city"] as? String,
            let statusRawValue = data["status"] as? String,
            let status = TaskStatus(rawValue: statusRawValue)
        else {
            return nil
        }

        return TaskItem(
            id: snapshot.documentID,
            creatorId: creatorId,
            creatorUsername: creatorUsername,
            title: title,
            description: description,
            category: category,
            city: city,
            price: data["price"] as? Double,
            photoURLs: data["photoURLs"] as? [String] ?? [],
            status: status,
            acceptedUserId: data["acceptedUserId"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    private func mapTask(document: QueryDocumentSnapshot) throws -> TaskItem {
        let data = document.data()

        guard
            let creatorId = data["creatorId"] as? String,
            let creatorUsername = data["creatorUsername"] as? String,
            let title = data["title"] as? String,
            let description = data["description"] as? String,
            let categoryRawValue = data["category"] as? String,
            let category = TaskCategory(rawValue: categoryRawValue),
            let city = data["city"] as? String,
            let statusRawValue = data["status"] as? String,
            let status = TaskStatus(rawValue: statusRawValue)
        else {
            throw NSError(
                domain: "FirebaseTaskRepository",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Invalid task document structure"]
            )
        }

        return TaskItem(
            id: document.documentID,
            creatorId: creatorId,
            creatorUsername: creatorUsername,
            title: title,
            description: description,
            category: category,
            city: city,
            price: data["price"] as? Double,
            photoURLs: data["photoURLs"] as? [String] ?? [],
            status: status,
            acceptedUserId: data["acceptedUserId"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
