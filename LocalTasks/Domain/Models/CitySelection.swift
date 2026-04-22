import Foundation

struct CitySelection: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let canonicalName: String
    let latitude: Double
    let longitude: Double
}
