import SwiftUI
import MapKit

struct TasksMapView: View {
    @StateObject private var viewModel: TasksMapViewModel
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedTask: TaskItem?

    @ObservedObject var authViewModel: AuthViewModel
    let applicationRepository: ApplicationRepository
    let reviewRepository: ReviewRepository
    let onRequireAuth: () -> Void

    init(
        taskRepository: TaskRepository,
        authViewModel: AuthViewModel,
        applicationRepository: ApplicationRepository,
        reviewRepository: ReviewRepository,
        onRequireAuth: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: TasksMapViewModel(taskRepository: taskRepository)
        )
        self.authViewModel = authViewModel
        self.applicationRepository = applicationRepository
        self.reviewRepository = reviewRepository
        self.onRequireAuth = onRequireAuth
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $position) {
                    ForEach(viewModel.tasks) { task in
                        if let lat = task.approxLatitude,
                           let lon = task.approxLongitude {
                            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)

                            Annotation(task.creatorUsername, coordinate: coordinate) {
                                Button {
                                    selectedTask = task
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: task.category.iconName)
                                            .foregroundStyle(.white)
                                            .padding(10)
                                            .background(AppColors.primary)
                                            .clipShape(Circle())

                                        VStack(spacing: 2) {
                                            Text(task.creatorUsername)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(AppColors.textPrimary)

                                            Text(task.category.displayName)
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundStyle(AppColors.textSecondary)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                }
                                .buttonStyle(.plain)
                            }

                            MapCircle(center: coordinate, radius: 2000)
                                .foregroundStyle(AppColors.primary.opacity(0.12))
                                .stroke(AppColors.primary.opacity(0.25), lineWidth: 1)
                        }
                    }
                }
                .mapStyle(.standard)

                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedTask) { task in
                TaskDetailView(
                    task: task,
                    authViewModel: authViewModel,
                    applicationRepository: applicationRepository,
                    reviewRepository: reviewRepository,
                    onRequireAuth: onRequireAuth
                )
            }
            .task {
                await viewModel.load()

                if let first = viewModel.tasks.first,
                   let lat = first.approxLatitude,
                   let lon = first.approxLongitude {
                    position = .region(
                        MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                        )
                    )
                }
            }
        }
    }
}
