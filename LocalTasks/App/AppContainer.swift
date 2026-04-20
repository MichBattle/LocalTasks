import Foundation

final class AppContainer {
    let authRepository: AuthRepository
    let userRepository: UserRepository
    let taskRepository: TaskRepository
    let applicationRepository: ApplicationRepository
    let chatRepository: ChatRepository

    init() {
        self.authRepository = FirebaseAuthRepository()
        self.userRepository = FirebaseUserRepository()
        self.taskRepository = FirebaseTaskRepository()
        self.applicationRepository = FirebaseApplicationRepository()
        self.chatRepository = FirebaseChatRepository()
    }
}
