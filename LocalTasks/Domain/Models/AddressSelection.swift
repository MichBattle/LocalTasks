import Foundation

struct AddressSelection: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let fullAddress: String
    let cityName: String
    let cityCanonical: String
    let latitude: Double
    let longitude: Double
}
