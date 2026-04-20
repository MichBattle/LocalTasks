import SwiftUI

struct MainTabRootView: View {
    @ObservedObject var authViewModel: AuthViewModel
    private let taskRepository: TaskRepository

    @State private var selectedTab: RootTab = .home
    @State private var showAuthSheet = false

    @State private var toastMessage: String?
    @State private var showToast = false

    init(authViewModel: AuthViewModel, taskRepository: TaskRepository) {
        self.authViewModel = authViewModel
        self.taskRepository = taskRepository
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()

            currentContent

            CustomTabBar(
                selectedTab: selectedTab,
                onTabSelected: handleTabSelection
            )

            if showToast, let toastMessage {
                VStack {
                    HStack {
                        Spacer()

                        Text(toastMessage)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(AppColors.primary)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                        Spacer()
                    }
                    .padding(.top, 18)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showToast)
        .sheet(isPresented: $showAuthSheet) {
            AuthScreen(authViewModel: authViewModel) { message in
                showAuthSheet = false
                showTemporaryToast(message)
            }
        }
    }

    @ViewBuilder
    private var currentContent: some View {
        switch selectedTab {
        case .home:
            HomeView(
                viewModel: HomeViewModel(repository: taskRepository)
            )

        case .map:
            NavigationStack {
                ZStack {
                    AppColors.background.ignoresSafeArea()

                    Text("Map")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                }
            }

        case .create:
            CreateTaskView(
                viewModel: CreateTaskViewModel(repository: taskRepository)
            )

        case .messages:
            NavigationStack {
                ZStack {
                    AppColors.background.ignoresSafeArea()

                    Text("Messages")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                }
            }

        case .profile:
            ProfileView(
                authViewModel: authViewModel,
                onLogout: handleLogout
            )
        }
    }

    private func handleTabSelection(_ tab: RootTab) {
        if requiresAuthentication(tab), !authViewModel.isAuthenticated {
            showAuthSheet = true
            return
        }

        selectedTab = tab
    }

    private func requiresAuthentication(_ tab: RootTab) -> Bool {
        switch tab {
        case .create, .messages, .profile:
            return true
        case .home, .map:
            return false
        }
    }

    private func handleLogout() {
        selectedTab = .home
        showAuthSheet = true
    }

    private func showTemporaryToast(_ message: String) {
        toastMessage = message
        showToast = true

        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                showToast = false
            }

            try? await Task.sleep(for: .milliseconds(250))
            await MainActor.run {
                toastMessage = nil
            }
        }
    }
}
