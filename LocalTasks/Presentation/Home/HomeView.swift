import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var notificationsViewModel: NotificationsViewModel

    @ObservedObject var authViewModel: AuthViewModel

    let applicationRepository: ApplicationRepository
    let reviewRepository: ReviewRepository
    let notificationRepository: NotificationRepository
    let onRequireAuth: () -> Void
    let userRepository: UserRepository
    let taskRepository: TaskRepository

    @State private var showNotifications = false

    init(
        viewModel: HomeViewModel,
        authViewModel: AuthViewModel,
        applicationRepository: ApplicationRepository,
        reviewRepository: ReviewRepository,
        notificationRepository: NotificationRepository,
        userRepository: UserRepository,
        taskRepository: TaskRepository,
        onRequireAuth: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)

        let userId = authViewModel.currentUser?.id ?? ""
        _notificationsViewModel = StateObject(
            wrappedValue: NotificationsViewModel(
                repository: notificationRepository,
                userId: userId
            )
        )

        self.authViewModel = authViewModel
        self.applicationRepository = applicationRepository
        self.reviewRepository = reviewRepository
        self.notificationRepository = notificationRepository
        self.userRepository = userRepository
        self.taskRepository = taskRepository
        self.onRequireAuth = onRequireAuth
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        HomeHeaderView(
                            notificationCount: notificationsViewModel.unreadCount
                        ) {
                            if authViewModel.isAuthenticated {
                                showNotifications = true
                            } else {
                                onRequireAuth()
                            }
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.categories) { category in
                                    CategoryChipView(
                                        category: category,
                                        isSelected: viewModel.selectedCategory == category
                                    ) {
                                        viewModel.toggleCategory(category)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        LazyVStack(spacing: 18) {
                            ForEach(viewModel.filteredTasks) { task in
                                NavigationLink {
                                    TaskDetailView(
                                        task: task,
                                        authViewModel: authViewModel,
                                        applicationRepository: applicationRepository,
                                        reviewRepository: reviewRepository,
                                        userRepository: userRepository,
                                        taskRepository: taskRepository,
                                        onRequireAuth: onRequireAuth
                                    )
                                } label: {
                                    TaskCardView(task: task)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 120)
                    }
                    .padding(.top, 10)
                }
            }
            .navigationDestination(isPresented: $showNotifications) {
                NotificationsView(
                    notificationRepository: notificationRepository,
                    userId: authViewModel.currentUser?.id ?? ""
                )
            }
            .task {
                await viewModel.load()
            }
            .onAppear {
                if authViewModel.isAuthenticated {
                    notificationsViewModel.startListening()
                }
            }
            .onDisappear {
                notificationsViewModel.stopListening()
            }
            .navigationBarHidden(true)
        }
    }
}
