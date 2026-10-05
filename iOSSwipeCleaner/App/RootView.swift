import SwiftUI

/// Chooses between the permission onboarding and the main screen from the current authorization.
struct RootView: View {
    @ObservedObject var viewModel: RootViewModel
    let container: AppContainer

    var body: some View {
        ZStack {
            AppBackground()
            if viewModel.authorization.canReadLibrary {
                MainView(
                    swipeViewModel: container.swipeViewModel,
                    trashViewModel: container.trashViewModel,
                    keptViewModel: container.keptViewModel,
                    isLimitedAccess: viewModel.authorization == .limited,
                    onManageSelection: viewModel.manageLimitedSelection
                )
            } else {
                PermissionView(
                    authorization: viewModel.authorization,
                    onAllowAccess: { Task { await viewModel.requestAccess() } },
                    onOpenSettings: viewModel.openSettings
                )
            }
        }
    }
}
