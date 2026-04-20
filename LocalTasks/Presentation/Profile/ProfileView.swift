import SwiftUI

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    let onLogout: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    Circle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 110, height: 110)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 42))
                                .foregroundStyle(.gray)
                        )

                    if let user = authViewModel.currentUser {
                        VStack(spacing: 8) {
                            Text(user.username)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(AppColors.textPrimary)

                            Text(user.email)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(AppColors.textSecondary)

                            Text(user.city)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(AppColors.textSecondary)

                            Text("Rating: \(String(format: "%.1f", user.ratingAvg)) (\(user.ratingCount))")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppColors.primary)
                        }
                    }

                    Button {
                        authViewModel.signOut()
                        onLogout()
                    } label: {
                        Text("Logout")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppColors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .padding(.top, 12)

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
