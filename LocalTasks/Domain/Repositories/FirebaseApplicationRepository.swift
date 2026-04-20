import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseApplicationRepository: ApplicationRepository {
    private let db = Firestore.firestore()
    private let auth = Auth.auth()

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
                applicantCity: userData["city"] as? String ?? "",
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
    }
}
