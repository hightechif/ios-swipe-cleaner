import SwiftUI

struct PermissionView: View {
    let authorization: PhotoAuthorization
    let onAllowAccess: () -> Void
    let onOpenSettings: () -> Void

    private var isDenied: Bool { authorization == .denied }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: isDenied ? "lock.fill" : "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(Theme.primary)
                .accessibilityHidden(true)
            Text("SwipeCleaner")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.white)
            Text(isDenied
                 ? "Photo access is turned off. Open Settings and allow access to your photos so you can start cleaning up."
                 : "SwipeCleaner needs access to your photos so you can swipe right to keep and left to delete. Nothing is deleted until you confirm.")
                .font(.body)
                .foregroundColor(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: isDenied ? onOpenSettings : onAllowAccess) {
                Text(isDenied ? "Open Settings" : "Allow Access")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 32)
            Spacer()
        }
    }
}
