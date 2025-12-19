import SwiftUI
import SwiftData

/// Advanced Analytics view providing botanical insights, plant care optimization,
/// seasonal care guidance, and predictive plant health analytics
struct AnalyticsView: View {
    @Query private var plants: [Plant]
    @Query private var careEvents: [CareEvent]
    @StateObject private var viewModel = AnalyticsViewModel()
    @AppStorage("analytics.timeRange") private var storedRange: String = AnalyticsTimeRange.month.rawValue
    @State private var selectedTimeRange: AnalyticsTimeRange = .month
    @State private var showingSeasonalGuidance = false
    @State private var reviewSheet: ReviewSheet?
    @State private var selectedPlantForCare: Plant?
    @State private var selectedPlantForDetails: Plant?

    var body: some View {
        NavigationStack {
            LoadStateView(
                state: viewModel.loadState,
                retry: { viewModel.refresh(plants: plants, careEvents: careEvents, range: selectedTimeRange) },
                loading: {
                    if plants.isEmpty {
                        VStack(spacing: BotanicaTheme.Spacing.md) {
                            Image(systemName: "leaf")
                                .font(.largeTitle)
                                .foregroundColor(BotanicaTheme.Colors.primary)
                            Text("Add a plant to see analytics")
                                .font(BotanicaTheme.Typography.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(spacing: BotanicaTheme.Spacing.md) {
                            ProgressView("Analyzing collection…")
                                .progressViewStyle(.circular)
                            Text("Summarizing your logs and schedules")
                                .font(BotanicaTheme.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                },
                content: {
                    if plants.isEmpty {
                        VStack(spacing: BotanicaTheme.Spacing.md) {
                            Image(systemName: "leaf")
                                .font(.largeTitle)
                                .foregroundColor(BotanicaTheme.Colors.primary)
                            Text("Add a plant to see analytics")
                                .font(BotanicaTheme.Typography.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: BotanicaTheme.Spacing.xl) {
                                // Collection summary
                                collectionHealthHero
                                
                                // Care focus
                                careFocusSection
                                
                                // Care activity
                                careActivitySection
                                
                                // Health check-ins
                                healthCheckinsSection
                                
                                // Seasonal Botanical Guidance
                                seasonalGuidanceCard
                                
                                // Insights
                                smartRecommendationsSection
                            }
                            .padding(.horizontal, BotanicaTheme.Spacing.lg)
                            .padding(.top, BotanicaTheme.Spacing.lg)
                            .padding(.bottom, BotanicaTheme.Spacing.jumbo)
                        }
                        .safeAreaInset(edge: .bottom) {
                            Color.clear.frame(height: 120)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            )
            .navigationTitle("Plant Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSeasonalGuidance) {
                SeasonalCareGuidanceView(plants: plants)
            }
            .sheet(item: $reviewSheet) { sheet in
                switch sheet {
                case .careFocus:
                    CareFocusListView(
                        title: "Care Focus",
                        subtitle: "Plants due today or overdue.",
                        plants: careFocusPlants,
                        statusProvider: careFocusStatus(for:)
                    )
                case .attention:
                    CareFocusListView(
                        title: "Needs Attention",
                        subtitle: "Based on your health status updates.",
                        plants: attentionPlants,
                        statusProvider: attentionStatus(for:)
                    )
                }
            }
            .sheet(item: $selectedPlantForCare) { plant in
                AddCareEventView(plant: plant)
            }
            .sheet(item: $selectedPlantForDetails) { plant in
                PlantDetailView(plant: plant)
            }
            .task(id: selectedTimeRange) {
                viewModel.refresh(plants: plants, careEvents: careEvents, range: selectedTimeRange)
                storedRange = selectedTimeRange.rawValue
            }
            .onChange(of: plants.count) { _, _ in
                viewModel.refresh(plants: plants, careEvents: careEvents, range: selectedTimeRange)
            }
            .onChange(of: careEvents.count) { _, _ in
                viewModel.refresh(plants: plants, careEvents: careEvents, range: selectedTimeRange)
            }
            .onAppear {
                selectedTimeRange = AnalyticsTimeRange(rawValue: storedRange) ?? .month
            }
        }
    }
    
    // MARK: - Modern Botanical Analytics Components
    
    private var collectionHealthHero: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            Text("Collection Summary")
                .font(BotanicaTheme.Typography.title2)
                .fontWeight(.bold)
            
            Text(collectionSummaryLine)
                .font(BotanicaTheme.Typography.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: BotanicaTheme.Spacing.md) {
                SummaryMetricPill(
                    title: "On schedule",
                    count: onScheduleCount,
                    color: BotanicaTheme.Colors.success,
                    icon: "checkmark.circle.fill"
                )
                
                SummaryMetricPill(
                    title: "Due today",
                    count: dueTodayCount,
                    color: BotanicaTheme.Colors.waterBlue,
                    icon: "calendar.badge.clock"
                )
                
                SummaryMetricPill(
                    title: "Overdue",
                    count: overdueCount,
                    color: BotanicaTheme.Colors.warning,
                    icon: "clock.badge.exclamationmark"
                )
            }
            
            Text(healthSummaryLine)
                .font(BotanicaTheme.Typography.caption)
                .foregroundStyle(.secondary)
            
            Text(dataBasisLine)
                .font(BotanicaTheme.Typography.caption2)
                .foregroundStyle(BotanicaTheme.Colors.textSecondary)
            
            if overdueCount + dueTodayCount > 0 {
                Button(action: { reviewSheet = .careFocus }) {
                    HStack {
                        Text("Review due plants")
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                }
                .foregroundColor(BotanicaTheme.Colors.primary)
            }
        }
        .padding(BotanicaTheme.Spacing.lg)
        .cardStyle()
    }
    
    private var careFocusSection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            Text("Care Focus")
                .font(BotanicaTheme.Typography.title2)
                .fontWeight(.bold)
            
            Text(careFocusSummaryLine)
                .font(BotanicaTheme.Typography.caption)
                .foregroundColor(.secondary)
            
            if careFocusPlants.isEmpty {
                EmptyStateCard(
                    icon: "checkmark.circle",
                    title: "Nothing due today",
                    description: "You are up to date. Next care actions will show here."
                )
            } else {
                VStack(spacing: BotanicaTheme.Spacing.md) {
                    ForEach(careFocusPlants.prefix(4), id: \.id) { plant in
                        CareFocusRow(
                            plant: plant,
                            status: careFocusStatus(for: plant),
                            onOpen: { selectedPlantForDetails = plant },
                            onLogCare: { selectedPlantForCare = plant }
                        )
                    }
                }
                
                if careFocusPlants.count > 4 {
                    Button(action: { reviewSheet = .careFocus }) {
                        HStack {
                            Text("View all due plants")
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(BotanicaTheme.Colors.primary)
                }
            }
            
            Text("Based on schedules and last logged care.")
                .font(BotanicaTheme.Typography.caption2)
                .foregroundColor(.secondary)
        }
        .cardStyle()
        .accessibilityLabel("Care focus")
    }
    
    private var careActivitySection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            Text("Care Activity")
                .font(BotanicaTheme.Typography.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                HStack {
                    Text("Analysis Period")
                        .font(BotanicaTheme.Typography.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(selectedTimeRange.subtitle)
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(AnalyticsTimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue)
                            .tag(range)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            if careEventsInRange.isEmpty {
                EmptyStateCard(
                    icon: "calendar.badge.clock",
                    title: "No care logs",
                    description: "Log care actions to see patterns over time."
                )
            } else {
                Text(careActivitySummaryLine)
                    .font(BotanicaTheme.Typography.callout)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: BotanicaTheme.Spacing.md) {
                    AnalyticsMetricCard(
                        title: "Care logs",
                        value: "\(careEventsInRange.count)",
                        subtitle: selectedTimeRange.subtitle,
                        tint: BotanicaTheme.Colors.leafGreen
                    )
                    
                    AnalyticsMetricCard(
                        title: "Plants cared for",
                        value: "\(plantsCaredForCount)/\(plants.count)",
                        subtitle: "with logs",
                        tint: BotanicaTheme.Colors.waterBlue
                    )
                    
                    AnalyticsMetricCard(
                        title: "Most common",
                        value: mostCommonCareType?.rawValue ?? "—",
                        subtitle: "care type",
                        tint: BotanicaTheme.Colors.nutrientOrange
                    )
                    
                    AnalyticsMetricCard(
                        title: "Average gap",
                        value: averageCareGapText,
                        subtitle: "between logs",
                        tint: BotanicaTheme.Colors.primary
                    )
                }
                
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                    Text("Care logs by type")
                        .font(BotanicaTheme.Typography.headline)
                        .fontWeight(.semibold)
                    Text(selectedTimeRange.subtitle)
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                    CareTypeEffectivenessGrid(careEvents: careEventsInRange)
                }
            }
        }
        .cardStyle()
        .accessibilityLabel("Care activity")
    }
    
    private var healthCheckinsSection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            Text("Health Check-ins")
                .font(BotanicaTheme.Typography.title2)
                .fontWeight(.bold)
            
            Text("Current status based on the health you set per plant.")
                .font(BotanicaTheme.Typography.caption)
                .foregroundColor(.secondary)
            
            if plants.isEmpty {
                EmptyStateCard(
                    icon: "heart.text.square",
                    title: "No Health Data",
                    description: "Add plants to see a health overview."
                )
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: BotanicaTheme.Spacing.md) {
                    AnalyticsMetricCard(
                        title: "Doing well",
                        value: "\(healthyPlantsCount)",
                        subtitle: "excellent or healthy",
                        tint: BotanicaTheme.Colors.success
                    )
                    
                    AnalyticsMetricCard(
                        title: "Watch",
                        value: "\(watchPlantsCount)",
                        subtitle: "fair",
                        tint: BotanicaTheme.Colors.waterBlue
                    )
                    
                    AnalyticsMetricCard(
                        title: "Needs attention",
                        value: "\(attentionNeededCount)",
                        subtitle: "poor or critical",
                        tint: BotanicaTheme.Colors.warning
                    )
                }
                
                if attentionNeededCount > 0 {
                    Button(action: { reviewSheet = .attention }) {
                        HStack {
                            Text("Review health needs")
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(BotanicaTheme.Colors.primary)
                }
            }
        }
        .cardStyle()
        .accessibilityLabel("Health check-ins")
    }
    
    private var seasonalGuidanceCard: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                    Text("\(BotanicalSeason.current.rawValue) Guidance")
                        .font(BotanicaTheme.Typography.title3)
                        .fontWeight(.semibold)
                    
                    Text("General seasonal guidance. Review each plant before adjusting schedules.")
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    Text(BotanicalSeason.current.careModifications)
                        .font(BotanicaTheme.Typography.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Image(systemName: currentSeasonIcon)
                    .font(.system(size: 32))
                    .foregroundColor(BotanicalSeason.current.primaryColor)
            }
            
            Button(action: { showingSeasonalGuidance = true }) {
                HStack {
                    Text("Review seasonal guidance")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(BotanicaTheme.Colors.primary)
            }
        }
        .cardStyle()
        .accessibilityLabel("Seasonal care guide")
        .padding(.bottom, BotanicaTheme.Spacing.md)
    }
    
    private var smartRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            Text("Insights")
                .font(BotanicaTheme.Typography.title2)
                .fontWeight(.bold)
            Text("Based on your logs and schedules.")
                .font(BotanicaTheme.Typography.caption)
                .foregroundColor(.secondary)
            
            if smartRecommendations.isEmpty {
                Text("No new insights yet. Keep logging care to reveal patterns.")
                    .font(BotanicaTheme.Typography.callout)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: BotanicaTheme.Spacing.md) {
                    ForEach(smartRecommendations, id: \.title) { recommendation in
                        SmartRecommendationCard(recommendation: recommendation)
                    }
                }
            }
        }
        .cardStyle()
        .accessibilityLabel("Insights")
    }
    
    // MARK: - Botanical Analytics Data Processing
    
    private var careEventsInRange: [CareEvent] {
        return careEvents.filter { $0.date >= selectedTimeRange.startDate }
    }
    
    private var healthyPlantsCount: Int {
        plants.filter { $0.healthStatus == .excellent || $0.healthStatus == .healthy }.count
    }
    
    private var watchPlantsCount: Int {
        plants.filter { $0.healthStatus == .fair }.count
    }
    
    private var attentionNeededCount: Int {
        plants.filter { $0.healthStatus == .poor || $0.healthStatus == .critical }.count
    }
    
    private var currentSeasonIcon: String {
        switch BotanicalSeason.current {
        case .spring: return "leaf.fill"
        case .summer: return "sun.max.fill"
        case .fall: return "leaf.circle.fill"
        case .winter: return "snowflake"
        }
    }
    
    private var overdueCount: Int {
        plants.filter { $0.isWateringOverdue || $0.isFertilizingOverdue || $0.isRepottingOverdue }.count
    }
    
    private var dueTodayCount: Int {
        let cal = Calendar.current
        return plants.filter { plant in
            let waterToday = plant.nextWateringDate.map { cal.isDateInToday($0) } ?? false
            let feedToday = plant.nextFertilizingDate.map { cal.isDateInToday($0) } ?? false
            let repotToday = plant.nextRepottingDate.map { cal.isDateInToday($0) } ?? false
            return waterToday || feedToday || repotToday
        }.count
    }

    private var onScheduleCount: Int {
        max(plants.count - overdueCount - dueTodayCount, 0)
    }
    
    private var careFocusPlants: [Plant] {
        plants
            .filter { isDueToday($0) || isOverdue($0) }
            .sorted { careFocusPriority($0) > careFocusPriority($1) }
    }
    
    private var attentionPlants: [Plant] {
        plants
            .filter { $0.healthStatus == .poor || $0.healthStatus == .critical }
            .sorted { attentionPriority($0) > attentionPriority($1) }
    }

    private var collectionSummaryLine: String {
        if plants.isEmpty {
            return "Add plants to see collection patterns."
        }
        if overdueCount + dueTodayCount == 0 {
            return "\(onScheduleCount) plants on schedule. No care due today."
        }
        return "\(onScheduleCount) on schedule, \(dueTodayCount) due today, \(overdueCount) overdue."
    }
    
    private var healthSummaryLine: String {
        if plants.isEmpty {
            return "Health status appears once you add plants."
        }
        if attentionNeededCount > 0 {
            return "\(attentionNeededCount) plants marked as needing attention."
        }
        return "No plants currently marked as needing attention."
    }
    
    private var dataBasisLine: String {
        if plants.isEmpty {
            return "Based on your schedules and logs."
        }
        let rangeText = selectedTimeRange.subtitle.lowercased()
        if careEventsInRange.isEmpty {
            return "Based on your schedules. No logs in \(rangeText)."
        }
        return "Based on your schedules and \(careEventsInRange.count) logs \(rangeText)."
    }
    
    private var careFocusSummaryLine: String {
        if careFocusPlants.isEmpty {
            return "No care due today."
        }
        let total = overdueCount + dueTodayCount
        return "\(total) plants are due today or overdue."
    }
    
    private var plantsCaredForCount: Int {
        let ids = careEventsInRange.compactMap { $0.plant?.id }
        return Set(ids).count
    }
    
    private var mostCommonCareType: CareType? {
        let counts = Dictionary(grouping: careEventsInRange, by: \.type)
            .mapValues { $0.count }
        return counts.max { $0.value < $1.value }?.key
    }
    
    private var averageCareGapDays: Double? {
        let sortedEvents = careEventsInRange.sorted { $0.date < $1.date }
        guard sortedEvents.count >= 2 else { return nil }
        let intervals = zip(sortedEvents.dropFirst(), sortedEvents.dropLast()).map { (next, prev) -> Double in
            Calendar.current.dateComponents([.day], from: prev.date, to: next.date).day.map(Double.init) ?? 0
        }
        guard !intervals.isEmpty else { return nil }
        let total = intervals.reduce(0, +)
        return total / Double(intervals.count)
    }
    
    private var averageCareGapText: String {
        guard let gap = averageCareGapDays, gap > 0 else { return "—" }
        let rounded = Int(gap.rounded())
        return rounded == 1 ? "1 day" : "\(rounded) days"
    }
    
    private var careActivitySummaryLine: String {
        if careEventsInRange.isEmpty {
            return "No care logged \(selectedTimeRange.subtitle.lowercased())."
        }
        let rangeText = selectedTimeRange.subtitle.lowercased()
        let plantCount = plantsCaredForCount
        let totalPlants = plants.count
        if totalPlants == 0 {
            return "You logged \(careEventsInRange.count) care actions \(rangeText)."
        }
        if let common = mostCommonCareType {
            return "You logged \(careEventsInRange.count) care actions \(rangeText), mostly \(common.rawValue.lowercased()). \(plantCount) of \(totalPlants) plants had activity."
        }
        return "You logged \(careEventsInRange.count) care actions \(rangeText). \(plantCount) of \(totalPlants) plants had activity."
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
    
    private var smartRecommendations: [SmartRecommendation] {
        var recommendations: [SmartRecommendation] = []
        
        if overdueCount + dueTodayCount > 0 {
            recommendations.append(SmartRecommendation(
                title: "Care due now",
                description: "\(overdueCount + dueTodayCount) plants are due today or overdue.",
                evidence: "Based on your schedules and last logged care.",
                priority: .high,
                icon: "calendar.badge.clock",
                actionTitle: "Review due plants",
                action: { reviewSheet = .careFocus }
            ))
        }
        
        if attentionNeededCount > 0 {
            let names = attentionPlants.prefix(3).map { $0.displayName }.joined(separator: ", ")
            let summary = attentionPlants.count > 3 ? "\(names) and \(attentionPlants.count - 3) more" : names
            recommendations.append(SmartRecommendation(
                title: "Health check needed",
                description: summary,
                evidence: "Based on your health status entries.",
                priority: .medium,
                icon: "exclamationmark.triangle.fill",
                actionTitle: "Review health",
                action: { reviewSheet = .attention }
            ))
        }
        
        if careEventsInRange.isEmpty {
            recommendations.append(SmartRecommendation(
                title: "No care logged",
                description: "There are no care logs in \(selectedTimeRange.subtitle.lowercased()).",
                evidence: "Based on your care history.",
                priority: .low,
                icon: "clock.arrow.circlepath",
                actionTitle: "Review due plants",
                action: { reviewSheet = .careFocus }
            ))
        }
        
        if recommendations.isEmpty {
            recommendations.append(SmartRecommendation(
                title: "\(BotanicalSeason.current.rawValue) guidance",
                description: BotanicalSeason.current.careModifications,
                evidence: "General seasonal guidance. Review per plant before changing schedules.",
                priority: .low,
                icon: currentSeasonIcon,
                actionTitle: "Review guidance",
                action: { showingSeasonalGuidance = true }
            ))
        }
        
        return Array(recommendations.prefix(2))
    }
}

enum UIRecommendationPriority {
    case high, medium, low
    
    var color: Color {
        switch self {
        case .high: return BotanicaTheme.Colors.warning
        case .medium: return BotanicaTheme.Colors.waterBlue
        case .low: return BotanicaTheme.Colors.leafGreen
        }
    }
}

struct SmartRecommendation {
    let title: String
    let description: String
    let evidence: String
    let priority: UIRecommendationPriority
    let icon: String
    let actionTitle: String?
    let action: (() -> Void)?
}

enum ReviewSheet: Identifiable {
    case careFocus
    case attention
    
    var id: String {
        switch self {
        case .careFocus: return "careFocus"
        case .attention: return "attention"
        }
    }
}

// MARK: - Supporting Views

struct SummaryMetricPill: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(count)")
                    .font(BotanicaTheme.Typography.callout)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, BotanicaTheme.Spacing.sm)
        .padding(.vertical, BotanicaTheme.Spacing.xs)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title). \(count) plants")
    }
}

struct ReviewStatus {
    let title: String
    let detail: String
    let color: Color
}

struct AnalyticsMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let tint: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
            Text(value)
                .font(BotanicaTheme.Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(tint)
            
            Text(title)
                .font(BotanicaTheme.Typography.caption)
                .foregroundColor(.secondary)
            
            Text(subtitle)
                .font(BotanicaTheme.Typography.caption2)
                .foregroundColor(.secondary)
        }
        .padding(BotanicaTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium))
    }
}

struct StatusPill: View {
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(title)
                .font(.caption2)
                .foregroundColor(color)
        }
        .padding(.horizontal, BotanicaTheme.Spacing.sm)
        .padding(.vertical, BotanicaTheme.Spacing.xs)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct CareFocusRow: View {
    let plant: Plant
    let status: ReviewStatus
    let onOpen: () -> Void
    let onLogCare: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
            HStack(alignment: .top, spacing: BotanicaTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plant.displayName)
                        .font(BotanicaTheme.Typography.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(status.detail)
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Log care", action: onLogCare)
                    .font(.caption)
                    .foregroundColor(BotanicaTheme.Colors.primary)
                    .padding(.horizontal, BotanicaTheme.Spacing.sm)
                    .padding(.vertical, BotanicaTheme.Spacing.xs)
                    .background(BotanicaTheme.Colors.primary.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            StatusPill(title: status.title, color: status.color)
        }
        .padding(BotanicaTheme.Spacing.md)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium))
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(plant.displayName). \(status.detail).")
    }
}

struct PlantReviewRow: View {
    let plant: Plant
    let status: ReviewStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
            Text(plant.displayName)
                .font(BotanicaTheme.Typography.callout)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(status.detail)
                .font(.caption)
                .foregroundColor(.secondary)
            
            StatusPill(title: status.title, color: status.color)
        }
        .padding(.vertical, BotanicaTheme.Spacing.xs)
    }
}

struct CareFocusListView: View {
    let title: String
    let subtitle: String
    let plants: [Plant]
    let statusProvider: (Plant) -> ReviewStatus
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlantForCare: Plant?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(subtitle)
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                if plants.isEmpty {
                    Text("No plants to review right now.")
                        .font(BotanicaTheme.Typography.callout)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(plants, id: \.id) { plant in
                        NavigationLink(destination: PlantDetailView(plant: plant)) {
                            PlantReviewRow(plant: plant, status: statusProvider(plant))
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Log care") { selectedPlantForCare = plant }
                                .tint(BotanicaTheme.Colors.primary)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(item: $selectedPlantForCare) { plant in
            AddCareEventView(plant: plant)
        }
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: BotanicaTheme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            VStack(spacing: BotanicaTheme.Spacing.xs) {
                Text(title)
                    .font(BotanicaTheme.Typography.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(BotanicaTheme.Typography.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(BotanicaTheme.Spacing.xxl)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct CareTypeEffectivenessGrid: View {
    let careEvents: [CareEvent]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: BotanicaTheme.Spacing.sm) {
            ForEach(CareType.allCases, id: \.self) { careType in
                let count = careEvents.filter { $0.type == careType }.count
                if count > 0 {
                    CareTypeEffectivenessCard(careType: careType, count: count)
                }
            }
        }
    }
}

struct CareTypeEffectivenessCard: View {
    let careType: CareType
    let count: Int
    
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.sm) {
            Image(systemName: careType.icon)
                .foregroundColor(careTypeColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(careType.rawValue)
                    .font(BotanicaTheme.Typography.caption)
                    .fontWeight(.medium)
                
                Text("\(count) times")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(BotanicaTheme.Spacing.sm)
        .background(careTypeColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.small))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(careType.rawValue) performed \(count) times")
    }
    
    private var careTypeColor: Color {
        switch careType {
        case .watering: return BotanicaTheme.Colors.waterBlue
        case .fertilizing: return BotanicaTheme.Colors.leafGreen
        case .repotting: return BotanicaTheme.Colors.soilBrown
        case .pruning: return BotanicaTheme.Colors.nutrientOrange
        case .cleaning: return Color.purple
        case .rotating: return Color.gray
        case .misting: return Color.cyan
        case .inspection: return BotanicaTheme.Colors.sunYellow
        }
    }
}

struct SmartRecommendationCard: View {
    let recommendation: SmartRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
            HStack(alignment: .top, spacing: BotanicaTheme.Spacing.sm) {
                Image(systemName: recommendation.icon)
                    .foregroundColor(recommendation.priority.color)
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.headline)
                    Text(recommendation.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(recommendation.evidence)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            if let actionTitle = recommendation.actionTitle, let action = recommendation.action {
                Button(actionTitle, action: action)
                    .font(.caption)
                    .foregroundColor(BotanicaTheme.Colors.primary)
                    .padding(.horizontal, BotanicaTheme.Spacing.sm)
                    .padding(.vertical, BotanicaTheme.Spacing.xs)
                    .background(BotanicaTheme.Colors.primary.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(recommendation.title). \(recommendation.description). \(recommendation.evidence)")
    }
}

// Placeholder sheet views
struct SeasonalCareGuidanceView: View {
    let plants: [Plant]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var applyToAllPlants: Bool = true
    @State private var selectedPlantIDs: Set<UUID> = []
    @State private var recurrence: RecurrencePattern = .monthly
    
    private let seasons: [SeasonalCareSection] = SeasonalCareSection.sampleData
    
    var body: some View {
        NavigationView {
            List {
                applyScopeControls
                
                ForEach(seasons) { section in
                    Section(header: Text(section.title).font(BotanicaTheme.Typography.headline)) {
                        Text(section.summary)
                            .font(BotanicaTheme.Typography.callout)
                            .foregroundColor(.secondary)
                            .padding(.bottom, BotanicaTheme.Spacing.sm)
                        
                        ForEach(section.tasks, id: \.title) { task in
                            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                                HStack {
                                    Image(systemName: task.icon)
                                        .foregroundColor(task.iconColor)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(task.title)
                                            .font(BotanicaTheme.Typography.callout)
                                        Text(task.detail)
                                            .font(BotanicaTheme.Typography.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                Button {
                                    addReminder(for: task)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "bell.badge")
                                        Text("Add reminder")
                                    }
                                    .font(BotanicaTheme.Typography.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, BotanicaTheme.Spacing.sm)
                                    .padding(.vertical, BotanicaTheme.Spacing.xs)
                                    .background(BotanicaTheme.Colors.primary)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, BotanicaTheme.Spacing.sm)
                        }
                    }
                }
            }
            .navigationTitle("Seasonal Care")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if !applyToAllPlants {
                        Text("Selected: \(selectedPlantIDs.count)")
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear {
                if selectedPlantIDs.isEmpty {
                    selectedPlantIDs = Set(plants.map { $0.id })
                }
            }
        }
    }
    
    private var applyScopeControls: some View {
        Section {
            Picker("Apply to", selection: $applyToAllPlants) {
                Text("All plants").tag(true)
                Text("Choose plant").tag(false)
            }
            .pickerStyle(.segmented)
            
            Picker("Recurrence", selection: $recurrence) {
                Text("Monthly").tag(RecurrencePattern.monthly)
                Text("Once").tag(RecurrencePattern.custom)
            }
            .pickerStyle(.segmented)
            
            if !applyToAllPlants, !plants.isEmpty {
                ForEach(plants, id: \.id) { plant in
                    Button {
                        toggleSelection(for: plant.id)
                    } label: {
                        HStack {
                            Text(plant.nickname)
                            Spacer()
                            Image(systemName: selectedPlantIDs.contains(plant.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedPlantIDs.contains(plant.id) ? BotanicaTheme.Colors.primary : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Text("Apply reminders to")
                .font(BotanicaTheme.Typography.subheadline)
        }
    }
}

private struct SeasonalCareSection: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let tasks: [SeasonalTask]
    
    static let sampleData: [SeasonalCareSection] = [
        SeasonalCareSection(
            title: "Fall",
            summary: "Reduce watering gradually, stop fertilizing, prepare for dormancy.",
            tasks: [
                SeasonalTask(title: "Reduce watering", detail: "Cut watering by 25-50% for most tropicals.", icon: "drop.fill", iconColor: BotanicaTheme.Colors.waterBlue, careType: .watering),
                SeasonalTask(title: "Pause fertilizer", detail: "Stop feeding until spring growth resumes.", icon: "leaf.arrow.circlepath", iconColor: BotanicaTheme.Colors.leafGreen, careType: .fertilizing),
                SeasonalTask(title: "Light & temp", detail: "Move closer to windows, avoid drafts.", icon: "sun.max.fill", iconColor: BotanicaTheme.Colors.sunYellow, careType: .inspection)
            ]
        ),
        SeasonalCareSection(
            title: "Winter",
            summary: "Protect from drafts, monitor watering, increase humidity.",
            tasks: [
                SeasonalTask(title: "Draft protection", detail: "Keep leaves away from vents/windows.", icon: "wind", iconColor: .cyan, careType: .inspection),
                SeasonalTask(title: "Humidity boost", detail: "Use trays or a humidifier near dry plants.", icon: "aqi.medium", iconColor: BotanicaTheme.Colors.waterBlue, careType: .misting),
                SeasonalTask(title: "Water carefully", detail: "Only when soil is dry, avoid cold water.", icon: "drop.triangle.fill", iconColor: .blue, careType: .watering)
            ]
        ),
        SeasonalCareSection(
            title: "Spring",
            summary: "Resume feeding, check roots, refresh soil for active growth.",
            tasks: [
                SeasonalTask(title: "Resume fertilizing", detail: "Light feed every 4–6 weeks.", icon: "leaf.fill", iconColor: BotanicaTheme.Colors.leafGreen, careType: .fertilizing),
                SeasonalTask(title: "Repot check", detail: "Assess pot-bound plants and refresh soil.", icon: "flowerpot.fill", iconColor: BotanicaTheme.Colors.soilBrown, careType: .repotting),
                SeasonalTask(title: "Prune & clean", detail: "Trim leggy growth and wipe leaves.", icon: "scissors", iconColor: BotanicaTheme.Colors.nutrientOrange, careType: .pruning)
            ]
        ),
        SeasonalCareSection(
            title: "Summer",
            summary: "Manage heat and light; water consistently during active growth.",
            tasks: [
                SeasonalTask(title: "Consistent watering", detail: "Top up when top inch is dry.", icon: "drop.circle.fill", iconColor: BotanicaTheme.Colors.waterBlue, careType: .watering),
                SeasonalTask(title: "Sun management", detail: "Shift away from harsh midday sun.", icon: "sun.max.fill", iconColor: BotanicaTheme.Colors.sunYellow, careType: .inspection),
                SeasonalTask(title: "Pest checks", detail: "Inspect weekly for mites and scale.", icon: "ant.fill", iconColor: .red, careType: .inspection)
            ]
        )
    ]
}

private struct SeasonalTask {
    let title: String
    let detail: String
    let icon: String
    let iconColor: Color
    let careType: CareType
}

private extension SeasonalCareGuidanceView {
    func addReminder(for task: SeasonalTask) {
        let targetPlants: [Plant] = {
            if applyToAllPlants || plants.isEmpty {
                return plants
            } else {
                return plants.filter { selectedPlantIDs.contains($0.id) }
            }
        }()
        
        for plant in targetPlants {
            let reminder = Reminder(
                taskType: task.careType,
                recurrence: recurrence,
                notificationTime: Date(),
                customMessage: "\(task.title) – \(task.detail)"
            )
            reminder.plant = plant
            modelContext.insert(reminder)
        }
    }
    
    func toggleSelection(for id: UUID) {
        if selectedPlantIDs.contains(id) {
            selectedPlantIDs.remove(id)
        } else {
            selectedPlantIDs.insert(id)
        }
    }
}

#Preview("With Data") {
    AnalyticsView()
        .modelContainer(MockDataGenerator.previewContainer())
}

#Preview("Empty State") {
    AnalyticsView()
        .modelContainer(for: [Plant.self, CareEvent.self, Reminder.self, Photo.self, CarePlan.self], inMemory: true)
}
