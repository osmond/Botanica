//
//  CareCalculator.swift
//  Botanica
//
//  Created by Assistant on 10/2/25.
//

import Foundation

/// Utility service for calculating plant care recommendations
/// Provides intelligent suggestions for watering amounts, timing, and care schedules
/// Now enhanced with weather-aware recommendations
struct CareCalculator {
    
    // MARK: - Weather Integration
    
    /// Calculate weather-adjusted care recommendations
    @MainActor
    static func weatherAdjustedRecommendation(
        for plant: Plant,
        baseRecommendation: WateringRecommendation? = nil
    ) -> WateringRecommendation {
        let weatherService = WeatherService.shared
        let weatherAdjustments = weatherService.getWeatherAdjustments(for: plant)
        
        // Get base recommendation if not provided
        let base = baseRecommendation ?? recommendedWateringAmount(
            potSize: plant.potSize,
            plantType: PlantWateringType.from(plant: plant),
            season: .current,
            environment: .indoor,
            potMaterial: plant.potMaterial ?? .unknown,
            lightLevel: plant.lightLevel
        )
        
        // Apply weather multiplier to amount
        let adjustedAmount = Int(Double(base.amount) * weatherAdjustments.wateringMultiplier)
        
        // Enhance technique with weather considerations
        var enhancedTechnique = base.technique
        if weatherAdjustments.wateringMultiplier > 1.2 {
            enhancedTechnique += " Water more thoroughly due to hot/dry conditions."
        } else if weatherAdjustments.wateringMultiplier < 0.8 {
            enhancedTechnique += " Water less due to cool/humid conditions."
        }
        
        // Add weather-specific notes
        var seasonalNote = base.seasonalNote
        if !weatherAdjustments.careMessage.isEmpty {
            seasonalNote = weatherAdjustments.careMessage + (seasonalNote.isEmpty ? "" : " • \(seasonalNote)")
        }
        
        return WateringRecommendation(
            amount: adjustedAmount,
            unit: base.unit,
            technique: enhancedTechnique,
            frequency: adjustWeatherFrequency(base.frequency, multiplier: weatherAdjustments.wateringMultiplier),
            seasonalNote: seasonalNote,
            soilCheck: base.soilCheck,
            lightAdjustment: weatherAdjustments.lightAdjustment.message
        )
    }
    
    /// Adjust watering frequency based on weather conditions
    private static func adjustWeatherFrequency(_ baseFrequency: String, multiplier: Double) -> String {
        if multiplier > 1.3 {
            return baseFrequency.replacingOccurrences(of: "every", with: "more frequently than every")
        } else if multiplier < 0.7 {
            return baseFrequency.replacingOccurrences(of: "every", with: "less frequently than every")
        }
        return baseFrequency
    }
    
    // MARK: - Watering Amount Calculations
    
    /// Calculate recommended watering amount based on plant characteristics
    static func recommendedWateringAmount(
        potSize: Int,
        plantType: PlantWateringType,
        season: Season = .current,
        environment: CareEnvironment = .indoor,
        potMaterial: PotMaterial = .unknown,
        lightLevel: LightLevel = .medium,
        potHeight: Int? = nil
    ) -> WateringRecommendation {
        // Base amount: percentage of estimated soil volume
        let volMl = estimateSoilVolumeMl(diameterInches: potSize, heightInches: potHeight)
        let baseFraction = baseFractionForPlantType(plantType) // 6-12% typical
        let baseAmount = volMl * baseFraction
        
        // Adjust for plant type
        let plantAdjustedAmount = adjustForPlantType(baseAmount: baseAmount, plantType: plantType)
        
        // Adjust for season
        let seasonAdjustedAmount = adjustForSeason(amount: plantAdjustedAmount, season: season)

        // Adjust for pot material (terracotta/fabric dry faster; plastic/glazed retain moisture)
        let potAdjustedAmount = adjustForPotMaterial(amount: seasonAdjustedAmount, material: potMaterial)

        // Adjust for light level (more light -> more transpiration)
        let lightAdjustedAmount = adjustForLightLevel(amount: potAdjustedAmount, level: lightLevel)
        
        // Adjust for environment
        let finalAmount = adjustForEnvironment(amount: lightAdjustedAmount, environment: environment)
        
        return WateringRecommendation(
            amount: Int(finalAmount),
            unit: "ml",
            technique: getWateringTechnique(for: plantType),
            frequency: getWateringFrequency(for: plantType, potSize: potSize),
            seasonalNote: getSeasonalNote(for: season),
            soilCheck: getSoilCheckGuidance(for: plantType)
        )
    }

    /// Estimate soil volume in milliliters using a simple cylinder approximation.
    static func estimateSoilVolumeMl(diameterInches: Int, heightInches: Int?) -> Double {
        let d = max(1.0, Double(diameterInches))
        let h = max(1.0, Double(heightInches ?? Int((0.75 * d).rounded())))
        let radius = d / 2.0
        let cubicInches = Double.pi * radius * radius * h
        return cubicInches * 16.387 // 1 in^3 = 16.387 ml
    }

    /// Returns base fraction of soil volume to water for a given plant type
    private static func baseFractionForPlantType(_ type: PlantWateringType) -> Double {
        switch type {
        case .cactus: return 0.04
        case .succulent: return 0.05
        case .orchid: return 0.06
        case .foliage: return 0.08
        case .herb: return 0.08
        case .flowering: return 0.10
        case .tropical: return 0.11
        case .fern: return 0.12
        }
    }
    
    /// Calculate fertilizer amount based on plant size and type
    static func recommendedFertilizerAmount(
        potSize: Int,
        plantType: PlantWateringType,
        fertilizerType: FertilizerType = .liquid
    ) -> FertilizerRecommendation {
        
        let baseAmount = calculateBaseFertilizerAmount(potSize: potSize, type: fertilizerType)
        let adjustedAmount = adjustFertilizerForPlantType(baseAmount: baseAmount, plantType: plantType)
        
        return FertilizerRecommendation(
            amount: adjustedAmount,
            unit: fertilizerType.unit,
            dilution: fertilizerType.dilutionRatio,
            frequency: getFertilizerFrequency(for: plantType),
            seasonalSchedule: getFertilizerSeasonalSchedule(),
            instructions: getFertilizerInstructions(for: fertilizerType)
        )
    }
    
    // MARK: - Private Calculation Methods
    
    private static func calculateBaseWateringAmount(potSize: Int) -> Double {
        // Base formula: ~15-25ml per inch of pot diameter for most houseplants
        let baseRate = 20.0 // ml per inch
        return Double(potSize) * baseRate
    }
    
    private static func adjustForPlantType(baseAmount: Double, plantType: PlantWateringType) -> Double {
        switch plantType {
        case .succulent:
            return baseAmount * 0.3 // Much less water
        case .tropical:
            return baseAmount * 1.2 // More water
        case .flowering:
            return baseAmount * 1.1 // Slightly more water
        case .foliage:
            return baseAmount * 1.0 // Standard amount
        case .fern:
            return baseAmount * 1.3 // More water, consistent moisture
        case .cactus:
            return baseAmount * 0.2 // Very little water
        case .herb:
            return baseAmount * 1.1 // Regular watering
        case .orchid:
            return baseAmount * 0.8 // Less frequent but thorough
        }
    }
    
    private static func adjustForSeason(amount: Double, season: Season) -> Double {
        switch season {
        case .spring:
            return amount * 1.1 // Growing season
        case .summer:
            return amount * 1.2 // More evaporation
        case .fall:
            return amount * 0.9 // Slowing growth
        case .winter:
            return amount * 0.7 // Dormant period
        }
    }

    private static func adjustForPotMaterial(amount: Double, material: PotMaterial) -> Double {
        switch material {
        case .terracotta, .clay:
            return amount * 1.15
        case .fabric:
            return amount * 1.2
        case .plastic:
            return amount * 0.95
        case .glazedCeramics, .ceramic, .concrete, .metal, .wood, .other, .unknown:
            return amount * 1.0
        }
    }

    private static func adjustForLightLevel(amount: Double, level: LightLevel) -> Double {
        switch level {
        case .low:
            return amount * 0.9
        case .medium:
            return amount * 1.0
        case .bright:
            return amount * 1.1
        case .direct:
            return amount * 1.2
        }
    }
    
    private static func adjustForEnvironment(amount: Double, environment: CareEnvironment) -> Double {
        switch environment {
        case .indoor:
            return amount * 1.0 // Standard
        case .outdoor:
            return amount * 1.3 // More evaporation
        case .greenhouse:
            return amount * 1.1 // Higher humidity but controlled
        case .balcony:
            return amount * 1.2 // More air circulation
        }
    }
    
    private static func getWateringTechnique(for plantType: PlantWateringType) -> String {
        switch plantType {
        case .succulent, .cactus:
            return "Deep, infrequent watering. Soak thoroughly then let dry completely."
        case .tropical, .fern:
            return "Keep soil consistently moist but not waterlogged. Water when top inch is dry."
        case .flowering:
            return "Regular watering during growing season. Water at soil level to avoid wet leaves."
        case .foliage:
            return "Water when top 1-2 inches of soil are dry. Water thoroughly until draining."
        case .herb:
            return "Keep evenly moist during growing season. Morning watering preferred."
        case .orchid:
            return "Water weekly with lukewarm water. Allow excess to drain completely."
        }
    }
    
    private static func getWateringFrequency(for plantType: PlantWateringType, potSize: Int) -> String {
        let baseFrequency = switch plantType {
        case .succulent: 10...14
        case .cactus: 14...21
        case .tropical: 5...7
        case .flowering: 3...5
        case .foliage: 7...10
        case .fern: 3...5
        case .herb: 2...4
        case .orchid: 7...10
        }
        
        // Larger pots dry out slower
        let adjustment = potSize > 8 ? 2 : 0
        let adjustedRange = (baseFrequency.lowerBound + adjustment)...(baseFrequency.upperBound + adjustment)
        
        return "Every \(adjustedRange.lowerBound)-\(adjustedRange.upperBound) days"
    }

    // MARK: - Auto frequency calculation

    static func autoWateringFrequencyDays(
        potSize: Int,
        potHeight: Int?,
        plantType: PlantWateringType,
        potMaterial: PotMaterial,
        lightLevel: LightLevel,
        season: Season = .current,
        environment: CareEnvironment = .indoor
    ) -> Int {
        // Start from a type baseline
        var days: Double
        switch plantType {
        case .cactus: days = 16
        case .succulent: days = 14
        case .orchid: days = 10
        case .fern: days = 4
        case .flowering: days = 5
        case .herb: days = 4
        case .tropical: days = 6
        case .foliage: days = 7
        }

        // Volume adjustment
        let volMl = estimateSoilVolumeMl(diameterInches: potSize, heightInches: potHeight)
        if volMl > 1500 { days += 2 }
        else if volMl > 900 { days += 1 }
        else if volMl < 600 { days -= 1 }

        // Material
        switch potMaterial {
        case .terracotta, .clay: days -= 1
        case .fabric: days -= 1
        case .plastic: days += 1
        default: break
        }

        // Light
        switch lightLevel {
        case .low: days += 1
        case .medium: break
        case .bright: days -= 1
        case .direct: days -= 2
        }

        // Season
        switch season {
        case .summer: days -= 1
        case .spring: break
        case .fall: days += 1
        case .winter: days += 2
        }

        // Environment
        switch environment {
        case .outdoor: days -= 1
        case .balcony: days -= 1
        case .greenhouse: break
        case .indoor: break
        }

        let clamped = max(2, min(28, Int(days.rounded())))
        return clamped
    }
    
    private static func getSoilCheckGuidance(for plantType: PlantWateringType) -> String {
        switch plantType {
        case .succulent, .cactus:
            return "Check soil 2-3 inches deep. Should be completely dry before watering."
        case .tropical, .fern:
            return "Check top inch of soil. Should be slightly dry but not completely."
        case .flowering, .herb:
            return "Check top 1-2 inches. Water when dry to touch."
        case .foliage:
            return "Finger test: top inch should be dry, deeper soil slightly moist."
        case .orchid:
            return "Check bark/moss medium. Should be nearly dry but not dusty."
        }
    }
    
    private static func getSeasonalNote(for season: Season) -> String {
        switch season {
        case .spring:
            return "Growing season - plants may need more frequent watering as they actively grow."
        case .summer:
            return "Peak growing season - monitor closely as soil dries faster in heat."
        case .fall:
            return "Growth slowing - reduce watering frequency as plants prepare for dormancy."
        case .winter:
            return "Dormant period - reduce watering significantly, plants need less water."
        }
    }
    
    private static func calculateBaseFertilizerAmount(potSize: Int, type: FertilizerType) -> Double {
        switch type {
        case .liquid:
            return Double(potSize) * 0.5 // 0.5ml per inch of pot diameter
        case .granular:
            return Double(potSize) * 0.25 // 0.25g per inch
        case .slow_release:
            return Double(potSize) * 0.1 // Less frequent, smaller amounts
        }
    }
    
    private static func adjustFertilizerForPlantType(baseAmount: Double, plantType: PlantWateringType) -> Double {
        switch plantType {
        case .succulent, .cactus:
            return baseAmount * 0.5 // Light feeding
        case .tropical, .flowering:
            return baseAmount * 1.2 // Heavy feeders
        case .foliage, .herb:
            return baseAmount * 1.0 // Standard feeding
        case .fern:
            return baseAmount * 0.8 // Light feeding
        case .orchid:
            return baseAmount * 0.6 // Specialized feeding
        }
    }
    
    private static func getFertilizerFrequency(for plantType: PlantWateringType) -> String {
        switch plantType {
        case .succulent, .cactus:
            return "Every 6-8 weeks during growing season"
        case .tropical, .flowering, .herb:
            return "Every 2-3 weeks during growing season"
        case .foliage:
            return "Every 4 weeks during growing season"
        case .fern:
            return "Every 6 weeks with diluted fertilizer"
        case .orchid:
            return "Weekly with orchid-specific fertilizer (heavily diluted)"
        }
    }
    
    private static func getFertilizerSeasonalSchedule() -> String {
        return "Spring-Summer: Regular feeding. Fall: Reduced feeding. Winter: Minimal to no feeding."
    }
    
    private static func getFertilizerInstructions(for type: FertilizerType) -> String {
        switch type {
        case .liquid:
            return "Dilute according to package directions, typically 1/4 to 1/2 strength. Apply to moist soil."
        case .granular:
            return "Sprinkle evenly on soil surface, water thoroughly. Keep away from stem."
        case .slow_release:
            return "Mix into top inch of soil or place on surface. Water normally, releases over 3-6 months."
        }
    }
}

// MARK: - Supporting Types

struct WateringRecommendation {
    let amount: Int
    let unit: String
    let technique: String
    let frequency: String
    let seasonalNote: String
    let soilCheck: String
    let lightAdjustment: String?
    
    init(amount: Int, unit: String, technique: String, frequency: String, seasonalNote: String, soilCheck: String, lightAdjustment: String? = nil) {
        self.amount = amount
        self.unit = unit
        self.technique = technique
        self.frequency = frequency
        self.seasonalNote = seasonalNote
        self.soilCheck = soilCheck
        self.lightAdjustment = lightAdjustment
    }
}

struct FertilizerRecommendation {
    let amount: Double
    let unit: String
    let dilution: String
    let frequency: String
    let seasonalSchedule: String
    let instructions: String
}

enum PlantWateringType: String, CaseIterable {
    case succulent = "Succulent"
    case tropical = "Tropical"
    case flowering = "Flowering"
    case foliage = "Foliage"
    case fern = "Fern"
    case cactus = "Cactus"
    case herb = "Herb"
    case orchid = "Orchid"
    
    /// Determine plant watering type from common names and family
    static func from(commonNames: [String], family: String, scientificName: String) -> PlantWateringType {
        let allText = (commonNames.joined(separator: " ") + " " + family + " " + scientificName).lowercased()
        
        if allText.contains("succulent") || allText.contains("echeveria") || allText.contains("sedum") {
            return .succulent
        } else if allText.contains("cactus") || allText.contains("cactaceae") {
            return .cactus
        } else if allText.contains("fern") || allText.contains("pteridaceae") {
            return .fern
        } else if allText.contains("orchid") || allText.contains("orchidaceae") {
            return .orchid
        } else if allText.contains("herb") || allText.contains("basil") || allText.contains("mint") {
            return .herb
        } else if allText.contains("flower") || allText.contains("bloom") || allText.contains("flowering") {
            return .flowering
        } else if allText.contains("tropical") || allText.contains("monstera") || allText.contains("philodendron") {
            return .tropical
        } else {
            return .foliage // Default
        }
    }
}

enum Season: String, CaseIterable {
    case spring = "Spring"
    case summer = "Summer"
    case fall = "Fall"
    case winter = "Winter"
    
    static var current: Season {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .fall
        default: return .winter
        }
    }
}

enum CareEnvironment: String, CaseIterable {
    case indoor = "Indoor"
    case outdoor = "Outdoor"
    case greenhouse = "Greenhouse"
    case balcony = "Balcony"
}

enum FertilizerType: String, CaseIterable {
    case liquid = "Liquid"
    case granular = "Granular"
    case slow_release = "Slow Release"
    
    var unit: String {
        switch self {
        case .liquid: return "ml"
        case .granular: return "g"
        case .slow_release: return "pellets"
        }
    }
    
    var dilutionRatio: String {
        switch self {
        case .liquid: return "1:4 (1 part fertilizer to 4 parts water)"
        case .granular: return "Apply directly as directed"
        case .slow_release: return "No dilution needed"
        }
    }
}
