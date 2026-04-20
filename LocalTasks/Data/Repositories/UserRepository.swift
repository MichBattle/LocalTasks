import Foundation

protocol UserRepository {
    func fetchUser(by id: String) async throws -> AppUser?
}
