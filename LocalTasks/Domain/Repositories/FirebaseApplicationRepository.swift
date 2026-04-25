import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseApplicationRepository: ApplicationRepository {
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    private let notificationRepository: NotificationRepository

    init(notificationRepository: NotificationRepository) {
        self.notificationRepository = notificationRepository
    }

    func apply(to input: CreateApplicationInput) async throws {
        guard let currentUser = auth.currentUser else {
            throw NSError(
                domain: "FirebaseApplicationRepository",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Authentication required"]
            )
        }

        if currentUser.uid == input.taskCreatorId {
            throw NSError(
                domain: "FirebaseApplicationRepository",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "You cannot apply to your own task"]
            )
        }

        let alreadyApplied = try await hasApplied(taskId: input.taskId, applicantId: currentUser.uid)
        if alreadyApplied {
            throw NSError(
                domain: "FirebaseApplicationRepository",
                code: 409,
                userInfo: [NSLocalizedDescriptionKey: "You already applied to this task"]
            )
        }

        let applicationRef = db.collection("applications").document()
        let now = Date()

        let applicantSnapshot = try await db.collection("users").document(currentUser.uid).getDocument()
        let applicantData = applicantSnapshot.data() ?? [:]
        let applicantUsername = applicantData["username"] as? String ?? "Unknown user"

        let taskSnapshot = try await db.collection("tasks").document(input.taskId).getDocument()
        let taskData = taskSnapshot.data() ?? [:]
        let taskTitle = taskData["title"] as? String ?? "this task"

        let data: [String: Any] = [
            "taskId": input.taskId,
            "taskCreatorId": input.taskCreatorId,
            "applicantId": currentUser.uid,
            "status": ApplicationStatus.pending.rawValue,
            "message": input.message ?? "",
            "createdAt": Timestamp(date: now),
            "updatedAt": Timestamp(date: now)
        ]

        try await applicationRef.setData(data)

        let chat = try await getOrCreateChat(
            taskId: input.taskId,
            creatorId: input.taskCreatorId,
            applicantId: currentUser.uid
        )

        try await sendSystemMessage(
            chatId: chat.id,
            senderId: currentUser.uid,
            text: "Ciao sono \(applicantUsername), mi applico per \(taskTitle)"
        )

        try await notificationRepository.createNotification(
            CreateNotificationInput(
                recipientId: input.taskCreatorId,
                type: .newApplication,
                title: "New application",
                message: "\(applicantUsername) applied to \(taskTitle)",
                relatedTaskId: input.taskId,
                relatedChatId: chat.id
            )
        )
    }

    func hasApplied(taskId: String, applicantId: String) async throws -> Bool {
        let snapshot = try await db.collection("applications")
            .whereField("taskId", isEqualTo: taskId)
            .whereField("applicantId", isEqualTo: applicantId)
            .limit(to: 1)
            .getDocuments()

        return !snapshot.documents.isEmpty
    }

    func fetchApplicationsByApplicant(userId: String) async throws -> [ApplicationItem] {
        let snapshot = try await db.collection("applications")
            .whereField("applicantId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { document in
            let data = document.data()

            guard
                let taskId = data["taskId"] as? String,
                let taskCreatorId = data["taskCreatorId"] as? String,
                let statusRaw = data["status"] as? String,
                let status = ApplicationStatus(rawValue: statusRaw)
            else {
                return nil
            }

            return ApplicationItem(
                id: document.documentID,
                taskId: taskId,
                taskCreatorId: taskCreatorId,
                applicantId: data["applicantId"] as? String ?? "",
                status: status,
                message: data["message"] as? String,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
            )
        }
    }

    func fetchApplicationsForTask(taskId: String) async throws -> [ApplicationDetailsItem] {
        let applicationsSnapshot = try await db.collection("applications")
            .whereField("taskId", isEqualTo: taskId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        var results: [ApplicationDetailsItem] = []

        for document in applicationsSnapshot.documents {
            let data = document.data()

            guard
                let applicantId = data["applicantId"] as? String,
                let taskCreatorId = data["taskCreatorId"] as? String,
                let statusRaw = data["status"] as? String,
                let status = ApplicationStatus(rawValue: statusRaw)
            else {
                continue
            }

            let userSnapshot = try await db.collection("users").document(applicantId).getDocument()
            let userData = userSnapshot.data() ?? [:]

            let item = ApplicationDetailsItem(
                id: document.documentID,
                taskId: taskId,
                taskCreatorId: taskCreatorId,
                applicantId: applicantId,
                applicantUsername: userData["username"] as? String ?? "Unknown user",
                applicantCity: userData["cityName"] as? String ?? userData["city"] as? String ?? "",
                applicantRatingAvg: userData["ratingAvg"] as? Double ?? 0.0,
                applicantRatingCount: userData["ratingCount"] as? Int ?? 0,
                message: data["message"] as? String,
                status: status,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            )

            results.append(item)
        }

        return results
    }

    func updateApplicationStatus(
        applicationId: String,
        taskId: String,
        applicantId: String,
        status: ApplicationStatus
    ) async throws {
        let applicationRef = db.collection("applications").document(applicationId)
        let taskRef = db.collection("tasks").document(taskId)
        let now = Date()

        let taskSnapshot = try await taskRef.getDocument()
        let taskData = taskSnapshot.data() ?? [:]
        let taskTitle = taskData["title"] as? String ?? "this task"
        let creatorId = taskData["creatorId"] as? String ?? ""

        let applicantSnapshot = try await db.collection("users").document(applicantId).getDocument()
        let applicantData = applicantSnapshot.data() ?? [:]
        let applicantUsername = applicantData["username"] as? String ?? "This user"

        let batch = db.batch()

        batch.updateData([
            "status": status.rawValue,
            "updatedAt": Timestamp(date: now)
        ], forDocument: applicationRef)

        if status == .accepted {
            batch.updateData([
                "status": TaskStatus.inProgress.rawValue,
                "acceptedUserId": applicantId,
                "updatedAt": Timestamp(date: now)
            ], forDocument: taskRef)

            let otherApplications = try await db.collection("applications")
                .whereField("taskId", isEqualTo: taskId)
                .getDocuments()

            for document in otherApplications.documents where document.documentID != applicationId {
                batch.updateData([
                    "status": ApplicationStatus.rejected.rawValue,
                    "updatedAt": Timestamp(date: now)
                ], forDocument: document.reference)
            }
        }

        try await batch.commit()

        let chat = try await getOrCreateChat(
            taskId: taskId,
            creatorId: creatorId,
            applicantId: applicantId
        )

        let text: String
        let notificationType: AppNotificationType
        let notificationTitle: String

        switch status {
        case .accepted:
            let address = try await fetchPrivateAddress(taskId: taskId) ?? "Address unavailable"
            text = "\(applicantUsername), sei stato accettato per \(taskTitle). Indirizzo: \(address)"
            notificationType = .applicationAccepted
            notificationTitle = "Application accepted"

        case .rejected:
            text = "\(applicantUsername), la tua candidatura per \(taskTitle) è stata rifiutata"
            notificationType = .applicationRejected
            notificationTitle = "Application rejected"

        case .pending:
            text = "\(applicantUsername), la tua candidatura per \(taskTitle) è tornata in pending"
            notificationType = .newApplication
            notificationTitle = "Application reset"

        case .cancelled:
            text = "\(applicantUsername), la tua candidatura per \(taskTitle) è stata annullata"
            notificationType = .applicationRejected
            notificationTitle = "Application cancelled"
        }

        try await sendSystemMessage(
            chatId: chat.id,
            senderId: creatorId,
            text: text
        )

        try await notificationRepository.createNotification(
            CreateNotificationInput(
                recipientId: applicantId,
                type: notificationType,
                title: notificationTitle,
                message: text,
                relatedTaskId: taskId,
                relatedChatId: chat.id
            )
        )
    }

    func resetApplicationStatus(
        applicationId: String,
        taskId: String,
        applicantId: String
    ) async throws {
        let applicationRef = db.collection("applications").document(applicationId)
        let taskRef = db.collection("tasks").document(taskId)
        let now = Date()

        let taskSnapshot = try await taskRef.getDocument()
        let taskData = taskSnapshot.data() ?? [:]

        let currentAcceptedUserId = taskData["acceptedUserId"] as? String
        let currentTaskStatusRaw = taskData["status"] as? String ?? TaskStatus.open.rawValue
        let currentTaskStatus = TaskStatus(rawValue: currentTaskStatusRaw) ?? .open

        let batch = db.batch()

        batch.updateData([
            "status": ApplicationStatus.pending.rawValue,
            "updatedAt": Timestamp(date: now)
        ], forDocument: applicationRef)

        if currentAcceptedUserId == applicantId && currentTaskStatus == .inProgress {
            batch.updateData([
                "status": TaskStatus.open.rawValue,
                "acceptedUserId": NSNull(),
                "updatedAt": Timestamp(date: now)
            ], forDocument: taskRef)
        }

        try await batch.commit()
    }

    private func getOrCreateChat(
        taskId: String,
        creatorId: String,
        applicantId: String
    ) async throws -> ChatItem {
        let snapshot = try await db.collection("chats")
            .whereField("taskId", isEqualTo: taskId)
            .whereField("creatorId", isEqualTo: creatorId)
            .whereField("applicantId", isEqualTo: applicantId)
            .limit(to: 1)
            .getDocuments()

        if let existing = snapshot.documents.first {
            let data = existing.data()

            return ChatItem(
                id: existing.documentID,
                taskId: data["taskId"] as? String ?? "",
                creatorId: data["creatorId"] as? String ?? "",
                applicantId: data["applicantId"] as? String ?? "",
                participantIds: data["participantIds"] as? [String] ?? [],
                lastMessageText: emptyToNil(data["lastMessageText"] as? String),
                lastMessageSenderId: emptyToNil(data["lastMessageSenderId"] as? String),
                lastMessageAt: (data["lastMessageAt"] as? Timestamp)?.dateValue(),
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            )
        }

        let chatRef = db.collection("chats").document()
        let now = Date()

        let data: [String: Any] = [
            "taskId": taskId,
            "creatorId": creatorId,
            "applicantId": applicantId,
            "participantIds": [creatorId, applicantId],
            "lastMessageText": "",
            "lastMessageSenderId": "",
            "lastMessageAt": Timestamp(date: now),
            "createdAt": Timestamp(date: now)
        ]

        try await chatRef.setData(data)

        return ChatItem(
            id: chatRef.documentID,
            taskId: taskId,
            creatorId: creatorId,
            applicantId: applicantId,
            participantIds: [creatorId, applicantId],
            lastMessageText: nil,
            lastMessageSenderId: nil,
            lastMessageAt: now,
            createdAt: now
        )
    }

    private func sendSystemMessage(chatId: String, senderId: String, text: String) async throws {
        let now = Date()
        let chatRef = db.collection("chats").document(chatId)
        let messageRef = chatRef.collection("messages").document()

        let batch = db.batch()

        batch.setData([
            "senderId": senderId,
            "text": text,
            "createdAt": Timestamp(date: now),
            "isRead": false
        ], forDocument: messageRef)

        batch.updateData([
            "lastMessageText": text,
            "lastMessageSenderId": senderId,
            "lastMessageAt": Timestamp(date: now)
        ], forDocument: chatRef)

        try await batch.commit()
    }

    private func fetchPrivateAddress(taskId: String) async throws -> String? {
        let snapshot = try await db.collection("tasks_private").document(taskId).getDocument()
        let data = snapshot.data() ?? [:]
        return data["fullAddress"] as? String
    }

    private func emptyToNil(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value
    }
}
