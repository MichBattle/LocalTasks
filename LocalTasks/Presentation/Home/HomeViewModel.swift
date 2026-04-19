import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var categories: [TaskCategory] = TaskCategory.allCases
    @Published var selectedCategory: TaskCategory?
    @Published var tasks: [TaskItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: TaskRepository

    init(repository: TaskRepository) {
        self.repository = repository
    }

    func load(city: String? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            tasks = try await repository.fetchFeedTasks(city: city)
        } catch {
            tasks = []
            errorMessage = error.localizedDescription
        }
    }

    var filteredTasks: [TaskItem] {
        guard let selectedCategory else { return tasks }
        return tasks.filter { $0.category == selectedCategory }
    }

    func toggleCategory(_ category: TaskCategory) {
        if selectedCategory == category {
            selectedCategory = nil
        } else {
            selectedCategory = category
        }
    }
}
