import SwiftUI

struct RootView: View {
    @StateObject private var authViewModel: AuthViewModel

    private let userRepository: UserRepository
    private let taskRepository: TaskRepository
    private let applicationRepository: ApplicationRepository
    private let chatRepository: ChatRepository

    init() {
        let container = AppContainer()
        self.userRepository = container.userRepository
        self.taskRepository = container.taskRepository
        self.applicationRepository = container.applicationRepository
        self.chatRepository = container.chatRepository

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
            chatRepository: chatRepository
        )
        .task {
            await authViewModel.restoreSession()
        }
    }
}
