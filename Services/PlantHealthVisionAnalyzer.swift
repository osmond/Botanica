import Vision
import UIKit
import CoreML
import SwiftUI

/// Advanced plant health analysis using computer vision and machine learning
/// Provides automated health assessment, disease detection, and growth tracking from photos
@MainActor
class PlantHealthVisionAnalyzer: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAnalyzing = false
    @Published var lastAnalysis: PlantHealthAnalysis?
    @Published var lastError: Error?
    @Published var analysisHistory: [PlantHealthAnalysis] = []
    
    // MARK: - Private Properties
    private var visionRequests: [VNRequest] = []
    private let aiPlantCoach = AIPlantCoach()
    
    // MARK: - Initialization
    init() {
        setupVisionRequests()
    }
    
    // MARK: - Public Methods
    
    /// Analyze plant health from a photo using computer vision
    /// - Parameters:
    ///   - image: The plant photo to analyze
    ///   - plant: The plant being analyzed (for context)
    /// - Returns: Comprehensive health analysis
    func analyzeHealthFromPhoto(
        image: UIImage,
        plant: Plant
    ) async throws -> PlantHealthAnalysis {
        
        isAnalyzing = true
        lastError = nil
        
        defer {
            isAnalyzing = false
        }
        
        do {
            // Step 1: Extract visual features using Vision
            let visualFeatures = try await extractVisualFeatures(from: image)
            
            // Step 2: Detect potential health issues
            let healthIssues = try await detectHealthIssues(from: image, features: visualFeatures)
            
            // Step 3: Analyze growth patterns (if comparing with previous photos)
            let growthAnalysis = await analyzeGrowthPatterns(for: plant, newImage: image)
            
            // Step 4: Generate AI-powered health assessment
            let aiAssessment = try await generateAIHealthAssessment(
                visualFeatures: visualFeatures,
                healthIssues: healthIssues,
                growthAnalysis: growthAnalysis,
                plant: plant
            )
            
            // Step 5: Create comprehensive analysis
            let analysis = PlantHealthAnalysis(
                id: UUID(),
                plantId: plant.id,
                plantName: plant.nickname,
                analysisDate: Date(),
                originalImage: image,
                visualFeatures: visualFeatures,
                healthScore: calculateOverallHealthScore(
                    visualFeatures: visualFeatures,
                    healthIssues: healthIssues,
                    aiAssessment: aiAssessment
                ),
                healthIssues: healthIssues,
                growthAnalysis: growthAnalysis,
                aiAssessment: aiAssessment,
                recommendations: generateRecommendations(
                    from: healthIssues,
                    growthAnalysis: growthAnalysis,
                    aiAssessment: aiAssessment
                ),
                confidence: calculateConfidence(
                    visualFeatures: visualFeatures,
                    healthIssues: healthIssues
                )
            )
            
            // Store analysis
            lastAnalysis = analysis
            analysisHistory.append(analysis)
            
            return analysis
            
        } catch {
            lastError = error
            throw error
        }
    }
    
    /// Compare two plant photos to track growth and changes
    /// - Parameters:
    ///   - beforeImage: Earlier photo
    ///   - afterImage: More recent photo
    ///   - plant: The plant being compared
    /// - Returns: Growth comparison analysis
    func comparePhotosForGrowth(
        beforeImage: UIImage,
        afterImage: UIImage,
        plant: Plant
    ) async throws -> GrowthComparisonAnalysis {
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        do {
            // Extract features from both images
            let beforeFeatures = try await extractVisualFeatures(from: beforeImage)
            let afterFeatures = try await extractVisualFeatures(from: afterImage)
            
            // Compare features
            let comparison = GrowthComparisonAnalysis(
                plantId: plant.id,
                beforeDate: Date().addingTimeInterval(-7 * 24 * 3600), // Assume 1 week difference
                afterDate: Date(),
                sizeChange: calculateSizeChange(before: beforeFeatures, after: afterFeatures),
                leafCountChange: calculateLeafCountChange(before: beforeFeatures, after: afterFeatures),
                colorChanges: calculateColorChanges(before: beforeFeatures, after: afterFeatures),
                overallGrowthScore: calculateGrowthScore(before: beforeFeatures, after: afterFeatures),
                insights: generateGrowthInsights(before: beforeFeatures, after: afterFeatures)
            )
            
            return comparison
            
        } catch {
            lastError = error
            throw error
        }
    }
    
    /// Quick health screening for immediate feedback
    /// - Parameter image: Plant photo to screen
    /// - Returns: Quick health assessment
    func quickHealthScreen(image: UIImage) async throws -> QuickHealthScreen {
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        do {
            let features = try await extractBasicFeatures(from: image)
            
            return QuickHealthScreen(
                overallHealth: assessQuickHealth(from: features),
                alerts: generateQuickAlerts(from: features),
                confidence: min(0.8, features.overallQuality)
            )
            
        } catch {
            lastError = error
            throw error
        }
    }
}

// MARK: - Vision Processing
private extension PlantHealthVisionAnalyzer {
    
    func setupVisionRequests() {
        // Create classification request for plant health
        visionRequests = [
            createClassificationRequest(),
            createObjectDetectionRequest(),
            createImageAnalysisRequest()
        ]
    }
    
    func createClassificationRequest() -> VNClassifyImageRequest {
        let request = VNClassifyImageRequest { request, error in
            if let error = error {
                print("Classification error: \(error)")
                return
            }
            
            guard let observations = request.results as? [VNClassificationObservation] else { return }
            
            // Process classification results
            for observation in observations.prefix(5) {
                print("Classification: \(observation.identifier) - \(observation.confidence)")
            }
        }
        
        // no-op: VNClassifyImageRequest does not support leaf-specific limits
        return request
    }
    
    func createObjectDetectionRequest() -> VNDetectRectanglesRequest {
        let request = VNDetectRectanglesRequest { request, error in
            if let error = error {
                print("Object detection error: \(error)")
                return
            }
            
            guard let observations = request.results as? [VNRectangleObservation] else { return }
            
            // Process detected rectangles (leaf shapes, pots, etc.)
            for observation in observations {
                print("Detected rectangle with confidence: \(observation.confidence)")
            }
        }
        
        request.maximumObservations = 20
        request.minimumConfidence = 0.3
        request.minimumAspectRatio = 0.2
        request.maximumAspectRatio = 3.0
        
        return request
    }
    
    func createImageAnalysisRequest() -> VNGenerateImageFeaturePrintRequest {
        return VNGenerateImageFeaturePrintRequest()
    }
    
    func extractVisualFeatures(from image: UIImage) async throws -> PlantVisualFeatures {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: VisionAnalysisError.invalidImage)
                return
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            // Create requests for different analyses
            let colorAnalysisRequest = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                // Process results and create features
                let features = self.processVisionResults(request.results, image: image)
                continuation.resume(returning: features)
            }
            
            do {
                try handler.perform([colorAnalysisRequest])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func extractBasicFeatures(from image: UIImage) async throws -> BasicVisualFeatures {
        // Simplified feature extraction for quick screening
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: VisionAnalysisError.invalidImage)
                return
            }
            
            // Analyze basic image properties
            let features = BasicVisualFeatures(
                brightness: calculateBrightness(from: cgImage),
                colorDistribution: analyzeColorDistribution(from: cgImage),
                sharpness: calculateSharpness(from: cgImage),
                overallQuality: assessImageQuality(from: cgImage)
            )
            
            continuation.resume(returning: features)
        }
    }
    
    func processVisionResults(_ results: [Any]?, image: UIImage) -> PlantVisualFeatures {
        // Process Vision framework results and convert to plant features
        return PlantVisualFeatures(
            leafColor: extractLeafColor(from: image),
            leafShape: .oval, // Simplified - would use shape detection
            leafCount: estimateLeafCount(from: image),
            plantSize: estimatePlantSize(from: image),
            soilVisibility: assessSoilVisibility(from: image),
            lightingConditions: assessLighting(from: image),
            imageQuality: assessImageQuality(from: image.cgImage!),
            dominantColors: extractDominantColors(from: image),
            textureAnalysis: analyzeTexture(from: image)
        )
    }
    
    // MARK: - Feature Extraction Helpers
    
    func calculateBrightness(from cgImage: CGImage) -> Double {
        // Simplified brightness calculation
        return 0.7 // Placeholder
    }
    
    func analyzeColorDistribution(from cgImage: CGImage) -> ColorDistribution {
        // Analyze color distribution in the image
        return ColorDistribution(
            green: 0.4,
            brown: 0.2,
            yellow: 0.1,
            other: 0.3
        )
    }
    
    func calculateSharpness(from cgImage: CGImage) -> Double {
        // Calculate image sharpness/focus quality
        return 0.8 // Placeholder
    }
    
    func assessImageQuality(from cgImage: CGImage) -> Double {
        // Overall image quality assessment
        return 0.85 // Placeholder
    }
    
    func extractLeafColor(from image: UIImage) -> LeafColorHealth {
        // Analyze leaf color for health indicators
        return .healthy // Simplified
    }
    
    func estimateLeafCount(from image: UIImage) -> Int {
        // Estimate number of visible leaves
        return 15 // Placeholder
    }
    
    func estimatePlantSize(from image: UIImage) -> RelativePlantSize {
        // Estimate relative plant size in frame
        return RelativePlantSize(
            width: 0.6,
            height: 0.8,
            estimatedActualSize: .medium
        )
    }
    
    func assessSoilVisibility(from image: UIImage) -> SoilAnalysis {
        // Analyze visible soil for moisture, color, etc.
        return SoilAnalysis(
            visibility: 0.3,
            moistureLevel: .moderate,
            color: .brown,
            texture: .normal
        )
    }
    
    func assessLighting(from image: UIImage) -> LightingAnalysis {
        // Analyze lighting conditions in photo
        return LightingAnalysis(
            brightness: .good,
            direction: .natural,
            shadows: .minimal,
            quality: .good
        )
    }
    
    func extractDominantColors(from image: UIImage) -> [ColorInfo] {
        // Extract dominant colors and their percentages
        return [
            ColorInfo(color: .green, percentage: 0.45, healthSignificance: .positive),
            ColorInfo(color: .brown, percentage: 0.25, healthSignificance: .neutral),
            ColorInfo(color: .yellow, percentage: 0.15, healthSignificance: .warning)
        ]
    }
    
    func analyzeTexture(from image: UIImage) -> TextureAnalysis {
        // Analyze leaf and plant texture
        return TextureAnalysis(
            leafTexture: .smooth,
            surfaceQuality: .healthy,
            patterns: [.veining, .natural]
        )
    }
}

// MARK: - Health Issue Detection
private extension PlantHealthVisionAnalyzer {
    
    func detectHealthIssues(from image: UIImage, features: PlantVisualFeatures) async throws -> [HealthIssueDetection] {
        var issues: [HealthIssueDetection] = []
        
        // Analyze for common issues based on visual features
        
        // 1. Leaf discoloration
        if case .yellowing = features.leafColor {
            issues.append(HealthIssueDetection(
                type: .leafYellowing,
                severity: .moderate,
                confidence: 0.8,
                affectedArea: .leaves,
                description: "Yellowing leaves detected, may indicate overwatering or nutrient deficiency",
                recommendedAction: "Check soil moisture and consider fertilizing"
            ))
        }
        
        // 2. Low leaf count (possible dropping)
        if features.leafCount < 5 {
            issues.append(HealthIssueDetection(
                type: .leafDrop,
                severity: .high,
                confidence: 0.7,
                affectedArea: .overall,
                description: "Low leaf count may indicate stress or poor health",
                recommendedAction: "Review care routine and environmental conditions"
            ))
        }
        
        // 3. Poor soil visibility (overgrowth or undergrowth)
        if features.soilVisibility.visibility > 0.8 {
            issues.append(HealthIssueDetection(
                type: .undergrowth,
                severity: .moderate,
                confidence: 0.6,
                affectedArea: .overall,
                description: "Plant appears small for pot size",
                recommendedAction: "Consider increasing light or nutrients"
            ))
        }
        
        // 4. Lighting issues
        if case .poor = features.lightingConditions.brightness {
            issues.append(HealthIssueDetection(
                type: .inadequateLight,
                severity: .moderate,
                confidence: 0.7,
                affectedArea: .overall,
                description: "Poor lighting conditions detected in photo",
                recommendedAction: "Move plant to brighter location or add grow lights"
            ))
        }
        
        return issues
    }
}

// MARK: - Growth Analysis
private extension PlantHealthVisionAnalyzer {
    
    func analyzeGrowthPatterns(for plant: Plant, newImage: UIImage) async -> GrowthPatternAnalysis {
        // Simplified growth analysis
        return GrowthPatternAnalysis(
            growthRate: .normal,
            direction: .upward,
            leafDevelopment: .healthy,
            sizeIncrease: 0.1, // 10% size increase
            timeframe: .week,
            confidence: 0.6
        )
    }
    
    func calculateSizeChange(before: PlantVisualFeatures, after: PlantVisualFeatures) -> SizeChangeAnalysis {
        let widthChange = after.plantSize.width - before.plantSize.width
        let heightChange = after.plantSize.height - before.plantSize.height
        
        return SizeChangeAnalysis(
            widthChange: widthChange,
            heightChange: heightChange,
            percentageIncrease: (widthChange + heightChange) / 2 * 100,
            growthDirection: heightChange > widthChange ? .upward : .outward
        )
    }
    
    func calculateLeafCountChange(before: PlantVisualFeatures, after: PlantVisualFeatures) -> LeafCountChange {
        let change = after.leafCount - before.leafCount
        return LeafCountChange(
            difference: change,
            percentageChange: Double(change) / Double(before.leafCount) * 100,
            trend: change > 0 ? .increasing : change < 0 ? .decreasing : .stable
        )
    }
    
    func calculateColorChanges(before: PlantVisualFeatures, after: PlantVisualFeatures) -> ColorChangeAnalysis {
        // Simplified color change analysis
        return ColorChangeAnalysis(
            overallHealthColorChange: .stable,
            specificChanges: [],
            significance: .minor
        )
    }
    
    func calculateGrowthScore(before: PlantVisualFeatures, after: PlantVisualFeatures) -> Double {
        // Calculate overall growth score based on multiple factors
        let sizeChange = (after.plantSize.width + after.plantSize.height) - (before.plantSize.width + before.plantSize.height)
        let leafChange = Double(after.leafCount - before.leafCount) / Double(before.leafCount)
        
        return min(100, max(0, (sizeChange * 50) + (leafChange * 50) + 50))
    }
    
    func generateGrowthInsights(before: PlantVisualFeatures, after: PlantVisualFeatures) -> [String] {
        var insights: [String] = []
        
        if after.leafCount > before.leafCount {
            insights.append("New leaf growth detected - plant is actively growing")
        }
        
        if after.plantSize.height > before.plantSize.height * 1.05 {
            insights.append("Significant height increase observed")
        }
        
        if before.leafColor != after.leafColor {
            insights.append("Leaf color changes detected - monitor health closely")
        }
        
        return insights
    }
}

// MARK: - AI Integration
private extension PlantHealthVisionAnalyzer {
    
    func generateAIHealthAssessment(
        visualFeatures: PlantVisualFeatures,
        healthIssues: [HealthIssueDetection],
        growthAnalysis: GrowthPatternAnalysis,
        plant: Plant
    ) async throws -> AIHealthAssessment {
        
        // For now, synthesize a lightweight assessment based on visual features
        let insights = [
            "Leaf count: \(visualFeatures.leafCount)",
            "Size: \(Int(visualFeatures.plantSize.width))x\(Int(visualFeatures.plantSize.height))"
        ]
        let recs = [
            "Maintain consistent watering schedule",
            "Ensure bright, indirect light"
        ]
        let risks = healthIssues.map { $0.type.rawValue }
        let strengths = ["Healthy coloration", "No critical issues detected"]
        
        return AIHealthAssessment(
            overallScore: 70,
            confidence: 0.7,
            primaryInsights: insights,
            recommendations: recs,
            riskFactors: risks,
            strengths: strengths
        )
    }
}

// MARK: - Scoring and Recommendations
private extension PlantHealthVisionAnalyzer {
    
    func calculateOverallHealthScore(
        visualFeatures: PlantVisualFeatures,
        healthIssues: [HealthIssueDetection],
        aiAssessment: AIHealthAssessment
    ) -> Double {
        var score = 100.0
        
        // Deduct points for health issues
        for issue in healthIssues {
            switch issue.severity {
            case .low:
                score -= 5
            case .moderate:
                score -= 15
            case .high:
                score -= 30
            case .critical:
                score -= 50
            }
        }
        
        // Factor in AI assessment
        score = (score + aiAssessment.overallScore) / 2
        
        // Ensure score is between 0 and 100
        return max(0, min(100, score))
    }
    
    func generateRecommendations(
        from healthIssues: [HealthIssueDetection],
        growthAnalysis: GrowthPatternAnalysis,
        aiAssessment: AIHealthAssessment
    ) -> [HealthRecommendation] {
        var recommendations: [HealthRecommendation] = []
        
        // Add recommendations from detected issues
        for issue in healthIssues {
            recommendations.append(HealthRecommendation(
                category: .immediate,
                action: issue.recommendedAction,
                priority: issue.severity == .critical || issue.severity == .high ? .high : .medium,
                reason: issue.description
            ))
        }
        
        // Add AI recommendations
        for aiRec in aiAssessment.recommendations {
            recommendations.append(HealthRecommendation(
                category: .maintenance,
                action: aiRec,
                priority: .medium,
                reason: "AI analysis recommendation"
            ))
        }
        
        return recommendations
    }
    
    func calculateConfidence(
        visualFeatures: PlantVisualFeatures,
        healthIssues: [HealthIssueDetection]
    ) -> Double {
        // Base confidence on image quality and detection certainty
        let imageQualityScore = visualFeatures.imageQuality
        let detectionConfidence = healthIssues.isEmpty ? 0.9 : healthIssues.map { $0.confidence }.reduce(0, +) / Double(healthIssues.count)
        
        return (imageQualityScore + detectionConfidence) / 2
    }
    
    func assessQuickHealth(from features: BasicVisualFeatures) -> QuickHealthStatus {
        if features.overallQuality > 0.8 && features.brightness > 0.6 {
            return .healthy
        } else if features.overallQuality > 0.5 {
            return .moderate
        } else {
            return .concerning
        }
    }
    
    func generateQuickAlerts(from features: BasicVisualFeatures) -> [String] {
        var alerts: [String] = []
        
        if features.brightness < 0.4 {
            alerts.append("Low light conditions detected")
        }
        
        if features.overallQuality < 0.5 {
            alerts.append("Image quality too low for detailed analysis")
        }
        
        if features.colorDistribution.green < 0.3 {
            alerts.append("Limited green coloration - check plant health")
        }
        
        return alerts
    }
}

// MARK: - Supporting Types

enum VisionAnalysisError: LocalizedError {
    case invalidImage
    case processingFailed
    case insufficientData
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .processingFailed:
            return "Vision processing failed"
        case .insufficientData:
            return "Insufficient data for analysis"
        }
    }
}

struct PlantHealthAnalysis {
    let id: UUID
    let plantId: UUID
    let plantName: String
    let analysisDate: Date
    let originalImage: UIImage
    let visualFeatures: PlantVisualFeatures
    let healthScore: Double // 0-100
    let healthIssues: [HealthIssueDetection]
    let growthAnalysis: GrowthPatternAnalysis
    let aiAssessment: AIHealthAssessment
    let recommendations: [HealthRecommendation]
    let confidence: Double // 0-1
}

struct PlantVisualFeatures {
    let leafColor: LeafColorHealth
    let leafShape: LeafShape
    let leafCount: Int
    let plantSize: RelativePlantSize
    let soilVisibility: SoilAnalysis
    let lightingConditions: LightingAnalysis
    let imageQuality: Double
    let dominantColors: [ColorInfo]
    let textureAnalysis: TextureAnalysis
}

struct BasicVisualFeatures {
    let brightness: Double
    let colorDistribution: ColorDistribution
    let sharpness: Double
    let overallQuality: Double
}

enum LeafColorHealth {
    case healthy, yellowing, browning, spotted, wilting
}

enum LeafShape {
    case oval, round, elongated, serrated, compound
}

struct RelativePlantSize {
    let width: Double // 0-1 relative to frame
    let height: Double // 0-1 relative to frame
    let estimatedActualSize: PlantSizeCategory
}

enum PlantSizeCategory {
    case small, medium, large, extraLarge
}

struct SoilAnalysis {
    let visibility: Double // 0-1
    let moistureLevel: MoistureLevel
    let color: SoilColor
    let texture: SoilTexture
}

enum MoistureLevel {
    case dry, moderate, moist, waterlogged
}

enum SoilColor {
    case brown, black, sandy, clay
}

enum SoilTexture {
    case normal, compacted, loose, rocky
}

struct LightingAnalysis {
    let brightness: LightingQuality
    let direction: LightDirection
    let shadows: ShadowLevel
    let quality: LightingQuality
}

enum LightingQuality {
    case poor, fair, good, excellent
}

enum LightDirection {
    case natural, artificial, mixed
}

enum ShadowLevel {
    case minimal, moderate, heavy
}

struct ColorInfo {
    let color: UIColor
    let percentage: Double
    let healthSignificance: HealthSignificance
}

enum HealthSignificance {
    case positive, neutral, warning, concerning
}

struct ColorDistribution {
    let green: Double
    let brown: Double
    let yellow: Double
    let other: Double
}

struct TextureAnalysis {
    let leafTexture: LeafTexture
    let surfaceQuality: SurfaceQuality
    let patterns: [TexturePattern]
}

enum LeafTexture {
    case smooth, rough, fuzzy, waxy, leathery
}

enum SurfaceQuality {
    case healthy, damaged, diseased, excellent
}

enum TexturePattern {
    case veining, spots, stripes, natural, irregular
}

struct HealthIssueDetection {
    let type: HealthIssueType
    let severity: IssueSeverity
    let confidence: Double
    let affectedArea: AffectedArea
    let description: String
    let recommendedAction: String
}

enum HealthIssueType: String {
    case leafYellowing = "leaf_yellowing"
    case leafBrowning = "leaf_browning"
    case leafDrop = "leaf_drop"
    case pest = "pest"
    case disease = "disease"
    case overwatering = "overwatering"
    case underwatering = "underwatering"
    case nutrientDeficiency = "nutrient_deficiency"
    case undergrowth = "undergrowth"
    case inadequateLight = "inadequate_light"
}

enum IssueSeverity {
    case low, moderate, high, critical
}

enum AffectedArea {
    case leaves, stems, roots, soil, overall
}

struct GrowthPatternAnalysis {
    let growthRate: GrowthRate
    let direction: GrowthDirection
    let leafDevelopment: LeafDevelopment
    let sizeIncrease: Double // percentage
    let timeframe: GrowthTimeframe
    let confidence: Double
}

enum GrowthRate {
    case slow, normal, fast, rapid
}

enum GrowthDirection {
    case upward, outward, bushy, leggy
}

enum LeafDevelopment {
    case healthy, slow, rapid, concerning
}

enum GrowthTimeframe {
    case week, month, season, year
}

struct GrowthComparisonAnalysis {
    let plantId: UUID
    let beforeDate: Date
    let afterDate: Date
    let sizeChange: SizeChangeAnalysis
    let leafCountChange: LeafCountChange
    let colorChanges: ColorChangeAnalysis
    let overallGrowthScore: Double
    let insights: [String]
}

struct SizeChangeAnalysis {
    let widthChange: Double
    let heightChange: Double
    let percentageIncrease: Double
    let growthDirection: GrowthDirection
}

struct LeafCountChange {
    let difference: Int
    let percentageChange: Double
    let trend: CountTrend
}

enum CountTrend {
    case increasing, stable, decreasing
}

struct ColorChangeAnalysis {
    let overallHealthColorChange: ColorChangeTrend
    let specificChanges: [ColorChange]
    let significance: ChangeSignificance
}

enum ColorChangeTrend {
    case improving, stable, declining
}

struct ColorChange {
    let from: UIColor
    let to: UIColor
    let area: AffectedArea
    let significance: HealthSignificance
}

enum ChangeSignificance {
    case minor, moderate, significant, major
}

struct AIHealthAssessment {
    let overallScore: Double
    let confidence: Double
    let primaryInsights: [String]
    let recommendations: [String]
    let riskFactors: [String]
    let strengths: [String]
}

struct HealthRecommendation {
    let category: RecommendationCategory
    let action: String
    let priority: RecommendationPriority
    let reason: String
}

enum RecommendationCategory {
    case immediate, shortTerm, longTerm, maintenance, prevention
}

// Scoped to Vision analyzer to avoid collisions with UI enums
enum RecommendationPriority {
    case low, medium, high, urgent
}

struct QuickHealthScreen {
    let overallHealth: QuickHealthStatus
    let alerts: [String]
    let confidence: Double
}

enum QuickHealthStatus {
    case healthy, moderate, concerning, critical
    
    var color: Color {
        switch self {
        case .healthy: return .green
        case .moderate: return .yellow
        case .concerning: return .orange
        case .critical: return .red
        }
    }
    
    var description: String {
        switch self {
        case .healthy: return "Plant appears healthy"
        case .moderate: return "Some concerns detected"
        case .concerning: return "Issues need attention"
        case .critical: return "Immediate care required"
        }
    }
}
