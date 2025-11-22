//
//  CareCalculatorTests.swift
//  BotanicaTests
//
//  Created by GitHub Copilot
//

import XCTest
@testable import Botanica

final class CareCalculatorTests: XCTestCase {
    
    // MARK: - Base Watering Amount Tests
    
    func testCalculateBaseWateringAmount_SmallPot() {
        // Given: 4-inch pot
        let potSize = 4
        let plantType = PlantWateringType.tropical
        let season = Season.summer
        let environment = Environment.indoor
        
        // When: Calculate watering amount
        let result = CareCalculator.recommendedWateringAmount(
            potSize: potSize,
            plantType: plantType,
            season: season,
            environment: environment
        )
        
        // Then: Should be base rate (20ml/inch) * 4 * tropical multiplier (1.2) * summer (1.2) * indoor (1.0)
        // Expected: 20 * 4 * 1.2 * 1.2 * 1.0 = 115.2 ml
        XCTAssertEqual(result.amount, 115.2, accuracy: 0.1, "Small pot watering amount calculation incorrect")
        XCTAssertFalse(result.technique.isEmpty, "Watering technique should not be empty")
        XCTAssertFalse(result.frequency.isEmpty, "Watering frequency should not be empty")
    }
    
    func testCalculateBaseWateringAmount_LargePot() {
        // Given: 12-inch pot
        let potSize = 12
        let plantType = PlantWateringType.tropical
        let season = Season.summer
        let environment = Environment.indoor
        
        // When: Calculate watering amount
        let result = CareCalculator.recommendedWateringAmount(
            potSize: potSize,
            plantType: plantType,
            season: season,
            environment: environment
        )
        
        // Then: Should be base rate * 12 * multipliers
        // Expected: 20 * 12 * 1.2 * 1.2 * 1.0 = 345.6 ml
        XCTAssertEqual(result.amount, 345.6, accuracy: 0.1, "Large pot watering amount calculation incorrect")
    }
    
    // MARK: - Plant Type Multiplier Tests
    
    func testWateringAmount_SucculentType() {
        // Given: Succulent plant (low water needs)
        let potSize = 6
        let plantType = PlantWateringType.succulent
        let season = Season.summer
        let environment = Environment.indoor
        
        // When: Calculate watering amount
        let result = CareCalculator.recommendedWateringAmount(
            potSize: potSize,
            plantType: plantType,
            season: season,
            environment: environment
        )
        
        // Then: Should apply succulent multiplier (0.3)
        // Expected: 20 * 6 * 0.3 * 1.2 * 1.0 = 43.2 ml
        XCTAssertEqual(result.amount, 43.2, accuracy: 0.1, "Succulent watering amount should be significantly reduced")
        XCTAssertTrue(result.frequency.contains("10-14 days") || result.frequency.contains("10") || result.frequency.contains("14"), 
                     "Succulent frequency should be 10-14 days")
    }
    
    func testWateringAmount_CactusType() {
        // Given: Cactus plant (very low water needs)
        let potSize = 6
        let plantType = PlantWateringType.cactus
        let season = Season.summer
        let environment = Environment.indoor
        
        // When: Calculate watering amount
        let result = CareCalculator.recommendedWateringAmount(
            potSize: potSize,
            plantType: plantType,
            season: season,
            environment: environment
        )
        
        // Then: Should apply cactus multiplier (0.2)
        // Expected: 20 * 6 * 0.2 * 1.2 * 1.0 = 28.8 ml
        XCTAssertEqual(result.amount, 28.8, accuracy: 0.1, "Cactus watering amount should be minimal")
        XCTAssertTrue(result.frequency.contains("14-21 days") || result.frequency.contains("14") || result.frequency.contains("21"), 
                     "Cactus frequency should be 14-21 days")
    }
    
    func testWateringAmount_TropicalType() {
        // Given: Tropical plant (high water needs)
        let potSize = 6
        let plantType = PlantWateringType.tropical
        let season = Season.summer
        let environment = Environment.indoor
        
        // When: Calculate watering amount
        let result = CareCalculator.recommendedWateringAmount(
            potSize: potSize,
            plantType: plantType,
            season: season,
            environment: environment
        )
        
        // Then: Should apply tropical multiplier (1.2)
        // Expected: 20 * 6 * 1.2 * 1.2 * 1.0 = 172.8 ml
        XCTAssertEqual(result.amount, 172.8, accuracy: 0.1, "Tropical watering amount should be increased")
        XCTAssertTrue(result.frequency.contains("5-7 days") || result.frequency.contains("5") || result.frequency.contains("7"), 
                     "Tropical frequency should be 5-7 days")
    }
    
    func testWateringAmount_FernType() {
        // Given: Fern plant (high water needs)
        let potSize = 6
        let plantType = PlantWateringType.fern
        let season = Season.summer
        let environment = Environment.indoor
        
        // When: Calculate watering amount
        let result = CareCalculator.recommendedWateringAmount(
            potSize: potSize,
            plantType: plantType,
            season: season,
            environment: environment
        )
        
        // Then: Should apply fern multiplier (1.3)
        // Expected: 20 * 6 * 1.3 * 1.2 * 1.0 = 187.2 ml
        XCTAssertEqual(result.amount, 187.2, accuracy: 0.1, "Fern watering amount should be highest")
        XCTAssertTrue(result.frequency.contains("3-5 days") || result.frequency.contains("3") || result.frequency.contains("5"), 
                     "Fern frequency should be 3-5 days")
    }
    
    // MARK: - Seasonal Adjustment Tests
    
    func testWateringAmount_SpringSeason() {
        // Given: Spring season (moderate growth)
        let potSize = 6
        let plantType = PlantWateringType.tropical
        let season = Season.spring
        let environment = Environment.indoor
        
        // When: Calculate watering amount
        let result = CareCalculator.recommendedWateringAmount(
            potSize: potSize,
            plantType: plantType,
            season: season,
            environment: environment
        )
        
        // Then: Should apply spring multiplier (1.1)
        // Expected: 20 * 6 * 1.2 * 1.1 * 1.0 = 158.4 ml
        XCTAssertEqual(result.amount, 158.4, accuracy: 0.1, "Spring watering should be moderately increased")
    }
    
    func testWateringAmount_SummerSeason() {
        // Given: Summer season (peak growth)
        let potSize = 6
        let plantType = PlantWateringType.tropical
        let season = Season.summer
        let environment = Environment.indoor
        
        // When: Calculate watering amount
        let result = CareCalculator.recommendedWateringAmount(
            potSize: potSize,
            plantType: plantType,
            season: season,
            environment: environment
        )
        
        // Then: Should apply summer multiplier (1.2)
        // Expected: 20 * 6 * 1.2 * 1.2 * 1.0 = 172.8 ml
        XCTAssertEqual(result.amount, 172.8, accuracy: 0.1, "Summer watering should be highest")
    }
    
    func testWateringAmount_FallSeason() {
        // Given: Fall season (reduced growth)
        let potSize = 6
        let plantType = PlantWateringType.tropical
        let season = Season.fall
        let environment = Environment.indoor
        
        // When: Calculate watering amount
        let result = CareCalculator.recommendedWateringAmount(
            potSize: potSize,
            plantType: plantType,
            season: season,
            environment: environment
        )
        
        // Then: Should apply fall multiplier (0.9)
        // Expected: 20 * 6 * 1.2 * 0.9 * 1.0 = 129.6 ml
        XCTAssertEqual(result.amount, 129.6, accuracy: 0.1, "Fall watering should be reduced")
    }
    
    func testWateringAmount_WinterSeason() {
        // Given: Winter season (dormant period)
        let potSize = 6
        let plantType = PlantWateringType.tropical
        let season = Season.winter
        let environment = Environment.indoor
        
        // When: Calculate watering amount
        let result = CareCalculator.recommendedWateringAmount(
            potSize: potSize,
            plantType: plantType,
            season: season,
            environment: environment
        )
        
        // Then: Should apply winter multiplier (0.7)
        // Expected: 20 * 6 * 1.2 * 0.7 * 1.0 = 100.8 ml
        XCTAssertEqual(result.amount, 100.8, accuracy: 0.1, "Winter watering should be significantly reduced")
    }
    
    // MARK: - Environment Adjustment Tests
    
    func testWateringAmount_IndoorEnvironment() {
        // Given: Indoor environment (standard conditions)
        let potSize = 6
        let plantType = PlantWateringType.tropical
        let season = Season.summer
        let environment = Environment.indoor
        
        // When: Calculate watering amount
        let result = CareCalculator.recommendedWateringAmount(
            potSize: potSize,
            plantType: plantType,
            season: season,
            environment: environment
        )
        
        // Then: Should apply indoor multiplier (1.0 - no adjustment)
        // Expected: 20 * 6 * 1.2 * 1.2 * 1.0 = 172.8 ml
        XCTAssertEqual(result.amount, 172.8, accuracy: 0.1, "Indoor should be baseline")
    }
    
    func testWateringAmount_OutdoorEnvironment() {
        // Given: Outdoor environment (higher evaporation)
        let potSize = 6
        let plantType = PlantWateringType.tropical
        let season = Season.summer
        let environment = Environment.outdoor
        
        // When: Calculate watering amount
        let result = CareCalculator.recommendedWateringAmount(
            potSize: potSize,
            plantType: plantType,
            season: season,
            environment: environment
        )
        
        // Then: Should apply outdoor multiplier (1.15)
        // Expected: 20 * 6 * 1.2 * 1.2 * 1.15 = 198.72 ml
        XCTAssertEqual(result.amount, 198.72, accuracy: 0.1, "Outdoor watering should be increased")
    }
    
    func testWateringAmount_GreenhouseEnvironment() {
        // Given: Greenhouse environment (humid)
        let potSize = 6
        let plantType = PlantWateringType.tropical
        let season = Season.summer
        let environment = Environment.greenhouse
        
        // When: Calculate watering amount
        let result = CareCalculator.recommendedWateringAmount(
            potSize: potSize,
            plantType: plantType,
            season: season,
            environment: environment
        )
        
        // Then: Should apply greenhouse multiplier (0.9)
        // Expected: 20 * 6 * 1.2 * 1.2 * 0.9 = 155.52 ml
        XCTAssertEqual(result.amount, 155.52, accuracy: 0.1, "Greenhouse watering should be reduced due to humidity")
    }
    
    // MARK: - Combined Multiplier Tests
    
    func testWateringAmount_ExtremeConditions_WinterCactusIndoor() {
        // Given: Cactus in winter indoors (minimal water)
        let potSize = 8
        let plantType = PlantWateringType.cactus
        let season = Season.winter
        let environment = Environment.indoor
        
        // When: Calculate watering amount
        let result = CareCalculator.recommendedWateringAmount(
            potSize: potSize,
            plantType: plantType,
            season: season,
            environment: environment
        )
        
        // Then: Should apply all reducing multipliers
        // Expected: 20 * 8 * 0.2 * 0.7 * 1.0 = 22.4 ml
        XCTAssertEqual(result.amount, 22.4, accuracy: 0.1, "Winter cactus should need very little water")
    }
    
    func testWateringAmount_ExtremeConditions_SummerFernOutdoor() {
        // Given: Fern in summer outdoors (maximum water)
        let potSize = 8
        let plantType = PlantWateringType.fern
        let season = Season.summer
        let environment = Environment.outdoor
        
        // When: Calculate watering amount
        let result = CareCalculator.recommendedWateringAmount(
            potSize: potSize,
            plantType: plantType,
            season: season,
            environment: environment
        )
        
        // Then: Should apply all increasing multipliers
        // Expected: 20 * 8 * 1.3 * 1.2 * 1.15 = 287.04 ml
        XCTAssertEqual(result.amount, 287.04, accuracy: 0.1, "Summer fern outdoors should need maximum water")
    }
    
    // MARK: - Fertilizer Amount Tests
    
    func testRecommendedFertilizerAmount_LiquidFertilizer() {
        // Given: Liquid fertilizer for tropical plant
        let potSize = 6
        let plantType = PlantWateringType.tropical
        let feedingLevel = FeedingLevel.normal
        let type = FertilizerType.liquid
        
        // When: Calculate fertilizer amount
        let result = CareCalculator.recommendedFertilizerAmount(
            potSize: potSize,
            plantType: plantType,
            feedingLevel: feedingLevel,
            type: type
        )
        
        // Then: Should be liquid base rate (0.5 ml/inch) * potSize * tropical multiplier * normal level
        // Expected: 0.5 * 6 * 1.2 * 1.0 = 3.6 ml
        XCTAssertEqual(result.amount, 3.6, accuracy: 0.1, "Liquid fertilizer amount incorrect")
        XCTAssertFalse(result.frequency.isEmpty, "Fertilizer frequency should not be empty")
    }
    
    func testRecommendedFertilizerAmount_GranularFertilizer() {
        // Given: Granular fertilizer for succulent
        let potSize = 6
        let plantType = PlantWateringType.succulent
        let feedingLevel = FeedingLevel.normal
        let type = FertilizerType.granular
        
        // When: Calculate fertilizer amount
        let result = CareCalculator.recommendedFertilizerAmount(
            potSize: potSize,
            plantType: plantType,
            feedingLevel: feedingLevel,
            type: type
        )
        
        // Then: Should be granular base rate (0.25 g/inch) * potSize * succulent multiplier * normal level
        // Expected: 0.25 * 6 * 0.5 * 1.0 = 0.75 g
        XCTAssertEqual(result.amount, 0.75, accuracy: 0.1, "Granular fertilizer amount incorrect")
    }
    
    func testRecommendedFertilizerAmount_HeavyFeeding() {
        // Given: Heavy feeding level
        let potSize = 8
        let plantType = PlantWateringType.flowering
        let feedingLevel = FeedingLevel.heavy
        let type = FertilizerType.liquid
        
        // When: Calculate fertilizer amount
        let result = CareCalculator.recommendedFertilizerAmount(
            potSize: potSize,
            plantType: plantType,
            feedingLevel: feedingLevel,
            type: type
        )
        
        // Then: Should be base * 1.5 for heavy feeding
        // Expected: 0.5 * 8 * 1.0 * 1.5 = 6.0 ml
        XCTAssertEqual(result.amount, 6.0, accuracy: 0.1, "Heavy feeding level should increase amount by 1.5x")
    }
    
    func testRecommendedFertilizerAmount_LightFeeding() {
        // Given: Light feeding level
        let potSize = 8
        let plantType = PlantWateringType.succulent
        let feedingLevel = FeedingLevel.light
        let type = FertilizerType.liquid
        
        // When: Calculate fertilizer amount
        let result = CareCalculator.recommendedFertilizerAmount(
            potSize: potSize,
            plantType: plantType,
            feedingLevel: feedingLevel,
            type: type
        )
        
        // Then: Should be base * 0.5 for light feeding
        // Expected: 0.5 * 8 * 0.5 * 0.5 = 1.0 ml
        XCTAssertEqual(result.amount, 1.0, accuracy: 0.1, "Light feeding level should reduce amount by 0.5x")
    }
    
    // MARK: - Weather-Adjusted Recommendation Tests
    
    func testWeatherAdjustedRecommendation_HotDryWeather() {
        // Given: Hot and dry weather conditions
        let baseAmount = 100.0
        let baseFrequency = "7 days"
        let temperature = 32.0 // Hot
        let humidity = 25.0    // Dry
        
        // When: Calculate weather-adjusted recommendation
        let result = CareCalculator.weatherAdjustedRecommendation(
            baseAmount: baseAmount,
            baseFrequency: baseFrequency,
            temperature: temperature,
            humidity: humidity
        )
        
        // Then: Should increase amount by hot-dry multiplier (1.2)
        XCTAssertEqual(result.adjustedAmount, 120.0, accuracy: 0.1, "Hot-dry weather should increase watering")
        XCTAssertTrue(result.adjustedFrequency.contains("5-6") || result.adjustedFrequency.contains("5") || result.adjustedFrequency.contains("6"), 
                     "Frequency should be reduced to 5-6 days")
        XCTAssertFalse(result.weatherNote.isEmpty, "Should include weather note")
    }
    
    func testWeatherAdjustedRecommendation_CoolHumidWeather() {
        // Given: Cool and humid weather conditions
        let baseAmount = 100.0
        let baseFrequency = "7 days"
        let temperature = 15.0 // Cool
        let humidity = 75.0    // Humid
        
        // When: Calculate weather-adjusted recommendation
        let result = CareCalculator.weatherAdjustedRecommendation(
            baseAmount: baseAmount,
            baseFrequency: baseFrequency,
            temperature: temperature,
            humidity: humidity
        )
        
        // Then: Should reduce amount by cool-humid multiplier (0.8)
        XCTAssertEqual(result.adjustedAmount, 80.0, accuracy: 0.1, "Cool-humid weather should reduce watering")
        XCTAssertTrue(result.adjustedFrequency.contains("8-9") || result.adjustedFrequency.contains("8") || result.adjustedFrequency.contains("9"), 
                     "Frequency should be increased to 8-9 days")
        XCTAssertFalse(result.weatherNote.isEmpty, "Should include weather note")
    }
    
    func testWeatherAdjustedRecommendation_ModerateWeather() {
        // Given: Moderate weather conditions
        let baseAmount = 100.0
        let baseFrequency = "7 days"
        let temperature = 22.0 // Moderate
        let humidity = 55.0    // Moderate
        
        // When: Calculate weather-adjusted recommendation
        let result = CareCalculator.weatherAdjustedRecommendation(
            baseAmount: baseAmount,
            baseFrequency: baseFrequency,
            temperature: temperature,
            humidity: humidity
        )
        
        // Then: Should maintain base amount (no weather multiplier)
        XCTAssertEqual(result.adjustedAmount, 100.0, accuracy: 0.1, "Moderate weather should not adjust watering")
        XCTAssertEqual(result.adjustedFrequency, baseFrequency, "Frequency should remain unchanged")
    }
    
    // MARK: - Plant Type Detection Tests
    
    func testPlantWateringType_FromCactusNames() {
        // Given: Cactus common names
        let commonNames = ["Prickly Pear", "Barrel Cactus"]
        let family = ""
        let scientificName = ""
        
        // When: Detect plant type
        let type = PlantWateringType.from(commonNames: commonNames, family: family, scientificName: scientificName)
        
        // Then: Should be cactus type
        XCTAssertEqual(type, .cactus, "Should detect cactus from common names")
    }
    
    func testPlantWateringType_FromSucculentNames() {
        // Given: Succulent common names
        let commonNames = ["Jade Plant", "Aloe Vera"]
        let family = ""
        let scientificName = ""
        
        // When: Detect plant type
        let type = PlantWateringType.from(commonNames: commonNames, family: family, scientificName: scientificName)
        
        // Then: Should be succulent type
        XCTAssertEqual(type, .succulent, "Should detect succulent from common names")
    }
    
    func testPlantWateringType_FromFernFamily() {
        // Given: Fern family
        let commonNames: [String] = []
        let family = "Polypodiaceae"
        let scientificName = ""
        
        // When: Detect plant type
        let type = PlantWateringType.from(commonNames: commonNames, family: family, scientificName: scientificName)
        
        // Then: Should be fern type
        XCTAssertEqual(type, .fern, "Should detect fern from family name")
    }
    
    func testPlantWateringType_FromTropicalNames() {
        // Given: Tropical plant names
        let commonNames = ["Monstera", "Philodendron"]
        let family = ""
        let scientificName = ""
        
        // When: Detect plant type
        let type = PlantWateringType.from(commonNames: commonNames, family: family, scientificName: scientificName)
        
        // Then: Should be tropical type
        XCTAssertEqual(type, .tropical, "Should detect tropical from common names")
    }
    
    func testPlantWateringType_DefaultToNormal() {
        // Given: Unknown plant
        let commonNames = ["Mystery Plant"]
        let family = "Unknown Family"
        let scientificName = "Plantus unknownus"
        
        // When: Detect plant type
        let type = PlantWateringType.from(commonNames: commonNames, family: family, scientificName: scientificName)
        
        // Then: Should default to normal
        XCTAssertEqual(type, .normal, "Unknown plants should default to normal watering")
    }
    
    // MARK: - Edge Cases and Validation Tests
    
    func testWateringAmount_MinimumPotSize() {
        // Given: Very small pot (2 inches)
        let potSize = 2
        let plantType = PlantWateringType.normal
        let season = Season.summer
        let environment = Environment.indoor
        
        // When: Calculate watering amount
        let result = CareCalculator.recommendedWateringAmount(
            potSize: potSize,
            plantType: plantType,
            season: season,
            environment: environment
        )
        
        // Then: Should calculate properly for small pots
        XCTAssertGreaterThan(result.amount, 0, "Should handle minimum pot size")
        XCTAssertLessThan(result.amount, 100, "Small pot should have reasonable amount")
    }
    
    func testWateringAmount_LargePotSize() {
        // Given: Very large pot (24 inches)
        let potSize = 24
        let plantType = PlantWateringType.normal
        let season = Season.summer
        let environment = Environment.indoor
        
        // When: Calculate watering amount
        let result = CareCalculator.recommendedWateringAmount(
            potSize: potSize,
            plantType: plantType,
            season: season,
            environment: environment
        )
        
        // Then: Should scale appropriately
        XCTAssertGreaterThan(result.amount, 200, "Large pot should need significant water")
        XCTAssertLessThan(result.amount, 1000, "Amount should be reasonable even for large pots")
    }
    
    func testRecommendationConsistency_SameInputsSameOutput() {
        // Given: Same parameters
        let potSize = 6
        let plantType = PlantWateringType.tropical
        let season = Season.summer
        let environment = Environment.indoor
        
        // When: Calculate multiple times
        let result1 = CareCalculator.recommendedWateringAmount(
            potSize: potSize,
            plantType: plantType,
            season: season,
            environment: environment
        )
        let result2 = CareCalculator.recommendedWateringAmount(
            potSize: potSize,
            plantType: plantType,
            season: season,
            environment: environment
        )
        
        // Then: Results should be identical
        XCTAssertEqual(result1.amount, result2.amount, "Same inputs should produce same output")
        XCTAssertEqual(result1.frequency, result2.frequency, "Frequency should be consistent")
    }
}
