import SwiftUI

struct RootView: View {
    @State private var selectedTab: RootTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .home:
                    HomeView(
                        viewModel: HomeViewModel(
                            repository: MockTaskRepository()
                        )
                    )
                case .map:
                    PlaceholderScreen(title: "Map")
                case .create:
                    PlaceholderScreen(title: "Create Task")
                case .messages:
                    PlaceholderScreen(title: "Messages")
                case .profile:
                    PlaceholderScreen(title: "Profile")
                }
            }

            CustomTabBar(selectedTab: $selectedTab)
        }
    }
}
