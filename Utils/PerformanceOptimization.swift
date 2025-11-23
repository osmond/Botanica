import SwiftUI
import UIKit
import Combine

/// High-performance image caching and loading system for plant photos
class ImageCache: ObservableObject {
    
    // MARK: - Constants
    
    /// Cache configuration constants
    private enum CacheConstants {
        static let maxMemoryImageCount = 50 // Maximum images in memory
        static let maxMemorySizeBytes = 50 * 1024 * 1024 // 50MB memory limit
        static let maxDiskSizeBytes = 100 * 1024 * 1024 // 100MB disk cache
        static let compressionQuality: CGFloat = 0.8 // JPEG compression quality (0.0-1.0)
        static let maxDisplayDimension: CGFloat = 800 // Maximum width/height for plant photos
        static let cacheDirectoryName = "PlantImages"
    }
    
    // MARK: - Properties
    
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    // MARK: - Initialization
    
    private init() {
        // Configure memory cache
        cache.countLimit = CacheConstants.maxMemoryImageCount
        cache.totalCostLimit = CacheConstants.maxMemorySizeBytes
        
        // Setup disk cache directory
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cacheDir.appendingPathComponent(CacheConstants.cacheDirectoryName)
        
        // Create directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Setup memory warnings observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearMemoryCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // Cleanup old cache on startup
        Task { [weak self] in
            await self?.cleanupOldCache()
        }
    }
    
    deinit {
        // Remove notification observers to prevent memory leaks
        NotificationCenter.default.removeObserver(self)
        
        // Clear memory cache
        cache.removeAllObjects()
    }
    
    /// Load image with caching and optimization
    func loadImage(from data: Data, id: String) async -> UIImage? {
        let cacheKey = NSString(string: id)
        
        // Check memory cache first
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Check disk cache
        let diskURL = cacheDirectory.appendingPathComponent("\(id).jpg")
        if let diskImage = UIImage(contentsOfFile: diskURL.path) {
            // Store in memory cache for future access
            cache.setObject(diskImage, forKey: cacheKey)
            return diskImage
        }
        
        // Process and cache the image
        return await processAndCacheImage(data: data, id: id)
    }
    
    /// Process image with optimization and store in cache
    private func processAndCacheImage(data: Data, id: String) async -> UIImage? {
        guard let originalImage = UIImage(data: data) else { return nil }
        
        // Optimize image size and compression
        let optimizedImage = await optimizeImage(originalImage)
        
        let cacheKey = NSString(string: id)
        let diskURL = cacheDirectory.appendingPathComponent("\(id).jpg")
        
        // Store in memory cache
        cache.setObject(optimizedImage, forKey: cacheKey)
        
        // Store in disk cache
        if let compressedData = optimizedImage.jpegData(compressionQuality: CacheConstants.compressionQuality) {
            try? compressedData.write(to: diskURL)
        }
        
        return optimizedImage
    }
    
    /// Optimize image for display performance
    private func optimizeImage(_ image: UIImage) async -> UIImage {
        // Calculate optimal size for display
        let maxDisplaySize = CacheConstants.maxDisplayDimension
        let scale = min(maxDisplaySize / image.size.width, maxDisplaySize / image.size.height, 1.0)
        
        if scale < 1.0 {
            let newSize = CGSize(
                width: image.size.width * scale,
                height: image.size.height * scale
            )
            
            // Resize image on a background thread without capturing self
            return await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                    image.draw(in: CGRect(origin: .zero, size: newSize))
                    let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
                    UIGraphicsEndImageContext()
                    
                    continuation.resume(returning: resizedImage)
                }
            }
        }
        
        return image
    }
    
    /// Clear memory cache (called on memory warnings)
    @objc private func clearMemoryCache() {
        cache.removeAllObjects()
    }
    
    /// Clean up old cached files
    private func cleanupOldCache() async {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey], options: [])
            
            // Calculate total cache size
            var totalSize: Int64 = 0
            var fileInfos: [(URL, Date, Int64)] = []
            
            for file in files {
                let attributes = try fileManager.attributesOfItem(atPath: file.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                let modDate = attributes[.modificationDate] as? Date ?? Date.distantPast
                
                totalSize += fileSize
                fileInfos.append((file, modDate, fileSize))
            }
            
            // Remove old files if cache is too large
            if totalSize > CacheConstants.maxDiskSizeBytes {
                // Sort by modification date (oldest first)
                fileInfos.sort { $0.1 < $1.1 }
                
                var currentSize = totalSize
                for (fileURL, _, fileSize) in fileInfos {
                    if currentSize <= CacheConstants.maxDiskSizeBytes { break }
                    
                    try? fileManager.removeItem(at: fileURL)
                    currentSize -= fileSize
                }
            }
        } catch {
            print("Cache cleanup error: \(error)")
        }
    }
    
    /// Clear all cached data
    func clearAllCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}

/// Optimized image view for plant photos
struct OptimizedPlantImageView: View {
    let imageData: Data?
    let imageId: String
    let placeholder: String
    let aspectRatio: CGFloat?
    
    @StateObject private var imageCache = ImageCache.shared
    @State private var displayImage: UIImage?
    @State private var isLoading = true
    @State private var loadTask: Task<Void, Never>?
    
    init(
        imageData: Data?,
        imageId: String,
        placeholder: String = "leaf.fill",
        aspectRatio: CGFloat? = 1.0
    ) {
        self.imageData = imageData
        self.imageId = imageId
        self.placeholder = placeholder
        self.aspectRatio = aspectRatio
    }
    
    var body: some View {
        Group {
            if let displayImage = displayImage {
                Image(uiImage: displayImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                // Loading placeholder with shimmer effect
                Rectangle()
                    .fill(BotanicaTheme.Gradients.card)
                    .overlay {
                        VStack(spacing: BotanicaTheme.Spacing.sm) {
                            ProgressView()
                                .scaleEffect(0.8)
                            
                            Image(systemName: placeholder)
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
            } else {
                // Static placeholder
                Rectangle()
                    .fill(BotanicaTheme.Gradients.card)
                    .overlay {
                        Image(systemName: placeholder)
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
            }
        }
        .task {
            await loadImage()
        }
        .onChange(of: imageData) { _, _ in
            // Cancel previous load task if any
            loadTask?.cancel()
            
            loadTask = Task {
                await loadImage()
            }
        }
        .onDisappear {
            // Cancel any ongoing load tasks to prevent memory leaks
            loadTask?.cancel()
            loadTask = nil
        }
    }
    
    private func loadImage() async {
        guard let imageData = imageData else {
            isLoading = false
            return
        }
        
        // Check if task was cancelled
        guard !Task.isCancelled else {
            return
        }
        
        isLoading = true
        
        let image = await imageCache.loadImage(from: imageData, id: imageId)
        
        // Check again before updating UI
        guard !Task.isCancelled else {
            return
        }
        
        await MainActor.run {
            displayImage = image
            isLoading = false
        }
    }
}

/// Performance monitoring for SwiftData queries
class QueryPerformanceMonitor {
    static let shared = QueryPerformanceMonitor()
    
    private var queryTimes: [String: [TimeInterval]] = [:]
    private let maxStoredTimes = 100
    
    private init() {}
    
    /// Track query performance
    func trackQuery<T>(_ name: String, operation: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let duration = endTime - startTime
        recordQueryTime(name: name, duration: duration)
        
        // Log slow queries in debug mode
        #if DEBUG
        if duration > 0.1 { // Queries slower than 100ms
            print("⚠️ Slow query '\(name)': \(String(format: "%.3f", duration * 1000))ms")
        }
        #endif
        
        return result
    }
    
    /// Track async query performance
    func trackAsyncQuery<T>(_ name: String, operation: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let duration = endTime - startTime
        recordQueryTime(name: name, duration: duration)
        
        #if DEBUG
        if duration > 0.1 {
            print("⚠️ Slow async query '\(name)': \(String(format: "%.3f", duration * 1000))ms")
        }
        #endif
        
        return result
    }
    
    private func recordQueryTime(name: String, duration: TimeInterval) {
        if queryTimes[name] == nil {
            queryTimes[name] = []
        }
        
        queryTimes[name]?.append(duration)
        
        // Keep only recent measurements
        if let count = queryTimes[name]?.count, count > maxStoredTimes {
            queryTimes[name]?.removeFirst(count - maxStoredTimes)
        }
    }
    
    /// Get average query time for debugging
    func getAverageQueryTime(for name: String) -> TimeInterval? {
        guard let times = queryTimes[name], !times.isEmpty else { return nil }
        return times.reduce(0, +) / Double(times.count)
    }
    
    /// Print performance summary
    func printDebugSummary() {
        #if DEBUG
        print("🔍 Query Performance Summary:")
        for (name, times) in queryTimes {
            let avg = times.reduce(0, +) / Double(times.count)
            let max = times.max() ?? 0
            print("  \(name): avg \(String(format: "%.1f", avg * 1000))ms, max \(String(format: "%.1f", max * 1000))ms")
        }
        #endif
    }
}

#Preview {
    OptimizedPlantImageView(
        imageData: nil,
        imageId: "preview-plant",
        placeholder: "leaf.fill"
    )
    .frame(width: 200, height: 200)
    .clipShape(RoundedRectangle(cornerRadius: 12))
}
