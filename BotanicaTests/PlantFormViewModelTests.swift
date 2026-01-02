import XCTest
import SwiftData
@testable import Botanica

@MainActor
final class PlantFormViewModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var viewModel: PlantFormViewModel!
    
    override func setUp() {
        super.setUp()
        ModelTransformers.register()
        let schema = Schema([Plant.self, CareEvent.self, Photo.self, Reminder.self, CarePlan.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try? ModelContainer(for: schema, configurations: [configuration])
        modelContext = modelContainer.mainContext
        viewModel = PlantFormViewModel()
    }
    
    override func tearDown() {
        modelContext = nil
        modelContainer = nil
        viewModel = nil
        super.tearDown()
    }
    
    func testSaveNewPlantPersistsPlant() throws {
        let data = PlantFormData(
            nickname: "Test Plant",
            scientificName: "Ficus testus",
            family: "Moraceae",
            commonNames: ["Test Fig"],
            potSize: 8,
            potHeight: nil,
            potMaterial: .ceramic,
            growthHabit: .upright,
            matureSize: "Medium",
            lightLevel: .medium,
            wateringFrequency: 7,
            fertilizingFrequency: 30,
            humidityPreference: 50,
            temperatureRange: TemperatureRange(min: 60, max: 80),
            recommendedWaterAmount: 250,
            waterUnit: .milliliters,
            source: "Nursery",
            location: "Kitchen",
            healthStatus: .healthy,
            notes: "Looks good",
            lastWatered: nil,
            lastFertilized: nil,
            photosData: []
        )
        
        let plant = try viewModel.saveNewPlant(data, in: modelContext)
        XCTAssertEqual(plant.nickname, "Test Plant")
        let fetched = try modelContext.fetch(FetchDescriptor<Plant>())
        XCTAssertEqual(fetched.count, 1)
    }
    
    func testValidationFailsWithoutNickname() {
        let data = PlantFormData(
            nickname: "",
            scientificName: "Ficus testus",
            family: "Moraceae",
            commonNames: [],
            potSize: 6,
            potHeight: nil,
            potMaterial: nil,
            growthHabit: .upright,
            matureSize: "",
            lightLevel: .medium,
            wateringFrequency: 7,
            fertilizingFrequency: 30,
            humidityPreference: 50,
            temperatureRange: TemperatureRange(min: 60, max: 80),
            recommendedWaterAmount: 200,
            waterUnit: .milliliters,
            source: "",
            location: "",
            healthStatus: .healthy,
            notes: "",
            lastWatered: nil,
            lastFertilized: nil,
            photosData: []
        )
        
        XCTAssertThrowsError(try viewModel.saveNewPlant(data, in: modelContext))
    }
}
