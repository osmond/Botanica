import Foundation
import SwiftData

// MARK: - Advanced Analytics Engine
class AdvancedAnalytics: ObservableObject {
    
    // MARK: - Health Trends Analytics
    struct HealthTrend {
        let date: Date
        let overallScore: Double
        let plantCount: Int
        let issueCount: Int
        let recoveryRate: Double
    }
    
    struct PlantHealthInsight {
        let title: String
        let description: String
        let severity: InsightSeverity
        let actionable: Bool
        let plantIds: [UUID]
    }
    
    enum InsightSeverity: String, CaseIterable {
        case info = "Info"
        case warning = "Warning"
        case critical = "Critical"
        
        var color: String {
            switch self {
            case .info: return "blue"
            case .warning: return "orange"
            case .critical: return "red"
            }
        }
    }
    
    // MARK: - Environment Analytics
    struct EnvironmentalImpact {
        let season: BotanicalSeason
        let avgHealthScore: Double
        let stressEvents: Int
        let optimalConditions: [String]
        let recommendations: [String]
    }
    
    struct LocationAnalysis {
        let location: String
        let plantCount: Int
        let avgHealthScore: Double
        let successRate: Double
        let bestSpecies: [String]
        let challenges: [String]
    }
    
    // MARK: - Growth Pattern Analytics
    struct GrowthMetrics {
        let plantId: UUID
        let species: String
        let growthRate: Double // cm per month
        let healthCorrelation: Double
        let careImpact: Double
        let seasonalVariation: [BotanicalSeason: Double]
        let maturityEstimate: TimeInterval
    }
    
    struct GrowthInsight {
        let title: String
        let description: String
        let trend: GrowthTrend
        let prediction: String
    }
    
    enum GrowthTrend: String, CaseIterable {
        case accelerating = "Accelerating"
        case steady = "Steady"
        case slowing = "Slowing"
        case dormant = "Dormant"
    }
    
    // MARK: - Health Trends Implementation
    func analyzeHealthTrends(plants: [Plant], careEvents: [CareEvent]) -> [HealthTrend] {
        let calendar = Calendar.current
        let now = Date()
        let _ = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        
        var trends: [HealthTrend] = []
        
        // Generate weekly health trends for the past 30 days
        for weekOffset in 0..<5 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) ?? now
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            
            let weeklyScore = calculateWeeklyHealthScore(plants: plants, careEvents: careEvents, start: weekStart, end: weekEnd)
            let weeklyIssues = countHealthIssues(plants: plants, date: weekStart)
            let recoveryRate = calculateRecoveryRate(plants: plants, careEvents: careEvents, date: weekStart)
            
            trends.append(HealthTrend(
                date: weekStart,
                overallScore: weeklyScore,
                plantCount: plants.count,
                issueCount: weeklyIssues,
                recoveryRate: recoveryRate
            ))
        }
        
        return trends.reversed()
    }
    
    func generateHealthInsights(plants: [Plant], careEvents: [CareEvent]) -> [PlantHealthInsight] {
        var insights: [PlantHealthInsight] = []
        
        // Pattern Detection: Overwatering tendency
        let overwateringPattern = detectOverwateringPattern(plants: plants, careEvents: careEvents)
        if !overwateringPattern.isEmpty {
            insights.append(PlantHealthInsight(
                title: "Overwatering Pattern Detected",
                description: "Several plants show signs of overwatering. Consider extending watering intervals.",
                severity: .warning,
                actionable: true,
                plantIds: overwateringPattern
            ))
        }
        
        // Species Performance Analysis
        let underPerformingSpecies = findUnderPerformingSpecies(plants: plants)
        if !underPerformingSpecies.isEmpty {
            insights.append(PlantHealthInsight(
                title: "Species Care Optimization",
                description: "Some plant species may need specialized care adjustments.",
                severity: .info,
                actionable: true,
                plantIds: underPerformingSpecies
            ))
        }
        
        // Recovery Success Rate
        let fastRecoverers = findFastRecoveringPlants(plants: plants, careEvents: careEvents)
        if !fastRecoverers.isEmpty {
            insights.append(PlantHealthInsight(
                title: "Excellent Recovery Rates",
                description: "These plants are responding well to your care adjustments!",
                severity: .info,
                actionable: false,
                plantIds: fastRecoverers
            ))
        }
        
        return insights
    }
    
    // MARK: - Environment Analytics Implementation
    func analyzeEnvironmentalImpact(plants: [Plant], careEvents: [CareEvent]) -> [EnvironmentalImpact] {
        var impacts: [EnvironmentalImpact] = []
        
        for season in BotanicalSeason.allCases {
            let seasonalHealth = calculateSeasonalHealthScore(plants: plants, season: season)
            let stressEvents = countSeasonalStressEvents(plants: plants, careEvents: careEvents, season: season)
            let conditions = getOptimalConditionsForSeason(season: season)
            let recommendations = generateSeasonalRecommendations(season: season, plants: plants)
            
            impacts.append(EnvironmentalImpact(
                season: season,
                avgHealthScore: seasonalHealth,
                stressEvents: stressEvents,
                optimalConditions: conditions,
                recommendations: recommendations
            ))
        }
        
        return impacts
    }
    
    func analyzeLocationPerformance(plants: [Plant]) -> [LocationAnalysis] {
        let locationGroups = Dictionary(grouping: plants) { $0.source.isEmpty ? "Unknown Location" : $0.source }
        var analyses: [LocationAnalysis] = []
        
        for (location, locationPlants) in locationGroups {
            let avgHealth = locationPlants.compactMap { $0.healthScore }.reduce(0, +) / Double(locationPlants.count)
            let successRate = Double(locationPlants.filter { $0.healthScore > 7 }.count) / Double(locationPlants.count)
            let species = Array(Set(locationPlants.compactMap { $0.scientificName })).prefix(3)
            let challenges = identifyLocationChallenges(plants: locationPlants)
            
            analyses.append(LocationAnalysis(
                location: location,
                plantCount: locationPlants.count,
                avgHealthScore: avgHealth,
                successRate: successRate,
                bestSpecies: Array(species),
                challenges: challenges
            ))
        }
        
        return analyses.sorted { $0.avgHealthScore > $1.avgHealthScore }
    }
    
    // MARK: - Growth Pattern Analytics Implementation
    func analyzeGrowthPatterns(plants: [Plant], careEvents: [CareEvent]) -> [GrowthMetrics] {
        return plants.compactMap { plant in
            let species = plant.scientificName
            
            let growthRate = calculateGrowthRate(plant: plant, careEvents: careEvents)
            let healthCorrelation = calculateGrowthHealthCorrelation(plant: plant)
            let careImpact = calculateCareImpactOnGrowth(plant: plant, careEvents: careEvents)
            let seasonalVariation = calculateSeasonalGrowthVariation(plant: plant)
            let maturityEstimate = estimateMaturityTime(plant: plant, species: species)
            
            return GrowthMetrics(
                plantId: plant.id,
                species: species,
                growthRate: growthRate,
                healthCorrelation: healthCorrelation,
                careImpact: careImpact,
                seasonalVariation: seasonalVariation,
                maturityEstimate: maturityEstimate
            )
        }
    }
    
    func generateGrowthInsights(growthMetrics: [GrowthMetrics], plants: [Plant]) -> [GrowthInsight] {
        var insights: [GrowthInsight] = []
        
        // Fastest Growing Plants
        let fastestGrowers = growthMetrics.sorted { $0.growthRate > $1.growthRate }.prefix(3)
        if let fastest = fastestGrowers.first {
            insights.append(GrowthInsight(
                title: "Exceptional Growth Rate",
                description: "Your \(fastest.species) is growing \(String(format: "%.1f", fastest.growthRate))cm per month!",
                trend: .accelerating,
                prediction: "Expect repotting needed in 6-8 months"
            ))
        }
        
        // Seasonal Growth Patterns
        let springGrowth = growthMetrics.compactMap { $0.seasonalVariation[.spring] }.reduce(0, +) / Double(growthMetrics.count)
        if springGrowth > 0.5 {
            insights.append(GrowthInsight(
                title: "Spring Growth Surge",
                description: "Your plants show \(Int(springGrowth * 100))% increased growth in spring",
                trend: .accelerating,
                prediction: "Increase feeding frequency starting in March"
            ))
        }
        
        // Care Impact Analysis
        let highCareImpact = growthMetrics.filter { $0.careImpact > 0.7 }
        if !highCareImpact.isEmpty {
            insights.append(GrowthInsight(
                title: "Care Optimization Success",
                description: "\(highCareImpact.count) plants show strong growth response to your care routine",
                trend: .steady,
                prediction: "Continue current care schedule for optimal results"
            ))
        }
        
        return insights
    }
    
    // MARK: - Helper Methods
    private func calculateWeeklyHealthScore(plants: [Plant], careEvents: [CareEvent], start: Date, end: Date) -> Double {
        let relevantEvents = careEvents.filter { event in
            event.date >= start && event.date <= end
        }
        
        let careScore = min(Double(relevantEvents.count) / Double(plants.count), 1.0)
        let healthScores = plants.compactMap { $0.healthScore }
        let avgHealth = healthScores.isEmpty ? 0.5 : healthScores.reduce(0, +) / Double(healthScores.count)
        
        return (careScore * 0.3 + avgHealth * 0.7) * 10
    }
    
    private func countHealthIssues(plants: [Plant], date: Date) -> Int {
        return plants.filter { plant in
            plant.healthScore < 4
        }.count
    }
    
    private func calculateRecoveryRate(plants: [Plant], careEvents: [CareEvent], date: Date) -> Double {
        let recoveredPlants = plants.filter { plant in
            plant.healthScore >= 7
        }.count
        
        return Double(recoveredPlants) / Double(max(plants.count, 1))
    }
    
    private func detectOverwateringPattern(plants: [Plant], careEvents: [CareEvent]) -> [UUID] {
        // Simplified logic - in reality would analyze watering frequency vs plant needs
        return plants.filter { plant in
            let wateringEvents = careEvents.filter { $0.plant?.id == plant.id && $0.type == .watering }
            let recentWaterings = wateringEvents.filter { event in
                event.date > Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            }
            return recentWaterings.count > 3 // More than 3 waterings per week might indicate overwatering
        }.map { $0.id }
    }
    
    private func findUnderPerformingSpecies(plants: [Plant]) -> [UUID] {
        let speciesGroups = Dictionary(grouping: plants) { $0.scientificName }
        var underPerforming: [UUID] = []
        
        for (_, speciesPlants) in speciesGroups {
            let avgHealth = speciesPlants.compactMap { $0.healthScore }.reduce(0, +) / Double(speciesPlants.count)
            if avgHealth < 5 {
                underPerforming.append(contentsOf: speciesPlants.map { $0.id })
            }
        }
        
        return underPerforming
    }
    
    private func findFastRecoveringPlants(plants: [Plant], careEvents: [CareEvent]) -> [UUID] {
        return plants.filter { plant in
            plant.healthScore > 8
        }.map { $0.id }
    }
    
    private func calculateSeasonalHealthScore(plants: [Plant], season: BotanicalSeason) -> Double {
        // In a real implementation, this would analyze historical data by season
        let baseScore = plants.compactMap { $0.healthScore }.reduce(0, +) / Double(max(plants.count, 1))
        
        // Seasonal modifiers based on botanical knowledge
        let seasonalModifier: Double = switch season {
        case .spring: 1.2 // Plants generally thrive in spring
        case .summer: 1.0 // Baseline
        case .fall: 0.9   // Some decline as growth slows
        case .winter: 0.8 // Challenging season for many plants
        }
        
        return min(baseScore * seasonalModifier, 10.0)
    }
    
    private func countSeasonalStressEvents(plants: [Plant], careEvents: [CareEvent], season: BotanicalSeason) -> Int {
        // Simplified - would analyze actual seasonal stress patterns
        return Int.random(in: 0...5)
    }
    
    private func getOptimalConditionsForSeason(season: BotanicalSeason) -> [String] {
        switch season {
        case .spring:
            return ["Increase humidity", "Bright indirect light", "Resume fertilizing"]
        case .summer:
            return ["Consistent watering", "Monitor for pests", "Adequate ventilation"]
        case .fall:
            return ["Reduce watering", "Prepare for dormancy", "Check for drafts"]
        case .winter:
            return ["Lower temperatures", "Reduce fertilizing", "Increase humidity"]
        }
    }
    
    private func generateSeasonalRecommendations(season: BotanicalSeason, plants: [Plant]) -> [String] {
        let plantCount = plants.count
        
        switch season {
        case .spring:
            return [
                "Repot \(plantCount/3) plants that have outgrown containers",
                "Begin weekly fertilizing schedule",
                "Increase watering frequency by 20%"
            ]
        case .summer:
            return [
                "Monitor daily for pest activity",
                "Maintain consistent soil moisture",
                "Provide morning sunlight, afternoon shade"
            ]
        case .fall:
            return [
                "Gradually reduce watering frequency",
                "Stop fertilizing by October",
                "Move sensitive plants away from windows"
            ]
        case .winter:
            return [
                "Water only when soil is dry 2 inches down",
                "Increase humidity with pebble trays",
                "Rotate plants weekly for even light exposure"
            ]
        }
    }
    
    private func identifyLocationChallenges(plants: [Plant]) -> [String] {
        let avgHealth = plants.compactMap { $0.healthScore }.reduce(0, +) / Double(max(plants.count, 1))
        
        if avgHealth < 4 {
            return ["Low light conditions", "Poor air circulation", "Inconsistent temperature"]
        } else if avgHealth < 6 {
            return ["Moderate light stress", "Humidity fluctuations"]
        } else {
            return ["Optimal growing conditions"]
        }
    }
    
    private func calculateGrowthRate(plant: Plant, careEvents: [CareEvent]) -> Double {
        // Simplified growth rate calculation
        // In reality, would track actual measurements over time
        let baseRate = Double.random(in: 0.5...3.0) // cm per month
        let careFrequency = careEvents.filter { $0.plant?.id == plant.id }.count
        let careBonus = min(Double(careFrequency) * 0.1, 1.0)
        
        return baseRate * (1.0 + careBonus)
    }
    
    private func calculateGrowthHealthCorrelation(plant: Plant) -> Double {
        // Correlation between plant health and growth
        let health = plant.healthScore
        return health / 10.0 // Normalize to 0-1
    }
    
    private func calculateCareImpactOnGrowth(plant: Plant, careEvents: [CareEvent]) -> Double {
        let plantCareEvents = careEvents.filter { $0.plant?.id == plant.id }
        let careScore = min(Double(plantCareEvents.count) / 10.0, 1.0) // Normalize care frequency
        
        return careScore
    }
    
    private func calculateSeasonalGrowthVariation(plant: Plant) -> [BotanicalSeason: Double] {
        // Seasonal growth variations - would be based on historical data
        return [
            .spring: Double.random(in: 0.8...1.5),
            .summer: Double.random(in: 0.6...1.2),
            .fall: Double.random(in: 0.3...0.8),
            .winter: Double.random(in: 0.1...0.5)
        ]
    }
    
    private func estimateMaturityTime(plant: Plant, species: String) -> TimeInterval {
        // Estimated time to maturity based on species
        // In reality, would have a comprehensive species database
        let speciesMaturityMonths: [String: Int] = [
            "Monstera": 24,
            "Pothos": 12,
            "Snake Plant": 36,
            "Fiddle Leaf Fig": 60,
            "Peace Lily": 18
        ]
        
        let months = speciesMaturityMonths[species] ?? 24
        return TimeInterval(months * 30 * 24 * 3600) // Convert to seconds
    }
}