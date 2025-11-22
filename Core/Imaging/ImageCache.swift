import Foundation
import UIKit

actor ThumbnailCache {
    static let shared = ThumbnailCache()
    private var store: [UUID: UIImage] = [:]
    private var lru: [UUID] = []
    private var capacity: Int = 200

    func get(_ id: UUID) -> UIImage? {
        if let img = store[id] {
            // mark as recently used
            if let idx = lru.firstIndex(of: id) { lru.remove(at: idx) }
            lru.insert(id, at: 0)
            return img
        }
        return nil
    }

    func set(_ image: UIImage, for id: UUID) {
        store[id] = image
        if let idx = lru.firstIndex(of: id) { lru.remove(at: idx) }
        lru.insert(id, at: 0)
        // evict if over capacity
        while lru.count > capacity {
            if let evict = lru.popLast() {
                store.removeValue(forKey: evict)
            } else { break }
        }
    }

    func setCapacity(_ newValue: Int) {
        capacity = max(20, newValue)
        // Trim if needed
        while lru.count > capacity {
            if let evict = lru.popLast() {
                store.removeValue(forKey: evict)
            } else { break }
        }
    }

    func getCapacity() -> Int { capacity }
}

enum ThumbnailDecode {
    static func decodeThumbnail(_ data: Data, maxDimension: CGFloat) async -> UIImage? {
        await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let source = UIImage(data: data) else {
                    cont.resume(returning: nil)
                    return
                }
                let aspect = source.size.width / max(source.size.height, 1)
                let targetSize: CGSize
                if aspect >= 1 { // landscape or square
                    targetSize = CGSize(width: maxDimension, height: maxDimension / max(aspect, 0.01))
                } else { // portrait
                    targetSize = CGSize(width: maxDimension * aspect, height: maxDimension)
                }
                UIGraphicsBeginImageContextWithOptions(targetSize, true, 0)
                source.draw(in: CGRect(origin: .zero, size: targetSize))
                let resized = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                cont.resume(returning: resized ?? source)
            }
        }
    }
}

// MARK: - Image Processing for Storage

/// Utilities for normalizing and compressing images before storing them.
enum ImageProcessor {
    /// Returns JPEG data for an image that has been resized down to the given
    /// `maxDimension` (longest edge) and compressed with the provided quality.
    /// This keeps on-disk storage and backup sizes reasonable.
    static func normalizedJPEGData(
        from image: UIImage,
        maxDimension: CGFloat = 2000,
        compressionQuality: CGFloat = 0.8
    ) -> Data? {
        let width = image.size.width
        let height = image.size.height
        let maxSide = max(width, height)
        guard maxSide > 0 else { return image.jpegData(compressionQuality: compressionQuality) }

        let scale = maxSide > maxDimension ? maxDimension / maxSide : 1.0
        let targetSize = CGSize(width: width * scale, height: height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return rendered.jpegData(compressionQuality: compressionQuality)
    }
}
