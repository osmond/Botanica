import SwiftUI
import SwiftData

struct AIHubView: View {
    @Query private var plants: [Plant]
    @Query private var careEvents: [CareEvent]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        PlantIdentificationView()
                    } label: {
                        AIPrimaryCard(
                            title: "Identify a plant",
                            subtitle: "Take a photo or upload to get the name and care info.",
                            icon: "camera.viewfinder",
                            accent: BotanicaTheme.Colors.primary
                        )
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                if plants.isEmpty {
                    Section(header: sectionHeader("Insights")) {
                        HStack(spacing: BotanicaTheme.Spacing.md) {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(BotanicaTheme.Colors.leafGreen)
                                .font(.system(size: BotanicaTheme.Sizing.iconInline, weight: .semibold))
                            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                                Text("Add a plant to see insights")
                                    .font(BotanicaTheme.Typography.subheadline)
                                Text("Care summaries appear here once you start logging.")
                                    .font(BotanicaTheme.Typography.caption)
                                    .foregroundColor(BotanicaTheme.Colors.textSecondary)
                            }
                        }
                        .padding(.vertical, BotanicaTheme.Spacing.xs)
                    }
                } else if !insightItems.isEmpty {
                    Section(header: sectionHeader("Insights")) {
                        ForEach(insightItems.prefix(2)) { item in
                            switch item.destination {
                            case .careFocus:
                                NavigationLink {
                                    CareFocusListView(
                                        title: "Care Focus",
                                        subtitle: "Plants due today or overdue.",
                                        plants: careFocusPlants,
                                        statusProvider: careFocusStatus(for:)
                                    )
                                } label: {
                                    InsightRow(item: item)
                                }
                            case .attention:
                                NavigationLink {
                                    CareFocusListView(
                                        title: "Needs Attention",
                                        subtitle: "Based on your health status updates.",
                                        plants: attentionPlants,
                                        statusProvider: attentionStatus(for:)
                                    )
                                } label: {
                                    InsightRow(item: item)
                                }
                            case .seasonal:
                                NavigationLink {
                                    SeasonalCareGuidanceView(plants: plants)
                                } label: {
                                    InsightRow(item: item)
                                }
                            case .logCare:
                                NavigationLink {
                                    AIPlantPickerView(
                                        title: "Log Care",
                                        emptyTitle: "No Plants Yet",
                                        emptySubtitle: "Add a plant before logging care."
                                    ) { plant in
                                        AddCareEventView(plant: plant)
                                    }
                                } label: {
                                    InsightRow(item: item)
                                }
                            }
                        }

                        if insightItems.count > 2 {
                            NavigationLink("View all insights") {
                                AIInsightsListView(
                                    items: insightItems,
                                    plants: plants,
                                    careFocusPlants: careFocusPlants,
                                    attentionPlants: attentionPlants,
                                    careFocusStatus: careFocusStatus(for:),
                                    attentionStatus: attentionStatus(for:)
                                )
                            }
                            .font(BotanicaTheme.Typography.subheadline)
                            .foregroundColor(BotanicaTheme.Colors.primary)
                        }
                    }
                }

                Section(header: sectionHeader("Ask")) {
                    NavigationLink {
                        AIPlantPickerView(
                            title: "AI Plant Coach",
                            emptyTitle: "No Plants Yet",
                            emptySubtitle: "Add a plant to start a chat with your AI coach."
                        ) { plant in
                            AICoachView(plant: plant)
                        }
                    } label: {
                        AIHubRow(
                            title: "AI Plant Coach",
                            subtitle: "Ask questions and get advice",
                            icon: "message.badge.waveform",
                            color: BotanicaTheme.Colors.leafGreen
                        )
                    }

                    NavigationLink {
                        AIPlantPickerView(
                            title: "AI Care Assistant",
                            emptyTitle: "No Plants Yet",
                            emptySubtitle: "Add a plant to generate care plans and diagnostics."
                        ) { plant in
                            AICareAssistantView(plant: plant)
                        }
                    } label: {
                        AIHubRow(
                            title: "AI Care Assistant",
                            subtitle: "Plans, questions, and diagnosis",
                            icon: "wand.and.stars",
                            color: BotanicaTheme.Colors.waterBlue
                        )
                    }
                }

                Section(header: sectionHeader("Health")) {
                    NavigationLink {
                        PlantHealthSelectionView()
                    } label: {
                        AIHubRow(
                            title: "Health Vision",
                            subtitle: "Analyze plant health with photos",
                            icon: "stethoscope",
                            color: BotanicaTheme.Colors.warning
                        )
                    }
                }

                Section(header: sectionHeader("Settings")) {
                    NavigationLink {
                        AISettingsView()
                    } label: {
                        AIHubRow(
                            title: "AI Settings",
                            subtitle: "Configure OpenAI and AI features",
                            icon: "gearshape.fill",
                            color: BotanicaTheme.Colors.terracotta
                        )
                    }
                }
            }
            .navigationTitle("AI")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(BotanicaTheme.Typography.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(BotanicaTheme.Colors.textSecondary)
            .textCase(.uppercase)
    }
    
    private var insightItems: [InsightItem] {
        var items: [InsightItem] = []
        
        let dueCount = careFocusPlants.count
        if dueCount > 0 {
            items.append(InsightItem(
                title: "Care due now",
                subtitle: "\(dueCount) plants are due today or overdue.",
                evidence: "Based on schedules and \(careEventsInRange.count) logs in the last 30 days.",
                icon: "calendar.badge.clock",
                color: BotanicaTheme.Colors.warning,
                destination: .careFocus
            ))
        }
        
        let attentionCount = attentionPlants.count
        if attentionCount > 0 {
            items.append(InsightItem(
                title: "Health check needed",
                subtitle: "\(attentionCount) plants are marked as needing attention.",
                evidence: "Based on \(attentionCount) health status updates.",
                icon: "exclamationmark.triangle.fill",
                color: BotanicaTheme.Colors.warning,
                destination: .attention
            ))
        }
        
        if careEventsInRange.isEmpty {
            items.append(InsightItem(
                title: "No care logged recently",
                subtitle: "There are no care logs in the last 30 days.",
                evidence: "0 logs across \(plants.count) plants in 30 days.",
                icon: "clock.arrow.circlepath",
                color: BotanicaTheme.Colors.waterBlue,
                destination: .logCare
            ))
        }
        
        if items.isEmpty || items.count < 3 {
            items.append(InsightItem(
                title: "\(BotanicalSeason.current.rawValue) guidance",
                subtitle: BotanicalSeason.current.careModifications,
                evidence: "Seasonal guidance, not plant-specific. Review before applying.",
                icon: seasonalIcon,
                color: BotanicalSeason.current.primaryColor,
                destination: .seasonal
            ))
        }
        
        return Array(items.prefix(3))
    }
    
    private var careEventsInRange: [CareEvent] {
        let start = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return careEvents.filter { $0.date >= start }
    }
    
    private var careFocusPlants: [Plant] {
        plants
            .filter { isOverdue($0) || isDueToday($0) }
            .sorted { careFocusPriority($0) > careFocusPriority($1) }
    }
    
    private var attentionPlants: [Plant] {
        plants
            .filter { $0.healthStatus == .poor || $0.healthStatus == .critical }
            .sorted { attentionPriority($0) > attentionPriority($1) }
    }
    
    private func isOverdue(_ plant: Plant) -> Bool {
        plant.isWateringOverdue || plant.isFertilizingOverdue || plant.isRepottingOverdue
    }
    
    private func isDueToday(_ plant: Plant) -> Bool {
        let cal = Calendar.current
        let waterToday = plant.nextWateringDate.map { cal.isDateInToday($0) } ?? false
        let feedToday = plant.nextFertilizingDate.map { cal.isDateInToday($0) } ?? false
        let repotToday = plant.nextRepottingDate.map { cal.isDateInToday($0) } ?? false
        return waterToday || feedToday || repotToday
    }
    
    private func careFocusPriority(_ plant: Plant) -> Int {
        var score = 0
        if plant.isWateringOverdue { score += 4 }
        if plant.isFertilizingOverdue { score += 3 }
        if plant.isRepottingOverdue { score += 2 }
        if isDueToday(plant) { score += 1 }
        return score
    }
    
    private func attentionPriority(_ plant: Plant) -> Int {
        plant.healthStatus == .critical ? 2 : 1
    }
    
    private func careFocusStatus(for plant: Plant) -> ReviewStatus {
        let overdueTypes = careTypes(for: plant, overdue: true)
        if !overdueTypes.isEmpty {
            return ReviewStatus(
                title: "Overdue",
                detail: detailLine(for: overdueTypes, suffix: "overdue"),
                color: BotanicaTheme.Colors.warning
            )
        }
        
        let dueTodayTypes = careTypes(for: plant, overdue: false)
        if !dueTodayTypes.isEmpty {
            return ReviewStatus(
                title: "Due today",
                detail: detailLine(for: dueTodayTypes, suffix: "due today"),
                color: BotanicaTheme.Colors.waterBlue
            )
        }
        
        return ReviewStatus(title: "On schedule", detail: "No care due today", color: BotanicaTheme.Colors.success)
    }
    
    private func attentionStatus(for plant: Plant) -> ReviewStatus {
        switch plant.healthStatus {
        case .critical:
            return ReviewStatus(title: "Critical", detail: "Needs attention", color: BotanicaTheme.Colors.warning)
        case .poor:
            return ReviewStatus(title: "Poor", detail: "Needs attention", color: BotanicaTheme.Colors.warning)
        case .fair:
            return ReviewStatus(title: "Fair", detail: "Watch closely", color: BotanicaTheme.Colors.waterBlue)
        case .healthy:
            return ReviewStatus(title: "Healthy", detail: "On track", color: BotanicaTheme.Colors.success)
        case .excellent:
            return ReviewStatus(title: "Excellent", detail: "On track", color: BotanicaTheme.Colors.success)
        }
    }
    
    private func careTypes(for plant: Plant, overdue: Bool) -> [CareType] {
        if overdue {
            var types: [CareType] = []
            if plant.isWateringOverdue { types.append(.watering) }
            if plant.isFertilizingOverdue { types.append(.fertilizing) }
            if plant.isRepottingOverdue { types.append(.repotting) }
            return types
        }
        
        let cal = Calendar.current
        var types: [CareType] = []
        if let date = plant.nextWateringDate, cal.isDateInToday(date) { types.append(.watering) }
        if let date = plant.nextFertilizingDate, cal.isDateInToday(date) { types.append(.fertilizing) }
        if let date = plant.nextRepottingDate, cal.isDateInToday(date) { types.append(.repotting) }
        return types
    }
    
    private func detailLine(for types: [CareType], suffix: String) -> String {
        guard !types.isEmpty else { return "No care due" }
        if types.count == 1 {
            return "\(types[0].rawValue) \(suffix)"
        }
        return "Multiple tasks \(suffix)"
    }
    
    private var seasonalIcon: String {
        switch BotanicalSeason.current {
        case .spring: return "leaf.fill"
        case .summer: return "sun.max.fill"
        case .fall: return "leaf.circle.fill"
        case .winter: return "snowflake"
        }
    }
}

private struct AIHubRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: BotanicaTheme.Sizing.iconSmall, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                Text(title)
                    .font(BotanicaTheme.Typography.subheadline)
                    .foregroundColor(BotanicaTheme.Colors.textPrimary)
                Text(subtitle)
                    .font(BotanicaTheme.Typography.caption)
                    .foregroundColor(BotanicaTheme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, BotanicaTheme.Spacing.xs)
    }
}

private struct InsightItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let evidence: String
    let icon: String
    let color: Color
    let destination: InsightDestination
}

private enum InsightDestination {
    case careFocus
    case attention
    case seasonal
    case logCare
}

private struct InsightRow: View {
    let item: InsightItem
    
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(item.color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: item.icon)
                    .font(.system(size: BotanicaTheme.Sizing.iconSmall, weight: .semibold))
                    .foregroundColor(item.color)
            }
            
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                Text(item.title)
                    .font(BotanicaTheme.Typography.subheadline)
                    .foregroundColor(BotanicaTheme.Colors.textPrimary)
                Text(item.subtitle)
                    .font(BotanicaTheme.Typography.caption)
                    .foregroundColor(BotanicaTheme.Colors.textSecondary)
                Text(item.evidence)
                    .font(BotanicaTheme.Typography.caption2)
                    .foregroundColor(BotanicaTheme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, BotanicaTheme.Spacing.xs)
    }
}

private struct AIPrimaryCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color

    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                    .fill(accent.opacity(0.12))
                    .frame(width: BotanicaTheme.Sizing.iconHero, height: BotanicaTheme.Sizing.iconHero)
                Image(systemName: icon)
                    .font(.system(size: BotanicaTheme.Sizing.iconPrimary, weight: .semibold))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                Text(title)
                    .font(BotanicaTheme.Typography.title3)
                    .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                Text(subtitle)
                    .font(BotanicaTheme.Typography.subheadline)
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(BotanicaTheme.Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(BotanicaTheme.Colors.textTertiary)
        }
        .padding(BotanicaTheme.Spacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                .fill(BotanicaTheme.Colors.surfaceAlt)
        )
    }
}

private struct AIInsightsListView: View {
    let items: [InsightItem]
    let plants: [Plant]
    let careFocusPlants: [Plant]
    let attentionPlants: [Plant]
    let careFocusStatus: (Plant) -> ReviewStatus
    let attentionStatus: (Plant) -> ReviewStatus

    var body: some View {
        List {
            ForEach(items) { item in
                switch item.destination {
                case .careFocus:
                    NavigationLink {
                        CareFocusListView(
                            title: "Care Focus",
                            subtitle: "Plants due today or overdue.",
                            plants: careFocusPlants,
                            statusProvider: careFocusStatus
                        )
                    } label: {
                        InsightRow(item: item)
                    }
                case .attention:
                    NavigationLink {
                        CareFocusListView(
                            title: "Needs Attention",
                            subtitle: "Based on your health status updates.",
                            plants: attentionPlants,
                            statusProvider: attentionStatus
                        )
                    } label: {
                        InsightRow(item: item)
                    }
                case .seasonal:
                    NavigationLink {
                        SeasonalCareGuidanceView(plants: plants)
                    } label: {
                        InsightRow(item: item)
                    }
                case .logCare:
                    NavigationLink {
                        AIPlantPickerView(
                            title: "Log Care",
                            emptyTitle: "No Plants Yet",
                            emptySubtitle: "Add a plant before logging care."
                        ) { plant in
                            AddCareEventView(plant: plant)
                        }
                    } label: {
                        InsightRow(item: item)
                    }
                }
            }
        }
        .navigationTitle("Insights")
    }
}

private struct AIPlantPickerView<Destination: View>: View {
    let title: String
    let emptyTitle: String
    let emptySubtitle: String
    let destination: (Plant) -> Destination
    
    @Query private var plants: [Plant]
    
    var body: some View {
        List {
            if plants.isEmpty {
                VStack(spacing: BotanicaTheme.Spacing.md) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: BotanicaTheme.Sizing.iconHero))
                        .foregroundColor(BotanicaTheme.Colors.leafGreen)
                    Text(emptyTitle)
                        .font(BotanicaTheme.Typography.title3)
                        .fontWeight(.semibold)
                    Text(emptySubtitle)
                        .font(BotanicaTheme.Typography.body)
                        .foregroundColor(BotanicaTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(BotanicaTheme.Spacing.xl)
                .listRowSeparator(.hidden)
            } else {
                ForEach(plants) { plant in
                    NavigationLink {
                        destination(plant)
                    } label: {
                        HStack(spacing: BotanicaTheme.Spacing.md) {
                            AsyncPlantThumbnail(photo: plant.primaryPhoto, plant: plant, size: 44)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(plant.displayName)
                                    .font(BotanicaTheme.Typography.subheadline)
                                    .foregroundColor(BotanicaTheme.Colors.textPrimary)
                                Text(plant.scientificName)
                                    .font(BotanicaTheme.Typography.caption)
                                    .foregroundColor(BotanicaTheme.Colors.textSecondary)
                            }
                        }
                        .padding(.vertical, BotanicaTheme.Spacing.xs)
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    AIHubView()
        .modelContainer(MockDataGenerator.previewContainer())
}
