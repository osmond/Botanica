import Foundation
import SwiftData

/// Provides mock data for development, testing, and SwiftUI previews
/// Contains botanically accurate sample plants and care data
final class MockDataGenerator: Sendable {
    
    static let shared = MockDataGenerator()
    
    private init() {}
    
    // MARK: - Sample Plants
    
    /// Creates a collection of sample plants with realistic botanical data
    func createSamplePlants() -> [Plant] {
        return [
            Plant(
                scientificName: "Monstera deliciosa",
                nickname: "My Swiss Cheese Plant",
                family: "Araceae",
                commonNames: ["Swiss Cheese Plant", "Split-leaf Philodendron"],
                potSize: 10,
                growthHabit: .climbing,
                matureSize: "6-8 feet indoors",
                lightLevel: .bright,
                wateringFrequency: 7,
                fertilizingFrequency: 30,
                humidityPreference: 60,
                temperatureRange: TemperatureRange(min: 65, max: 80),
                recommendedWaterAmount: 300,
                waterUnit: .milliliters,
                source: "Local nursery",
                healthStatus: .healthy,
                notes: "Beautiful fenestrations developing on new leaves. Loves the bright corner spot."
            ),
            
            Plant(
                scientificName: "Ficus lyrata",
                nickname: "Fiddle",
                family: "Moraceae",
                commonNames: ["Fiddle Leaf Fig", "Banjo Fig"],
                potSize: 12,
                growthHabit: .upright,
                matureSize: "6-10 feet indoors",
                lightLevel: .bright,
                wateringFrequency: 10,
                fertilizingFrequency: 45,
                humidityPreference: 50,
                temperatureRange: TemperatureRange(min: 65, max: 75),
                recommendedWaterAmount: 400,
                waterUnit: .milliliters,
                source: "Online plant shop",
                healthStatus: .fair,
                notes: "Struggling with brown spots on lower leaves. May be overwatering."
            ),
            
            Plant(
                scientificName: "Sansevieria trifasciata",
                nickname: "Snake Plant",
                family: "Asparagaceae",
                commonNames: ["Snake Plant", "Mother-in-Law's Tongue"],
                potSize: 6,
                growthHabit: .upright,
                matureSize: "2-4 feet",
                lightLevel: .low,
                wateringFrequency: 21,
                fertilizingFrequency: 90,
                humidityPreference: 30,
                temperatureRange: TemperatureRange(min: 60, max: 85),
                recommendedWaterAmount: 150,
                waterUnit: .milliliters,
                source: "Friend's cutting",
                healthStatus: .excellent,
                notes: "Perfect low-maintenance plant. Thriving in the bedroom corner."
            ),
            
            Plant(
                scientificName: "Pothos aureus",
                nickname: "Golden Pothos",
                family: "Araceae",
                commonNames: ["Golden Pothos", "Devil's Ivy"],
                potSize: 8,
                growthHabit: .trailing,
                matureSize: "6-10 feet vine",
                lightLevel: .medium,
                wateringFrequency: 7,
                fertilizingFrequency: 60,
                humidityPreference: 40,
                temperatureRange: TemperatureRange(min: 65, max: 85),
                recommendedWaterAmount: 200,
                waterUnit: .milliliters,
                source: "Hardware store",
                healthStatus: .healthy,
                notes: "Fast grower! Need to trim back regularly. Propagating cuttings for friends."
            ),
            
            Plant(
                scientificName: "Pilea peperomioides",
                nickname: "Pancake Plant",
                family: "Urticaceae",
                commonNames: ["Pancake Plant", "Chinese Money Plant"],
                potSize: 4,
                growthHabit: .rosette,
                matureSize: "8-12 inches",
                lightLevel: .bright,
                wateringFrequency: 5,
                fertilizingFrequency: 30,
                humidityPreference: 50,
                temperatureRange: TemperatureRange(min: 65, max: 75),
                recommendedWaterAmount: 100,
                waterUnit: .milliliters,
                source: "Plant swap",
                healthStatus: .healthy,
                notes: "Produces lots of babies! Great for sharing with plant friends."
            )
        ]
    }
    
    // MARK: - Sample Care Events
    
    /// Creates realistic care events for a plant
    func createSampleCareEvents(for plant: Plant) -> [CareEvent] {
        let now = Date()
        let calendar = Calendar.current
        
        return [
            CareEvent(
                type: .watering,
                date: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                amount: 200,
                unit: "ml",
                notes: "Soil was quite dry, gave extra water"
            ),
            
            CareEvent(
                type: .fertilizing,
                date: calendar.date(byAdding: .day, value: -15, to: now) ?? now,
                amount: 5,
                unit: "ml",
                notes: "Diluted liquid fertilizer as recommended"
            ),
            
            CareEvent(
                type: .rotating,
                date: calendar.date(byAdding: .day, value: -7, to: now) ?? now,
                notes: "Quarter turn towards window for even growth"
            ),
            
            CareEvent(
                type: .inspection,
                date: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                notes: "Checked for pests, new growth looking good"
            ),
            
            CareEvent(
                type: .cleaning,
                date: calendar.date(byAdding: .day, value: -10, to: now) ?? now,
                notes: "Wiped leaves with damp cloth to remove dust"
            )
        ]
    }
    
    // MARK: - Sample Reminders
    
    /// Creates sample reminders for a plant
    func createSampleReminders(for plant: Plant) -> [Reminder] {
        let calendar = Calendar.current
        let wateringTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        let fertilizingTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
        
        return [
            Reminder(
                taskType: .watering,
                recurrence: .weekly,
                notificationTime: wateringTime,
                customMessage: "Time to water \(plant.nickname)! Check soil moisture first.",
                isActive: true
            ),
            
            Reminder(
                taskType: .fertilizing,
                recurrence: .monthly,
                notificationTime: fertilizingTime,
                customMessage: "Monthly feeding time for \(plant.nickname)",
                isActive: true
            )
        ]
    }
    
    // MARK: - Sample Care Plan
    
    /// Creates an AI-generated care plan for a plant
    func createSampleCarePlan(for plant: Plant) -> CarePlan {
        return CarePlan(
            source: .ai,
            wateringInterval: plant.wateringFrequency,
            fertilizingInterval: plant.fertilizingFrequency,
            lightRequirements: "Bright, indirect light. Avoid direct sunlight which can scorch leaves.",
            humidityRequirements: "Moderate to high humidity (40-60%). Use pebble tray or humidifier if needed.",
            temperatureRequirements: "Consistent temperatures between 65-80°F. Avoid cold drafts.",
            seasonalNotes: "Reduce watering in winter. Increase humidity during heating season.",
            aiExplanation: "Based on the species \(plant.scientificName), this plant thrives in bright, indirect light with consistent moisture but good drainage. Native to tropical regions, it appreciates higher humidity levels.",
            userApproved: true
        )
    }
    
    // MARK: - Model Container Setup
    
    /// Creates a model container with sample data for previews
    @MainActor
    static func previewContainer() -> ModelContainer {
        do {
            let container = try ModelContainer(
                for: Plant.self, CareEvent.self, Reminder.self, Photo.self, CarePlan.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            
            let mockData = MockDataGenerator.shared
            let plants = mockData.createSamplePlants()
            
            for plant in plants {
                container.mainContext.insert(plant)
                
                // Add care events
                let careEvents = mockData.createSampleCareEvents(for: plant)
                for event in careEvents {
                    event.plant = plant
                    container.mainContext.insert(event)
                }
                
                // Add reminders
                let reminders = mockData.createSampleReminders(for: plant)
                for reminder in reminders {
                    reminder.plant = plant
                    container.mainContext.insert(reminder)
                }
                
                // Add care plan
                let carePlan = mockData.createSampleCarePlan(for: plant)
                carePlan.plant = plant
                container.mainContext.insert(carePlan)
            }
            
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}

// Convenient single sample plant for previews
extension MockDataGenerator {
    static var samplePlant: Plant {
        MockDataGenerator.shared.createSamplePlants().first ??
        Plant(scientificName: "Ficus elastica", nickname: "Rubber Plant")
    }
}
