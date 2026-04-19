import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var isRestoringSession = false
    @Published var errorMessage: String?

    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    var isAuthenticated: Bool {
        currentUser != nil
    }

    func restoreSession() async {
        guard repository.getCurrentUserId() != nil else { return }

        isRestoringSession = true
        errorMessage = nil
        defer { isRestoringSession = false }

        do {
            currentUser = try await repository.fetchCurrentUserProfile()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            currentUser = try await repository.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp(email: String, password: String, username: String, city: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            currentUser = try await repository.signUp(
                email: email,
                password: password,
                username: username,
                city: city
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        do {
            try repository.signOut()
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
