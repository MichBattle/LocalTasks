import SwiftUI

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    let taskRepository: TaskRepository
    let applicationRepository: ApplicationRepository
    let chatRepository: ChatRepository
    let onLogout: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
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

                            VStack(spacing: 14) {
                                NavigationLink {
                                    MyApplicationsView(
                                        applicationRepository: applicationRepository,
                                        taskRepository: taskRepository,
                                        userId: user.id
                                    )
                                } label: {
                                    profileActionCard(title: "My Applications", icon: "doc.text")
                                }

                                NavigationLink {
                                    MyJobPostsView(
                                        taskRepository: taskRepository,
                                        applicationRepository: applicationRepository,
                                        chatRepository: chatRepository,
                                        authViewModel: authViewModel,
                                        userId: user.id
                                    )
                                } label: {
                                    profileActionCard(title: "My Job Posts", icon: "briefcase")
                                }
                            }
                            .padding(.top, 8)
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
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func profileActionCard(title: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColors.primary)
                .frame(width: 42, height: 42)
                .background(AppColors.primary.opacity(0.12))
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
