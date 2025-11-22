import Foundation
import SwiftData
import SwiftUI

/// Advanced analytics engine for plant performance tracking and insights
/// Provides comprehensive metrics, growth analysis, and predictive insights
@MainActor
class PlantAnalyticsEngine: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isCalculating = false
    @Published var lastAnalysisDate: Date?
    @Published var analyticsCache: [String: AnalyticsPlantPerformanceMetrics] = [:]
    
    // MARK: - Dependencies
    private let weatherService = WeatherService.shared
    
    // MARK: - Public Methods
    
    /// Generate comprehensive performance metrics for a plant
    func generatePerformanceMetrics(
        for plant: Plant, 
        careEvents: [CareEvent],
        photos: [Photo],
        context: ModelContext
    ) -> AnalyticsPlantPerformanceMetrics {
        
        // Check cache first
        let cacheKey = "\(plant.id.uuidString)_\(Date().timeIntervalSince1970 / 3600)" // Hourly cache
        if let cached = analyticsCache[cacheKey] {
            return cached
        }
        
        isCalculating = true
        defer { isCalculating = false }
        
        let metrics = AnalyticsPlantPerformanceMetrics(
            plantId: plant.id,
            plantName: plant.nickname,
            analysisDate: Date(),
            
            // Care Performance
            careConsistencyScore: calculateCareConsistencyScore(plant: plant, careEvents: careEvents),
            wateringEfficiency: calculateWateringEfficiency(plant: plant, careEvents: careEvents),
            fertilizerOptimization: calculateFertilizerOptimization(plant: plant, careEvents: careEvents),
            
            // Growth Metrics
            growthRate: calculateGrowthRate(plant: plant, photos: photos),
            healthTrend: calculateHealthTrend(plant: plant, careEvents: careEvents),
            photoProgressScore: calculatePhotoProgress(photos: photos),
            
            // Environmental Correlation
            weatherCorrelation: calculateWeatherCorrelation(plant: plant, careEvents: careEvents),
            seasonalPerformance: calculateSeasonalPerformance(plant: plant, careEvents: careEvents),
            optimalConditions: identifyOptimalConditions(plant: plant, careEvents: careEvents),
            
            // Predictive Insights
            nextCareRecommendations: generateNextCareRecommendations(plant: plant, careEvents: careEvents),
            riskAssessment: calculateRiskAssessment(plant: plant, careEvents: careEvents),
            improvementSuggestions: generateImprovementSuggestions(plant: plant, careEvents: careEvents),
            
            // Comparative Analysis
            plantHappinessIndex: calculatePlantHappinessIndex(plant: plant, careEvents: careEvents, photos: photos),
            benchmarkComparison: generateBenchmarkComparison(plant: plant, careEvents: careEvents, context: context)
        )
        
        // Cache the results
        analyticsCache[cacheKey] = metrics
        lastAnalysisDate = Date()
        
        return metrics
    }
    
    /// Generate collection-wide analytics
    func generateCollectionAnalytics(
        plants: [Plant],
        allCareEvents: [CareEvent],
        allPhotos: [Photo],
        context: ModelContext
    ) -> AnalyticsCollectionAnalytics {
        
        isCalculating = true
        defer { isCalculating = false }
        
        return AnalyticsCollectionAnalytics(
            totalPlants: plants.count,
            averageCollectionAge: calculateAverageCollectionAge(plants: plants),
            overallCareScore: calculateOverallCareScore(plants: plants, careEvents: allCareEvents),
            
            // Performance Metrics
            topPerformingPlants: identifyTopPerformers(plants: plants, careEvents: allCareEvents, photos: allPhotos),
            plantsNeedingAttention: identifyPlantsNeedingAttention(plants: plants, careEvents: allCareEvents),
            careStreaks: calculateCareStreaks(careEvents: allCareEvents),
            
            // Insights
            collectionInsights: generateCollectionInsights(plants: plants, careEvents: allCareEvents),
            seasonalTrends: calculateCollectionSeasonalTrends(careEvents: allCareEvents),
            improvementOpportunities: identifyCollectionImprovements(plants: plants, careEvents: allCareEvents)
        )
    }
    
    /// Generate predictive care schedule based on analytics
    func generatePredictiveCareSchedule(
        for plant: Plant,
        careEvents: [CareEvent],
        daysAhead: Int = 14
    ) -> [AnalyticsPredictiveCareEvent] {
        
        let baseFrequencies = extractCareFrequencies(from: careEvents)
        let weatherAdjustments = weatherService.getWeatherAdjustments(for: plant)
        let seasonalFactors = calculateSeasonalFactors()
        
        var schedule: [AnalyticsPredictiveCareEvent] = []
        let startDate = Date()
        
        // Generate watering predictions
        if let wateringFreq = baseFrequencies[.watering] {
            let adjustedFreq = wateringFreq * weatherAdjustments.wateringMultiplier * seasonalFactors.watering
            schedule.append(contentsOf: generatePredictiveEvents(
                type: .watering,
                frequency: adjustedFreq,
                startDate: startDate,
                daysAhead: daysAhead,
                confidence: calculatePredictionConfidence(for: .watering, plant: plant, events: careEvents)
            ))
        }
        
        // Generate fertilizing predictions
        if let fertilizingFreq = baseFrequencies[.fertilizing] {
            let adjustedFreq = fertilizingFreq * seasonalFactors.fertilizing
            schedule.append(contentsOf: generatePredictiveEvents(
                type: .fertilizing,
                frequency: adjustedFreq,
                startDate: startDate,
                daysAhead: daysAhead,
                confidence: calculatePredictionConfidence(for: .fertilizing, plant: plant, events: careEvents)
            ))
        }
        
        return schedule.sorted { $0.predictedDate < $1.predictedDate }
    }
}

// MARK: - Calculation Methods
private extension PlantAnalyticsEngine {
    
    // MARK: - Care Performance Calculations
    
    func calculateCareConsistencyScore(plant: Plant, careEvents: [CareEvent]) -> Double {
        let last30Days = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentEvents = careEvents.filter { $0.date >= last30Days }
        
        guard !recentEvents.isEmpty else { return 0.0 }
        
        // Calculate expected vs actual care events
        let expectedWaterings = 30 / plant.wateringFrequency
        let actualWaterings = recentEvents.filter { $0.type == .watering }.count
        
        let wateringScore = min(1.0, Double(actualWaterings) / Double(expectedWaterings))
        
        // Factor in timing consistency
        let wateringEvents = recentEvents.filter { $0.type == .watering }.sorted { $0.date < $1.date }
        let timingScore = calculateTimingConsistency(events: wateringEvents, expectedFrequency: plant.wateringFrequency)
        
        return (wateringScore * 0.7 + timingScore * 0.3) * 100
    }
    
    func calculateWateringEfficiency(plant: Plant, careEvents: [CareEvent]) -> Double {
        let wateringEvents = careEvents.filter { $0.type == .watering }
        guard wateringEvents.count >= 5 else { return 50.0 } // Default score for insufficient data
        
        // Analyze watering amounts vs plant needs
        let averageAmount = wateringEvents.compactMap { $0.amount }.reduce(0.0, +) / Double(wateringEvents.count)
        let recommendedAmount = CareCalculator.recommendedWateringAmount(
            potSize: plant.potSize,
            plantType: PlantWateringType.from(plant: plant)
        ).amount
        
        let efficiency = 100.0 - abs(averageAmount - Double(recommendedAmount)) / Double(recommendedAmount) * 100.0
        return max(0.0, min(100.0, efficiency))
    }
    
    func calculateFertilizerOptimization(plant: Plant, careEvents: [CareEvent]) -> Double {
        let fertilizingEvents = careEvents.filter { $0.type == .fertilizing }
        guard !fertilizingEvents.isEmpty else { return 0.0 }
        
        let last90Days = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        let recentFertilizing = fertilizingEvents.filter { $0.date >= last90Days }
        
        let expectedFrequency = plant.fertilizingFrequency
        let actualFrequency = 90 / max(1, recentFertilizing.count)
        
        let optimizationScore = 100.0 - abs(Double(actualFrequency) - Double(expectedFrequency)) / Double(expectedFrequency) * 100.0
        return max(0.0, min(100.0, optimizationScore))
    }
    
    // MARK: - Growth Analysis
    
    func calculateGrowthRate(plant: Plant, photos: [Photo]) -> GrowthMetrics {
        let growthPhotos = photos.filter { $0.category == .newGrowth }.sorted { $0.timestamp < $1.timestamp }
        
        guard growthPhotos.count >= 2 else {
            return GrowthMetrics(rate: 0, trend: .stable, confidence: 0.1)
        }
        
        // Simple growth rate calculation based on photo frequency and plant age
        let timeSpan = growthPhotos.last!.timestamp.timeIntervalSince(growthPhotos.first!.timestamp)
        let daysSpan = timeSpan / (24 * 3600)
        let photosPerMonth = Double(growthPhotos.count) / (daysSpan / 30)
        
        // More photos over time typically indicates active growth
        let growthRate = min(100, photosPerMonth * 10)
        
        // Determine trend based on recent photo frequency
        let recentPhotos = growthPhotos.filter { 
            Calendar.current.dateInterval(of: .month, for: Date())?.contains($0.timestamp) ?? false 
        }
        let previousMonthPhotos = growthPhotos.filter {
            let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            return Calendar.current.dateInterval(of: .month, for: previousMonth)?.contains($0.timestamp) ?? false
        }
        
        let trend: GrowthTrend = recentPhotos.count > previousMonthPhotos.count ? .increasing : 
                                 recentPhotos.count < previousMonthPhotos.count ? .decreasing : .stable
        
        return GrowthMetrics(
            rate: growthRate,
            trend: trend,
            confidence: min(1.0, Double(growthPhotos.count) / 10.0)
        )
    }
    
    func calculateHealthTrend(plant: Plant, careEvents: [CareEvent]) -> AnalyticsHealthTrend {
        let healthEvents = careEvents.filter { $0.type == .inspection }.sorted { $0.date < $1.date }
        
        guard healthEvents.count >= 3 else { return .stable }
        
        // Analyze recent health status changes
        let recent = Array(healthEvents.suffix(5))
        let healthScores = recent.compactMap { event -> Double? in
            // Convert health notes to numerical scores (simplified)
            let notes = event.notes.lowercased()
            if notes.contains("excellent") || notes.contains("thriving") { return 5.0 }
            if notes.contains("good") || notes.contains("healthy") { return 4.0 }
            if notes.contains("okay") || notes.contains("fair") { return 3.0 }
            if notes.contains("concerning") || notes.contains("issues") { return 2.0 }
            if notes.contains("poor") || notes.contains("struggling") { return 1.0 }
            return 3.0 // Default neutral
        }
        
        guard healthScores.count >= 2 else { return .stable }
        
        let trend = healthScores.last! - healthScores.first!
        if trend > 0.5 { return .improving }
        if trend < -0.5 { return .declining }
        return .stable
    }
    
    // MARK: - Environmental Correlation
    
    func calculateWeatherCorrelation(plant: Plant, careEvents: [CareEvent]) -> WeatherCorrelation {
        guard let currentWeather = weatherService.currentWeather else {
            return WeatherCorrelation(hasData: false, insights: [])
        }
        
        let recentEvents = careEvents.filter { 
            Calendar.current.dateInterval(of: .month, for: Date())?.contains($0.date) ?? false 
        }
        
        var insights: [String] = []
        
        // Analyze care frequency vs weather patterns
        let wateringEvents = recentEvents.filter { $0.type == .watering }
        let avgWateringGap = calculateAverageEventGap(events: wateringEvents)
        
        if avgWateringGap < Double(plant.wateringFrequency) * 0.8 {
            insights.append("Plant is being watered more frequently than usual - possibly due to weather conditions")
        }
        
        // Temperature correlation
        let tempF = currentWeather.temperature.converted(to: .fahrenheit).value
        if tempF > 80 && (plant.lightLevel == .bright || plant.lightLevel == .direct) {
            insights.append("High temperatures with high light requirements may increase water needs")
        }
        
        return WeatherCorrelation(hasData: true, insights: insights)
    }
    
    // MARK: - Helper Methods
    
    func calculateTimingConsistency(events: [CareEvent], expectedFrequency: Int) -> Double {
        guard events.count >= 3 else { return 0.5 }
        
        var gaps: [Int] = []
        for i in 1..<events.count {
            let gap = Calendar.current.dateComponents([.day], 
                from: events[i-1].date, 
                to: events[i].date).day ?? 0
            gaps.append(gap)
        }
        
        let averageGap = Double(gaps.reduce(0, +)) / Double(gaps.count)
        let variance = gaps.map { pow(Double($0) - averageGap, 2) }.reduce(0, +) / Double(gaps.count)
        let standardDeviation = sqrt(variance)
        
        // Lower standard deviation = more consistent timing
        let maxExpectedDeviation = Double(expectedFrequency) * 0.3
        let consistencyScore = max(0, 1 - (standardDeviation / maxExpectedDeviation))
        
        return consistencyScore
    }
    
    func calculateAverageEventGap(events: [CareEvent]) -> Double {
        guard events.count >= 2 else { return 0 }
        
        let sortedEvents = events.sorted { $0.date < $1.date }
        var totalGap = 0.0
        
        for i in 1..<sortedEvents.count {
            let gap = sortedEvents[i].date.timeIntervalSince(sortedEvents[i-1].date) / (24 * 3600)
            totalGap += gap
        }
        
        return totalGap / Double(sortedEvents.count - 1)
    }
    
    func extractCareFrequencies(from events: [CareEvent]) -> [CareType: Double] {
        var frequencies: [CareType: Double] = [:]
        
        for type in CareType.allCases {
            let typeEvents = events.filter { $0.type == type }.sorted { $0.date < $1.date }
            if typeEvents.count >= 2 {
                let totalTime = typeEvents.last!.date.timeIntervalSince(typeEvents.first!.date)
                let avgFreq = totalTime / Double(typeEvents.count - 1) / (24 * 3600) // Days
                frequencies[type] = avgFreq
            }
        }
        
        return frequencies
    }
    
    func calculateSeasonalFactors() -> (watering: Double, fertilizing: Double) {
        let month = Calendar.current.component(.month, from: Date())
        
        switch month {
        case 3...5: // Spring - growing season
            return (watering: 1.1, fertilizing: 1.2)
        case 6...8: // Summer - peak growing season
            return (watering: 1.3, fertilizing: 1.3)
        case 9...11: // Fall - slowing down
            return (watering: 0.9, fertilizing: 0.8)
        default: // Winter - dormant season
            return (watering: 0.7, fertilizing: 0.5)
        }
    }
    
    func generatePredictiveEvents(
        type: CareType,
        frequency: Double,
        startDate: Date,
        daysAhead: Int,
        confidence: Double
    ) -> [AnalyticsPredictiveCareEvent] {
        var events: [AnalyticsPredictiveCareEvent] = []
        var currentDate = startDate
        
        while currentDate <= Calendar.current.date(byAdding: .day, value: daysAhead, to: startDate)! {
            currentDate = Calendar.current.date(byAdding: .day, value: Int(frequency), to: currentDate)!
            
            if currentDate <= Calendar.current.date(byAdding: .day, value: daysAhead, to: startDate)! {
                events.append(AnalyticsPredictiveCareEvent(
                    type: type,
                    predictedDate: currentDate,
                    confidence: confidence,
                    reason: generatePredictionReason(for: type, confidence: confidence)
                ))
            }
        }
        
        return events
    }
    
    func calculatePredictionConfidence(for type: CareType, plant: Plant, events: [CareEvent]) -> Double {
        let typeEvents = events.filter { $0.type == type }
        
        // More historical data = higher confidence
        let dataConfidence = min(1.0, Double(typeEvents.count) / 10.0)
        
        // Consistency of timing = higher confidence
        let timingConsistency = calculateTimingConsistency(
            events: typeEvents, 
            expectedFrequency: type == .watering ? plant.wateringFrequency : plant.fertilizingFrequency
        )
        
        return (dataConfidence * 0.6 + timingConsistency * 0.4)
    }
    
    func generatePredictionReason(for type: CareType, confidence: Double) -> String {
        let confidenceLevel = confidence > 0.8 ? "High" : confidence > 0.5 ? "Medium" : "Low"
        return "Based on historical \(type.rawValue) patterns (\(confidenceLevel) confidence)"
    }
}

// MARK: - Placeholder implementations to keep build green
private extension PlantAnalyticsEngine {
    func calculateAverageCollectionAge(plants: [Plant]) -> TimeInterval {
        guard !plants.isEmpty else { return 0 }
        let total = plants.reduce(0.0) { partial, plant in
            partial + Date().timeIntervalSince(plant.dateAdded)
        }
        return total / Double(plants.count)
    }
    
    func calculateOverallCareScore(plants: [Plant], careEvents: [CareEvent]) -> Double {
        guard !plants.isEmpty else { return 0 }
        let avg = plants.reduce(0.0) { $0 + plantCareScore($1) } / Double(plants.count)
        return min(100, max(0, avg))
    }
    
    func plantCareScore(_ plant: Plant) -> Double {
        // Scale existing healthScore (0-10) to 0-100
        return plant.healthScore * 10.0
    }
    func calculatePhotoProgress(photos: [Photo]) -> Double { 50 }
    func calculateSeasonalPerformance(plant: Plant, careEvents: [CareEvent]) -> SeasonalPerformance {
        SeasonalPerformance(spring: 50, summer: 50, fall: 50, winter: 50, currentSeasonScore: 50)
    }
    func identifyOptimalConditions(plant: Plant, careEvents: [CareEvent]) -> OptimalConditions {
        OptimalConditions(temperature: 65...80, humidity: 0.4...0.6, lightHours: 8, confidence: 0.5)
    }
    func generateNextCareRecommendations(plant: Plant, careEvents: [CareEvent]) -> [CareRecommendation] {
        [CareRecommendation(type: .watering, suggestedDate: Date().addingTimeInterval(86400), priority: .medium, reason: "Routine watering")] 
    }
    func calculateRiskAssessment(plant: Plant, careEvents: [CareEvent]) -> RiskAssessment {
        RiskAssessment(overallRisk: .low, specificRisks: [])
    }
    func generateImprovementSuggestions(plant: Plant, careEvents: [CareEvent]) -> [String] { [] }
    func calculatePlantHappinessIndex(plant: Plant, careEvents: [CareEvent], photos: [Photo]) -> Double { 70 }
    func generateBenchmarkComparison(plant: Plant, careEvents: [CareEvent], context: ModelContext) -> BenchmarkComparison {
        BenchmarkComparison(comparedToSimilarPlants: 60, collectionRanking: 1, improvements: [])
    }
    func identifyTopPerformers(plants: [Plant], careEvents: [CareEvent], photos: [Photo]) -> [PlantPerformanceSummary] { [] }
    func identifyPlantsNeedingAttention(plants: [Plant], careEvents: [CareEvent]) -> [PlantAttentionItem] { [] }
    func calculateCareStreaks(careEvents: [CareEvent]) -> CareStreaks { CareStreaks(current: 0, longest: 0, type: .watering) }
    func generateCollectionInsights(plants: [Plant], careEvents: [CareEvent]) -> [String] { [] }
    func calculateCollectionSeasonalTrends(careEvents: [CareEvent]) -> SeasonalTrends {
        SeasonalTrends(spring: TrendData(careFrequency: 0, plantHealth: 0, growthRate: 0),
                       summer: TrendData(careFrequency: 0, plantHealth: 0, growthRate: 0),
                       fall: TrendData(careFrequency: 0, plantHealth: 0, growthRate: 0),
                       winter: TrendData(careFrequency: 0, plantHealth: 0, growthRate: 0))
    }
    func identifyCollectionImprovements(plants: [Plant], careEvents: [CareEvent]) -> [String] { [] }
}

// MARK: - Supporting Types

struct AnalyticsPlantPerformanceMetrics {
    let plantId: UUID
    let plantName: String
    let analysisDate: Date
    
    // Care Performance (0-100 scores)
    let careConsistencyScore: Double
    let wateringEfficiency: Double
    let fertilizerOptimization: Double
    
    // Growth Metrics
    let growthRate: GrowthMetrics
    let healthTrend: AnalyticsHealthTrend
    let photoProgressScore: Double
    
    // Environmental
    let weatherCorrelation: WeatherCorrelation
    let seasonalPerformance: SeasonalPerformance
    let optimalConditions: OptimalConditions
    
    // Predictive
    let nextCareRecommendations: [CareRecommendation]
    let riskAssessment: RiskAssessment
    let improvementSuggestions: [String]
    
    // Overall
    let plantHappinessIndex: Double // 0-100
    let benchmarkComparison: BenchmarkComparison
}

struct GrowthMetrics {
    let rate: Double // 0-100 growth rate score
    let trend: GrowthTrend
    let confidence: Double // 0-1
}

enum GrowthTrend {
    case increasing, stable, decreasing
}

enum AnalyticsHealthTrend {
    case improving, stable, declining
}

struct WeatherCorrelation {
    let hasData: Bool
    let insights: [String]
}

struct SeasonalPerformance {
    let spring: Double
    let summer: Double
    let fall: Double
    let winter: Double
    let currentSeasonScore: Double
}

struct OptimalConditions {
    let temperature: ClosedRange<Double>
    let humidity: ClosedRange<Double>
    let lightHours: Int
    let confidence: Double
}

struct CareRecommendation {
    let type: CareType
    let suggestedDate: Date
    let priority: Priority
    let reason: String
    
    enum Priority {
        case low, medium, high, urgent
    }
}

struct RiskAssessment {
    let overallRisk: RiskLevel
    let specificRisks: [PlantRisk]
    
    enum RiskLevel {
        case low, medium, high
    }
}

struct PlantRisk {
    let type: RiskType
    let description: String
    let mitigation: String
    
    enum RiskType {
        case overwatering, underwatering, pest, disease, environmental
    }
}

struct BenchmarkComparison {
    let comparedToSimilarPlants: Double // percentile 0-100
    let collectionRanking: Int
    let improvements: [String]
}

struct AnalyticsCollectionAnalytics {
    let totalPlants: Int
    let averageCollectionAge: TimeInterval
    let overallCareScore: Double
    
    let topPerformingPlants: [PlantPerformanceSummary]
    let plantsNeedingAttention: [PlantAttentionItem]
    let careStreaks: CareStreaks
    
    let collectionInsights: [String]
    let seasonalTrends: SeasonalTrends
    let improvementOpportunities: [String]
}

struct PlantPerformanceSummary {
    let plantId: UUID
    let name: String
    let score: Double
    let highlights: [String]
}

struct PlantAttentionItem {
    let plantId: UUID
    let name: String
    let issues: [String]
    let urgency: CareRecommendation.Priority
}

struct CareStreaks {
    let current: Int
    let longest: Int
    let type: CareType
}

struct SeasonalTrends {
    let spring: TrendData
    let summer: TrendData
    let fall: TrendData
    let winter: TrendData
}

struct TrendData {
    let careFrequency: Double
    let plantHealth: Double
    let growthRate: Double
}

struct AnalyticsPredictiveCareEvent {
    let type: CareType
    let predictedDate: Date
    let confidence: Double // 0-1
    let reason: String
}

// MARK: - Extensions

extension PlantWateringType {
    static func from(plant: Plant) -> PlantWateringType {
        // Rough heuristic based on light level and family/names
        switch plant.lightLevel {
        case .direct, .bright:
            return .tropical
        case .medium:
            return .foliage
        case .low:
            return .fern
        }
    }
}
