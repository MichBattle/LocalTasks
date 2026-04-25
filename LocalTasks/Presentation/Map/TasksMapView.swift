import SwiftUI
import MapKit
import CoreLocation

struct TasksMapView: View {
    @StateObject private var viewModel: TasksMapViewModel
    @StateObject private var locationManager = UserLocationManager()

    @State private var position: MapCameraPosition = .automatic
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var selectedTask: TaskItem?

    @ObservedObject var authViewModel: AuthViewModel
    let applicationRepository: ApplicationRepository
    let reviewRepository: ReviewRepository
    let onRequireAuth: () -> Void
    let userRepository: UserRepository
    let taskRepository: TaskRepository

    init(
        taskRepository: TaskRepository,
        userRepository: UserRepository,
        authViewModel: AuthViewModel,
        applicationRepository: ApplicationRepository,
        reviewRepository: ReviewRepository,
        onRequireAuth: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: TasksMapViewModel(taskRepository: taskRepository)
        )

        self.taskRepository = taskRepository
        self.userRepository = userRepository
        self.authViewModel = authViewModel
        self.applicationRepository = applicationRepository
        self.reviewRepository = reviewRepository
        self.onRequireAuth = onRequireAuth
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Map(position: $position) {
                    UserAnnotation()

                    ForEach(viewModel.annotationItems(for: visibleRegion), id: \.id) { item in
                        switch item {
                        case .single(let task):
                            let coordinate = CLLocationCoordinate2D(
                                latitude: task.approxLatitude ?? 0,
                                longitude: task.approxLongitude ?? 0
                            )

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

                        case .cluster(_, let coordinate, let tasks):
                            Annotation("Cluster", coordinate: coordinate) {
                                Button {
                                    zoomIntoCluster(coordinate: coordinate)
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(AppColors.primary)
                                            .frame(width: 44, height: 44)

                                        Text("\(tasks.count)")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                    .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .mapStyle(.standard)
                .onMapCameraChange { context in
                    visibleRegion = context.region
                }

                filtersBar
                    .padding(.top, 8)

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
                    userRepository: userRepository,
                    taskRepository: taskRepository,
                    onRequireAuth: onRequireAuth
                )
            }
            .task {
                await viewModel.load()
                locationManager.requestPermissionIfNeeded()

                if let userLocation = locationManager.currentLocation {
                    zoomToUser(userLocation.coordinate)
                } else if let first = viewModel.filteredTasks.first,
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
            .onChange(of: locationManager.currentLocation) { _, newLocation in
                guard let newLocation else { return }
                if visibleRegion == nil {
                    zoomToUser(newLocation.coordinate)
                }
            }
            .onChange(of: viewModel.selectedCity) { _, _ in
                refreshCameraForFilteredResults()
            }
            .onChange(of: viewModel.selectedCategory) { _, _ in
                refreshCameraForFilteredResults()
            }
        }
    }

    private var filtersBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Menu {
                    Button("All cities") {
                        viewModel.selectedCity = nil
                    }

                    ForEach(viewModel.availableCities, id: \.self) { city in
                        Button(city) {
                            viewModel.selectedCity = city
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedCity ?? "All cities")
                            .lineLimit(1)

                        Image(systemName: "chevron.down")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .clipShape(Capsule())
                }

                Menu {
                    Button("All categories") {
                        viewModel.selectedCategory = nil
                    }

                    ForEach(TaskCategory.allCases) { category in
                        Button(category.displayName) {
                            viewModel.selectedCategory = category
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedCategory?.displayName ?? "All categories")
                            .lineLimit(1)

                        Image(systemName: "chevron.down")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .clipShape(Capsule())
                }

                Button {
                    viewModel.clearFilters()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(10)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func zoomToUser(_ coordinate: CLLocationCoordinate2D) {
        position = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
        )
    }

    private func zoomIntoCluster(coordinate: CLLocationCoordinate2D) {
        position = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
            )
        )
    }

    private func refreshCameraForFilteredResults() {
        guard let first = viewModel.filteredTasks.first,
              let lat = first.approxLatitude,
              let lon = first.approxLongitude else {
            return
        }

        position = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
            )
        )
    }
}
