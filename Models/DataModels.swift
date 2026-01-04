import SwiftData
import Foundation

// MARK: - Plant Model

/// Comprehensive plant model with botanically accurate fields
/// Represents a user's plant with all necessary care and identification information
@Model
final class Plant {
    /// Unique identifier
    var id: UUID
    
    // MARK: Botanical Information
    /// Scientific name (e.g., "Monstera deliciosa")
    var scientificName: String
    /// Common nickname given by user (e.g., "My Monstera")
    var nickname: String
    /// Plant family (e.g., "Araceae")
    var family: String
    /// Common names (e.g., "Swiss Cheese Plant, Split-leaf Philodendron")
    @Attribute(.transformable(by: ModelTransformers.stringArrayName.rawValue))
    var commonNames: [String]
    
    // MARK: Physical Characteristics
    /// Pot size in inches (e.g., 6, 8, 10)
    var potSize: Int
    /// Pot height in inches (optional)
    var potHeight: Int?
    /// Pot material (optional)
    var potMaterial: PotMaterial?
    /// Growth habit (e.g., climbing, trailing, upright)
    var growthHabit: GrowthHabit
    /// Mature size description
    var matureSize: String
    
    // MARK: Care Requirements
    /// Light level requirement
    var lightLevel: LightLevel
    /// Watering frequency in days
    var wateringFrequency: Int
    /// Fertilizing frequency in days  
    var fertilizingFrequency: Int
    /// Humidity preference (0-100%)
    var humidityPreference: Int
    /// Temperature range (min-max in Fahrenheit)
    var temperatureRange: TemperatureRange
    /// Recommended water amount per watering session
    var recommendedWaterAmount: Double
    /// Unit of measurement for water amount
    var waterUnit: WaterUnit
    /// Repotting frequency in months (e.g., 12). Optional to keep older stores compatible.
    var repotFrequencyMonths: Int?
    /// Date when the plant was last repotted
    var lastRepotted: Date?
    
    // MARK: Metadata
    /// Date when plant was added to collection
    var dateAdded: Date
    /// Date when plant was acquired
    var dateAcquired: Date?
    /// Purchase location or source
    var source: String
    /// Physical location of the plant (e.g., "Living Room", "Kitchen", "Bedroom Window")
    var location: String
    /// Current health status
    var healthStatus: HealthStatus
    /// User notes
    var notes: String
    
    // MARK: Care History
    /// Date when the plant was last watered
    var lastWatered: Date?
    /// Date when the plant was last fertilized
    var lastFertilized: Date?
    
    // MARK: Relationships
    /// Photos of this plant
    @Relationship(deleteRule: .cascade, inverse: \Photo.plant)
    var photos: [Photo] = []
    
    /// Care events for this plant
    @Relationship(deleteRule: .cascade, inverse: \CareEvent.plant)
    var careEvents: [CareEvent] = []
    
    /// Reminders for this plant
    @Relationship(deleteRule: .cascade, inverse: \Reminder.plant)
    var reminders: [Reminder] = []
    
    /// AI-generated care plan (optional)
    @Relationship(deleteRule: .cascade, inverse: \CarePlan.plant)
    var carePlan: CarePlan?
    
    init(
        scientificName: String,
        nickname: String,
        family: String = "",
        commonNames: [String] = [],
        potSize: Int = 6,
        potHeight: Int? = nil,
        potMaterial: PotMaterial? = nil,
        growthHabit: GrowthHabit = .upright,
        matureSize: String = "",
        lightLevel: LightLevel = .medium,
        wateringFrequency: Int = 7,
        fertilizingFrequency: Int = 30,
        humidityPreference: Int = 50,
        temperatureRange: TemperatureRange = TemperatureRange(min: 65, max: 80),
        recommendedWaterAmount: Double = 250,
        waterUnit: WaterUnit = .milliliters,
        repotFrequencyMonths: Int = 12,
        lastRepotted: Date? = nil,
        source: String = "",
        location: String = "",
        healthStatus: HealthStatus = .healthy,
        notes: String = "",
        lastWatered: Date? = nil,
        lastFertilized: Date? = nil
    ) {
        self.id = UUID()
        self.scientificName = scientificName
        self.nickname = nickname
        self.family = family
        self.commonNames = commonNames
        self.potSize = potSize
        self.potHeight = potHeight
        self.potMaterial = potMaterial
        self.growthHabit = growthHabit
        self.matureSize = matureSize
        self.lightLevel = lightLevel
        self.wateringFrequency = wateringFrequency
        self.fertilizingFrequency = fertilizingFrequency
        self.humidityPreference = humidityPreference
        self.temperatureRange = temperatureRange
        self.recommendedWaterAmount = recommendedWaterAmount
        self.waterUnit = waterUnit
        self.repotFrequencyMonths = repotFrequencyMonths
        self.lastRepotted = lastRepotted
        self.dateAdded = Date()
        self.dateAcquired = nil
        self.source = source
        self.location = location
        self.healthStatus = healthStatus
        self.notes = notes
        self.lastWatered = lastWatered
        self.lastFertilized = lastFertilized
    }
}

// MARK: - Model Transformers

enum ModelTransformers {
    static let stringArrayName = NSValueTransformerName("StringArrayTransformer")
    private static let registerOnce: Void = {
        if ValueTransformer(forName: stringArrayName) == nil {
            ValueTransformer.setValueTransformer(StringArrayTransformer(), forName: stringArrayName)
        }
    }()
    
    static func register() {
        _ = registerOnce
    }
}

// Ensure transformers are registered before any SwiftData work.
private let _registerModelTransformers: Void = {
    ModelTransformers.register()
}()

final class StringArrayTransformer: ValueTransformer {
    override class func allowsReverseTransformation() -> Bool { true }
    
    override class func transformedValueClass() -> AnyClass { NSData.self }
    
    override func transformedValue(_ value: Any?) -> Any? {
        let strings: [String]
        if let value = value as? [String] {
            strings = value
        } else if let value = value as? String {
            strings = [value]
        } else if let value = value as? [Any] {
            strings = value.compactMap { $0 as? String }
        } else if let value = value as? NSArray {
            strings = value.compactMap { $0 as? String }
        } else {
            strings = []
        }
        return try? JSONEncoder().encode(strings)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        if let data = value as? Data {
            if let decoded = try? JSONDecoder().decode([String].self, from: data) {
                return decoded
            }
            if let string = String(data: data, encoding: .utf8) {
                let parts = string.split(separator: ",").map {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                }.filter { !$0.isEmpty }
                return parts
            }
            if let array = try? NSKeyedUnarchiver.unarchivedObject(
                ofClasses: [NSArray.self, NSString.self, NSData.self],
                from: data
            ) as? [String] {
                return array
            }
        }
        if let strings = value as? [String] {
            return strings
        }
        if let string = value as? String {
            let parts = string.split(separator: ",").map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }.filter { !$0.isEmpty }
            return parts
        }
        if let array = value as? [Any] {
            return array.compactMap { $0 as? String }
        }
        if let array = value as? NSArray {
            return array.compactMap { $0 as? String }
        }
        return []
    }
}

// MARK: - Plant Enums

enum GrowthHabit: String, CaseIterable, Codable {
    case upright = "Upright"
    case climbing = "Climbing"
    case trailing = "Trailing"
    case spreading = "Spreading"
    case rosette = "Rosette"
    case bushy = "Bushy"
    
    var description: String {
        return rawValue
    }
}

enum LightLevel: String, CaseIterable, Codable {
    case low = "Low Light"
    case medium = "Medium Light"
    case bright = "Bright Indirect"
    case direct = "Direct Sun"
    
    var description: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .low: return "sun.min"
        case .medium: return "sun.dust"
        case .bright: return "sun.max"
        case .direct: return "sun.max.fill"
        }
    }
}

enum HealthStatus: String, CaseIterable, Codable {
    case excellent = "Excellent"
    case healthy = "Healthy"
    case fair = "Fair"
    case poor = "Poor"
    case critical = "Critical"
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .healthy: return "green"
        case .fair: return "yellow"
        case .poor: return "orange"
        case .critical: return "red"
        }
    }
}

struct TemperatureRange: Codable {
    let min: Int
    let max: Int
    
    var description: String {
        return "\(min)°F - \(max)°F"
    }
}

enum WaterUnit: String, CaseIterable, Codable {
    case milliliters = "ml"
    case ounces = "fl oz"
    case cups = "cups"
    case liters = "L"
    
    var description: String {
        return rawValue
    }
    
    var fullName: String {
        switch self {
        case .milliliters: return "Milliliters"
        case .ounces: return "Fluid Ounces"
        case .cups: return "Cups"
        case .liters: return "Liters"
        }
    }
}

// MARK: - Pot Material

enum PotMaterial: String, CaseIterable, Codable {
    case plastic = "Plastic"
    case terracotta = "Terracotta"
    case glazedCeramics = "Glazed Ceramics"
    case ceramic = "Ceramic"
    case clay = "Clay"
    case fabric = "Fabric"
    case metal = "Metal"
    case wood = "Wood"
    case concrete = "Concrete"
    case other = "Other"
    case unknown = "Unknown"
}

// MARK: - CareEvent Model

/// Represents a care action performed on a plant
@Model
final class CareEvent {
    /// Unique identifier
    var id: UUID
    
    /// Type of care performed
    var type: CareType
    /// Date and time when care was performed
    var date: Date
    /// Amount given (for water/fertilizer)
    var amount: Double?
    /// Unit of measurement (ml, oz, etc.)
    var unit: String
    /// User notes about the care event
    var notes: String
    /// Weather conditions (for outdoor plants)
    var weatherConditions: String
    
    // MARK: Relationships
    /// The plant this care event belongs to
    var plant: Plant?
    
    init(
        type: CareType,
        date: Date = Date(),
        amount: Double? = nil,
        unit: String = "",
        notes: String = "",
        weatherConditions: String = ""
    ) {
        self.id = UUID()
        self.type = type
        self.date = date
        self.amount = amount
        self.unit = unit
        self.notes = notes
        self.weatherConditions = weatherConditions
    }
}

enum CareType: String, CaseIterable, Codable {
    case watering = "Watering"
    case fertilizing = "Fertilizing"
    case repotting = "Repotting"
    case pruning = "Pruning"
    case cleaning = "Cleaning"
    case rotating = "Rotating"
    case misting = "Misting"
    case inspection = "Inspection"
    
    var icon: String {
        switch self {
        case .watering: return "drop.fill"
        case .fertilizing: return "leaf.arrow.circlepath"
        case .repotting: return "flowerpot.fill"
        case .pruning: return "scissors"
        case .cleaning: return "paintbrush.fill"
        case .rotating: return "arrow.clockwise"
        case .misting: return "cloud.rain.fill"
        case .inspection: return "magnifyingglass"
        }
    }
    
    var color: String {
        switch self {
        case .watering: return "blue"
        case .fertilizing: return "green"
        case .repotting: return "brown"
        case .pruning: return "orange"
        case .cleaning: return "purple"
        case .rotating: return "gray"
        case .misting: return "cyan"
        case .inspection: return "yellow"
        }
    }
}

// MARK: - Reminder Model

/// Represents a scheduled reminder for plant care
@Model
final class Reminder {
    /// Unique identifier
    var id: UUID
    
    /// Type of care to remind about
    var taskType: CareType
    /// Recurrence pattern
    var recurrence: RecurrencePattern
    /// Time of day for notification
    var notificationTime: Date
    /// Whether reminder is active
    var isActive: Bool
    /// Custom message for the reminder
    var customMessage: String
    /// Last notification date
    var lastNotified: Date?
    /// Next scheduled notification
    var nextNotification: Date
    /// If set, hide tasks of this type until this date
    var snoozedUntil: Date?
    
    // MARK: Relationships
    /// The plant this reminder belongs to
    var plant: Plant?
    
    init(
        taskType: CareType,
        recurrence: RecurrencePattern,
        notificationTime: Date,
        customMessage: String = "",
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.taskType = taskType
        self.recurrence = recurrence
        self.notificationTime = notificationTime
        self.customMessage = customMessage
        self.isActive = isActive
        self.lastNotified = nil
        self.nextNotification = recurrence.calculateNextDate(from: Date(), at: notificationTime)
        self.snoozedUntil = nil
    }
}

enum RecurrencePattern: String, CaseIterable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"  
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case custom = "Custom"
    
    func calculateNextDate(from date: Date, at time: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: time)
        
        switch self {
        case .daily:
            return calendar.nextDate(after: date, matching: components, matchingPolicy: .nextTime) ?? date
        case .weekly:
            components.weekday = calendar.component(.weekday, from: date)
            return calendar.nextDate(after: date, matching: components, matchingPolicy: .nextTime) ?? date
        case .biweekly:
            return calendar.date(byAdding: .day, value: 14, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .custom:
            return date // Custom logic would be implemented based on user input
        }
    }
}

// MARK: - Photo Model

/// Represents a photo of a plant
@Model
final class Photo {
    /// Unique identifier
    var id: UUID
    
    /// Image data
    @Attribute(.externalStorage) 
    var imageData: Data
    /// When photo was taken
    var timestamp: Date
    /// Optional caption
    var caption: String
    /// Photo category
    var category: PhotoCategory
    /// Whether this is the primary photo for the plant
    var isPrimary: Bool
    
    // MARK: Relationships
    /// The plant this photo belongs to
    var plant: Plant?
    
    init(
        imageData: Data,
        timestamp: Date = Date(),
        caption: String = "",
        category: PhotoCategory = .general,
        isPrimary: Bool = false
    ) {
        self.id = UUID()
        self.imageData = imageData
        self.timestamp = timestamp  
        self.caption = caption
        self.category = category
        self.isPrimary = isPrimary
    }
}

enum PhotoCategory: String, CaseIterable, Codable {
    case general = "General"
    case newGrowth = "New Growth"
    case flowers = "Flowers"
    case issue = "Issue/Problem"
    case beforeAfter = "Before/After"
    case repotting = "Repotting"
    
    var icon: String {
        switch self {
        case .general: return "camera"
        case .newGrowth: return "leaf"
        case .flowers: return "camera.macro"
        case .issue: return "exclamationmark.triangle"
        case .beforeAfter: return "slider.horizontal.2.rectangle.and.arrow.triangle.2.circlepath"
        case .repotting: return "flowerpot"
        }
    }
}

// MARK: - CarePlan Model

/// AI-generated or user-defined care plan for a plant
@Model
final class CarePlan {
    /// Unique identifier
    var id: UUID
    
    /// Source of the care plan (AI or user)
    var source: CarePlanSource
    /// Recommended watering interval in days
    var wateringInterval: Int
    /// Recommended fertilizing interval in days
    var fertilizingInterval: Int
    /// Light requirements description
    var lightRequirements: String
    /// Humidity recommendations
    var humidityRequirements: String
    /// Temperature recommendations  
    var temperatureRequirements: String
    /// Seasonal care notes
    var seasonalNotes: String
    /// AI explanation (if generated by AI)
    var aiExplanation: String
    /// When plan was created
    var createdDate: Date
    /// When plan was last updated
    var lastUpdated: Date
    /// Whether user has accepted AI recommendations
    var userApproved: Bool
    
    // MARK: Relationships
    /// The plant this care plan belongs to
    var plant: Plant?
    
    init(
        source: CarePlanSource,
        wateringInterval: Int = 7,
        fertilizingInterval: Int = 30,
        lightRequirements: String = "",
        humidityRequirements: String = "",
        temperatureRequirements: String = "",
        seasonalNotes: String = "",
        aiExplanation: String = "",
        userApproved: Bool = false
    ) {
        self.id = UUID()
        self.source = source
        self.wateringInterval = wateringInterval
        self.fertilizingInterval = fertilizingInterval
        self.lightRequirements = lightRequirements
        self.humidityRequirements = humidityRequirements
        self.temperatureRequirements = temperatureRequirements
        self.seasonalNotes = seasonalNotes
        self.aiExplanation = aiExplanation
        self.createdDate = Date()
        self.lastUpdated = Date()
        self.userApproved = userApproved
    }
}

enum CarePlanSource: String, CaseIterable, Codable {
    case user = "User Created"
    case ai = "AI Generated"
    case expert = "Expert Recommendation"
    
    var icon: String {
        switch self {
        case .user: return "person.fill"
        case .ai: return "brain.head.profile"
        case .expert: return "graduationcap.fill"
        }
    }
}
