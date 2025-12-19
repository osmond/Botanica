import UserNotifications
import SwiftData
import Foundation

/// Manages local notifications for plant care reminders
/// Handles scheduling, permissions, and notification content generation
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isEnabled = true
    
    private init() {
        Task { await updateAuthorizationStatus() }
    }
    
    // MARK: - Permission Management
    
    /// Request notification permissions from the user
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            await updateAuthorizationStatus()
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    /// Update the current authorization status
    func updateAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            self.authorizationStatus = settings.authorizationStatus
        }
    }
    
    // MARK: - Notification Scheduling
    
    /// Schedule notifications for a specific plant based on its care requirements
    func scheduleNotificationsForPlant(_ plant: Plant) async {
        guard isEnabled && authorizationStatus == .authorized else { return }
        
        // Remove existing notifications for this plant
        await removeNotificationsForPlant(plant)
        
        // Schedule watering notifications
        if plant.wateringFrequency > 0 {
            await scheduleWateringNotifications(for: plant)
        }
        
        // Schedule fertilizing notifications
        if plant.fertilizingFrequency > 0 {
            await scheduleFertilizingNotifications(for: plant)
        }
        
        // Schedule health check notifications if plant needs attention
        if plant.needsAttention {
            await scheduleHealthCheckNotification(for: plant)
        }
    }
    
    /// Schedule notifications for all plants
    func scheduleNotificationsForAllPlants(_ plants: [Plant]) async {
        guard isEnabled && authorizationStatus == .authorized else { return }
        
        for plant in plants {
            await scheduleNotificationsForPlant(plant)
        }
    }
    
    /// Remove all notifications for a specific plant
    func removeNotificationsForPlant(_ plant: Plant) async {
        let identifiers = [
            "watering_\(plant.id.uuidString)",
            "watering_overdue_\(plant.id.uuidString)",
            "fertilizing_\(plant.id.uuidString)",
            "fertilizing_overdue_\(plant.id.uuidString)",
            "health_check_\(plant.id.uuidString)"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    /// Remove all plant care notifications
    func removeAllNotifications() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Private Scheduling Methods
    
    private func scheduleWateringNotifications(for plant: Plant) async {
        let lastWatering = plant.lastCareEvent(of: .watering)?.date ?? plant.dateAdded
        let nextWateringDate = Calendar.current.date(byAdding: .day, value: plant.wateringFrequency, to: lastWatering) ?? Date()
        let wateringRec = plant.recommendedWateringAmount
        
        // Schedule reminder notification (day before due)
        if let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: nextWateringDate),
           reminderDate > Date() {
            await scheduleNotification(
                identifier: "watering_\(plant.id.uuidString)",
                title: "💧 \(plant.displayName) needs water soon",
                body: "Your \(plant.displayName) will need watering tomorrow. Prepare \(wateringRec.amount)\(wateringRec.unit) of water.",
                date: reminderDate,
                plant: plant,
                careType: .watering
            )
        }
        
        // Schedule overdue notification
        if nextWateringDate > Date() {
            await scheduleNotification(
                identifier: "watering_overdue_\(plant.id.uuidString)",
                title: "🚨 \(plant.displayName) needs water now!",
                body: "Your \(plant.displayName) is overdue for watering. Give it \(wateringRec.amount)\(wateringRec.unit) now!",
                date: nextWateringDate,
                plant: plant,
                careType: .watering,
                isOverdue: true
            )
        }
    }
    
    private func scheduleFertilizingNotifications(for plant: Plant) async {
        let lastFertilizing = plant.lastCareEvent(of: .fertilizing)?.date ?? plant.dateAdded
        let nextFertilizingDate = Calendar.current.date(byAdding: .day, value: plant.fertilizingFrequency, to: lastFertilizing) ?? Date()
        let fertilizerRec = plant.recommendedFertilizerAmount
        
        // Schedule reminder notification (3 days before due)
        if let reminderDate = Calendar.current.date(byAdding: .day, value: -3, to: nextFertilizingDate),
           reminderDate > Date() {
            await scheduleNotification(
                identifier: "fertilizing_\(plant.id.uuidString)",
                title: "🌱 \(plant.displayName) needs fertilizer soon",
                body: "Your \(plant.displayName) will need fertilizing in 3 days. Prepare \(fertilizerRec.amount)\(fertilizerRec.unit) diluted fertilizer.",
                date: reminderDate,
                plant: plant,
                careType: .fertilizing
            )
        }
        
        // Schedule overdue notification
        if nextFertilizingDate > Date() {
            await scheduleNotification(
                identifier: "fertilizing_overdue_\(plant.id.uuidString)",
                title: "🍃 \(plant.displayName) needs fertilizer",
                body: "Your \(plant.displayName) is ready for its next feeding. Use \(fertilizerRec.amount)\(fertilizerRec.unit) diluted fertilizer.",
                date: nextFertilizingDate,
                plant: plant,
                careType: .fertilizing,
                isOverdue: true
            )
        }
    }
    
    private func scheduleHealthCheckNotification(for plant: Plant) async {
        // Schedule health check notification for tomorrow
        if let checkDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
            await scheduleNotification(
                identifier: "health_check_\(plant.id.uuidString)",
                title: "🏥 Check on \(plant.displayName)",
                body: "Your \(plant.displayName) may need special attention. Take a moment to assess its health.",
                date: checkDate,
                plant: plant,
                careType: nil
            )
        }
    }
    
    private func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        date: Date,
        plant: Plant,
        careType: CareType?,
        isOverdue: Bool = false
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = isOverdue ? UNNotificationSound.defaultCriticalSound(withAudioVolume: 1.0) : UNNotificationSound.default
        
        // Add plant information to userInfo for handling taps
        var userInfo: [String: Any] = [
            "plantId": plant.id.uuidString,
            "plantName": plant.displayName,
            "isOverdue": isOverdue
        ]
        
        if let careType = careType {
            userInfo["careType"] = careType.rawValue
        }
        
        content.userInfo = userInfo
        
        // Create trigger for specific date
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled notification: \(title) for \(date)")
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get all pending notifications for debugging
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
    
    /// Get notification settings
    func getNotificationSettings() async -> UNNotificationSettings {
        return await UNUserNotificationCenter.current().notificationSettings()
    }
    
    /// Check if notifications are enabled and authorized
    var canSendNotifications: Bool {
        return isEnabled && authorizationStatus == .authorized
    }
}

// MARK: - Notification Handling

extension NotificationManager {
    /// Handle notification tap - to be called from app delegate
    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let plantIdString = userInfo["plantId"] as? String,
              let plantId = UUID(uuidString: plantIdString) else {
            print("Invalid plant ID in notification")
            return
        }
        
        let plantName = userInfo["plantName"] as? String ?? "Plant"
        let isOverdue = userInfo["isOverdue"] as? Bool ?? false
        
        print("Notification tapped for plant: \(plantName), overdue: \(isOverdue)")
        
        // Post notification for app to handle navigation
        NotificationCenter.default.post(
            name: .plantCareNotificationTapped,
            object: nil,
            userInfo: [
                "plantId": plantId,
                "plantName": plantName,
                "isOverdue": isOverdue
            ]
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let plantCareNotificationTapped = Notification.Name("plantCareNotificationTapped")
}
