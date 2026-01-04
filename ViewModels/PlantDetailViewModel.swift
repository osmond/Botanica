import Foundation
import SwiftData
import SwiftUI

/// Handles quick actions and error state for PlantDetailView.
@MainActor
final class PlantDetailViewModel: ObservableObject {
    @Published var isPerformingAction = false
    @Published var actionError: String?

    enum CareStatusType {
        case needsAction
        case allSet
    }

    enum CareActionType {
        case logWater
        case logFertilize
    }

    struct CareCTA {
        let label: String
        let actionType: CareActionType
    }

    struct CareState {
        let statusType: CareStatusType
        let primaryTitle: String
        let primarySubtitle: String
        let primaryMeta: String?
        let ctas: [CareCTA]
    }
    
    func quickWaterPlant(_ plant: Plant, context: ModelContext) {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        let recommendation = plant.recommendedWateringAmount
        let wateringEvent = CareEvent(
            type: .watering,
            date: Date(),
            amount: Double(recommendation.amount),
            unit: recommendation.unit,
            notes: "Quick watering - \(recommendation.amount)\(recommendation.unit)"
        )
        wateringEvent.plant = plant
        plant.lastWatered = wateringEvent.date
        context.insert(wateringEvent)
        do {
            try context.save()
            HapticManager.shared.success()
            actionError = nil
        } catch {
            actionError = error.localizedDescription
            HapticManager.shared.error()
        }
    }
    
    func quickFertilizePlant(_ plant: Plant, context: ModelContext) {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        let recommendation = plant.recommendedFertilizerAmount
        let fertilizingEvent = CareEvent(
            type: .fertilizing,
            date: Date(),
            amount: recommendation.amount,
            unit: recommendation.unit,
            notes: "Quick fertilizing - \(String(format: "%.1f", recommendation.amount))\(recommendation.unit)"
        )
        fertilizingEvent.plant = plant
        plant.lastFertilized = fertilizingEvent.date
        context.insert(fertilizingEvent)
        do {
            try context.save()
            HapticManager.shared.success()
            actionError = nil
        } catch {
            actionError = error.localizedDescription
            HapticManager.shared.error()
        }
    }

    func careState(
        nextWaterDate: Date?,
        nextFertilizeDate: Date?,
        nextRepotDate: Date?,
        lastWateredDate: Date?,
        recommendedWaterMl: Double?,
        scheduleIntervalText: String?
    ) -> CareState {
        let calendar = Calendar.current
        let now = Date()

        func dueStatus(for date: Date?) -> (isToday: Bool, isOverdue: Bool, daysOverdue: Int) {
            guard let date else { return (false, false, 0) }
            if calendar.isDateInToday(date) { return (true, false, 0) }
            let startOfToday = calendar.startOfDay(for: now)
            if date < startOfToday {
                let days = max(1, calendar.dateComponents([.day], from: date, to: startOfToday).day ?? 1)
                return (false, true, days)
            }
            return (false, false, 0)
        }

        let waterStatus = dueStatus(for: nextWaterDate)
        let fertilizeStatus = dueStatus(for: nextFertilizeDate)
        let waterDue = waterStatus.isToday || waterStatus.isOverdue
        let fertilizeDue = fertilizeStatus.isToday || fertilizeStatus.isOverdue

        if waterDue && fertilizeDue {
            let subtitleParts = [
                waterStatus.isOverdue ? "Water overdue" : "Water today",
                fertilizeStatus.isOverdue ? "Fertilize overdue" : "Fertilize today"
            ]
            return CareState(
                statusType: .needsAction,
                primaryTitle: "Care due",
                primarySubtitle: subtitleParts.joined(separator: " · "),
                primaryMeta: scheduleIntervalText,
                ctas: [
                    CareCTA(label: "Log Water", actionType: .logWater),
                    CareCTA(label: "Log Fertilize", actionType: .logFertilize)
                ]
            )
        }

        if waterDue {
            let title = waterStatus.isOverdue ? "Water overdue" : "Water today"
            let subtitle: String = {
                guard let recommendedWaterMl else { return "Use recommended amount" }
                let rounded = recommendedWaterMl.truncatingRemainder(dividingBy: 1) == 0
                    ? String(format: "%.0f", recommendedWaterMl)
                    : String(format: "%.1f", recommendedWaterMl)
                return "Use \(rounded) ml"
            }()
            let meta: String? = {
                guard let lastWateredDate else { return "Last watered not logged" }
                return "Last watered \(relativeTimeText(for: lastWateredDate))"
            }()
            return CareState(
                statusType: .needsAction,
                primaryTitle: title,
                primarySubtitle: subtitle,
                primaryMeta: meta,
                ctas: [CareCTA(label: "Log Water", actionType: .logWater)]
            )
        }

        if fertilizeDue {
            let title = fertilizeStatus.isOverdue ? "Fertilize overdue" : "Fertilize today"
            let subtitle = fertilizeStatus.isOverdue
                ? "Overdue by \(fertilizeStatus.daysOverdue) day\(fertilizeStatus.daysOverdue == 1 ? "" : "s")"
                : "Scheduled for today"
            return CareState(
                statusType: .needsAction,
                primaryTitle: title,
                primarySubtitle: subtitle,
                primaryMeta: scheduleIntervalText,
                ctas: [CareCTA(label: "Log Fertilize", actionType: .logFertilize)]
            )
        }

        _ = nextRepotDate // Keep input for future expansion without changing behavior.

        let subtitle = nextWaterDate.map { "Next watering \(shortDateText(for: $0))" }
            ?? (scheduleIntervalText ?? "Next care not set")

        return CareState(
            statusType: .allSet,
            primaryTitle: "Next care",
            primarySubtitle: subtitle,
            primaryMeta: nil,
            ctas: []
        )
    }

    private func shortDateText(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "today" }
        if calendar.isDateInTomorrow(date) { return "tomorrow" }
        return Self.shortDateFormatter.string(from: date)
    }

    private func relativeTimeText(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "today" }
        return Self.relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
}
