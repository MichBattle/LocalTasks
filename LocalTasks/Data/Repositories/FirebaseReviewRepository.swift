import Foundation
import FirebaseFirestore

final class FirebaseReviewRepository: ReviewRepository {
    private let db = Firestore.firestore()

    func completeTask(task: TaskItem, currentUserId: String) async throws {
        guard task.creatorId == currentUserId else {
            throw NSError(
                domain: "FirebaseReviewRepository",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "Only the task creator can complete this task"]
            )
        }

        guard task.status == .inProgress else {
            throw NSError(
                domain: "FirebaseReviewRepository",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Task is not in progress"]
            )
        }

        guard let acceptedUserId = task.acceptedUserId, !acceptedUserId.isEmpty else {
            throw NSError(
                domain: "FirebaseReviewRepository",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "No accepted user for this task"]
            )
        }

        let taskRef = db.collection("tasks").document(task.id)
        let now = Date()

        let creatorRequirementRef = db.collection("review_requirements").document()
        let helperRequirementRef = db.collection("review_requirements").document()

        let batch = db.batch()

        batch.updateData([
            "status": TaskStatus.completed.rawValue,
            "updatedAt": Timestamp(date: now)
        ], forDocument: taskRef)

        batch.setData([
            "taskId": task.id,
            "reviewerId": task.creatorId,
            "reviewedUserId": acceptedUserId,
            "status": ReviewRequirementStatus.pending.rawValue,
            "createdAt": Timestamp(date: now),
            "completedAt": NSNull()
        ], forDocument: creatorRequirementRef)

        batch.setData([
            "taskId": task.id,
            "reviewerId": acceptedUserId,
            "reviewedUserId": task.creatorId,
            "status": ReviewRequirementStatus.pending.rawValue,
            "createdAt": Timestamp(date: now),
            "completedAt": NSNull()
        ], forDocument: helperRequirementRef)

        try await batch.commit()

        let chatSnapshot = try await db.collection("chats")
            .whereField("taskId", isEqualTo: task.id)
            .whereField("creatorId", isEqualTo: task.creatorId)
            .whereField("applicantId", isEqualTo: acceptedUserId)
            .limit(to: 1)
            .getDocuments()

        if let chatDocument = chatSnapshot.documents.first {
            let chatRef = db.collection("chats").document(chatDocument.documentID)
            let messageRef = chatRef.collection("messages").document()
            let completionText = "Il lavoro \"\(task.title)\" è stato segnato come completato. Ora entrambi dovete lasciare una recensione."

            let notifyBatch = db.batch()

            notifyBatch.setData([
                "senderId": task.creatorId,
                "text": completionText,
                "createdAt": Timestamp(date: now),
                "isRead": false
            ], forDocument: messageRef)

            notifyBatch.updateData([
                "lastMessageText": completionText,
                "lastMessageSenderId": task.creatorId,
                "lastMessageAt": Timestamp(date: now)
            ], forDocument: chatRef)

            try await notifyBatch.commit()
        }
    }

    func fetchPendingReviews(for userId: String) async throws -> [PendingReviewDetailsItem] {
        let snapshot = try await db.collection("review_requirements")
            .whereField("reviewerId", isEqualTo: userId)
            .whereField("status", isEqualTo: ReviewRequirementStatus.pending.rawValue)
            .getDocuments()

        var result: [PendingReviewDetailsItem] = []

        for document in snapshot.documents {
            let data = document.data()

            guard
                let taskId = data["taskId"] as? String,
                let reviewedUserId = data["reviewedUserId"] as? String
            else {
                continue
            }

            let userSnapshot = try await db.collection("users").document(reviewedUserId).getDocument()
            let userData = userSnapshot.data() ?? [:]

            let taskSnapshot = try await db.collection("tasks").document(taskId).getDocument()
            let taskData = taskSnapshot.data() ?? [:]

            let item = PendingReviewDetailsItem(
                id: document.documentID,
                taskId: taskId,
                reviewedUserId: reviewedUserId,
                reviewedUsername: userData["username"] as? String ?? "Unknown user",
                taskTitle: taskData["title"] as? String ?? "Unknown task",
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            )

            result.append(item)
        }

        return result
    }

    func submitReview(
        requirementId: String,
        taskId: String,
        reviewerId: String,
        reviewedUserId: String,
        rating: Int,
        comment: String
    ) async throws {
        guard (1...5).contains(rating) else {
            throw NSError(
                domain: "FirebaseReviewRepository",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Rating must be between 1 and 5"]
            )
        }

        let requirementRef = db.collection("review_requirements").document(requirementId)
        let reviewRef = db.collection("reviews").document()
        let reviewedUserRef = db.collection("users").document(reviewedUserId)
        let now = Date()

        let userSnapshot = try await reviewedUserRef.getDocument()
        let userData = userSnapshot.data() ?? [:]

        let currentAvg = userData["ratingAvg"] as? Double ?? 0.0
        let currentCount = userData["ratingCount"] as? Int ?? 0

        let newCount = currentCount + 1
        let newAvg = ((currentAvg * Double(currentCount)) + Double(rating)) / Double(newCount)

        let batch = db.batch()

        batch.setData([
            "taskId": taskId,
            "reviewerId": reviewerId,
            "reviewedUserId": reviewedUserId,
            "rating": rating,
            "comment": comment,
            "createdAt": Timestamp(date: now)
        ], forDocument: reviewRef)

        batch.updateData([
            "status": ReviewRequirementStatus.submitted.rawValue,
            "completedAt": Timestamp(date: now)
        ], forDocument: requirementRef)

        batch.updateData([
            "ratingAvg": newAvg,
            "ratingCount": newCount,
            "updatedAt": Timestamp(date: now)
        ], forDocument: reviewedUserRef)

        try await batch.commit()
    }

    func hasPendingReviews(userId: String) async throws -> Bool {
        let snapshot = try await db.collection("review_requirements")
            .whereField("reviewerId", isEqualTo: userId)
            .whereField("status", isEqualTo: ReviewRequirementStatus.pending.rawValue)
            .limit(to: 1)
            .getDocuments()

        return !snapshot.documents.isEmpty
    }
}
