import Foundation
import SwiftUI

// MARK: - Plant Extensions

extension Plant {
    /// Example plant for SwiftUI previews
    static var example: Plant {
        Plant(scientificName: "Monstera deliciosa", nickname: "Monstera")
    }
    /// Returns the primary photo for this plant
    var primaryPhoto: Photo? {
        return photos.first(where: { $0.isPrimary }) ?? photos.first
    }
    
    /// Adds a photo to this plant, enforcing primary-photo invariants.
    /// - Parameters:
    ///   - imageData: JPEG data to store.
    ///   - caption: Optional caption text.
    ///   - category: Photo category.
    ///   - isPrimary: If `true`, this becomes the primary photo. If `nil`,
    ///     the first photo for the plant is treated as primary.
    /// - Returns: The newly created `Photo` model.
    @discardableResult
    func addPhoto(
        from imageData: Data,
        caption: String = "",
        category: PhotoCategory = .general,
        isPrimary: Bool? = nil
    ) -> Photo {
        let shouldBePrimary: Bool
        if let isPrimary {
            shouldBePrimary = isPrimary
        } else {
            shouldBePrimary = photos.isEmpty
        }
        
        if shouldBePrimary {
            for existing in photos {
                existing.isPrimary = false
            }
        }
        
        let photo = Photo(
            imageData: imageData,
            caption: caption,
            category: category,
            isPrimary: shouldBePrimary
        )
        photos.append(photo)
        return photo
    }
    
    /// Returns the most recent care event of a specific type
    func lastCareEvent(of type: CareType) -> CareEvent? {
        return careEvents
            .filter { $0.type == type }
            .sorted { $0.date > $1.date }
            .first
    }
    
    /// Returns days since last watering
    var daysSinceLastWatering: Int {
        // Check care events first, then fall back to lastWatered date
        if let lastWatering = lastCareEvent(of: .watering) {
            return Calendar.current.dateComponents([.day], from: lastWatering.date, to: Date()).day ?? -1
        } else if let lastWatered = lastWatered {
            return Calendar.current.dateComponents([.day], from: lastWatered, to: Date()).day ?? -1
        }
        return -1
    }
    
    /// Returns days since last fertilizing
    var daysSinceLastFertilizing: Int {
        // Check care events first, then fall back to lastFertilized date
        if let lastFertilizing = lastCareEvent(of: .fertilizing) {
            return Calendar.current.dateComponents([.day], from: lastFertilizing.date, to: Date()).day ?? -1
        } else if let lastFertilized = lastFertilized {
            return Calendar.current.dateComponents([.day], from: lastFertilized, to: Date()).day ?? -1
        }
        return -1
    }
    
    /// Determines if watering is overdue
    var isWateringOverdue: Bool {
        let daysSince = daysSinceLastWatering
        return daysSince >= 0 && daysSince > wateringFrequency
    }
    
    /// Determines if fertilizing is overdue
    var isFertilizingOverdue: Bool {
        let daysSince = daysSinceLastFertilizing
        return daysSince >= 0 && daysSince > fertilizingFrequency
    }
    
    /// Returns next watering date based on frequency
    var nextWateringDate: Date? {
        // Check care events first, then fall back to lastWatered date
        if let lastWatering = lastCareEvent(of: .watering) {
            return Calendar.current.date(byAdding: .day, value: wateringFrequency, to: lastWatering.date)
        } else if let lastWatered = lastWatered {
            return Calendar.current.date(byAdding: .day, value: wateringFrequency, to: lastWatered)
        }
        return nil
    }
    
    /// Returns next fertilizing date based on frequency
    var nextFertilizingDate: Date? {
        // Check care events first, then fall back to lastFertilized date
        if let lastFertilizing = lastCareEvent(of: .fertilizing) {
            return Calendar.current.date(byAdding: .day, value: fertilizingFrequency, to: lastFertilizing.date)
        } else if let lastFertilized = lastFertilized {
            return Calendar.current.date(byAdding: .day, value: fertilizingFrequency, to: lastFertilized)
        }
        return nil
    }
    
    /// Returns care completion percentage for the last 30 days
    var careCompletionRate: Double {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentEvents = careEvents.filter { $0.date >= thirtyDaysAgo }
        
        // Calculate expected events (simplified calculation)
        let expectedWaterings = 30 / wateringFrequency
        let expectedFertilizings = max(1, 30 / fertilizingFrequency)
        let totalExpected = expectedWaterings + expectedFertilizings
        
        guard totalExpected > 0 else { return 0.0 }
        
        let actualEvents = recentEvents.count
        return min(1.0, Double(actualEvents) / Double(totalExpected))
    }
    
    /// Returns health status color
    var healthStatusColor: Color {
        switch healthStatus {
        case .excellent, .healthy:
            return BotanicaTheme.Colors.success
        case .fair:
            return BotanicaTheme.Colors.warning
        case .poor:
            return BotanicaTheme.Colors.nutrientOrange
        case .critical:
            return BotanicaTheme.Colors.error
        }
    }
    
    /// Returns display name (nickname or scientific name)
    var displayName: String {
        return nickname.isEmpty ? scientificName : nickname
    }
    
    /// Determines if plant needs attention based on health and care history
    var needsAttention: Bool {
        return healthStatus == .poor || healthStatus == .critical ||
               (careCompletionRate < 0.5 && !careEvents.isEmpty)
    }
    
    /// Returns days until next watering is due (negative if overdue)
    var wateringDueInDays: Int {
        guard lastCareEvent(of: .watering) != nil else { return 0 }
        let daysSince = daysSinceLastWatering
        return wateringFrequency - daysSince
    }
    
    /// Returns days until next fertilizing is due (negative if overdue)
    var fertilizingDueInDays: Int {
        guard lastCareEvent(of: .fertilizing) != nil else { return 0 }
        let daysSince = daysSinceLastFertilizing
        return fertilizingFrequency - daysSince
    }
    
    /// Returns the next urgent task description
    var nextUrgentTask: String? {
        if isWateringOverdue {
            let daysOverdue = daysSinceLastWatering - wateringFrequency
            return "Watering overdue by \(daysOverdue) day\(daysOverdue == 1 ? "" : "s")"
        } else if isFertilizingOverdue {
            return "Fertilizing is overdue"
        } else if needsAttention {
            return "Plant health needs attention"
        } else if wateringDueInDays <= 1 {
            return "Watering due \(wateringDueInDays == 0 ? "today" : "tomorrow")"
        }
        return nil
    }
    
    /// Get recommended watering amount based on plant characteristics
    var recommendedWateringAmount: WateringRecommendation {
        let plantType = PlantWateringType.from(
            commonNames: commonNames,
            family: family,
            scientificName: scientificName
        )
        
        return CareCalculator.recommendedWateringAmount(
            potSize: potSize,
            plantType: plantType,
            season: Season.current,
            environment: CareEnvironment.indoor,
            potMaterial: potMaterial ?? .unknown,
            lightLevel: lightLevel,
            potHeight: potHeight
        )
    }
    
    /// Get recommended fertilizer amount
    var recommendedFertilizerAmount: FertilizerRecommendation {
        let plantType = PlantWateringType.from(
            commonNames: commonNames,
            family: family,
            scientificName: scientificName
        )
        
        return CareCalculator.recommendedFertilizerAmount(
            potSize: potSize,
            plantType: plantType
        )
    }
    
    /// Calculates overall health score based on multiple factors (0-10 scale)
    var healthScore: Double {
        var score: Double = 5.0 // Base score
        
        // Health status factor (most important)
        switch healthStatus {
        case .excellent: score += 3.0
        case .healthy: score += 1.5
        case .fair: score += 0.0
        case .poor: score -= 1.5
        case .critical: score -= 3.0
        }
        
        // Care consistency factor
        let completionRate = careCompletionRate
        if completionRate >= 0.8 {
            score += 1.5
        } else if completionRate >= 0.6 {
            score += 0.5
        } else if completionRate < 0.3 {
            score -= 1.0
        }
        
        // Overdue care penalty
        if isWateringOverdue {
            let daysOverdue = daysSinceLastWatering - wateringFrequency
            score -= min(2.0, Double(daysOverdue) * 0.3)
        }
        
        if isFertilizingOverdue {
            score -= 0.5
        }
        
        // Age bonus (plants that have been cared for longer get slight bonus)
        let daysInCollection = Calendar.current.dateComponents([.day], from: dateAdded, to: Date()).day ?? 0
        if daysInCollection > 90 {
            score += 0.5
        }
        
        // Care event variety bonus
        let uniqueCareTypes = Set(careEvents.map { $0.type }).count
        if uniqueCareTypes >= 3 {
            score += 0.5
        }
        
        return max(0.0, min(10.0, score))
    }
}

// MARK: - CareEvent Extensions

extension CareEvent {
    /// Returns formatted amount with unit
    var formattedAmount: String {
        guard let amount = amount, !unit.isEmpty else { return "" }
        return "\(Int(amount)) \(unit)"
    }
    
    /// Returns time since this care event
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Returns care type color
    var typeColor: Color {
        switch type {
        case .watering:
            return BotanicaTheme.Colors.waterBlue
        case .fertilizing:
            return BotanicaTheme.Colors.leafGreen
        case .repotting:
            return BotanicaTheme.Colors.soilBrown
        case .pruning:
            return BotanicaTheme.Colors.nutrientOrange
        case .cleaning:
            return Color.purple
        case .rotating:
            return Color.gray
        case .misting:
            return Color.cyan
        case .inspection:
            return BotanicaTheme.Colors.sunYellow
        }
    }
}

// MARK: - Reminder Extensions

extension Reminder {
    /// Returns formatted next notification time
    var formattedNextNotification: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: nextNotification)
    }
    
    /// Updates next notification date based on recurrence
    func updateNextNotification() {
        self.lastNotified = Date()
        self.nextNotification = recurrence.calculateNextDate(from: Date(), at: notificationTime)
    }
    
    /// Returns whether this reminder is due soon (within 24 hours)
    var isDueSoon: Bool {
        let twentyFourHoursFromNow = Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date()
        return nextNotification <= twentyFourHoursFromNow
    }
}

// MARK: - Photo Extensions

extension Photo {
    /// Returns formatted timestamp
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    /// Returns relative timestamp
    var relativeTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - CarePlan Extensions

extension CarePlan {
    /// Returns whether the care plan needs user approval
    var needsApproval: Bool {
        return source == .ai && !userApproved
    }
    
    /// Returns formatted creation date
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdDate)
    }
    
    /// Returns whether the care plan is recent (created within 7 days)
    var isRecent: Bool {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return createdDate >= sevenDaysAgo
    }
}

// MARK: - Collection Extensions

extension Array where Element == CareEvent {
    /// Groups care events by date
    func groupedByDate() -> [Date: [CareEvent]] {
        let calendar = Calendar.current
        return Dictionary(grouping: self) { event in
            calendar.startOfDay(for: event.date)
        }
    }
    
    /// Returns events from the last N days
    func fromLastDays(_ days: Int) -> [CareEvent] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return self.filter { $0.date >= cutoffDate }
    }
}

extension Array where Element == Plant {
    /// Returns plants that need care today
    var needingCare: [Plant] {
        return self.filter { $0.isWateringOverdue || $0.isFertilizingOverdue }
    }
    
    /// Returns plants by health status
    func byHealthStatus(_ status: HealthStatus) -> [Plant] {
        return self.filter { $0.healthStatus == status }
    }
    
    /// Returns plants sorted by care urgency
    var sortedByCareUrgency: [Plant] {
        return self.sorted { plant1, plant2 in
            let plant1Score = (plant1.isWateringOverdue ? 10 : 0) + (plant1.isFertilizingOverdue ? 5 : 0)
            let plant2Score = (plant2.isWateringOverdue ? 10 : 0) + (plant2.isFertilizingOverdue ? 5 : 0)
            return plant1Score > plant2Score
        }
    }
}

// MARK: - HealthStatus Extensions

extension HealthStatus {
    var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .poor: return 1
        case .fair: return 2
        case .healthy: return 3
        case .excellent: return 4
        }
    }
}

// MARK: - LightLevel Extensions

extension LightLevel {
    var displayName: String {
        switch self {
        case .low: return "Low Light"
        case .medium: return "Medium Light"
        case .bright: return "Bright Light"
        case .direct: return "Direct Sun"
        }
    }
}
