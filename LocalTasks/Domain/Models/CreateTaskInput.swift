import Foundation

struct CreateTaskInput {
    let title: String
    let description: String
    let category: TaskCategory
    let address: AddressSelection
    let price: Double?
}
