import Foundation
import Combine
import MapKit

@MainActor
final class TasksMapViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var selectedCity: String?
    @Published var selectedCategory: TaskCategory?

    private let taskRepository: TaskRepository

    init(taskRepository: TaskRepository) {
        self.taskRepository = taskRepository
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            tasks = try await taskRepository.fetchFeedTasks(city: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var availableCities: [String] {
        Array(Set(tasks.map(\.city)))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var filteredTasks: [TaskItem] {
        tasks.filter { task in
            let cityMatches = selectedCity == nil || task.city == selectedCity
            let categoryMatches = selectedCategory == nil || task.category == selectedCategory
            return cityMatches && categoryMatches
        }
    }

    func toggleCategory(_ category: TaskCategory) {
        if selectedCategory == category {
            selectedCategory = nil
        } else {
            selectedCategory = category
        }
    }

    func clearFilters() {
        selectedCity = nil
        selectedCategory = nil
    }

    func annotationItems(for region: MKCoordinateRegion?) -> [MapAnnotationItem] {
        let tasksWithCoordinates = filteredTasks.filter {
            $0.approxLatitude != nil && $0.approxLongitude != nil
        }

        guard let region else {
            return tasksWithCoordinates.map { .single($0) }
        }

        let clusterDistance = clusterThreshold(for: region)

        var clusters: [[TaskItem]] = []

        for task in tasksWithCoordinates {
            guard let lat = task.approxLatitude, let lon = task.approxLongitude else { continue }
            let location = CLLocation(latitude: lat, longitude: lon)

            var inserted = false

            for index in clusters.indices {
                guard let first = clusters[index].first,
                      let firstLat = first.approxLatitude,
                      let firstLon = first.approxLongitude else { continue }

                let firstLocation = CLLocation(latitude: firstLat, longitude: firstLon)
                let distance = location.distance(from: firstLocation)

                if distance <= clusterDistance {
                    clusters[index].append(task)
                    inserted = true
                    break
                }
            }

            if !inserted {
                clusters.append([task])
            }
        }

        return clusters.map { cluster in
            if cluster.count == 1 {
                return .single(cluster[0])
            } else {
                let avgLat = cluster.compactMap(\.approxLatitude).reduce(0, +) / Double(cluster.count)
                let avgLon = cluster.compactMap(\.approxLongitude).reduce(0, +) / Double(cluster.count)

                return .cluster(
                    id: UUID(),
                    coordinate: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon),
                    tasks: cluster
                )
            }
        }
    }

    private func clusterThreshold(for region: MKCoordinateRegion) -> CLLocationDistance {
        let latitudeDelta = region.span.latitudeDelta

        switch latitudeDelta {
        case ..<0.03:
            return 250
        case ..<0.08:
            return 500
        case ..<0.2:
            return 900
        case ..<0.5:
            return 1500
        default:
            return 2500
        }
    }
}
