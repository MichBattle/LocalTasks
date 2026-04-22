import Foundation
import MapKit
import Combine
import CoreLocation

@MainActor
final class CitySearchViewModel: NSObject, ObservableObject {
    @Published var query = ""
    @Published var completions: [MKLocalSearchCompletion] = []
    @Published var selectedCity: CitySelection?
    @Published var errorMessage: String?

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .query]
    }

    func updateQuery(_ value: String) {
        query = value
        completer.queryFragment = value
    }

    func selectCompletion(_ completion: MKLocalSearchCompletion) async {
        let request = MKLocalSearch.Request(completion: completion)

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first else {
                errorMessage = "City not found"
                return
            }

            let coordinate = item.placemark.coordinate

            let geocoder = CLGeocoder()
            let placemarks = try await geocoder.reverseGeocodeLocation(
                CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            )

            guard let placemark = placemarks.first,
                  let city = placemark.locality ?? placemark.administrativeArea else {
                errorMessage = "Unable to resolve city"
                return
            }

            selectedCity = CitySelection(
                name: city,
                canonicalName: city
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .folding(options: .diacriticInsensitive, locale: .current)
                    .lowercased(),
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )

            query = city
            completions = []
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension CitySearchViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        errorMessage = error.localizedDescription
    }
}
