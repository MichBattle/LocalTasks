import Foundation
import CoreLocation

enum MapAnnotationItem: Identifiable {
    case single(TaskItem)
    case cluster(id: UUID, coordinate: CLLocationCoordinate2D, tasks: [TaskItem])

    var id: String {
        switch self {
        case .single(let task):
            return "task_\(task.id)"
        case .cluster(let id, _, _):
            return "cluster_\(id.uuidString)"
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .single(let task):
            return CLLocationCoordinate2D(
                latitude: task.approxLatitude ?? 0,
                longitude: task.approxLongitude ?? 0
            )
        case .cluster(_, let coordinate, _):
            return coordinate
        }
    }
}
