import Foundation
import SwiftData
import SwiftUI

struct PlantFormData {
    var nickname: String
    var scientificName: String
    var family: String
    var commonNames: [String]
    var potSize: Int
    var potHeight: Int?
    var potMaterial: PotMaterial?
    var growthHabit: GrowthHabit
    var matureSize: String
    var lightLevel: LightLevel
    var wateringFrequency: Int
    var fertilizingFrequency: Int
    var humidityPreference: Int
    var temperatureRange: TemperatureRange
    var recommendedWaterAmount: Double
    var waterUnit: WaterUnit
    var source: String
    var location: String
    var healthStatus: HealthStatus
    var notes: String
    var lastWatered: Date?
    var lastFertilized: Date?
    var photosData: [Data]
}

/// Shared add/edit view model to centralize validation and persistence.
@MainActor
final class PlantFormViewModel: ViewModel {
    @Published var loadState: LoadState = .idle
    @Published var validationMessage: String?
    
    func validate(_ data: PlantFormData) -> Bool {
        if data.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = "Nickname is required."
            return false
        }
        if data.wateringFrequency <= 0 {
            validationMessage = "Watering frequency must be greater than zero."
            return false
        }
        validationMessage = nil
        return true
    }
    
    func saveNewPlant(_ data: PlantFormData, in context: ModelContext) throws -> Plant {
        guard validate(data) else {
            throw PlantFormValidationError(message: validationMessage ?? "Invalid plant data.")
        }
        
        setLoading()
        
        let plant = Plant(
            scientificName: data.scientificName.trimmingCharacters(in: .whitespacesAndNewlines),
            nickname: data.nickname.trimmingCharacters(in: .whitespacesAndNewlines),
            family: data.family.trimmingCharacters(in: .whitespacesAndNewlines),
            commonNames: data.commonNames,
            potSize: data.potSize,
            potHeight: data.potHeight,
            potMaterial: data.potMaterial,
            growthHabit: data.growthHabit,
            matureSize: data.matureSize.trimmingCharacters(in: .whitespacesAndNewlines),
            lightLevel: data.lightLevel,
            wateringFrequency: data.wateringFrequency,
            fertilizingFrequency: data.fertilizingFrequency,
            humidityPreference: data.humidityPreference,
            temperatureRange: data.temperatureRange,
            recommendedWaterAmount: data.recommendedWaterAmount,
            waterUnit: data.waterUnit,
            source: data.source.trimmingCharacters(in: .whitespacesAndNewlines),
            location: data.location.trimmingCharacters(in: .whitespacesAndNewlines),
            healthStatus: data.healthStatus,
            notes: data.notes.trimmingCharacters(in: .whitespacesAndNewlines),
            lastWatered: data.lastWatered,
            lastFertilized: data.lastFertilized
        )
        
        context.insert(plant)
        
        for (index, data) in data.photosData.enumerated() {
            let photo = Photo(
                imageData: data,
                caption: index == 0 ? "Main photo" : "",
                isPrimary: index == 0
            )
            photo.plant = plant
            context.insert(photo)
        }
        
        try context.save()
        setLoaded()
        return plant
    }
    
    func update(_ plant: Plant, with data: PlantFormData, in context: ModelContext) throws {
        guard validate(data) else {
            throw PlantFormValidationError(message: validationMessage ?? "Invalid plant data.")
        }
        
        setLoading()
        
        plant.nickname = data.nickname
        plant.scientificName = data.scientificName
        plant.family = data.family
        plant.commonNames = data.commonNames
        plant.potSize = data.potSize
        plant.potHeight = data.potHeight
        plant.potMaterial = data.potMaterial
        plant.growthHabit = data.growthHabit
        plant.matureSize = data.matureSize
        plant.lightLevel = data.lightLevel
        plant.wateringFrequency = data.wateringFrequency
        plant.fertilizingFrequency = data.fertilizingFrequency
        plant.humidityPreference = data.humidityPreference
        plant.temperatureRange = data.temperatureRange
        plant.recommendedWaterAmount = data.recommendedWaterAmount
        plant.waterUnit = data.waterUnit
        plant.source = data.source
        plant.location = data.location
        plant.healthStatus = data.healthStatus
        plant.notes = data.notes
        plant.lastWatered = data.lastWatered
        plant.lastFertilized = data.lastFertilized
        
        if !data.photosData.isEmpty {
            for (index, data) in data.photosData.enumerated() {
                let photo = Photo(
                    imageData: data,
                    caption: index == 0 ? "Main photo" : "",
                    isPrimary: index == 0
                )
                photo.plant = plant
                context.insert(photo)
            }
        }
        
        try context.save()
        setLoaded()
    }
}

struct PlantFormValidationError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
