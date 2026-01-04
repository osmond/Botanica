import Foundation
import SwiftData

enum DataExportFormat: String, CaseIterable {
    case json = "JSON"
    case csv = "CSV"
    
    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        }
    }
}

struct DataExportOptions {
    let includePhotos: Bool
    let includeCareHistory: Bool
    let includeReminders: Bool
}

struct DataExportSummary {
    let plants: Int
    let careEvents: Int
    let reminders: Int
    let photos: Int
}

struct DataExportResult {
    let fileURL: URL
    let format: DataExportFormat
    let byteCount: Int
    let summary: DataExportSummary
}

enum DataExportError: LocalizedError {
    case noPlants
    case unsupportedFormat
    case writeFailed
    
    var errorDescription: String? {
        switch self {
        case .noPlants:
            return "No plants available to export."
        case .unsupportedFormat:
            return "That export format is not supported yet."
        case .writeFailed:
            return "Unable to write the export file."
        }
    }
}

// MARK: - Service

@MainActor
final class DataExportService {
    static let shared = DataExportService()
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    private let csvDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    func exportData(
        context: ModelContext,
        format: DataExportFormat,
        options: DataExportOptions,
        filePrefix: String,
        destinationDirectory: URL? = nil
    ) throws -> DataExportResult {
        let descriptor = FetchDescriptor<Plant>()
        let plants = try context.fetch(descriptor)
        
        guard !plants.isEmpty else { throw DataExportError.noPlants }
        
        let data: Data
        let summary: DataExportSummary
        switch format {
        case .json:
            let bundle = buildExportBundle(plants: plants, options: options)
            summary = bundle.summary
            data = try encoder.encode(bundle.payload)
        case .csv:
            let result = try buildCSV(plants: plants)
            summary = result.summary
            data = result.data
        }
        
        let directory = destinationDirectory ?? FileManager.default.temporaryDirectory
        let filename = exportFilename(prefix: filePrefix, format: format)
        let fileURL = directory.appendingPathComponent(filename)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            throw DataExportError.writeFailed
        }
        
        return DataExportResult(
            fileURL: fileURL,
            format: format,
            byteCount: data.count,
            summary: summary
        )
    }
    
    // MARK: - Export JSON
    
    private func buildExportBundle(
        plants: [Plant],
        options: DataExportOptions
    ) -> (payload: ExportBundleDTO, summary: DataExportSummary) {
        var careEvents = 0
        var reminders = 0
        var photos = 0
        
        let payloadPlants = plants.map { plant -> ExportPlantDTO in
            if options.includeCareHistory {
                careEvents += plant.careEvents.count
            }
            if options.includeReminders {
                reminders += plant.reminders.count
            }
            if options.includePhotos {
                photos += plant.photos.count
            }
            
            return ExportPlantDTO(
                scientificName: plant.scientificName,
                nickname: plant.nickname,
                family: plant.family,
                commonNames: plant.commonNames,
                potSize: plant.potSize,
                potHeight: plant.potHeight,
                growthHabit: plant.growthHabit.rawValue,
                matureSize: plant.matureSize,
                lightLevel: plant.lightLevel.rawValue,
                wateringFrequency: plant.wateringFrequency,
                fertilizingFrequency: plant.fertilizingFrequency,
                humidityPreference: plant.humidityPreference,
                temperatureRange: TemperatureRangeDTO(
                    min: plant.temperatureRange.min,
                    max: plant.temperatureRange.max
                ),
                recommendedWaterAmount: plant.recommendedWaterAmount,
                waterUnit: plant.waterUnit.rawValue,
                potMaterial: plant.potMaterial?.rawValue,
                dateAdded: plant.dateAdded,
                dateAcquired: plant.dateAcquired,
                source: plant.source,
                location: plant.location,
                healthStatus: plant.healthStatus.rawValue,
                notes: plant.notes,
                lastWatered: plant.lastWatered,
                lastFertilized: plant.lastFertilized,
                photos: options.includePhotos ? plant.photos.map { photo in
                    ExportPhotoDTO(
                        timestamp: photo.timestamp,
                        caption: photo.caption,
                        category: photo.category.rawValue,
                        isPrimary: photo.isPrimary,
                        data: photo.imageData.base64EncodedString(),
                        filename: nil
                    )
                } : nil,
                careEvents: options.includeCareHistory ? plant.careEvents.map { event in
                    ExportCareEventDTO(
                        type: event.type.rawValue,
                        date: event.date,
                        amount: event.amount,
                        unit: event.unit,
                        notes: event.notes,
                        weatherConditions: event.weatherConditions
                    )
                } : nil,
                reminders: options.includeReminders ? plant.reminders.map { reminder in
                    ExportReminderDTO(
                        taskType: reminder.taskType.rawValue,
                        recurrence: reminder.recurrence.rawValue,
                        notificationTime: reminder.notificationTime,
                        isActive: reminder.isActive,
                        customMessage: reminder.customMessage,
                        lastNotified: reminder.lastNotified,
                        nextNotification: reminder.nextNotification,
                        snoozedUntil: reminder.snoozedUntil
                    )
                } : nil,
                carePlan: plant.carePlan.map { plan in
                    ExportCarePlanDTO(
                        source: plan.source.rawValue,
                        wateringInterval: plan.wateringInterval,
                        fertilizingInterval: plan.fertilizingInterval,
                        lightRequirements: plan.lightRequirements,
                        humidityRequirements: plan.humidityRequirements,
                        temperatureRequirements: plan.temperatureRequirements,
                        seasonalNotes: plan.seasonalNotes,
                        aiExplanation: plan.aiExplanation,
                        createdDate: plan.createdDate,
                        lastUpdated: plan.lastUpdated,
                        userApproved: plan.userApproved
                    )
                }
            )
        }
        
        let payload = ExportBundleDTO(
            version: 1,
            exportedAt: Date(),
            plants: payloadPlants
        )
        
        let summary = DataExportSummary(
            plants: plants.count,
            careEvents: careEvents,
            reminders: reminders,
            photos: photos
        )
        
        return (payload: payload, summary: summary)
    }
    
    // MARK: - Export CSV
    
    private func buildCSV(plants: [Plant]) throws -> (data: Data, summary: DataExportSummary) {
        var rows: [String] = []
        rows.append([
            "Nickname",
            "Scientific Name",
            "Family",
            "Common Names",
            "Location",
            "Pot Size",
            "Light Level",
            "Watering Frequency (days)",
            "Fertilizing Frequency (days)",
            "Last Watered",
            "Last Fertilized",
            "Health Status"
        ].joined(separator: ","))
        
        for plant in plants {
            let row = [
                csvEscape(plant.nickname),
                csvEscape(plant.scientificName),
                csvEscape(plant.family),
                csvEscape(plant.commonNames.joined(separator: " | ")),
                csvEscape(plant.location),
                "\(plant.potSize)",
                csvEscape(plant.lightLevel.rawValue),
                "\(plant.wateringFrequency)",
                "\(plant.fertilizingFrequency)",
                csvEscape(formatDate(plant.lastWatered)),
                csvEscape(formatDate(plant.lastFertilized)),
                csvEscape(plant.healthStatus.rawValue)
            ].joined(separator: ",")
            rows.append(row)
        }
        
        guard let data = rows.joined(separator: "\n").data(using: .utf8) else {
            throw DataExportError.writeFailed
        }
        
        let summary = DataExportSummary(
            plants: plants.count,
            careEvents: 0,
            reminders: 0,
            photos: 0
        )
        
        return (data: data, summary: summary)
    }
    
    private func csvEscape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\"") {
            return "\"\(escaped)\""
        }
        return escaped
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "" }
        return csvDateFormatter.string(from: date)
    }
    
    private func exportFilename(prefix: String, format: DataExportFormat) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let stamp = formatter.string(from: Date())
        return "\(prefix)_\(stamp).\(format.fileExtension)"
    }
}

// MARK: - Export DTOs

private struct ExportBundleDTO: Encodable {
    let version: Int
    let exportedAt: Date
    let plants: [ExportPlantDTO]
}

private struct ExportPlantDTO: Encodable {
    // Core
    let scientificName: String
    let nickname: String
    let family: String
    let commonNames: [String]
    
    // Physical
    let potSize: Int
    let potHeight: Int?
    let growthHabit: String
    let matureSize: String
    
    // Care reqs
    let lightLevel: String
    let wateringFrequency: Int
    let fertilizingFrequency: Int
    let humidityPreference: Int
    let temperatureRange: TemperatureRangeDTO
    let recommendedWaterAmount: Double
    let waterUnit: String
    let potMaterial: String?
    
    // Metadata
    let dateAdded: Date
    let dateAcquired: Date?
    let source: String
    let location: String
    let healthStatus: String
    let notes: String
    
    // Care state
    let lastWatered: Date?
    let lastFertilized: Date?
    
    // Relationships
    let photos: [ExportPhotoDTO]?
    let careEvents: [ExportCareEventDTO]?
    let reminders: [ExportReminderDTO]?
    let carePlan: ExportCarePlanDTO?
}

private struct TemperatureRangeDTO: Encodable { let min: Int; let max: Int }

private struct ExportPhotoDTO: Encodable {
    let timestamp: Date?
    let caption: String?
    let category: String?
    let isPrimary: Bool?
    let data: String?
    let filename: String?
}

private struct ExportCareEventDTO: Encodable {
    let type: String?
    let date: Date?
    let amount: Double?
    let unit: String?
    let notes: String?
    let weatherConditions: String?
}

private struct ExportReminderDTO: Encodable {
    let taskType: String?
    let recurrence: String?
    let notificationTime: Date?
    let isActive: Bool?
    let customMessage: String?
    let lastNotified: Date?
    let nextNotification: Date?
    let snoozedUntil: Date?
}

private struct ExportCarePlanDTO: Encodable {
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
