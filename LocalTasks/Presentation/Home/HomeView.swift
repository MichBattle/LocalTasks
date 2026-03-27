import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        HomeHeaderView(notificationCount: 3)

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
                                TaskCardView(task: task)
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
