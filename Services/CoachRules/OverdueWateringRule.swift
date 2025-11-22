import Foundation

struct OverdueWateringRule: CoachRule {
    func evaluate(plants: [Plant], events: [CareEvent]) async -> [CoachSuggestion] {
        let overdue = plants.filter { $0.isWateringOverdue }
        var out: [CoachSuggestion] = []
        for plant in overdue.prefix(3) {
            let rec = await MainActor.run { CareCalculator.weatherAdjustedRecommendation(for: plant) }
            out.append(CoachSuggestion(
                id: UUID(),
                title: "Water soon: \(plant.displayName)",
                message: "~\(rec.amount)\(rec.unit). \(rec.soilCheck)",
                reason: "Last watering past \(plant.wateringFrequency)d",
                plantId: plant.id,
                surface: .today,
                expiresAt: Date().addingTimeInterval(60*60*6)
            ))
        }
        return out
    }
}

