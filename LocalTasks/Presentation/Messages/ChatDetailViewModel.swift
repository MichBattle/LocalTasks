import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class ChatDetailViewModel: ObservableObject {
    @Published var messages: [MessageItem] = []
    @Published var messageText = ""
    @Published var isSending = false
    @Published var errorMessage: String?

    private let repository: ChatRepository
    let chatId: String

    private var listener: (any ListenerRegistration)?

    init(chatId: String, repository: ChatRepository) {
        self.chatId = chatId
        self.repository = repository
    }

    func startListening() {
        errorMessage = nil

        listener?.remove()
        listener = repository.observeMessages(chatId: chatId) { [weak self] result in
            guard let self else { return }

            Task { @MainActor in
                switch result {
                case .success(let messages):
                    self.messages = messages
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func sendMessage() async {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true
        errorMessage = nil
        defer { isSending = false }

        do {
            try await repository.sendMessage(
                SendMessageInput(chatId: chatId, text: trimmed)
            )
            messageText = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    deinit {
        listener?.remove()
    }
}
