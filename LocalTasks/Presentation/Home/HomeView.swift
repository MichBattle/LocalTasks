import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel

    @ObservedObject var authViewModel: AuthViewModel
    let applicationRepository: ApplicationRepository
    let onRequireAuth: () -> Void

    init(
        viewModel: HomeViewModel,
        authViewModel: AuthViewModel,
        applicationRepository: ApplicationRepository,
        onRequireAuth: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.authViewModel = authViewModel
        self.applicationRepository = applicationRepository
        self.onRequireAuth = onRequireAuth
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        HomeHeaderView(notificationCount: 0)

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
            .task {
                await viewModel.load()
            }
            .navigationBarHidden(true)
        }
    }
}
