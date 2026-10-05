import SwiftUI

struct AlbumSelectorSheet: View {
    let albums: [Album]
    let selectedAlbumId: String?
    let onSelect: (Album?) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 0) {
                HStack {
                    Text("Select Folder").font(.title3.bold()).foregroundColor(.white)
                    Spacer()
                    Button("Close", action: onDismiss).foregroundColor(Theme.primary)
                }
                .padding(20)
                ScrollView {
                    LazyVStack(spacing: 8) {
                        row(title: "All Photos", subtitle: nil, coverId: nil, isSelected: selectedAlbumId == nil) {
                            onSelect(nil)
                        }
                        ForEach(albums) { album in
                            row(
                                title: album.name,
                                subtitle: Formatting.photos(album.photoCount),
                                coverId: album.coverPhotoId,
                                isSelected: album.id == selectedAlbumId
                            ) { onSelect(album) }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    private func row(title: String, subtitle: String?, coverId: String?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Group {
                    if let coverId {
                        PhotoImageView(photoId: coverId)
                    } else {
                        ZStack { Theme.surface; Image(systemName: "photo.on.rectangle").foregroundColor(Theme.secondaryText) }
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).foregroundColor(.white).font(.body.weight(.semibold))
                    if let subtitle { Text(subtitle).foregroundColor(Theme.secondaryText).font(.footnote) }
                }
                Spacer()
                if isSelected { Image(systemName: "checkmark").foregroundColor(Theme.primary) }
            }
            .padding(10)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
