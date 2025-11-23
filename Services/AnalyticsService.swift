import Foundation
import SwiftData
import SwiftUI

// MARK: - Shared Analytics Models

enum AnalyticsTimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        }
    }
    
    var startDate: Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }
}

enum BotanicalSeason: String, CaseIterable {
    case spring = "Spring"
    case summer = "Summer"
    case fall = "Fall"
    case winter = "Winter"
    
    var careModifications: String {
        switch self {
        case .spring: return "Increase watering frequency, begin fertilizing, repot if needed"
        case .summer: return "Peak watering needs, regular fertilizing, monitor for pests"
        case .fall: return "Reduce watering gradually, stop fertilizing, prepare for dormancy"
        case .winter: return "Minimal watering, no fertilizing, focus on humidity"
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .spring: return BotanicaTheme.Colors.leafGreen
        case .summer: return BotanicaTheme.Colors.sunYellow
        case .fall: return BotanicaTheme.Colors.nutrientOrange
        case .winter: return BotanicaTheme.Colors.waterBlue
        }
    }
    
    static var current: BotanicalSeason {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .fall
        default: return .winter
        }
    }
}

struct CollectionAnalyticsSummary {
    let healthScore: Double
    let healthyCount: Int
    let attentionCount: Int
    let careStreak: Int
}

struct CompletionDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let completionRate: Double
}

struct SpeciesInsight {
    let species: String
    let count: Int
    let averageHealth: Double
    let careRecommendation: String
    let seasonalNote: String
}

struct HealthTrendBreakdown {
    let improving: Int
    let stable: Int
    let declining: Int
}

struct AnalyticsSnapshot {
    let summary: CollectionAnalyticsSummary
    let completionData: [CompletionDataPoint]
    let averageCompletionRate: Double
    let healthTrends: HealthTrendBreakdown
    let speciesInsights: [SpeciesInsight]
}

/// Provides lightweight analytics calculations off the main thread.
final class AnalyticsService {
    private let calendar = Calendar.current
    
    func snapshot(plants: [Plant], careEvents: [CareEvent], range: AnalyticsTimeRange) async -> AnalyticsSnapshot {
        let summary = await summarizeCollection(plants: plants, careEvents: careEvents, range: range)
        let completion = completionData(plants: plants, careEvents: careEvents, range: range)
        let average = Self.averageCompletionRate(plants: plants, careEvents: careEvents, range: range)
        let trends = Self.healthTrends(for: plants)
        let species = Self.speciesInsights(from: plants)
        
        return AnalyticsSnapshot(
            summary: summary,
            completionData: completion,
            averageCompletionRate: average,
            healthTrends: trends,
            speciesInsights: species
        )
    }
    
    func summarizeCollection(plants: [Plant], careEvents: [CareEvent], range: AnalyticsTimeRange) async -> CollectionAnalyticsSummary {
        await withTaskGroup(of: CollectionAnalyticsSummary.self) { group in
            group.addTask {
                let healthScore = Self.collectionHealthScore(plants: plants)
                let healthy = plants.filter { $0.healthStatus == .healthy || $0.healthStatus == .excellent }.count
                let attention = plants.filter { $0.healthStatus == .fair || $0.healthStatus == .poor || $0.healthStatus == .critical }.count
                let streak = Self.currentCareStreak(careEvents: careEvents, calendar: self.calendar)
                return CollectionAnalyticsSummary(healthScore: healthScore, healthyCount: healthy, attentionCount: attention, careStreak: streak)
            }
            
            // Only one task, but using a group keeps async extensible
            return await group.next() ?? CollectionAnalyticsSummary(healthScore: 0, healthyCount: 0, attentionCount: 0, careStreak: 0)
        }
    }
    
    func completionData(plants: [Plant], careEvents: [CareEvent], range: AnalyticsTimeRange) -> [CompletionDataPoint] {
        let days = min(range.days, 30)
        let today = calendar.startOfDay(for: Date())
        
        return (0..<days).compactMap { offset -> CompletionDataPoint? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let completionRate = Self.completionRate(on: date, plants: plants, careEvents: careEvents, calendar: calendar)
            return CompletionDataPoint(date: date, completionRate: completionRate)
        }.reversed()
    }
    
    static func collectionHealthScore(plants: [Plant]) -> Double {
        guard !plants.isEmpty else { return 0 }
        let total = plants.reduce(0.0) { $0 + $1.healthScore }
        return (total / Double(plants.count)) * 100
    }
    
    static func currentCareStreak(careEvents: [CareEvent], calendar: Calendar) -> Int {
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            let dayEvents = careEvents.filter { calendar.isDate($0.date, inSameDayAs: date) }
            if dayEvents.isEmpty { break }
            streak += 1
        }
        return streak
    }
    
    static func averageCompletionRate(plants: [Plant], careEvents: [CareEvent], range: AnalyticsTimeRange) -> Double {
        guard !plants.isEmpty else { return 0.0 }
        let expectedEvents = plants.count * range.days / 7 // Approximate weekly care
        guard expectedEvents > 0 else { return 1.0 }
        let actualEvents = careEvents.filter { $0.date >= range.startDate }.count
        return min(Double(actualEvents) / Double(expectedEvents), 1.0)
    }
    
    static func completionRate(on date: Date, plants: [Plant], careEvents: [CareEvent], calendar: Calendar) -> Double {
        let dayEvents = careEvents.filter { calendar.isDate($0.date, inSameDayAs: date) }
        let expectedCare = max(1, plants.count / 7) // Assume weekly care events
        return min(Double(dayEvents.count) / Double(expectedCare), 1.0)
    }
    
    static func healthTrends(for plants: [Plant]) -> HealthTrendBreakdown {
        let improving = plants.filter { $0.healthStatus == .excellent || $0.healthStatus == .healthy }.count
        let declining = plants.filter { $0.healthStatus == .poor || $0.healthStatus == .critical }.count
        let stable = max(0, plants.count - improving - declining)
        return HealthTrendBreakdown(improving: improving, stable: stable, declining: declining)
    }
    
    static func speciesInsights(from plants: [Plant]) -> [SpeciesInsight] {
        let speciesGroups = Dictionary(grouping: plants) { $0.scientificName.isEmpty ? "Unknown" : $0.scientificName }
        return speciesGroups.compactMap { species, plantsInSpecies in
            guard !plantsInSpecies.isEmpty else { return nil }
            let avgHealth = plantsInSpecies.reduce(0.0) { $0 + $1.healthScore } / Double(plantsInSpecies.count)
            return SpeciesInsight(
                species: species,
                count: plantsInSpecies.count,
                averageHealth: avgHealth,
                careRecommendation: careRecommendation(for: species),
                seasonalNote: seasonalNote(for: species)
            )
        }
        .sorted { $0.count > $1.count }
        .prefix(3)
        .map { $0 }
    }
    
    private static func careRecommendation(for species: String) -> String {
        switch species.lowercased() {
        case let s where s.contains("monstera"):
            return "Bright indirect light, weekly watering, high humidity"
        case let s where s.contains("pothos"):
            return "Low to bright indirect light, water when soil dry"
        case let s where s.contains("snake"):
            return "Low light tolerant, water every 2-3 weeks"
        case let s where s.contains("rubber"):
            return "Bright indirect light, weekly watering, dust leaves"
        default:
            return "Monitor soil moisture, provide appropriate light"
        }
    }
    
    private static func seasonalNote(for species: String) -> String {
        let season = BotanicalSeason.current
        switch season {
        case .spring:
            return "Growing season - increase watering and fertilizing"
        case .summer:
            return "Peak growth - maintain consistent care schedule"
        case .fall:
            return "Prepare for dormancy - reduce fertilizing"
        case .winter:
            return "Dormant period - reduce watering frequency"
        }
    }
}
