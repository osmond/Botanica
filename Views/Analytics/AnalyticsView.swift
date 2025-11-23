import SwiftUI
import SwiftData
import Charts

// MARK: - Plant Performance Analytics
struct PlantHealthMetrics {
    let careConsistency: Double
    let growthRate: Double
    let seasonalAdaptation: Double
    let overallHealth: Double
    let trend: UIHealthTrend
    
    var performanceGrade: String {
        let average = (careConsistency + growthRate + seasonalAdaptation + overallHealth) / 4.0
        switch average {
        case 0.9...1.0: return "A+"
        case 0.8..<0.9: return "A"
        case 0.7..<0.8: return "B+"
        case 0.6..<0.7: return "B"
        case 0.5..<0.6: return "C"
        default: return "D"
        }
    }
}

enum UIHealthTrend {
    case improving
    case stable
    case declining
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.circle.fill"
        case .stable: return "minus.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return BotanicaTheme.Colors.success
        case .stable: return BotanicaTheme.Colors.waterBlue
        case .declining: return BotanicaTheme.Colors.warning
        }
    }
    
    var accessibilityDescription: String {
        switch self {
        case .improving: return "improving"
        case .stable: return "stable"
        case .declining: return "declining"
        }
    }
}

/// Advanced Analytics view providing botanical insights, plant care optimization,
/// seasonal care guidance, and predictive plant health analytics
struct AnalyticsView: View {
    @Query private var plants: [Plant]
    @Query private var careEvents: [CareEvent]
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var selectedTimeRange: AnalyticsTimeRange = .month
    @State private var showingSeasonalGuidance = false
    @State private var selectedPlantForDetails: Plant?
    @State private var showingAdvancedAnalytics = false

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
                            Text("Crunching health and care trends")
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
                            LazyVStack(spacing: BotanicaTheme.Spacing.lg) {
                                // Hero Section with Collection Health Score
                                collectionHealthHero
                                
                                // Time range selector
                                modernTimeRangeSelector
                                
                                // Seasonal Botanical Guidance
                                seasonalGuidanceCard
                                
                                // Advanced Analytics Quick Access
                                advancedAnalyticsSection
                                
                                // Plant Performance Dashboard
                                plantPerformanceDashboard
                                
                                // Care Effectiveness Analytics
                                careEffectivenessSection
                                
                                // Health & Growth Trends
                                healthTrendsSection
                                
                                // Species-Specific Insights
                                speciesInsightsSection
                                
                                // Botanical Achievements
                                botanicalAchievementsSection
                                
                                // Smart Recommendations
                                smartRecommendationsSection
                            }
                            .padding(.horizontal, BotanicaTheme.Spacing.lg)
                            .padding(.top, BotanicaTheme.Spacing.md)
                            .padding(.bottom, BotanicaTheme.Spacing.jumbo)
                        }
                        .safeAreaInset(edge: .bottom) {
                            Color.clear.frame(height: 120)
                        }
                    }
                }
            )
            .navigationTitle("Plant Analytics")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingSeasonalGuidance) {
                SeasonalCareGuidanceView()
            }
            .sheet(item: $selectedPlantForDetails) { plant in
                PlantDetailAnalyticsView(plant: plant)
            }
            .sheet(isPresented: $showingAdvancedAnalytics) {
                AdvancedAnalyticsView()
            }
            .task(id: selectedTimeRange) {
                viewModel.refresh(plants: plants, careEvents: careEvents, range: selectedTimeRange)
            }
            .onChange(of: plants.count) { _, _ in
                viewModel.refresh(plants: plants, careEvents: careEvents, range: selectedTimeRange)
            }
            .onChange(of: careEvents.count) { _, _ in
                viewModel.refresh(plants: plants, careEvents: careEvents, range: selectedTimeRange)
            }
        }
    }
    
    // MARK: - Modern Botanical Analytics Components
    
    private var collectionHealthHero: some View {
        VStack(spacing: BotanicaTheme.Spacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                    Text("Collection Health Score")
                        .font(BotanicaTheme.Typography.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("\(String(format: "%.0f", collectionHealthScore))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(healthScoreColor)
                    
                    Text(collectionHealthGrade)
                        .font(BotanicaTheme.Typography.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(healthScoreColor)
                }
                
                Spacer()
                
                VStack(spacing: BotanicaTheme.Spacing.sm) {
                    Circle()
                        .trim(from: 0, to: collectionHealthScore / 100)
                        .stroke(healthScoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .background(
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        )
                    
                    Text("\(plants.count) Plants")
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: BotanicaTheme.Spacing.lg) {
                HealthMetricPill(
                    title: "Thriving",
                    count: healthyPlantsCount,
                    color: BotanicaTheme.Colors.success,
                    icon: "heart.fill"
                )
                
                HealthMetricPill(
                    title: "Attention",
                    count: attentionNeededCount,
                    color: BotanicaTheme.Colors.warning,
                    icon: "exclamationmark.triangle.fill"
                )
                
                HealthMetricPill(
                    title: "Care Streak",
                    count: currentCareStreak,
                    color: BotanicaTheme.Colors.nutrientOrange,
                    icon: "flame.fill"
                )
            }
        }
        .cardStyle()
    }
    
    private var modernTimeRangeSelector: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            Text("Analysis Period")
                .font(BotanicaTheme.Typography.headline)
                .fontWeight(.semibold)
            
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(AnalyticsTimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue)
                        .tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
        .cardStyle()
        .accessibilityLabel("Analysis period selector")
    }
    
    private var seasonalGuidanceCard: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                    Text("\(BotanicalSeason.current.rawValue) Care Guide")
                        .font(BotanicaTheme.Typography.title3)
                        .fontWeight(.semibold)
                    
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
                    Text("View Seasonal Care Calendar")
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
    }
    
    private var advancedAnalyticsSection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            Text("Advanced Analytics")
                .font(BotanicaTheme.Typography.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: BotanicaTheme.Spacing.md) {
                
                // ML Analytics - Predictive care insights
                NavigationLink(destination: MLAnalyticsView()) {
                    AdvancedFeatureCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "ML Analytics",
                        description: "Predictive care insights",
                        color: BotanicaTheme.Colors.primary
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Collection Health Trends
                NavigationLink(destination: HealthTrendsView()) {
                    AdvancedFeatureCard(
                        icon: "heart.text.square",
                        title: "Health Trends",
                        description: "Collection health analysis",
                        color: Color.pink
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Environmental Analytics
                NavigationLink(destination: EnvironmentAnalyticsView()) {
                    AdvancedFeatureCard(
                        icon: "thermometer.sun.fill",
                        title: "Environment",
                        description: "Seasonal impact analysis",
                        color: BotanicaTheme.Colors.sunYellow
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Growth Pattern Analysis
                NavigationLink(destination: GrowthPatternsView()) {
                    AdvancedFeatureCard(
                        icon: "chart.bar.fill",
                        title: "Growth Patterns",
                        description: "Long-term growth analysis",
                        color: BotanicaTheme.Colors.leafGreen
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .cardStyle()
        .accessibilityLabel("Advanced analytics section")
    }
    
    private var plantPerformanceDashboard: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            HStack {
                Text("Plant Performance")
                    .font(BotanicaTheme.Typography.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("View All") {
                    // Show detailed performance view
                }
                .font(BotanicaTheme.Typography.callout)
                .foregroundColor(BotanicaTheme.Colors.primary)
            }
            
            if plants.isEmpty {
                EmptyStateCard(
                    icon: "chart.bar.fill",
                    title: "No Performance Data",
                    description: "Add plants and care events to see performance analytics"
                )
            } else {
                let top4 = Array(topPerformingPlants.prefix(4))
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: BotanicaTheme.Spacing.md) {
                    ForEach(top4, id: \.id) { plant in
                        PlantPerformanceCard(
                            plant: plant,
                            metrics: generatePlantMetrics(for: plant)
                        ) {
                            selectedPlantForDetails = plant
                        }
                    }
                }
            }
        }
        .cardStyle()
        .accessibilityLabel("Plant performance overview")
    }
    
    private var careEffectivenessSection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            Text("Care Effectiveness")
                .font(BotanicaTheme.Typography.title2)
                .fontWeight(.bold)
            
            if plants.isEmpty || careEvents.isEmpty {
                EmptyStateCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "No Care Data",
                    description: "Start caring for your plants to see effectiveness trends"
                )
            } else {
                VStack(spacing: BotanicaTheme.Spacing.lg) {
                    // Care completion rate chart
                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                        HStack {
                            Text("Care Completion Rate")
                                .font(BotanicaTheme.Typography.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text("\(String(format: "%.0f", averageCompletionRate * 100))%")
                                .font(BotanicaTheme.Typography.title3)
                                .fontWeight(.bold)
                                .foregroundColor(BotanicaTheme.Colors.success)
                        }
                        
                        Chart(completionData) { dataPoint in
                            LineMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Rate", dataPoint.completionRate * 100)
                            )
                            .foregroundStyle(BotanicaTheme.Colors.primary)
                            .symbol(.circle)
                            
                            AreaMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Rate", dataPoint.completionRate * 100)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [BotanicaTheme.Colors.primary.opacity(0.2), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .chartYScale(domain: 0...100)
                        .chartYAxis {
                            AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let intValue = value.as(Int.self) {
                                        Text("\(intValue)%")
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        .frame(height: 180)
                    }
                    .padding(BotanicaTheme.Spacing.lg)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    // Care type effectiveness
                    CareTypeEffectivenessGrid(careEvents: careEventsInRange)
                }
            }
        }
        .cardStyle()
        .accessibilityLabel("Care effectiveness")
    }
    
    private var healthTrendsSection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            Text("Health & Growth Trends")
                .font(BotanicaTheme.Typography.title2)
                .fontWeight(.bold)
            
            if plants.isEmpty {
                EmptyStateCard(
                    icon: "heart.text.square",
                    title: "No Health Data",
                    description: "Track your plants' health over time to see trends"
                )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: BotanicaTheme.Spacing.md) {
                    HealthTrendCard(
                        title: "Improving",
                        count: healthTrendCounts.improving,
                        color: BotanicaTheme.Colors.success,
                        icon: "arrow.up.circle.fill"
                    )
                    
                    HealthTrendCard(
                        title: "Stable",
                        count: healthTrendCounts.stable,
                        color: BotanicaTheme.Colors.waterBlue,
                        icon: "minus.circle.fill"
                    )
                    
                    HealthTrendCard(
                        title: "Declining",
                        count: healthTrendCounts.declining,
                        color: BotanicaTheme.Colors.warning,
                        icon: "arrow.down.circle.fill"
                    )
                }
            }
        }
        .cardStyle()
        .accessibilityLabel("Health and growth trends")
    }
    
    private var speciesInsightsSection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            Text("Species Insights")
                .font(BotanicaTheme.Typography.title2)
                .fontWeight(.bold)
            
            if plants.isEmpty {
                EmptyStateCard(
                    icon: "leaf.arrow.triangle.circlepath",
                    title: "No Species Data",
                    description: "Add plants to see species-specific care insights"
                )
            } else {
                VStack(spacing: BotanicaTheme.Spacing.md) {
                    ForEach(topSpeciesInsights, id: \.species) { insight in
                        SpeciesInsightCard(insight: insight)
                    }
                }
            }
        }
        .cardStyle()
        .accessibilityLabel("Species insights")
    }
    
    private var botanicalAchievementsSection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            HStack {
                Text("Botanical Achievements")
                    .font(BotanicaTheme.Typography.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(botanicalAchievements.filter { $0.isUnlocked }.count)/\(botanicalAchievements.count)")
                    .font(BotanicaTheme.Typography.callout)
                    .foregroundColor(.secondary)
            }
            
            let topAchievements = Array(botanicalAchievements.prefix(6))
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: BotanicaTheme.Spacing.md) {
                ForEach(topAchievements, id: \.title) { achievement in
                    BotanicalAchievementCard(achievement: achievement)
                }
            }
        }
        .cardStyle()
        .accessibilityLabel("Botanical achievements")
    }
    
    private var smartRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            Text("Smart Recommendations")
                .font(BotanicaTheme.Typography.title2)
                .fontWeight(.bold)
            
            VStack(spacing: BotanicaTheme.Spacing.md) {
                ForEach(smartRecommendations, id: \.title) { recommendation in
                    SmartRecommendationCard(recommendation: recommendation)
                }
            }
        }
        .cardStyle()
        .accessibilityLabel("Smart recommendations")
    }
    
    // MARK: - Botanical Analytics Data Processing
    
    private var careEventsInRange: [CareEvent] {
        return careEvents.filter { $0.date >= selectedTimeRange.startDate }
    }
    
    private var collectionHealthScore: Double {
        viewModel.snapshot?.summary.healthScore ?? 0
    }
    
    private var collectionHealthGrade: String {
        switch collectionHealthScore {
        case 90...100: return "Exceptional Care"
        case 80..<90: return "Excellent Care"
        case 70..<80: return "Good Care"
        case 60..<70: return "Needs Attention"
        default: return "Needs Improvement"
        }
    }
    
    private var healthScoreColor: Color {
        switch collectionHealthScore {
        case 80...100: return BotanicaTheme.Colors.success
        case 60..<80: return BotanicaTheme.Colors.warning
        default: return BotanicaTheme.Colors.error
        }
    }
    
    private var healthyPlantsCount: Int { viewModel.snapshot?.summary.healthyCount ?? 0 }
    
    private var attentionNeededCount: Int { viewModel.snapshot?.summary.attentionCount ?? 0 }
    
    private var topPerformingPlants: [Plant] {
        plants.sorted { $0.healthScore > $1.healthScore }
    }
    
    private var currentSeasonIcon: String {
        switch BotanicalSeason.current {
        case .spring: return "leaf.fill"
        case .summer: return "sun.max.fill"
        case .fall: return "leaf.circle.fill"
        case .winter: return "snowflake"
        }
    }
    
    private var currentCareStreak: Int { viewModel.snapshot?.summary.careStreak ?? 0 }
    
    private var completionData: [CompletionDataPoint] {
        viewModel.snapshot?.completionData ?? []
    }
    
    private var averageCompletionRate: Double {
        viewModel.snapshot?.averageCompletionRate ?? 0
    }
    
    private var healthTrendCounts: HealthTrendBreakdown {
        viewModel.snapshot?.healthTrends ?? HealthTrendBreakdown(improving: 0, stable: 0, declining: 0)
    }
    
    // MARK: - Plant Analysis Functions
    
    private func generatePlantMetrics(for plant: Plant) -> PlantHealthMetrics {
        let careConsistency = calculateCareConsistency(for: plant)
        let growthRate = calculateGrowthRate(for: plant)
        let seasonalAdaptation = calculateSeasonalAdaptation(for: plant)
        let trend = determineTrend(for: plant)
        
        return PlantHealthMetrics(
            careConsistency: careConsistency,
            growthRate: growthRate,
            seasonalAdaptation: seasonalAdaptation,
            overallHealth: plant.healthScore,
            trend: trend
        )
    }
    
    private func calculateCareConsistency(for plant: Plant) -> Double {
        let calendar = Calendar.current
        let windowStart = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentEvents = plant.careEvents.filter { $0.date >= windowStart }
        // Expected watering + fertilizing events over 30 days
        let expectedWater = plant.wateringFrequency > 0 ? 30.0 / Double(plant.wateringFrequency) : 0
        let expectedFertilize = plant.fertilizingFrequency > 0 ? 30.0 / Double(plant.fertilizingFrequency) : 0
        let expectedEvents = max(expectedWater + expectedFertilize, 1.0)
        return min(Double(recentEvents.count) / expectedEvents, 1.0)
    }
    
    private func calculateGrowthRate(for plant: Plant) -> Double {
        // Use normalized health score as a proxy for growth stability
        return min(max(plant.healthScore, 0.0), 1.0)
    }
    
    private func calculateSeasonalAdaptation(for plant: Plant) -> Double {
        // Rough heuristic: align light level with season
        let season = BotanicalSeason.current
        switch (season, plant.lightLevel) {
        case (.summer, .bright), (.summer, .direct), (.spring, .bright), (.spring, .medium):
            return 0.9
        case (.winter, .low), (.winter, .medium):
            return 0.85
        default:
            return 0.75
        }
    }
    
    private func determineTrend(for plant: Plant) -> UIHealthTrend {
        switch plant.healthStatus {
        case .excellent, .healthy: return .improving
        case .fair: return .stable
        case .poor, .critical: return .declining
        }
    }
    
    private var topSpeciesInsights: [SpeciesInsight] {
        viewModel.snapshot?.speciesInsights ?? []
    }
    
    private var botanicalAchievements: [BotanicalAchievement] {
        var achievements: [BotanicalAchievement] = []
        
        achievements.append(BotanicalAchievement(
            title: "Plant Parent",
            description: "Care for your first plant",
            icon: "leaf.fill",
            isUnlocked: plants.count >= 1,
            category: .collection
        ))
        
        achievements.append(BotanicalAchievement(
            title: "Green Collector",
            description: "Own 5 plants",
            icon: "hand.raised.fill",
            isUnlocked: plants.count >= 5,
            category: .collection
        ))
        
        achievements.append(BotanicalAchievement(
            title: "Plant Whisperer",
            description: "Maintain 90%+ health across collection",
            icon: "heart.circle.fill",
            isUnlocked: collectionHealthScore >= 90,
            category: .care
        ))
        
        achievements.append(BotanicalAchievement(
            title: "Streak Master",
            description: "30-day care streak",
            icon: "flame.fill",
            isUnlocked: currentCareStreak >= 30,
            category: .consistency
        ))
        
        achievements.append(BotanicalAchievement(
            title: "Species Expert",
            description: "Care for 3+ different species",
            icon: "books.vertical.fill",
            isUnlocked: Set(plants.map { $0.scientificName }).count >= 3,
            category: .knowledge
        ))
        
        achievements.append(BotanicalAchievement(
            title: "Season Sage",
            description: "Adapt care for all seasons",
            icon: "calendar.circle.fill",
            isUnlocked: hasSeasonalCareAdaptation,
            category: .knowledge
        ))
        
        return achievements
    }
    
    private var hasSeasonalCareAdaptation: Bool {
        return careEvents.count > 50 // Simplified check
    }
    
    private var smartRecommendations: [SmartRecommendation] {
        var recommendations: [SmartRecommendation] = []
        
        let season = BotanicalSeason.current
        recommendations.append(SmartRecommendation(
            title: "Seasonal Adjustment",
            description: season.careModifications,
            priority: .high,
            icon: currentSeasonIcon,
            action: "Adjust care schedule for \(season.rawValue.lowercased())"
        ))
        
        if attentionNeededCount > 0 {
            recommendations.append(SmartRecommendation(
                title: "Health Alert",
                description: "\(attentionNeededCount) plants need immediate attention",
                priority: .high,
                icon: "exclamationmark.triangle.fill",
                action: "Review plant health status"
            ))
        }
        
        if averageCompletionRate < 0.8 {
            recommendations.append(SmartRecommendation(
                title: "Improve Consistency",
                description: "Set up reminders to maintain regular care schedule",
                priority: .medium,
                icon: "bell.fill",
                action: "Enable smart notifications"
            ))
        }
        
        if collectionHealthScore > 80 {
            recommendations.append(SmartRecommendation(
                title: "Expansion Ready",
                description: "Your plants are thriving! Consider adding new species",
                priority: .low,
                icon: "plus.circle.fill",
                action: "Explore new plant varieties"
            ))
        }
        
        return recommendations
    }
}

enum AchievementCategory {
    case collection, care, consistency, knowledge
}

struct BotanicalAchievement {
    let title: String
    let description: String
    let icon: String
    let isUnlocked: Bool
    let category: AchievementCategory
}

enum UIRecommendationPriority {
    case high, medium, low
    
    var color: Color {
        switch self {
        case .high: return BotanicaTheme.Colors.error
        case .medium: return BotanicaTheme.Colors.warning
        case .low: return BotanicaTheme.Colors.waterBlue
        }
    }
}

struct SmartRecommendation {
    let title: String
    let description: String
    let priority: UIRecommendationPriority
    let icon: String
    let action: String
}

// MARK: - Supporting Views

struct HealthMetricPill: View {
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

struct AdvancedFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: BotanicaTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            VStack(spacing: BotanicaTheme.Spacing.xs) {
                Text(title)
                    .font(BotanicaTheme.Typography.callout)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(BotanicaTheme.Spacing.lg)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct PlantPerformanceCard: View {
    let plant: Plant
    let metrics: PlantHealthMetrics
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plant.nickname)
                            .font(BotanicaTheme.Typography.callout)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(plant.scientificName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(metrics.performanceGrade)
                            .font(BotanicaTheme.Typography.title3)
                            .fontWeight(.bold)
                            .foregroundColor(gradeColor(metrics.performanceGrade))
                        
                        Image(systemName: metrics.trend.icon)
                            .font(.caption)
                            .foregroundColor(metrics.trend.color)
                    }
                }
                
                ProgressView(value: metrics.overallHealth)
                    .progressViewStyle(LinearProgressViewStyle(tint: gradeColor(metrics.performanceGrade)))
                    .scaleEffect(y: 0.5)
            }
            .padding(BotanicaTheme.Spacing.md)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium))
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(plant.nickname). Grade \(metrics.performanceGrade). Health trend \(metrics.trend.accessibilityDescription)")
    }
    
    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "A+", "A": return BotanicaTheme.Colors.success
        case "B+", "B": return BotanicaTheme.Colors.waterBlue
        case "C": return BotanicaTheme.Colors.warning
        default: return BotanicaTheme.Colors.error
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

struct HealthTrendCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: BotanicaTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(BotanicaTheme.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(BotanicaTheme.Spacing.md)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title). \(count) plants")
    }
}

// Simplified supporting views to avoid bloating
struct SpeciesInsightCard: View {
    let insight: SpeciesInsight
    
    var body: some View {
        Text("Species insights for \(insight.species) coming soon!")
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct BotanicalAchievementCard: View {
    let achievement: BotanicalAchievement
    
    var body: some View {
        VStack {
            Image(systemName: achievement.icon)
                .foregroundColor(achievement.isUnlocked ? .green : .gray)
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(achievement.title). \(achievement.isUnlocked ? "Unlocked" : "Locked") achievement")
    }
}

struct SmartRecommendationCard: View {
    let recommendation: SmartRecommendation
    
    var body: some View {
        HStack {
            Image(systemName: recommendation.icon)
                .foregroundColor(recommendation.priority.color)
            VStack(alignment: .leading) {
                Text(recommendation.title)
                    .font(.headline)
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(recommendation.title). \(recommendation.description)")
    }
}

// Placeholder sheet views
struct SeasonalCareGuidanceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Seasonal care guidance coming soon!")
                .navigationTitle("Seasonal Care")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

struct PlantDetailAnalyticsView: View {
    let plant: Plant
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Plant analytics for \(plant.nickname) coming soon!")
                .navigationTitle(plant.nickname)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
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
