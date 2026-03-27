import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var categories: [TaskCategory] = TaskCategory.allCases
    @Published var selectedCategory: TaskCategory?
    @Published var tasks: [TaskItem] = []
    @Published var isLoading: Bool = false

    private let repository: TaskRepository

    init(repository: TaskRepository) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            tasks = try await repository.fetchFeaturedTasks()
        } catch {
            tasks = []
            print("Failed to load tasks: \(error)")
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
