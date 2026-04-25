import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var categories: [TaskCategory] = TaskCategory.allCases
    @Published var selectedCategory: TaskCategory?
    @Published var tasks: [TaskItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let repository: TaskRepository
    private let currentUserId: String?

    init(repository: TaskRepository, currentUserId: String? = nil) {
        self.repository = repository
        self.currentUserId = currentUserId
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            tasks = try await repository.fetchFeedTasks(city: nil)
        } catch {
            tasks = []
            errorMessage = error.localizedDescription
        }
    }

    var filteredTasks: [TaskItem] {
        tasks.filter { task in
            let isNotMine = task.creatorId != currentUserId
            let categoryMatches = selectedCategory == nil || task.category == selectedCategory
            return isNotMine && categoryMatches
        }
    }

    func toggleCategory(_ category: TaskCategory) {
        if selectedCategory == category {
            selectedCategory = nil
        } else {
            selectedCategory = category
        }
    }
}
