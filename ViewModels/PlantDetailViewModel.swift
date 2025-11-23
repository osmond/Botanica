import Foundation
import SwiftData
import SwiftUI

/// Handles quick actions and error state for PlantDetailView.
@MainActor
final class PlantDetailViewModel: ObservableObject {
    @Published var isPerformingAction = false
    @Published var actionError: String?
    
    func quickWaterPlant(_ plant: Plant, context: ModelContext) {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        let wateringEvent = CareEvent(
            type: .watering,
            date: Date(),
            amount: Double(plant.recommendedWateringAmount.amount),
            notes: "Quick watering - \(plant.recommendedWateringAmount.amount)\(plant.recommendedWateringAmount.unit)"
        )
        wateringEvent.plant = plant
        context.insert(wateringEvent)
        do {
            try context.save()
            HapticManager.shared.success()
            actionError = nil
        } catch {
            actionError = error.localizedDescription
            HapticManager.shared.error()
        }
        isPerformingAction = false
    }
    
    func quickFertilizePlant(_ plant: Plant, context: ModelContext) {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        let fertilizingEvent = CareEvent(
            type: .fertilizing,
            date: Date(),
            notes: "Quick fertilizing"
        )
        fertilizingEvent.plant = plant
        context.insert(fertilizingEvent)
        do {
            try context.save()
            HapticManager.shared.success()
            actionError = nil
        } catch {
            actionError = error.localizedDescription
            HapticManager.shared.error()
        }
        isPerformingAction = false
    }
}
