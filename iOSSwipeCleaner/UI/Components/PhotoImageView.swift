import SwiftUI

/// Shows a library photo at the size it is displayed, with a placeholder and an error tile.
struct PhotoImageView: View {
    @EnvironmentObject private var loader: ImageLoader

    let photoId: String
    var fill: Bool = true
    /// Requests more pixels than the view size, e.g. so a zoomed image stays sharp.
    var sizeMultiplier: CGFloat = 1
    var background: Color = Theme.surface

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                background
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: fill ? .fill : .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else if failed {
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundColor(Theme.secondaryText)
                        .accessibilityLabel("Photo unavailable")
                } else {
                    ProgressView().tint(Theme.primary)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .task(id: photoId) {
                await load(size: geometry.size)
            }
        }
    }

    private func load(size: CGSize) async {
        image = nil
        failed = false
        let pixels = ImageLoader.pixelSize(for: CGSize(width: size.width * sizeMultiplier, height: size.height * sizeMultiplier))
        for await result in loader.images(for: photoId, pixelSize: pixels, fill: fill) {
            switch result {
            case .image(let loaded, _): image = loaded
            case .failed: if image == nil { failed = true }
            }
        }
    }
}
