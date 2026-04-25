import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel: NotificationsViewModel

    init(notificationRepository: NotificationRepository, userId: String) {
        _viewModel = StateObject(
            wrappedValue: NotificationsViewModel(
                repository: notificationRepository,
                userId: userId
            )
        )
    }

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            if viewModel.notifications.isEmpty {
                ContentUnavailableView(
                    "No notifications yet",
                    systemImage: "bell",
                    description: Text("Your app notifications will appear here.")
                )
            } else {
                ForEach(viewModel.notifications) { notification in
                    Button {
                        Task {
                            await viewModel.markAsRead(notification)
                        }
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: iconName(for: notification.type))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(notification.isRead ? .gray : AppColors.primary)
                                .frame(width: 34, height: 34)
                                .background(
                                    (notification.isRead ? Color.gray : AppColors.primary)
                                        .opacity(0.12)
                                )
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 5) {
                                Text(notification.title)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(AppColors.textPrimary)

                                Text(notification.message)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppColors.textSecondary)

                                Text(relativeDate(notification.createdAt))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppColors.textSecondary)
                            }

                            Spacer()

                            if !notification.isRead {
                                Circle()
                                    .fill(AppColors.primary)
                                    .frame(width: 9, height: 9)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Read all") {
                    Task {
                        await viewModel.markAllAsRead()
                    }
                }
            }
        }
        .onAppear {
            viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }

    private func iconName(for type: AppNotificationType) -> String {
        switch type {
        case .newApplication:
            return "person.badge.plus"
        case .applicationAccepted:
            return "checkmark.circle"
        case .applicationRejected:
            return "xmark.circle"
        case .newMessage:
            return "message"
        case .taskCompleted:
            return "flag.checkered"
        case .reviewReceived:
            return "star"
        case .newTaskInYourCity:
            return "mappin.circle"
        }
    }

    private func relativeDate(_ date: Date) -> String {
        RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }
}
