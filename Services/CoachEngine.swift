import Foundation
import SwiftData

enum CoachSurface { case today, plantDetail, analytics }

struct CoachSuggestion: Identifiable, Equatable {
    let id: UUID
    let title: String
    let message: String
    let reason: String
    let plantId: UUID?
    let surface: CoachSurface
    let expiresAt: Date
}

protocol CoachRule {
    func evaluate(plants: [Plant], events: [CareEvent]) async -> [CoachSuggestion]
}

// Rules moved to Services/CoachRules/*

@MainActor
final class CoachEngine: ObservableObject {
    @Published private(set) var suggestions: [CoachSuggestion] = []
    private var cacheKey: String = ""

    init() {}

    // Derive active rules from UserDefaults to respect Settings toggles
    private func activeRules() -> [CoachRule] {
        let d = UserDefaults.standard
        // Defaults to true when unset
        func isOn(_ key: String, default def: Bool = true) -> Bool {
            if d.object(forKey: key) == nil { return def }
            return d.bool(forKey: key)
        }
        var list: [CoachRule] = []
        if isOn("coachRuleOverdueWatering", default: true) { list.append(OverdueWateringRule()) }
        if isOn("coachRuleStreakNudge", default: true) { list.append(StreakNudgeRule()) }
        return list
    }

    func refresh(plants: [Plant], events: [CareEvent], surface: CoachSurface) async {
        let newKey = "\(surface)-\(plants.count)-\(events.count)"
        if newKey == cacheKey, !suggestions.isEmpty { return }
        cacheKey = newKey
        let rules = activeRules()
        let results = await withTaskGroup(of: [CoachSuggestion].self) { group -> [CoachSuggestion] in
            for rule in rules { group.addTask { await rule.evaluate(plants: plants, events: events) } }
            return await group.reduce(into: []) { $0 += $1 }
        }
        let now = Date()
        self.suggestions = results.filter { $0.expiresAt > now && $0.surface == surface }
    }

    func reset() {
        cacheKey = ""
        suggestions = []
    }
}
