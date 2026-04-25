import SwiftUI

struct HomeHeaderView: View {
    let notificationCount: Int
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

                    if notificationCount > 0 {
                        Text("\(notificationCount)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }
}
