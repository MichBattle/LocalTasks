import Foundation

protocol ApplicationRepository {
    func apply(to input: CreateApplicationInput) async throws
    func hasApplied(taskId: String, applicantId: String) async throws -> Bool

    func fetchApplicationsByApplicant(userId: String) async throws -> [ApplicationItem]
    func fetchApplicationsForTask(taskId: String) async throws -> [ApplicationDetailsItem]

    func updateApplicationStatus(
        applicationId: String,
        taskId: String,
        applicantId: String,
        status: ApplicationStatus
    ) async throws

    func resetApplicationStatus(
        applicationId: String,
        taskId: String,
        applicantId: String
    ) async throws
}
