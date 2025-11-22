import Foundation

struct StreakNudgeRule: CoachRule {
    func evaluate(plants: [Plant], events: [CareEvent]) async -> [CoachSuggestion] {
        guard !plants.isEmpty else { return [] }
        let recent = events.filter { Calendar.current.isDateInToday($0.date) }
        if recent.isEmpty {
            return [CoachSuggestion(
                id: UUID(),
                title: "Quick win: log one care",
                message: "Keep your streak going with any small task.",
                reason: "No care logged today",
                plantId: nil,
                surface: .today,
                expiresAt: Date().addingTimeInterval(60*60*4)
            )]
        }
        return []
    }
}

