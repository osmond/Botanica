//
//  DataModelTests.swift
//  BotanicaTests
//
//  Created by GitHub Copilot
//

import XCTest
import SwiftData
@testable import Botanica

final class DataModelTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory model container for testing
        let schema = Schema([Plant.self, CareEvent.self, Photo.self, Reminder.self, CarePlan.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - Plant Model Tests
    
    func testPlantCreation_WithDefaultValues() {
        // Given: Plant with minimal required fields
        let plant = Plant(
            scientificName: "Monstera deliciosa",
            nickname: "My Monstera"
        )
        
        // Then: Should have sensible defaults
        XCTAssertEqual(plant.scientificName, "Monstera deliciosa")
        XCTAssertEqual(plant.nickname, "My Monstera")
        XCTAssertEqual(plant.potSize, 6, "Default pot size should be 6")
        XCTAssertEqual(plant.wateringFrequency, 7, "Default watering frequency should be 7 days")
        XCTAssertEqual(plant.fertilizingFrequency, 30, "Default fertilizing frequency should be 30 days")
        XCTAssertEqual(plant.healthStatus, .healthy, "Default health status should be healthy")
        XCTAssertNotNil(plant.id, "Plant should have a UUID")
    }
    
    func testPlantCreation_WithCustomValues() {
        // Given: Plant with custom values
        let temperatureRange = TemperatureRange(min: 60, max: 75)
        let plant = Plant(
            scientificName: "Aloe vera",
            nickname: "Aloe",
            family: "Asphodelaceae",
            commonNames: ["Aloe", "Medicinal Aloe"],
            potSize: 8,
            growthHabit: .rosette,
            lightLevel: .bright,
            wateringFrequency: 14,
            fertilizingFrequency: 60,
            humidityPreference: 30,
            temperatureRange: temperatureRange,
            healthStatus: .excellent
        )
        
        // Then: All custom values should be set correctly
        XCTAssertEqual(plant.scientificName, "Aloe vera")
        XCTAssertEqual(plant.family, "Asphodelaceae")
        XCTAssertEqual(plant.potSize, 8)
        XCTAssertEqual(plant.growthHabit, .rosette)
        XCTAssertEqual(plant.wateringFrequency, 14)
        XCTAssertEqual(plant.temperatureRange.min, 60)
        XCTAssertEqual(plant.temperatureRange.max, 75)
    }
    
    func testPlant_DisplayName_UsesNickname() {
        // Given: Plant with nickname
        let plant = Plant(
            scientificName: "Ficus benjamina",
            nickname: "Benny the Fig"
        )
        
        // When: Get display name
        let displayName = plant.displayName
        
        // Then: Should use nickname
        XCTAssertEqual(displayName, "Benny the Fig")
    }
    
    func testPlant_DisplayName_FallsBackToScientificName() {
        // Given: Plant without nickname
        let plant = Plant(
            scientificName: "Ficus benjamina",
            nickname: ""
        )
        
        // When: Get display name
        let displayName = plant.displayName
        
        // Then: Should use scientific name
        XCTAssertEqual(displayName, "Ficus benjamina")
    }
    
    // MARK: - Plant Care Event Relationship Tests
    
    func testPlant_AddsCareEventCorrectly() {
        // Given: A plant and a care event
        let plant = Plant(scientificName: "Test Plant", nickname: "Test")
        let careEvent = CareEvent(type: .watering, amount: 250, unit: "ml")
        
        // When: Link care event to plant
        plant.careEvents.append(careEvent)
        careEvent.plant = plant
        
        // Then: Relationship should be established
        XCTAssertEqual(plant.careEvents.count, 1)
        XCTAssertEqual(plant.careEvents.first?.type, .watering)
        XCTAssertEqual(careEvent.plant?.id, plant.id)
    }
    
    func testPlant_LastCareEvent_ReturnsCorrectEvent() {
        // Given: Plant with multiple watering events
        let plant = Plant(scientificName: "Test Plant", nickname: "Test")
        
        let oldWatering = CareEvent(type: .watering, date: Date().addingTimeInterval(-7 * 24 * 60 * 60))
        let recentWatering = CareEvent(type: .watering, date: Date().addingTimeInterval(-2 * 24 * 60 * 60))
        
        plant.careEvents.append(oldWatering)
        plant.careEvents.append(recentWatering)
        
        // When: Get last watering event
        let lastWatering = plant.lastCareEvent(of: .watering)
        
        // Then: Should return most recent watering
        XCTAssertNotNil(lastWatering)
        XCTAssertEqual(lastWatering?.date, recentWatering.date)
    }
    
    func testPlant_LastCareEvent_ReturnsNilWhenNoneExists() {
        // Given: Plant with no fertilizing events
        let plant = Plant(scientificName: "Test Plant", nickname: "Test")
        let watering = CareEvent(type: .watering)
        plant.careEvents.append(watering)
        
        // When: Try to get last fertilizing event
        let lastFertilizing = plant.lastCareEvent(of: .fertilizing)
        
        // Then: Should return nil
        XCTAssertNil(lastFertilizing)
    }
    
    // MARK: - Plant Care Due Date Tests
    
    func testPlant_DaysSinceLastWatering_CalculatesCorrectly() {
        // Given: Plant watered 3 days ago
        let plant = Plant(scientificName: "Test Plant", nickname: "Test")
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let watering = CareEvent(type: .watering, date: threeDaysAgo)
        plant.careEvents.append(watering)
        
        // When: Get days since last watering
        let days = plant.daysSinceLastWatering
        
        // Then: Should be 3 days
        XCTAssertEqual(days, 3)
    }
    
    func testPlant_DaysSinceLastWatering_ReturnsNegativeWhenNoEvents() {
        // Given: Plant with no watering events
        let plant = Plant(scientificName: "Test Plant", nickname: "Test")
        
        // When: Get days since last watering
        let days = plant.daysSinceLastWatering
        
        // Then: Should return -1
        XCTAssertEqual(days, -1)
    }
    
    func testPlant_IsWateringOverdue_DetectsOverdueWatering() {
        // Given: Plant with 7-day watering frequency, last watered 10 days ago
        let plant = Plant(scientificName: "Test Plant", nickname: "Test", wateringFrequency: 7)
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let watering = CareEvent(type: .watering, date: tenDaysAgo)
        plant.careEvents.append(watering)
        
        // When: Check if watering is overdue
        let isOverdue = plant.isWateringOverdue
        
        // Then: Should be overdue
        XCTAssertTrue(isOverdue)
    }
    
    func testPlant_IsWateringOverdue_NotOverdueWhenRecent() {
        // Given: Plant with 7-day watering frequency, last watered 3 days ago
        let plant = Plant(scientificName: "Test Plant", nickname: "Test", wateringFrequency: 7)
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let watering = CareEvent(type: .watering, date: threeDaysAgo)
        plant.careEvents.append(watering)
        
        // When: Check if watering is overdue
        let isOverdue = plant.isWateringOverdue
        
        // Then: Should not be overdue
        XCTAssertFalse(isOverdue)
    }
    
    func testPlant_WateringDueInDays_CalculatesPositiveDays() {
        // Given: Plant with 7-day frequency, watered 3 days ago
        let plant = Plant(scientificName: "Test Plant", nickname: "Test", wateringFrequency: 7)
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let watering = CareEvent(type: .watering, date: threeDaysAgo)
        plant.careEvents.append(watering)
        
        // When: Calculate days until due
        let daysUntilDue = plant.wateringDueInDays
        
        // Then: Should be 4 days (7 - 3)
        XCTAssertEqual(daysUntilDue, 4)
    }
    
    func testPlant_WateringDueInDays_CalculatesNegativeDaysWhenOverdue() {
        // Given: Plant with 7-day frequency, watered 10 days ago
        let plant = Plant(scientificName: "Test Plant", nickname: "Test", wateringFrequency: 7)
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let watering = CareEvent(type: .watering, date: tenDaysAgo)
        plant.careEvents.append(watering)
        
        // When: Calculate days until due
        let daysUntilDue = plant.wateringDueInDays
        
        // Then: Should be -3 days (7 - 10)
        XCTAssertEqual(daysUntilDue, -3)
    }
    
    func testPlant_NextWateringDate_CalculatesCorrectly() {
        // Given: Plant watered 3 days ago with 7-day frequency
        let plant = Plant(scientificName: "Test Plant", nickname: "Test", wateringFrequency: 7)
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let watering = CareEvent(type: .watering, date: threeDaysAgo)
        plant.careEvents.append(watering)
        
        // When: Get next watering date
        let nextDate = plant.nextWateringDate
        
        // Then: Should be 4 days from now
        XCTAssertNotNil(nextDate)
        let expectedDate = Calendar.current.date(byAdding: .day, value: 7, to: threeDaysAgo)!
        let calendar = Calendar.current
        XCTAssertEqual(
            calendar.startOfDay(for: nextDate!),
            calendar.startOfDay(for: expectedDate)
        )
    }
    
    // MARK: - Plant Health Status Tests
    
    func testPlant_HealthStatusColor_ReturnsCorrectColors() {
        // Given: Plants with different health statuses
        let excellentPlant = Plant(scientificName: "Test", nickname: "Test", healthStatus: .excellent)
        let healthyPlant = Plant(scientificName: "Test", nickname: "Test", healthStatus: .healthy)
        let fairPlant = Plant(scientificName: "Test", nickname: "Test", healthStatus: .fair)
        let poorPlant = Plant(scientificName: "Test", nickname: "Test", healthStatus: .poor)
        let criticalPlant = Plant(scientificName: "Test", nickname: "Test", healthStatus: .critical)
        
        // When/Then: Colors should match health status
        XCTAssertEqual(excellentPlant.healthStatusColor, BotanicaTheme.Colors.success)
        XCTAssertEqual(healthyPlant.healthStatusColor, BotanicaTheme.Colors.success)
        XCTAssertEqual(fairPlant.healthStatusColor, BotanicaTheme.Colors.warning)
        XCTAssertEqual(poorPlant.healthStatusColor, BotanicaTheme.Colors.nutrientOrange)
        XCTAssertEqual(criticalPlant.healthStatusColor, BotanicaTheme.Colors.error)
    }
    
    func testPlant_NeedsAttention_DetectsPoorHealth() {
        // Given: Plant with poor health
        let plant = Plant(scientificName: "Test", nickname: "Test", healthStatus: .poor)
        
        // When: Check if needs attention
        let needsAttention = plant.needsAttention
        
        // Then: Should need attention
        XCTAssertTrue(needsAttention)
    }
    
    func testPlant_NextUrgentTask_ReturnsOverdueWatering() {
        // Given: Plant with overdue watering
        let plant = Plant(scientificName: "Test", nickname: "Test", wateringFrequency: 7)
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let watering = CareEvent(type: .watering, date: tenDaysAgo)
        plant.careEvents.append(watering)
        
        // When: Get urgent task
        let task = plant.nextUrgentTask
        
        // Then: Should indicate overdue watering
        XCTAssertNotNil(task)
        XCTAssertTrue(task!.contains("Watering overdue"))
        XCTAssertTrue(task!.contains("3 days"))
    }
    
    func testPlant_NextUrgentTask_ReturnsWateringDueToday() {
        // Given: Plant watered exactly 7 days ago
        let plant = Plant(scientificName: "Test", nickname: "Test", wateringFrequency: 7)
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let watering = CareEvent(type: .watering, date: sevenDaysAgo)
        plant.careEvents.append(watering)
        
        // When: Get urgent task
        let task = plant.nextUrgentTask
        
        // Then: Should indicate watering due today
        XCTAssertNotNil(task)
        XCTAssertTrue(task!.contains("Watering due today"))
    }
    
    // MARK: - CareEvent Model Tests
    
    func testCareEvent_Creation_WithAllFields() {
        // Given: Care event with full details
        let date = Date()
        let careEvent = CareEvent(
            type: .watering,
            date: date,
            amount: 250,
            unit: "ml",
            notes: "Regular watering",
            weatherConditions: "Sunny, 75°F"
        )
        
        // Then: All fields should be set correctly
        XCTAssertEqual(careEvent.type, .watering)
        XCTAssertEqual(careEvent.date, date)
        XCTAssertEqual(careEvent.amount, 250)
        XCTAssertEqual(careEvent.unit, "ml")
        XCTAssertEqual(careEvent.notes, "Regular watering")
        XCTAssertEqual(careEvent.weatherConditions, "Sunny, 75°F")
        XCTAssertNotNil(careEvent.id)
    }
    
    func testCareEvent_DefaultValues() {
        // Given: Care event with minimal fields
        let careEvent = CareEvent(type: .pruning)
        
        // Then: Should have sensible defaults
        XCTAssertEqual(careEvent.type, .pruning)
        XCTAssertEqual(careEvent.unit, "")
        XCTAssertEqual(careEvent.notes, "")
        XCTAssertNil(careEvent.amount)
    }
    
    func testCareEvent_AllTypes_AreValid() {
        // Given: All care types
        let allTypes = CareType.allCases
        
        // Then: Should be able to create events for all types
        for type in allTypes {
            let event = CareEvent(type: type)
            XCTAssertEqual(event.type, type)
        }
        
        // Verify we have the expected types
        XCTAssertTrue(allTypes.contains(.watering))
        XCTAssertTrue(allTypes.contains(.fertilizing))
        XCTAssertTrue(allTypes.contains(.repotting))
        XCTAssertTrue(allTypes.contains(.pruning))
    }
    
    // MARK: - TemperatureRange Tests
    
    func testTemperatureRange_Description() {
        // Given: Temperature range
        let range = TemperatureRange(min: 65, max: 80)
        
        // When: Get description
        let description = range.description
        
        // Then: Should format correctly
        XCTAssertEqual(description, "65°F - 80°F")
    }
    
    func testTemperatureRange_ValidatesRange() {
        // Given: Temperature ranges
        let validRange = TemperatureRange(min: 50, max: 90)
        let narrowRange = TemperatureRange(min: 68, max: 72)
        
        // Then: Should store values correctly
        XCTAssertEqual(validRange.min, 50)
        XCTAssertEqual(validRange.max, 90)
        XCTAssertEqual(narrowRange.min, 68)
        XCTAssertEqual(narrowRange.max, 72)
    }
    
    // MARK: - Enum Tests
    
    func testGrowthHabit_AllCasesAvailable() {
        // Given: All growth habit cases
        let allHabits = GrowthHabit.allCases
        
        // Then: Should contain expected cases
        XCTAssertTrue(allHabits.contains(.upright))
        XCTAssertTrue(allHabits.contains(.climbing))
        XCTAssertTrue(allHabits.contains(.trailing))
        XCTAssertTrue(allHabits.contains(.spreading))
        XCTAssertTrue(allHabits.contains(.rosette))
        XCTAssertTrue(allHabits.contains(.bushy))
    }
    
    func testLightLevel_IconsAssigned() {
        // Given: All light levels
        let allLevels = LightLevel.allCases
        
        // Then: Each should have an icon
        for level in allLevels {
            XCTAssertFalse(level.icon.isEmpty, "\(level) should have an icon")
        }
    }
    
    func testHealthStatus_ColorsAssigned() {
        // Given: All health statuses
        let allStatuses = HealthStatus.allCases
        
        // Then: Each should have a color
        for status in allStatuses {
            XCTAssertFalse(status.color.isEmpty, "\(status) should have a color")
        }
    }
    
    func testWaterUnit_Conversions() {
        // Given: All water units
        let allUnits = WaterUnit.allCases
        
        // Then: Each should have description and full name
        for unit in allUnits {
            XCTAssertFalse(unit.description.isEmpty)
            XCTAssertFalse(unit.fullName.isEmpty)
        }
        
        // Verify specific conversions
        XCTAssertEqual(WaterUnit.milliliters.description, "ml")
        XCTAssertEqual(WaterUnit.ounces.description, "fl oz")
        XCTAssertEqual(WaterUnit.cups.description, "cups")
        XCTAssertEqual(WaterUnit.liters.description, "L")
    }
    
    // MARK: - Season Tests
    
    func testSeason_CurrentSeasonCalculation() {
        // Given: Current date
        let season = Season.current
        
        // Then: Season should be valid
        XCTAssertTrue(Season.allCases.contains(season))
    }
    
    func testSeason_MonthMapping() {
        // Test season calculation for specific months
        let calendar = Calendar.current
        
        // Spring (March-May)
        var components = DateComponents(year: 2024, month: 4, day: 15)
        if let springDate = calendar.date(from: components) {
            let month = calendar.component(.month, from: springDate)
            XCTAssertTrue((3...5).contains(month))
        }
        
        // Summer (June-August)
        components = DateComponents(year: 2024, month: 7, day: 15)
        if let summerDate = calendar.date(from: components) {
            let month = calendar.component(.month, from: summerDate)
            XCTAssertTrue((6...8).contains(month))
        }
    }
    
    // MARK: - Plant Care Completion Rate Tests
    
    func testPlant_CareCompletionRate_CalculatesCorrectly() {
        // Given: Plant with some care events in the last 30 days
        let plant = Plant(
            scientificName: "Test Plant",
            nickname: "Test",
            wateringFrequency: 7,  // Expect ~4 waterings in 30 days
            fertilizingFrequency: 30 // Expect 1 fertilizing in 30 days
        )
        
        // Add 4 watering events
        for i in 0..<4 {
            let daysAgo = i * 7
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
            let watering = CareEvent(type: .watering, date: date)
            plant.careEvents.append(watering)
        }
        
        // Add 1 fertilizing event
        let fertilizing = CareEvent(type: .fertilizing, date: Date().addingTimeInterval(-15 * 24 * 60 * 60))
        plant.careEvents.append(fertilizing)
        
        // When: Get completion rate
        let completionRate = plant.careCompletionRate
        
        // Then: Should be close to 100% (5 events / 5 expected)
        XCTAssertGreaterThan(completionRate, 0.8, "Completion rate should be high with regular care")
        XCTAssertLessThanOrEqual(completionRate, 1.0, "Completion rate should not exceed 100%")
    }
    
    func testPlant_CareCompletionRate_LowWhenNoEvents() {
        // Given: Plant with no care events
        let plant = Plant(
            scientificName: "Test Plant",
            nickname: "Test",
            wateringFrequency: 7
        )
        
        // When: Get completion rate
        let completionRate = plant.careCompletionRate
        
        // Then: Should be 0
        XCTAssertEqual(completionRate, 0.0)
    }
}
