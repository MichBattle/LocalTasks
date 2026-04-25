import SwiftUI

struct RootView: View {
    @StateObject private var authViewModel: AuthViewModel

    private let userRepository: UserRepository
    private let taskRepository: TaskRepository
    private let applicationRepository: ApplicationRepository
    private let chatRepository: ChatRepository
    private let reviewRepository: ReviewRepository
    private let notificationRepository: NotificationRepository

    init() {
        let container = AppContainer()
        self.userRepository = container.userRepository
        self.taskRepository = container.taskRepository
        self.applicationRepository = container.applicationRepository
        self.chatRepository = container.chatRepository
        self.reviewRepository = container.reviewRepository
        self.notificationRepository = container.notificationRepository

        _authViewModel = StateObject(
            wrappedValue: AuthViewModel(repository: container.authRepository)
        )
    }

    var body: some View {
        MainTabRootView(
            authViewModel: authViewModel,
            userRepository: userRepository,
            taskRepository: taskRepository,
            applicationRepository: applicationRepository,
            chatRepository: chatRepository,
            reviewRepository: reviewRepository,
            notificationRepository: notificationRepository
        )
        .task {
            await authViewModel.restoreSession()
        }
    }
}
