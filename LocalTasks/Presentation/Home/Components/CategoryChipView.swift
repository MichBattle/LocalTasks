import SwiftUI

struct CategoryChipView: View {
    let category: TaskCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: category.iconName)
                    .font(.system(size: 12, weight: .semibold))

                Text(category.displayName)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : AppColors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? AppColors.primary : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}
