import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel

    @ObservedObject var authViewModel: AuthViewModel

    let applicationRepository: ApplicationRepository
    let reviewRepository: ReviewRepository
    let notificationRepository: NotificationRepository
    let userRepository: UserRepository
    let taskRepository: TaskRepository
    let hasUnreadNotifications: Bool
    let onRequireAuth: () -> Void

    @State private var showNotifications = false
    @State private var showCategories = true

    init(
        viewModel: HomeViewModel,
        authViewModel: AuthViewModel,
        applicationRepository: ApplicationRepository,
        reviewRepository: ReviewRepository,
        notificationRepository: NotificationRepository,
        userRepository: UserRepository,
        taskRepository: TaskRepository,
        hasUnreadNotifications: Bool,
        onRequireAuth: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)

        self.authViewModel = authViewModel
        self.applicationRepository = applicationRepository
        self.reviewRepository = reviewRepository
        self.notificationRepository = notificationRepository
        self.userRepository = userRepository
        self.taskRepository = taskRepository
        self.hasUnreadNotifications = hasUnreadNotifications
        self.onRequireAuth = onRequireAuth
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        HomeHeaderView(
                            hasUnreadNotifications: hasUnreadNotifications
                        ) {
                            if authViewModel.isAuthenticated {
                                showNotifications = true
                            } else {
                                onRequireAuth()
                            }
                        }

                        categoriesSection

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
            .navigationBarHidden(true)
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showCategories.toggle()
                }
            } label: {
                HStack {
                    Text("Categories")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)

                    Spacer()

                    Image(systemName: showCategories ? "chevron.down" : "chevron.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.horizontal, 20)
            }
            .buttonStyle(.plain)

            if showCategories {
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
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}
