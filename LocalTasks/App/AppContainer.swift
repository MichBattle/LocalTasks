import Foundation

final class AppContainer {
    let authRepository: AuthRepository
    let userRepository: UserRepository
    let notificationRepository: NotificationRepository
    let taskRepository: TaskRepository
    let applicationRepository: ApplicationRepository
    let chatRepository: ChatRepository
    let reviewRepository: ReviewRepository

    init() {
        self.authRepository = FirebaseAuthRepository()
        self.userRepository = FirebaseUserRepository()
        self.notificationRepository = FirebaseNotificationRepository()

        self.taskRepository = FirebaseTaskRepository(
            notificationRepository: notificationRepository
        )

        self.applicationRepository = FirebaseApplicationRepository(
            notificationRepository: notificationRepository
        )

        self.chatRepository = FirebaseChatRepository(
            notificationRepository: notificationRepository
        )

        self.reviewRepository = FirebaseReviewRepository(
            notificationRepository: notificationRepository
        )
    }
}
