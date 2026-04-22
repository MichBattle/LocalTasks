import Foundation

protocol AuthRepository {
    func signUp(email: String, password: String, username: String, city: CitySelection) async throws -> AppUser
    func signIn(email: String, password: String) async throws -> AppUser
    func signOut() throws
    func getCurrentUserId() -> String?
    func fetchCurrentUserProfile() async throws -> AppUser?
}
