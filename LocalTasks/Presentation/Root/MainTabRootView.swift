import SwiftUI

struct MainTabRootView: View {
    @ObservedObject var authViewModel: AuthViewModel

    private let userRepository: UserRepository
    private let taskRepository: TaskRepository
    private let applicationRepository: ApplicationRepository
    private let chatRepository: ChatRepository
    private let reviewRepository: ReviewRepository
    private let notificationRepository: NotificationRepository

    @State private var selectedTab: RootTab = .home
    @State private var showAuthSheet = false

    @State private var toastMessage: String?
    @State private var showToast = false

    init(
        authViewModel: AuthViewModel,
        userRepository: UserRepository,
        taskRepository: TaskRepository,
        applicationRepository: ApplicationRepository,
        chatRepository: ChatRepository,
        reviewRepository: ReviewRepository,
        notificationRepository: NotificationRepository
    ) {
        self.authViewModel = authViewModel
        self.userRepository = userRepository
        self.taskRepository = taskRepository
        self.applicationRepository = applicationRepository
        self.chatRepository = chatRepository
        self.reviewRepository = reviewRepository
        self.notificationRepository = notificationRepository
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()

            currentContent

            if !isTabBarHidden {
                CustomTabBar(
                    selectedTab: selectedTab,
                    onTabSelected: handleTabSelection
                )
            }

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
                viewModel: HomeViewModel(repository: taskRepository),
                authViewModel: authViewModel,
                applicationRepository: applicationRepository,
                reviewRepository: reviewRepository,
                notificationRepository: notificationRepository,
                userRepository: userRepository,
                taskRepository: taskRepository,
                onRequireAuth: { showAuthSheet = true }
            )

        case .map:
            TasksMapView(
                taskRepository: taskRepository,
                userRepository: userRepository,
                authViewModel: authViewModel,
                applicationRepository: applicationRepository,
                reviewRepository: reviewRepository,
                onRequireAuth: { showAuthSheet = true }
            )

        case .create:
            CreateTaskView(
                viewModel: CreateTaskViewModel(
                    repository: taskRepository,
                    reviewRepository: reviewRepository,
                    currentUserId: authViewModel.currentUser?.id
                )
            )

        case .messages:
            MessagesListView(
                authViewModel: authViewModel,
                userRepository: userRepository,
                taskRepository: taskRepository,
                chatRepository: chatRepository,
                reviewRepository: reviewRepository,
                onExit: {
                    selectedTab = .home
                }
            )

        case .profile:
            ProfileView(
                authViewModel: authViewModel,
                userRepository: userRepository,
                taskRepository: taskRepository,
                applicationRepository: applicationRepository,
                chatRepository: chatRepository,
                reviewRepository: reviewRepository,
                onLogout: handleLogout
            )
        }
    }

    private var isTabBarHidden: Bool {
        selectedTab == .messages
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
