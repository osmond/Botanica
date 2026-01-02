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
        let primaryCTA: CareCTA?
    }
    
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
        if waterStatus.isToday || waterStatus.isOverdue {
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
                primaryCTA: CareCTA(label: "Log Water", actionType: .logWater)
            )
        }

        let fertilizeStatus = dueStatus(for: nextFertilizeDate)
        if fertilizeStatus.isToday || fertilizeStatus.isOverdue {
            let title = fertilizeStatus.isOverdue ? "Fertilize overdue" : "Fertilize today"
            let subtitle = fertilizeStatus.isOverdue
                ? "Overdue by \(fertilizeStatus.daysOverdue) day\(fertilizeStatus.daysOverdue == 1 ? "" : "s")"
                : "Scheduled for today"
            return CareState(
                statusType: .needsAction,
                primaryTitle: title,
                primarySubtitle: subtitle,
                primaryMeta: scheduleIntervalText,
                primaryCTA: CareCTA(label: "Log Fertilize", actionType: .logFertilize)
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
            primaryCTA: nil
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
