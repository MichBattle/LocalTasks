import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseTaskRepository: TaskRepository {
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    private let notificationRepository: NotificationRepository

    init(notificationRepository: NotificationRepository) {
        self.notificationRepository = notificationRepository
    }

    func fetchFeedTasks(city: String?) async throws -> [TaskItem] {
        var query: Query = db.collection("tasks")
            .whereField("status", isEqualTo: TaskStatus.open.rawValue)
            .order(by: "createdAt", descending: true)

        if let city, !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            query = query.whereField("cityCanonical", isEqualTo: city)
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

        let approx = Self.generateApproximateCoordinate(
            latitude: input.address.latitude,
            longitude: input.address.longitude,
            minDistanceMeters: 700,
            maxDistanceMeters: 1800
        )

        let publicData: [String: Any] = [
            "creatorId": currentUser.uid,
            "creatorUsername": username,
            "title": input.title,
            "description": input.description,
            "category": input.category.rawValue,
            "cityName": input.address.cityName,
            "cityCanonical": input.address.cityCanonical,
            "price": input.price as Any,
            "photoURLs": [],
            "status": TaskStatus.open.rawValue,
            "acceptedUserId": NSNull(),
            "approxLatitude": approx.latitude,
            "approxLongitude": approx.longitude,
            "createdAt": Timestamp(date: now),
            "updatedAt": Timestamp(date: now)
        ]

        let privateData: [String: Any] = [
            "taskId": taskRef.documentID,
            "fullAddress": input.address.fullAddress,
            "exactLatitude": input.address.latitude,
            "exactLongitude": input.address.longitude
        ]

        let batch = db.batch()
        batch.setData(publicData, forDocument: taskRef)
        batch.setData(privateData, forDocument: privateTaskRef)
        try await batch.commit()

        try await notifyUsersInSameCity(
            creatorId: currentUser.uid,
            cityCanonical: input.address.cityCanonical,
            taskId: taskRef.documentID,
            taskTitle: input.title
        )
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
            let city = data["cityName"] as? String,
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
            approxLatitude: data["approxLatitude"] as? Double,
            approxLongitude: data["approxLongitude"] as? Double,
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
            let city = data["cityName"] as? String,
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
            approxLatitude: data["approxLatitude"] as? Double,
            approxLongitude: data["approxLongitude"] as? Double,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    private func notifyUsersInSameCity(
        creatorId: String,
        cityCanonical: String,
        taskId: String,
        taskTitle: String
    ) async throws {
        let usersSnapshot = try await db.collection("users")
            .whereField("cityCanonical", isEqualTo: cityCanonical)
            .getDocuments()

        for document in usersSnapshot.documents {
            let userId = document.documentID

            guard userId != creatorId else { continue }

            try await notificationRepository.createNotification(
                CreateNotificationInput(
                    recipientId: userId,
                    type: .newTaskInYourCity,
                    title: "New task in your city",
                    message: "A new task was created near you: \(taskTitle)",
                    relatedTaskId: taskId,
                    relatedChatId: nil
                )
            )
        }
    }

    private static func generateApproximateCoordinate(
        latitude: Double,
        longitude: Double,
        minDistanceMeters: Double,
        maxDistanceMeters: Double
    ) -> (latitude: Double, longitude: Double) {
        let distance = Double.random(in: minDistanceMeters...maxDistanceMeters)
        let bearing = Double.random(in: 0...(2 * .pi))

        let earthRadius = 6_371_000.0
        let latRad = latitude * .pi / 180
        let lonRad = longitude * .pi / 180

        let newLatRad = asin(
            sin(latRad) * cos(distance / earthRadius) +
            cos(latRad) * sin(distance / earthRadius) * cos(bearing)
        )

        let newLonRad = lonRad + atan2(
            sin(bearing) * sin(distance / earthRadius) * cos(latRad),
            cos(distance / earthRadius) - sin(latRad) * sin(newLatRad)
        )

        return (
            latitude: newLatRad * 180 / .pi,
            longitude: newLonRad * 180 / .pi
        )
    }
}
