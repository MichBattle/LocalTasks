import Foundation
import FirebaseFirestore

final class FirebaseNotificationRepository: NotificationRepository {
    private let db = Firestore.firestore()

    func createNotification(_ input: CreateNotificationInput) async throws {
        let ref = db.collection("notifications").document()
        let now = Date()

        try await ref.setData([
            "recipientId": input.recipientId,
            "type": input.type.rawValue,
            "title": input.title,
            "message": input.message,
            "relatedTaskId": input.relatedTaskId as Any,
            "relatedChatId": input.relatedChatId as Any,
            "isRead": false,
            "createdAt": Timestamp(date: now)
        ])
    }

    func observeNotifications(
        for userId: String,
        onChange: @escaping (Result<[AppNotification], Error>) -> Void
    ) -> any ListenerRegistration {
        db.collection("notifications")
            .whereField("recipientId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                let notifications = snapshot?.documents.compactMap {
                    self.mapNotification($0)
                } ?? []

                onChange(.success(notifications))
            }
    }

    func markAsRead(notificationId: String) async throws {
        try await db.collection("notifications")
            .document(notificationId)
            .updateData([
                "isRead": true
            ])
    }

    func markAllAsRead(for userId: String) async throws {
        let snapshot = try await db.collection("notifications")
            .whereField("recipientId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()

        let batch = db.batch()

        for document in snapshot.documents {
            batch.updateData(["isRead": true], forDocument: document.reference)
        }

        try await batch.commit()
    }

    private func mapNotification(_ document: QueryDocumentSnapshot) -> AppNotification? {
        let data = document.data()

        guard
            let recipientId = data["recipientId"] as? String,
            let typeRaw = data["type"] as? String,
            let type = AppNotificationType(rawValue: typeRaw),
            let title = data["title"] as? String,
            let message = data["message"] as? String,
            let isRead = data["isRead"] as? Bool
        else {
            return nil
        }

        return AppNotification(
            id: document.documentID,
            recipientId: recipientId,
            type: type,
            title: title,
            message: message,
            relatedTaskId: data["relatedTaskId"] as? String,
            relatedChatId: data["relatedChatId"] as? String,
            isRead: isRead,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
