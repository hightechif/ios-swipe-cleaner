import Photos
import UIKit

enum ImageLoadResult {
    /// `isDegraded` images are low-quality placeholders; a final one follows.
    case image(UIImage, isDegraded: Bool)
    case failed
}

/// Loads photo-library images at the size actually displayed.
final class ImageLoader: ObservableObject {
    private let manager = PHCachingImageManager()
    private let assetCache = NSCache<NSString, PHAsset>()

    init() {
        assetCache.countLimit = 200
    }

    /// Pixel size for a view of the given point size on the current screen.
    static func pixelSize(for points: CGSize) -> CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: max(points.width, 1) * scale, height: max(points.height, 1) * scale)
    }

    func images(for id: String, pixelSize: CGSize, fill: Bool) -> AsyncStream<ImageLoadResult> {
        AsyncStream { continuation in
            guard let asset = asset(for: id) else {
                continuation.yield(.failed)
                continuation.finish()
                return
            }
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true

            let requestId = manager.requestImage(
                for: asset,
                targetSize: pixelSize,
                contentMode: fill ? .aspectFill : .aspectFit,
                options: options
            ) { image, info in
                let cancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if let image {
                    continuation.yield(.image(image, isDegraded: degraded))
                    if !degraded { continuation.finish() }
                } else if !cancelled, info?[PHImageErrorKey] != nil {
                    continuation.yield(.failed)
                    continuation.finish()
                }
            }
            continuation.onTermination = { [manager] _ in manager.cancelImageRequest(requestId) }
        }
    }

    func startCaching(ids: [String], pixelSize: CGSize) {
        let assets = ids.compactMap(asset(for:))
        manager.startCachingImages(for: assets, targetSize: pixelSize, contentMode: .aspectFill, options: nil)
    }

    func stopCaching() {
        manager.stopCachingImagesForAllAssets()
    }

    private func asset(for id: String) -> PHAsset? {
        if let cached = assetCache.object(forKey: id as NSString) { return cached }
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject else { return nil }
        assetCache.setObject(asset, forKey: id as NSString)
        return asset
    }
}
