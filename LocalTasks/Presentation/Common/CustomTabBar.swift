import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: RootTab

    var body: some View {
        HStack(alignment: .bottom) {
            tabButton(for: .home)
            Spacer()
            tabButton(for: .map)
            Spacer()

            centerButton

            Spacer()
            tabButton(for: .messages, showNotificationDot: true)
            Spacer()
            tabButton(for: .profile)
        }
        .padding(.horizontal, 26)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var centerButton: some View {
        Button {
            selectedTab = .create
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primaryLight, AppColors.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .shadow(color: AppColors.primary.opacity(0.22), radius: 10, y: 5)

                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .offset(y: -16)
    }

    @ViewBuilder
    private func tabButton(for tab: RootTab, showNotificationDot: Bool = false) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: selectedTab == tab ? "\(tab.iconName).fill" : tab.iconName)
                        .font(.system(size: 23, weight: .medium))
                        .foregroundStyle(selectedTab == tab ? AppColors.primary : AppColors.textSecondary)

                    if showNotificationDot {
                        Circle()
                            .fill(.red)
                            .frame(width: 10, height: 10)
                            .offset(x: 6, y: -3)
                    }
                }

                Text(tab.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(selectedTab == tab ? AppColors.primary : AppColors.textSecondary)
            }
            .frame(minWidth: 44)
        }
        .buttonStyle(.plain)
    }
}
