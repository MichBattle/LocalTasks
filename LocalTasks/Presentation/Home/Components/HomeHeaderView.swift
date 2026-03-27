import SwiftUI

struct HomeHeaderView: View {
    let notificationCount: Int

    var body: some View {
        HStack(alignment: .top) {
            Text("LocalTasks")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            ZStack(alignment: .topTrailing) {
                Button {
                    // future: open notifications
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.7))
                            .frame(width: 52, height: 52)

                        Image(systemName: "bell")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                if notificationCount > 0 {
                    ZStack {
                        Circle()
                            .fill(AppColors.badgeBackground)
                            .frame(width: 22, height: 22)

                        Text("\(notificationCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 4, y: -2)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}
