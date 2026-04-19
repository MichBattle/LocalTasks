import SwiftUI

struct RootView: View {
    @StateObject private var authViewModel: AuthViewModel
    private let taskRepository: TaskRepository

    init() {
        let container = AppContainer()
        self.taskRepository = container.taskRepository

        _authViewModel = StateObject(
            wrappedValue: AuthViewModel(repository: container.authRepository)
        )
    }

    var body: some View {
        MainTabRootView(
            authViewModel: authViewModel,
            taskRepository: taskRepository
        )
        .task {
            await authViewModel.restoreSession()
        }
    }
}
