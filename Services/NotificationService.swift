import Foundation
import SwiftData

/// Thin wrapper around NotificationManager to keep view code minimal.
final class NotificationService {
    private let manager: NotificationManager
    
    init(manager: NotificationManager) {
        self.manager = manager
    }
    
    func requestPermissionsIfNeeded() async -> Bool {
        if manager.authorizationStatus == .notDetermined {
            return await manager.requestNotificationPermission()
        }
        return manager.authorizationStatus == .authorized
    }
    
    func scheduleAll(plants: [Plant]) async {
        guard manager.isEnabled else { return }
        if manager.authorizationStatus == .notDetermined {
            _ = await manager.requestNotificationPermission()
        }
        await manager.scheduleNotificationsForAllPlants(plants)
    }
    
    func refresh(plant: Plant) async {
        guard manager.isEnabled else { return }
        await manager.scheduleNotificationsForPlant(plant)
    }
    
    func cancelAll() async {
        await manager.removeAllNotifications()
    }
}
