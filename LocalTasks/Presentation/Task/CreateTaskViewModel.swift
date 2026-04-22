import Foundation
import Combine

@MainActor
final class CreateTaskViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var selectedCategory: TaskCategory = .moving
    @Published var priceText = ""

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let repository: TaskRepository
    private let reviewRepository: ReviewRepository
    private let currentUserId: String?

    init(
        repository: TaskRepository,
        reviewRepository: ReviewRepository,
        currentUserId: String?
    ) {
        self.repository = repository
        self.reviewRepository = reviewRepository
        self.currentUserId = currentUserId
    }

    func createTask(address: AddressSelection?) async -> Bool {
        guard let currentUserId else {
            errorMessage = "Authentication required"
            return false
        }

        do {
            let hasPending = try await reviewRepository.hasPendingReviews(userId: currentUserId)
            if hasPending {
                errorMessage = "You must complete your pending reviews before creating a new task"
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            errorMessage = "Title is required"
            return false
        }

        guard !trimmedDescription.isEmpty else {
            errorMessage = "Description is required"
            return false
        }

        guard let address else {
            errorMessage = "Please select a valid address from the suggestions"
            return false
        }

        let parsedPrice: Double?
        if priceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parsedPrice = nil
        } else {
            parsedPrice = Double(priceText.replacingOccurrences(of: ",", with: "."))
            if parsedPrice == nil {
                errorMessage = "Invalid price"
                return false
            }
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            let input = CreateTaskInput(
                title: trimmedTitle,
                description: trimmedDescription,
                category: selectedCategory,
                address: address,
                price: parsedPrice
            )

            try await repository.createTask(input: input, imageDataList: [])
            successMessage = "Task created successfully"
            resetForm()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func resetForm() {
        title = ""
        description = ""
        selectedCategory = .moving
        priceText = ""
    }
}
