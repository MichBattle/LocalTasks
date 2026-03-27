import SwiftUI

struct CategoryChipView: View {
    let category: TaskCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(category.softBackgroundColor)
                        .frame(width: 54, height: 54)

                    Image(systemName: category.iconName)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(category.iconColor)
                }

                Text(category.rawValue)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 118, height: 142)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isSelected ? Color.white : AppColors.chipBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isSelected ? AppColors.primary.opacity(0.25) : .clear, lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(isSelected ? 0.06 : 0.02), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
}
