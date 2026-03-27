import SwiftUI

struct PlaceholderScreen: View {
    let title: String

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
    }
}
