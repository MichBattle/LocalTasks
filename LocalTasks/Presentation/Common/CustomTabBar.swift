import SwiftUI

struct CustomTabBar: View {
    let selectedTab: RootTab
    let hasUnreadMessages: Bool
    let onTabSelected: (RootTab) -> Void

    var body: some View {
        HStack(alignment: .bottom) {
            tabButton(for: .home)

            Spacer()

            tabButton(for: .map)

            Spacer()

            centerButton

            Spacer()

            tabButton(for: .messages)

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
            onTabSelected(.create)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(AppColors.primary)
                .clipShape(Circle())
                .shadow(color: AppColors.primary.opacity(0.35), radius: 12, y: 6)
                .offset(y: -18)
        }
        .buttonStyle(.plain)
    }

    private func tabButton(for tab: RootTab) -> some View {
        Button {
            onTabSelected(tab)
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: tab.iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(selectedTab == tab ? AppColors.primary : AppColors.textSecondary)

                    if tab == .messages && hasUnreadMessages {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                            .offset(x: 6, y: -6)
                    }
                }

                Text(tab.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(selectedTab == tab ? AppColors.primary : AppColors.textSecondary)
            }
            .frame(width: 58)
        }
        .buttonStyle(.plain)
    }
}
