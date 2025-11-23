import Foundation
import SwiftUI
import UIKit

@MainActor
final class MainTabCoordinator: ObservableObject {
    @Published var selectedTab: Tab = .plants
    @Published var showingPlantIdentification = false
    @Published var showingAddPlant = false
    @Published var showingManualAdd = false
    @Published var showingAddPlantWithAI = false
    @Published var aiIdentificationResult: PlantIdentificationResult?
    @Published var aiCapturedImage: UIImage?
    
    private let notificationService: NotificationService
    private var hasScheduledNotifications = false
    
    init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }
    
    func handleAddButtonTap() {
        showingAddPlant = true
    }
    
    func handleManualAddSelection() {
        showingAddPlant = false
        showingManualAdd = true
    }
    
    func handleAIAddSelection() {
        showingAddPlant = false
        showingPlantIdentification = true
    }
    
    func handleIdentificationCompletion(result: PlantIdentificationResult, image: UIImage?) {
        aiIdentificationResult = result
        aiCapturedImage = image
        showingPlantIdentification = false
        
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            await MainActor.run {
                showingAddPlantWithAI = true
            }
        }
    }
    
    func clearAIState() {
        aiIdentificationResult = nil
        aiCapturedImage = nil
    }
    
    func scheduleNotificationsIfNeeded(plants: [Plant]) {
        guard !hasScheduledNotifications else { return }
        hasScheduledNotifications = true
        Task {
            _ = await notificationService.requestPermissionsIfNeeded()
            await notificationService.scheduleAll(plants: plants)
        }
    }
    
    func refreshNotifications(plants: [Plant]) {
        Task {
            await notificationService.scheduleAll(plants: plants)
        }
    }
}
