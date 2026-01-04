import Foundation
import SwiftData

struct DataImportResult {
    var plantsCreated: Int = 0
    var careEventsCreated: Int = 0
    var remindersCreated: Int = 0
    var photosCreated: Int = 0
    var notes: [String] = []
}

// MARK: - DTOs

private struct ImportBundleDTO: Decodable {
    let version: Int?
    let exportedAt: Date?
    let plants: [ImportPlantDTO]
}

private struct ImportPlantDTO: Decodable {
    // Core
    let scientificName: String?
    let nickname: String?
    let family: String?
    let commonNames: [String]?

    // Physical
    let potSize: Int?
    let potHeight: Int?
    let growthHabit: String?
    let matureSize: String?

    // Care reqs
    let lightLevel: String?
    let wateringFrequency: Int?
    let fertilizingFrequency: Int?
    let humidityPreference: Int?
    let temperatureRange: TemperatureRangeDTO?
    let recommendedWaterAmount: Double?
    let waterUnit: String?
    let potMaterial: String?

    // Metadata
    let dateAdded: Date?
    let dateAcquired: Date?
    let source: String?
    let location: String?
    let healthStatus: String?
    let notes: String?

    // Care state
    let lastWatered: Date?
    let lastFertilized: Date?

    // Relationships
    let photos: [ImportPhotoDTO]?
    let careEvents: [ImportCareEventDTO]?
    let reminders: [ImportReminderDTO]?
    let carePlan: ImportCarePlanDTO?
}

private struct TemperatureRangeDTO: Decodable { let min: Int?; let max: Int? }

private struct ImportPhotoDTO: Decodable {
    let timestamp: Date?
    let caption: String?
    let category: String?
    let isPrimary: Bool?
    // Either base64 data or a filename that could be resolved later
    let data: String?
    let filename: String?
}

private struct ImportCareEventDTO: Decodable {
    let type: String?
    let date: Date?
    let amount: Double?
    let unit: String?
    let notes: String?
    let weatherConditions: String?
}

private struct ImportReminderDTO: Decodable {
    let taskType: String?
    let recurrence: String?
    let notificationTime: Date?
    let isActive: Bool?
    let customMessage: String?
    let lastNotified: Date?
    let nextNotification: Date?
    let snoozedUntil: Date?
}

private struct ImportCarePlanDTO: Decodable {
    let source: String?
    let wateringInterval: Int?
    let fertilizingInterval: Int?
    let lightRequirements: String?
    let humidityRequirements: String?
    let temperatureRequirements: String?
    let seasonalNotes: String?
    let aiExplanation: String?
    let createdDate: Date?
    let lastUpdated: Date?
    let userApproved: Bool?
}

// MARK: - Service

final class DataImportService {
    static let shared = DataImportService()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    /// Import that expects the built-in export bundle shape.
    func importFromJSONData(_ data: Data, into context: ModelContext) throws -> DataImportResult {
        let bundle = try decoder.decode(ImportBundleDTO.self, from: data)
        return try importPlants(bundle.plants, into: context)
    }

    /// Import with schema auto-detection. Tries known shapes and maps to internal DTOs.
    func importAutoDetectingData(_ data: Data, into context: ModelContext) throws -> DataImportResult {
        // Try native bundle first
        if let bundle = try? decoder.decode(ImportBundleDTO.self, from: data) {
            return try importPlants(bundle.plants, into: context)
        }
        // Try Blossom summary array
        if let blossom = try? decoder.decode([BlossomPlantSummary].self, from: data) {
            let mapped = blossom.map { $0.asImportPlantDTO }
            return try importPlants(mapped, into: context)
        }
        // If none matched, throw a descriptive error
        throw NSError(domain: "DataImportService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Unsupported JSON format. Provide Botanica export JSON or a Blossom summary JSON array."])
    }

    // Shared importer for a list of internal plant DTOs
    private func importPlants(_ plants: [ImportPlantDTO], into context: ModelContext) throws -> DataImportResult {
        ModelTransformers.register()
        var result = DataImportResult()
        for plantDTO in plants {
            let plant = makePlant(from: plantDTO, notes: &result.notes)
            context.insert(plant)

            // Photos
            if let photos = plantDTO.photos {
                for p in photos {
                    if let photo = makePhoto(from: p, notes: &result.notes) {
                        photo.plant = plant
                        plant.photos.append(photo)
                        result.photosCreated += 1
                    }
                }
            }

            // Care Events
            if let events = plantDTO.careEvents {
                for e in events {
                    if let ce = makeCareEvent(from: e, notes: &result.notes) {
                        ce.plant = plant
                        plant.careEvents.append(ce)
                        result.careEventsCreated += 1
                    }
                }
            }

            // Reminders
            if let reminders = plantDTO.reminders {
                for r in reminders {
                    if let rem = makeReminder(from: r, notes: &result.notes) {
                        rem.plant = plant
                        plant.reminders.append(rem)
                        result.remindersCreated += 1
                    }
                }
            }

            // Care plan
            if let cp = plantDTO.carePlan {
                plant.carePlan = makeCarePlan(from: cp)
                plant.carePlan?.plant = plant
            }

            result.plantsCreated += 1
        }

        try context.save()
        return result
    }

    // MARK: - Builders

    private func makePlant(from dto: ImportPlantDTO, notes: inout [String]) -> Plant {
        let tempRange = TemperatureRange(min: max(0, dto.temperatureRange?.min ?? 65),
                                         max: max(dto.temperatureRange?.min ?? 65, dto.temperatureRange?.max ?? 80))

        let p = Plant(
            scientificName: (dto.scientificName?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap{ $0.isEmpty ? nil : $0 } ?? "Unknown",
            nickname: (dto.nickname?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap{ $0.isEmpty ? nil : $0 } ?? (dto.scientificName ?? "My Plant"),
            family: dto.family ?? "",
            commonNames: dto.commonNames ?? [],
            potSize: dto.potSize ?? 6,
            potHeight: dto.potHeight,
            potMaterial: mapPotMaterial(dto.potMaterial),
            growthHabit: mapGrowthHabit(dto.growthHabit),
            matureSize: dto.matureSize ?? "",
            lightLevel: mapLightLevel(dto.lightLevel),
            wateringFrequency: max(1, dto.wateringFrequency ?? 7),
            fertilizingFrequency: max(1, dto.fertilizingFrequency ?? 30),
            humidityPreference: min(max(dto.humidityPreference ?? 50, 0), 100),
            temperatureRange: tempRange,
            recommendedWaterAmount: dto.recommendedWaterAmount ?? 250,
            waterUnit: mapWaterUnit(dto.waterUnit),
            source: dto.source ?? "",
            location: dto.location ?? "",
            healthStatus: mapHealthStatus(dto.healthStatus),
            notes: dto.notes ?? "",
            lastWatered: dto.lastWatered,
            lastFertilized: dto.lastFertilized
        )

        // Metadata overrides if provided
        if let added = dto.dateAdded { p.dateAdded = added }
        p.dateAcquired = dto.dateAcquired

        return p
    }

    private func makePhoto(from dto: ImportPhotoDTO, notes: inout [String]) -> Photo? {
        var imageData: Data?
        if let b64 = dto.data, let d = Data(base64Encoded: b64) {
            imageData = d
        }
        // filename-based import not implemented yet
        if imageData == nil {
            notes.append("Skipped photo without decodable data")
            return nil
        }
        let photo = Photo(
            imageData: imageData!,
            timestamp: dto.timestamp ?? Date(),
            caption: dto.caption ?? "",
            category: mapPhotoCategory(dto.category),
            isPrimary: dto.isPrimary ?? false
        )
        return photo
    }

    private func makeCareEvent(from dto: ImportCareEventDTO, notes: inout [String]) -> CareEvent? {
        guard let type = mapCareType(dto.type) else {
            notes.append("Skipped care event with unknown type: \(dto.type ?? "<nil>")")
            return nil
        }
        let ce = CareEvent(
            type: type,
            date: dto.date ?? Date(),
            amount: dto.amount,
            unit: dto.unit ?? "",
            notes: dto.notes ?? "",
            weatherConditions: dto.weatherConditions ?? ""
        )
        return ce
    }

    private func makeReminder(from dto: ImportReminderDTO, notes: inout [String]) -> Reminder? {
        guard let task = mapCareType(dto.taskType) else {
            notes.append("Skipped reminder with unknown task type: \(dto.taskType ?? "<nil>")")
            return nil
        }
        let rec = mapRecurrence(dto.recurrence)
        let notifTime = dto.notificationTime ?? Date()
        let r = Reminder(
            taskType: task,
            recurrence: rec,
            notificationTime: notifTime,
            customMessage: dto.customMessage ?? "",
            isActive: dto.isActive ?? true
        )
        r.lastNotified = dto.lastNotified
        r.nextNotification = dto.nextNotification ?? rec.calculateNextDate(from: Date(), at: notifTime)
        r.snoozedUntil = dto.snoozedUntil
        return r
    }

    private func makeCarePlan(from dto: ImportCarePlanDTO) -> CarePlan {
        let cp = CarePlan(
            source: mapCarePlanSource(dto.source),
            wateringInterval: dto.wateringInterval ?? 7,
            fertilizingInterval: dto.fertilizingInterval ?? 30,
            lightRequirements: dto.lightRequirements ?? "",
            humidityRequirements: dto.humidityRequirements ?? "",
            temperatureRequirements: dto.temperatureRequirements ?? "",
            seasonalNotes: dto.seasonalNotes ?? "",
            aiExplanation: dto.aiExplanation ?? "",
            userApproved: dto.userApproved ?? false
        )
        if let created = dto.createdDate { cp.createdDate = created }
        if let updated = dto.lastUpdated { cp.lastUpdated = updated }
        return cp
    }

    // MARK: - Mappers

    private func mapGrowthHabit(_ value: String?) -> GrowthHabit {
        guard let v = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else { return .upright }
        switch v {
        case "upright": return .upright
        case "climbing", "climb", "vine": return .climbing
        case "trailing", "trail": return .trailing
        case "spreading", "spread": return .spreading
        case "rosette": return .rosette
        case "bushy": return .bushy
        default: return .upright
        }
    }

    private func mapLightLevel(_ value: String?) -> LightLevel {
        guard let v = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else { return .medium }
        switch v {
        case "low", "low light": return .low
        case "medium", "medium light": return .medium
        case "bright", "bright indirect", "indirect": return .bright
        case "direct", "direct sun", "full sun": return .direct
        default: return .medium
        }
    }

    private func mapHealthStatus(_ value: String?) -> HealthStatus {
        guard let v = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else { return .healthy }
        switch v {
        case "excellent": return .excellent
        case "healthy": return .healthy
        case "fair": return .fair
        case "poor": return .poor
        case "critical": return .critical
        default: return .healthy
        }
    }

    private func mapWaterUnit(_ value: String?) -> WaterUnit {
        guard let v = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else { return .milliliters }
        switch v {
        case "ml", "milliliter", "milliliters": return .milliliters
        case "fl oz", "floz", "oz", "ounce", "ounces": return .ounces
        case "cups", "cup": return .cups
        case "l", "liter", "liters": return .liters
        default: return .milliliters
        }
    }

    private func mapCareType(_ value: String?) -> CareType? {
        guard let v = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else { return nil }
        switch v {
        case "watering", "water", "watered": return .watering
        case "fertilizing", "fertiliser", "fertilize", "fertilized", "fertilise": return .fertilizing
        case "repotting", "repot", "repotted": return .repotting
        case "pruning", "prune", "trim", "trimming": return .pruning
        case "cleaning", "clean", "wipe", "wiped": return .cleaning
        case "rotating", "rotate", "rotated": return .rotating
        case "misting", "mist", "misted": return .misting
        case "inspection", "inspect", "inspected": return .inspection
        default: return nil
        }
    }

    private func mapRecurrence(_ value: String?) -> RecurrencePattern {
        guard let v = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else { return .custom }
        switch v {
        case "daily": return .daily
        case "weekly": return .weekly
        case "bi-weekly", "biweekly": return .biweekly
        case "monthly": return .monthly
        default: return .custom
        }
    }

    private func mapPhotoCategory(_ value: String?) -> PhotoCategory {
        guard let v = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else { return .general }
        switch v {
        case "general": return .general
        case "new growth", "growth": return .newGrowth
        case "flowers", "flower": return .flowers
        case "issue/problem", "issue", "problem": return .issue
        case "before/after", "before-after", "beforeafter": return .beforeAfter
        case "repotting", "repot": return .repotting
        default: return .general
        }
    }

    private func mapCarePlanSource(_ value: String?) -> CarePlanSource {
        guard let v = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else { return .user }
        switch v {
        case "user", "user created", "manual": return .user
        case "ai", "ai generated", "assistant": return .ai
        case "expert", "expert recommendation", "pro": return .expert
        default: return .user
        }
    }

    private func mapPotMaterial(_ value: String?) -> PotMaterial {
        guard let v = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else { return .unknown }
        switch v {
        case "plastic": return .plastic
        case "terracota", "terracotta", "clay": return .terracotta
        case "glazed_ceramics", "glazed ceramics", "ceramics": return .glazedCeramics
        case "ceramic": return .ceramic
        case "fabric": return .fabric
        case "metal": return .metal
        case "wood": return .wood
        case "concrete": return .concrete
        default: return .other
        }
    }
}

// MARK: - Blossom Import Support

private struct BlossomPlantSummary: Decodable {
    let plant_internal_id: String?
    let plantId_numeric: Int?
    let name: String?
    let room: String?
    let kindOfLight: String?
    let sideLocation: String?
    let pot_material: String?
    let pot_height_cm: Double?
    let pot_diameter_cm: Double?

    var asImportPlantDTO: ImportPlantDTO {
        // Convert cm to inches and round to nearest int
        let inches = (pot_diameter_cm ?? 0) / 2.54
        let rounded = Int((inches).rounded())
        let heightInches = Int(((pot_height_cm ?? 0) / 2.54).rounded())

        // Map Blossom light to internal light string
        let light: String? = {
            switch kindOfLight?.uppercased() {
            case "LOW": return "low"
            case "MEDIUM": return "medium"
            case "BRIGHT_INDIRECT": return "bright"
            case "BRIGHT_DIRECT": return "direct"
            default: return nil
            }
        }()

        // Build a note with original metadata
        var noteParts: [String] = []
        if let pid = plant_internal_id { noteParts.append("Blossom ID: \(pid)") }
        if let pn = plantId_numeric { noteParts.append("PlantId: \(pn)") }
        if let mat = pot_material { noteParts.append("Pot material: \(mat)") }
        if let h = pot_height_cm { noteParts.append(String(format: "Pot height: %.1f cm", h)) }
        if let d = pot_diameter_cm { noteParts.append(String(format: "Pot diameter: %.1f cm", d)) }
        if let side = sideLocation { noteParts.append("Side: \(side)") }

        return ImportPlantDTO(
            scientificName: name, // treat as common/scientific placeholder
            nickname: name,
            family: nil,
            commonNames: nil,
            potSize: rounded > 0 ? rounded : nil,
            potHeight: heightInches > 0 ? heightInches : nil,
            growthHabit: nil,
            matureSize: nil,
            lightLevel: light,
            wateringFrequency: nil,
            fertilizingFrequency: nil,
            humidityPreference: nil,
            temperatureRange: TemperatureRangeDTO(min: nil, max: nil),
            recommendedWaterAmount: nil,
            waterUnit: nil,
            potMaterial: pot_material,
            dateAdded: nil,
            dateAcquired: nil,
            source: "Imported from Blossom",
            location: room,
            healthStatus: nil,
            notes: noteParts.isEmpty ? nil : noteParts.joined(separator: " | "),
            lastWatered: nil,
            lastFertilized: nil,
            photos: nil,
            careEvents: nil,
            reminders: nil,
            carePlan: nil
        )
    }
}
