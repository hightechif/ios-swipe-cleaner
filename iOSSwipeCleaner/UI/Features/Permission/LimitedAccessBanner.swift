import SwiftUI

/// Shown above the main content when the user shared only a selection of photos.
struct LimitedAccessBanner: View {
    let onManage: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill").foregroundColor(Theme.primary)
            Text("Only selected photos are available.")
                .font(.footnote)
                .foregroundColor(Theme.secondaryText)
            Spacer()
            Button("Manage selection", action: onManage)
                .font(.footnote.weight(.semibold))
                .foregroundColor(Theme.primary)
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }
}
