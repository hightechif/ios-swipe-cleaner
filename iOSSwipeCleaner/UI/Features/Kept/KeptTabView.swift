import SwiftUI

struct KeptTabView: View {
    let keptPhotos: [KeptPhoto]
    let keptAlbums: [KeptAlbum]
    let onPhotoTap: (String) -> Void
    let onPhotoLongPress: (String) -> Void
    let onResetAll: () -> Void

    @State private var viewMode: KeptViewMode = .allPhotos
    @State private var selectedAlbumId: String?

    private var selectedAlbum: KeptAlbum? { keptAlbums.first { $0.id == selectedAlbumId } }

    var body: some View {
        VStack(spacing: 0) {
            header
            if keptPhotos.isEmpty {
                Spacer()
                VStack(spacing: 6) {
                    Text("No Kept Photos Yet").font(.headline).foregroundColor(.white)
                    Text("Photos you swipe right will show up here.").foregroundColor(Theme.secondaryText)
                }
                Spacer()
            } else {
                content
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("Kept Photos")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            Menu {
                Button("All Kept Photos") { select(.allPhotos) }
                Button("Kept Photos Albums") { select(.albums) }
            } label: {
                Image(systemName: "chevron.down.circle")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.secondaryText)
            }
            .accessibilityLabel("Select View Mode")
            Spacer()
            if !keptPhotos.isEmpty {
                Button(action: onResetAll) {
                    Image(systemName: "arrow.uturn.backward.circle")
                        .font(.system(size: 22))
                        .foregroundColor(Theme.delete)
                }
                .accessibilityLabel("Restore All Kept")
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var content: some View {
        switch viewMode {
        case .allPhotos:
            PhotoGrid(
                photoIds: keptPhotos.map(\.id),
                accessibilityLabel: "Kept Photo",
                onTap: onPhotoTap,
                onLongPress: onPhotoLongPress
            )
        case .albums:
            if let album = selectedAlbum {
                VStack(alignment: .leading, spacing: 0) {
                    Button { selectedAlbumId = nil } label: {
                        Label("Back to Albums (\(album.name))", systemImage: "chevron.left")
                            .foregroundColor(Theme.primary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                    PhotoGrid(
                        photoIds: album.photos.map(\.id),
                        accessibilityLabel: "Kept Photo",
                        onTap: onPhotoTap,
                        onLongPress: onPhotoLongPress
                    )
                }
            } else {
                albumGrid
            }
        }
    }

    private var albumGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(keptAlbums) { album in
                    Button { selectedAlbumId = album.id } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            PhotoImageView(photoId: album.coverPhotoId)
                                .aspectRatio(1, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            Text(album.name).font(.subheadline.weight(.semibold)).foregroundColor(.white).lineLimit(1)
                            Text(Formatting.photos(album.photoCount)).font(.caption).foregroundColor(Theme.secondaryText)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private func select(_ mode: KeptViewMode) {
        viewMode = mode
        selectedAlbumId = nil
    }
}
