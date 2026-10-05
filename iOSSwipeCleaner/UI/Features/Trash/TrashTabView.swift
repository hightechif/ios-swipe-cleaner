import SwiftUI

struct TrashTabView: View {
    let deleteQueue: [String]
    let onPhotoTap: (String) -> Void
    let onViewPhoto: (String) -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("Trash Queue")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            if deleteQueue.isEmpty {
                Spacer()
                Text("Trash is empty.").foregroundColor(Theme.secondaryText)
                Spacer()
            } else {
                PhotoGrid(
                    photoIds: deleteQueue,
                    accessibilityLabel: "Trash photo",
                    onTap: onPhotoTap,
                    contextActions: [
                        (title: "View photo", action: onViewPhoto),
                        (title: "Restore", action: onPhotoTap)
                    ]
                )
                Button(action: onDelete) {
                    Text(Formatting.deleteButtonTitle(deleteQueue.count))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.delete)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(16)
            }
        }
    }
}
