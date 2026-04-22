import Foundation
import MapKit
import Combine
import CoreLocation

@MainActor
final class AddressSearchViewModel: NSObject, ObservableObject {
    @Published var query = ""
    @Published var completions: [MKLocalSearchCompletion] = []
    @Published var selectedAddress: AddressSelection?
    @Published var errorMessage: String?

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address]
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
                errorMessage = "Address not found"
                return
            }

            let coordinate = item.placemark.coordinate
            let geocoder = CLGeocoder()
            let placemarks = try await geocoder.reverseGeocodeLocation(
                CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            )

            guard let placemark = placemarks.first,
                  let city = placemark.locality ?? placemark.subAdministrativeArea else {
                errorMessage = "Unable to resolve city from address"
                return
            }

            let title = completion.title
            let subtitle = completion.subtitle
            let fullAddress = [title, subtitle]
                .filter { !$0.isEmpty }
                .joined(separator: ", ")

            selectedAddress = AddressSelection(
                title: title,
                subtitle: subtitle,
                fullAddress: fullAddress,
                cityName: city,
                cityCanonical: city
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .folding(options: .diacriticInsensitive, locale: .current)
                    .lowercased(),
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )

            query = fullAddress
            completions = []
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension AddressSearchViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        errorMessage = error.localizedDescription
    }
}
