//
//  ImageCacheTests.swift
//  BotanicaTests
//
//  Created by GitHub Copilot
//

import XCTest
import UIKit
@testable import Botanica

final class ImageCacheTests: XCTestCase {
    
    var cache: ImageCache!
    
    override func setUp() {
        super.setUp()
        cache = ImageCache.shared
        cache.clearAll() // Clean slate for each test
    }
    
    override func tearDown() {
        cache.clearAll()
        cache = nil
        super.tearDown()
    }
    
    // MARK: - Basic Cache Operations
    
    func testCacheImage_StoresAndRetrievesSuccessfully() {
        // Given: An image and a key
        let image = createTestImage(size: CGSize(width: 100, height: 100), color: .red)
        let key = "test-image-1"
        
        // When: Store the image
        cache.cache(image, for: key)
        
        // Then: Should be able to retrieve it
        let retrieved = cache.image(for: key)
        XCTAssertNotNil(retrieved, "Should retrieve cached image")
        XCTAssertEqual(retrieved?.size, image.size, "Retrieved image should have same size")
    }
    
    func testCacheImage_OverwritesExistingKey() {
        // Given: Two different images with same key
        let image1 = createTestImage(size: CGSize(width: 100, height: 100), color: .red)
        let image2 = createTestImage(size: CGSize(width: 200, height: 200), color: .blue)
        let key = "test-image"
        
        // When: Cache both images with same key
        cache.cache(image1, for: key)
        cache.cache(image2, for: key)
        
        // Then: Should retrieve the second image
        let retrieved = cache.image(for: key)
        XCTAssertNotNil(retrieved, "Should retrieve cached image")
        XCTAssertEqual(retrieved?.size, image2.size, "Should retrieve most recent image")
    }
    
    func testRetrieveNonExistentImage_ReturnsNil() {
        // Given: A key that doesn't exist
        let key = "non-existent-key"
        
        // When: Try to retrieve
        let retrieved = cache.image(for: key)
        
        // Then: Should return nil
        XCTAssertNil(retrieved, "Should return nil for non-existent key")
    }
    
    func testRemoveImage_DeletesFromCache() {
        // Given: A cached image
        let image = createTestImage(size: CGSize(width: 100, height: 100), color: .red)
        let key = "test-image"
        cache.cache(image, for: key)
        
        // When: Remove the image
        cache.removeImage(for: key)
        
        // Then: Should no longer be retrievable
        let retrieved = cache.image(for: key)
        XCTAssertNil(retrieved, "Image should be removed from cache")
    }
    
    func testClearAll_RemovesAllImages() {
        // Given: Multiple cached images
        let keys = ["image1", "image2", "image3"]
        for key in keys {
            let image = createTestImage(size: CGSize(width: 100, height: 100), color: .red)
            cache.cache(image, for: key)
        }
        
        // When: Clear all
        cache.clearAll()
        
        // Then: All images should be removed
        for key in keys {
            let retrieved = cache.image(for: key)
            XCTAssertNil(retrieved, "All images should be cleared")
        }
    }
    
    // MARK: - Image Compression Tests
    
    func testCacheImage_CompressesLargeImages() {
        // Given: A very large image (exceeding max display dimension)
        let largeImage = createTestImage(size: CGSize(width: 2000, height: 2000), color: .red)
        let key = "large-image"
        
        // When: Cache the large image
        cache.cache(largeImage, for: key)
        
        // Then: Retrieved image should be compressed to max dimensions (800x800)
        let retrieved = cache.image(for: key)
        XCTAssertNotNil(retrieved, "Should cache and retrieve large image")
        
        let maxDimension = max(retrieved!.size.width, retrieved!.size.height)
        XCTAssertLessThanOrEqual(maxDimension, 800, "Large images should be compressed to max dimension")
    }
    
    func testCacheImage_PreservesAspectRatio() {
        // Given: A rectangular image
        let originalWidth: CGFloat = 1600
        let originalHeight: CGFloat = 800
        let image = createTestImage(size: CGSize(width: originalWidth, height: originalHeight), color: .blue)
        let key = "aspect-ratio-test"
        
        // When: Cache the image
        cache.cache(image, for: key)
        
        // Then: Aspect ratio should be preserved
        let retrieved = cache.image(for: key)
        XCTAssertNotNil(retrieved, "Should retrieve cached image")
        
        let originalAspectRatio = originalWidth / originalHeight
        let retrievedAspectRatio = retrieved!.size.width / retrieved!.size.height
        XCTAssertEqual(originalAspectRatio, retrievedAspectRatio, accuracy: 0.01, 
                      "Aspect ratio should be preserved during compression")
    }
    
    func testCacheImage_DoesNotCompressSmallImages() {
        // Given: A small image (below max display dimension)
        let smallImage = createTestImage(size: CGSize(width: 400, height: 400), color: .green)
        let key = "small-image"
        
        // When: Cache the small image
        cache.cache(smallImage, for: key)
        
        // Then: Image should not be compressed
        let retrieved = cache.image(for: key)
        XCTAssertNotNil(retrieved, "Should retrieve cached image")
        XCTAssertEqual(retrieved?.size, smallImage.size, "Small images should not be compressed")
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryCache_HandlesMultipleImages() {
        // Given: Multiple images
        let imageCount = 10
        
        // When: Cache multiple images
        for i in 0..<imageCount {
            let image = createTestImage(size: CGSize(width: 200, height: 200), color: .red)
            cache.cache(image, for: "image-\(i)")
        }
        
        // Then: All images should be retrievable initially
        for i in 0..<imageCount {
            let retrieved = cache.image(for: "image-\(i)")
            XCTAssertNotNil(retrieved, "Should cache multiple images")
        }
    }
    
    func testMemoryCache_EvictsWhenFull() {
        // Given: Maximum memory cache count (50 images per CacheConstants)
        let maxCount = 55 // Slightly over limit
        
        // When: Cache more images than the limit
        for i in 0..<maxCount {
            let image = createTestImage(size: CGSize(width: 100, height: 100), color: .red)
            cache.cache(image, for: "image-\(i)")
        }
        
        // Then: Some images should be evicted (first images added)
        var retrievedCount = 0
        for i in 0..<maxCount {
            if cache.image(for: "image-\(i)") != nil {
                retrievedCount += 1
            }
        }
        
        // Should have evicted some images
        XCTAssertLessThan(retrievedCount, maxCount, "Cache should evict oldest images when full")
    }
    
    // MARK: - Disk Persistence Tests
    
    func testDiskCache_PersistsImagesToDisk() async {
        // Given: An image cached in memory
        let image = createTestImage(size: CGSize(width: 300, height: 300), color: .blue)
        let key = "disk-persist-test"
        cache.cache(image, for: key)
        
        // When: Save to disk
        await cache.saveToDisk(for: key)
        
        // Then: Image should be retrievable from disk
        let diskImage = await cache.loadFromDisk(for: key)
        XCTAssertNotNil(diskImage, "Image should be saved to disk")
        XCTAssertEqual(diskImage?.size, image.size, "Disk image should match cached image")
    }
    
    func testDiskCache_LoadsWhenNotInMemory() async {
        // Given: An image saved to disk but not in memory
        let image = createTestImage(size: CGSize(width: 300, height: 300), color: .green)
        let key = "disk-load-test"
        cache.cache(image, for: key)
        await cache.saveToDisk(for: key)
        
        // When: Clear memory cache
        cache.clearAll()
        
        // Then: Should be able to load from disk
        let diskImage = await cache.loadFromDisk(for: key)
        XCTAssertNotNil(diskImage, "Should load from disk when not in memory")
    }
    
    func testDiskCache_ClearsDiskCache() async {
        // Given: Multiple images saved to disk
        let keys = ["disk1", "disk2", "disk3"]
        for key in keys {
            let image = createTestImage(size: CGSize(width: 200, height: 200), color: .red)
            cache.cache(image, for: key)
            await cache.saveToDisk(for: key)
        }
        
        // When: Clear disk cache
        await cache.clearDiskCache()
        
        // Then: All disk images should be removed
        for key in keys {
            let diskImage = await cache.loadFromDisk(for: key)
            XCTAssertNil(diskImage, "All disk images should be cleared")
        }
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentAccess_MultipleReadsAndWrites() async {
        // Given: Multiple concurrent operations
        let operationCount = 20
        
        // When: Perform concurrent cache operations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<operationCount {
                group.addTask {
                    let image = self.createTestImage(size: CGSize(width: 100, height: 100), color: .red)
                    let key = "concurrent-\(i)"
                    self.cache.cache(image, for: key)
                    _ = self.cache.image(for: key)
                }
            }
        }
        
        // Then: All operations should complete without crashes
        // Verify some images are cached
        var cachedCount = 0
        for i in 0..<operationCount {
            if cache.image(for: "concurrent-\(i)") != nil {
                cachedCount += 1
            }
        }
        XCTAssertGreaterThan(cachedCount, 0, "Should cache some images during concurrent access")
    }
    
    // MARK: - Performance Tests
    
    func testCachePerformance_LargeNumberOfImages() {
        // Given: Performance test for caching many images
        let imageCount = 100
        
        measure {
            // When: Cache many images
            for i in 0..<imageCount {
                let image = createTestImage(size: CGSize(width: 200, height: 200), color: .red)
                cache.cache(image, for: "perf-\(i)")
            }
        }
    }
    
    func testRetrievalPerformance_RepeatedAccess() {
        // Given: Cached images
        let imageCount = 50
        for i in 0..<imageCount {
            let image = createTestImage(size: CGSize(width: 200, height: 200), color: .red)
            cache.cache(image, for: "perf-retrieve-\(i)")
        }
        
        measure {
            // When: Repeatedly retrieve images
            for i in 0..<imageCount {
                _ = cache.image(for: "perf-retrieve-\(i)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage(size: CGSize, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
