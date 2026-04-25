import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var errorMessage: String?

    private let repository: NotificationRepository
    private var userId: String = ""
    private var listener: (any ListenerRegistration)?

    init(repository: NotificationRepository, userId: String = "") {
        self.repository = repository
        self.userId = userId
    }

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var unreadMessagesCount: Int {
        notifications.filter { !$0.isRead && $0.type == .newMessage }.count
    }

    func startListening(for userId: String) {
        guard !userId.isEmpty else { return }

        if self.userId == userId, listener != nil {
            return
        }

        self.userId = userId
        listener?.remove()

        listener = repository.observeNotifications(for: userId) { [weak self] result in
            guard let self else { return }

            Task { @MainActor in
                switch result {
                case .success(let notifications):
                    self.notifications = notifications
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func markAsRead(_ notification: AppNotification) async {
        guard !notification.isRead else { return }

        do {
            try await repository.markAsRead(notificationId: notification.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markAllAsRead() async {
        guard !userId.isEmpty else { return }

        do {
            try await repository.markAllAsRead(for: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    deinit {
        listener?.remove()
    }
}
