import Foundation

final class AppContainer {
    let authRepository: AuthRepository
    let taskRepository: TaskRepository

    init() {
        self.authRepository = FirebaseAuthRepository()
        self.taskRepository = FirebaseTaskRepository()
    }
}
