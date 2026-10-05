import SwiftUI

/// Square-thumbnail grid used by the Kept and Trash tabs.
struct PhotoGrid: View {
    let photoIds: [String]
    let accessibilityLabel: String
    let onTap: (String) -> Void
    var onLongPress: ((String) -> Void)?
    var contextActions: [(title: String, action: (String) -> Void)] = []

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 6)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(photoIds, id: \.self) { id in
                    cell(for: id)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private func cell(for id: String) -> some View {
        let base = PhotoImageView(photoId: id)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
            .onTapGesture { onTap(id) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(.isButton)
        if let onLongPress {
            base
                .onLongPressGesture { onLongPress(id) }
                .accessibilityAction(named: "Restore") { onLongPress(id) }
        } else if !contextActions.isEmpty {
            base.contextMenu {
                ForEach(contextActions.indices, id: \.self) { index in
                    Button(contextActions[index].title) { contextActions[index].action(id) }
                }
            }
        } else {
            base
        }
    }
}
