import Foundation
import UIKit

/// Lightweight descriptor used for generating a reference image without
/// passing SwiftData models across actor boundaries.
struct PlantImageDescriptor: Sendable {
    let id: UUID
    let displayName: String
    let scientificName: String
    let commonNames: [String]
}

/// Service that generates a reference image for a plant using the
/// existing OpenAI API key. Images are cached on disk so each plant
/// only incurs a single generation cost.
final class PlantImageService {
    static let shared = PlantImageService()
    
    private let config = OpenAIConfig.shared
    private let client = OpenAIClient()
    private let inMemoryCache = NSCache<NSString, UIImage>()
    
    private init() {}
    
    /// Clears both memory and disk caches for generated reference images.
    func clearCache() {
        inMemoryCache.removeAllObjects()
        guard let dir = cacheDirectory() else { return }
        try? FileManager.default.removeItem(at: dir)
    }
    
    // MARK: - Public API
    
    /// Returns a cached or newly generated reference image for the given plant
    /// descriptor. Callers are responsible for ensuring that the plant does not
    /// already have a user photo.
    func referenceImage(for descriptor: PlantImageDescriptor) async -> UIImage? {
        guard config.isConfigured, config.useAIReferenceImages else { return nil }
        
        let key = cacheKey(for: descriptor)
        
        if let cached = inMemoryCache.object(forKey: key as NSString) {
            return cached
        }
        
        if let diskImage = loadFromDisk(key: key) {
            inMemoryCache.setObject(diskImage, forKey: key as NSString)
            return diskImage
        }
        
        guard let generated = try? await generateImage(for: descriptor) else {
            return nil
        }
        
        inMemoryCache.setObject(generated, forKey: key as NSString)
        saveToDisk(image: generated, key: key)
        return generated
    }
    
    // MARK: - Image Generation
    
    private func generateImage(for descriptor: PlantImageDescriptor) async throws -> UIImage {
        let prompt = buildPrompt(for: descriptor)
        return try await client.generateImage(prompt: prompt, size: "1024x1024")
    }
    
    private func buildPrompt(for descriptor: PlantImageDescriptor) -> String {
        let display = descriptor.displayName
        let scientific = descriptor.scientificName
        let common = descriptor.commonNames.joined(separator: ", ")
        
        var descriptors: [String] = []
        descriptors.append("High-quality, natural-light photo of a healthy indoor potted plant.")
        descriptors.append("Subject centered, soft background, no people, no text, no graphics.")
        
        var nameLine = "The plant should be \(display)"
        if !scientific.isEmpty {
            nameLine += " (scientific name: \(scientific))"
        }
        if !common.isEmpty {
            nameLine += ", also known as \(common)"
        }
        
        descriptors.append(nameLine + ".")
        descriptors.append("Show the whole plant and pot, realistic style, 4:5 aspect ratio framing.")
        
        return descriptors.joined(separator: " ")
    }
    
    // MARK: - Caching
    
    private func cacheKey(for descriptor: PlantImageDescriptor) -> String {
        return descriptor.id.uuidString
    }
    
    private func cacheDirectory() -> URL? {
        guard let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = base.appendingPathComponent("PlantReferenceImages", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    private func fileURL(for key: String) -> URL? {
        guard let dir = cacheDirectory() else { return nil }
        return dir.appendingPathComponent("\(key).jpg")
    }
    
    private func saveToDisk(image: UIImage, key: String) {
        guard let url = fileURL(for: key),
              let data = image.jpegData(compressionQuality: 0.9) else { return }
        try? data.write(to: url)
    }
    
    private func loadFromDisk(key: String) -> UIImage? {
        guard let url = fileURL(for: key),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        return image
    }
}
