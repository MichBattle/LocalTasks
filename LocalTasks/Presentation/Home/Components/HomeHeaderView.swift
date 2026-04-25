import SwiftUI

struct HomeHeaderView: View {
    let hasUnreadNotifications: Bool
    let onNotificationsTap: () -> Void

    var body: some View {
        HStack {
            Text("LocalTasks")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Button {
                onNotificationsTap()
            } label: {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 58, height: 58)
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)

                    Image(systemName: "bell")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(width: 58, height: 58)

                    if hasUnreadNotifications {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .offset(x: -6, y: 6)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }
}
