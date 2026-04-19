import SwiftUI
import FirebaseCore

@main
struct LocalTasksApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
