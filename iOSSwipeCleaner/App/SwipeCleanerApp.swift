import SwiftUI

@main
struct SwipeCleanerApp: App {
    private let container: AppContainer?

    init() {
        // Unit tests use their own fixtures; don't spin up PhotoKit/Core Data in the host app.
        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        container = isRunningTests ? nil : AppContainer()
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                RootView(viewModel: container.rootViewModel, container: container)
                    .environmentObject(container.imageLoader)
                    .preferredColorScheme(.dark)
            }
        }
    }
}
