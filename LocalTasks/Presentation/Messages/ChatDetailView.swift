import SwiftUI

struct ChatDetailView: View {
    let chat: ChatItem
    let currentUserId: String

    @StateObject private var viewModel: ChatDetailViewModel

    init(chat: ChatItem, currentUserId: String, repository: ChatRepository) {
        self.chat = chat
        self.currentUserId = currentUserId
        _viewModel = StateObject(
            wrappedValue: ChatDetailViewModel(chatId: chat.id, repository: repository)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            HStack {
                                if message.senderId == currentUserId { Spacer() }

                                VStack(
                                    alignment: message.senderId == currentUserId ? .trailing : .leading,
                                    spacing: 4
                                ) {
                                    Text(message.text)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(
                                            message.senderId == currentUserId
                                            ? AppColors.primary
                                            : Color.gray.opacity(0.15)
                                        )
                                        .foregroundStyle(
                                            message.senderId == currentUserId
                                            ? Color.white
                                            : AppColors.textPrimary
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                                    Text(timeString(from: message.createdAt))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                .id(message.id)

                                if message.senderId != currentUserId { Spacer() }
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    guard let lastId = viewModel.messages.last?.id else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
                .onAppear {
                    if let lastId = viewModel.messages.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }

            Divider()

            HStack(spacing: 12) {
                TextField("Write a message...", text: $viewModel.messageText)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button {
                    Task { await viewModel.sendMessage() }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(AppColors.primary)
                        .clipShape(Circle())
                }
                .disabled(viewModel.isSending)
            }
            .padding()
            .background(AppColors.background)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}
