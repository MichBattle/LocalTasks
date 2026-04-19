import Foundation

struct CreateTaskInput {
    let title: String
    let description: String
    let category: TaskCategory
    let city: String
    let fullAddress: String
    let price: Double?
}
