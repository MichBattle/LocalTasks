import SwiftUI

struct TaskCardView: View {
    let task: TaskItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 16)

            coverImage

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    Text(task.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(2)

                    Spacer(minLength: 12)

                    Text(task.priceText)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColors.primary)
                }

                Text(task.description)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(4)

                Button {
                    // future: navigate to task detail
                } label: {
                    Text("View Details")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            LinearGradient(
                                colors: [AppColors.primaryLight, AppColors.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
            }
            .padding(18)
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
    }

    private var header: some View {
        HStack(spacing: 12) {
            avatarView

            VStack(alignment: .leading, spacing: 4) {
                Text(task.authorName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text(task.createdAtText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "location")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.primary)

                Text(task.distanceText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.08))
            .clipShape(Capsule())
        }
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.15))
                .frame(width: 58, height: 58)

            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 54, height: 54)
                .foregroundStyle(Color.gray.opacity(0.65))
        }
    }

    private var coverImage: some View {
        ZStack {
            Rectangle()
                .fill(task.category.softBackgroundColor)

            Image(systemName: imageSymbol(for: task.category))
                .resizable()
                .scaledToFit()
                .frame(width: 82, height: 82)
                .foregroundStyle(task.category.iconColor.opacity(0.85))
        }
        .frame(height: 255)
        .clipped()
    }

    private func imageSymbol(for category: TaskCategory) -> String {
        switch category {
        case .moving:
            return "shippingbox.fill"
        case .babysitting:
            return "figure.2.and.child.holdinghands"
        case .gardening:
            return "leaf.fill"
        case .cleaning:
            return "sparkles"
        case .painting:
            return "paintbrush.fill"
        }
    }
}
