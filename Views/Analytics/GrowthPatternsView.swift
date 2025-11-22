import SwiftUI
import SwiftData
import Charts

// MARK: - Growth Patterns Detail View
struct GrowthPatternsView: View {
    @Query private var plants: [Plant]
    @Query private var careEvents: [CareEvent]
    @StateObject private var analytics = AdvancedAnalytics()
    @State private var growthMetrics: [AdvancedAnalytics.GrowthMetrics] = []
    @State private var growthInsights: [AdvancedAnalytics.GrowthInsight] = []
    @State private var selectedTimeframe: GrowthTimeframe = .sixMonths
    
    enum GrowthTimeframe: String, CaseIterable {
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1Y"
        case allTime = "All"
        
        var displayName: String {
            switch self {
            case .threeMonths: return "3 Months"
            case .sixMonths: return "6 Months"
            case .oneYear: return "1 Year"
            case .allTime: return "All Time"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Growth Patterns")
                        .font(.largeTitle.bold())
                    
                    Text("Long-term growth analysis and predictions")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                // Timeframe Selector
                timeframeSelector
                
                // Growth Overview Cards
                growthOverviewCards
                
                // Growth Rate Chart
                growthRateChart
                
                // Seasonal Growth Patterns
                seasonalGrowthSection
                
                // Growth Insights
                growthInsightsSection
                
                // Individual Plant Growth
                individualPlantGrowthSection
                
                // Maturity Predictions
                maturityPredictionsSection
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            loadGrowthData()
        }
    }
    
    private var timeframeSelector: some View {
        HStack {
            ForEach(GrowthTimeframe.allCases, id: \.self) { timeframe in
                Button(timeframe.rawValue) {
                    selectedTimeframe = timeframe
                }
                .buttonStyle(.bordered)
                .foregroundStyle(selectedTimeframe == timeframe ? .white : .primary)
                .background(selectedTimeframe == timeframe ? .green : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var growthOverviewCards: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            OverviewCard(
                title: "Avg Growth Rate",
                value: String(format: "%.1f cm/mo", averageGrowthRate),
                subtitle: "Collection average",
                color: .green,
                icon: "arrow.up.circle.fill"
            )
            
            OverviewCard(
                title: "Fastest Grower",
                value: fastestGrowingPlant?.scientificName ?? "N/A",
                subtitle: String(format: "%.1f cm/mo", fastestGrowthRate),
                color: .blue,
                icon: "speedometer"
            )
            
            OverviewCard(
                title: "Spring Growth",
                value: "\(Int(springGrowthBoost * 100))%",
                subtitle: "Seasonal boost",
                color: .orange,
                icon: "leaf.fill"
            )
            
            OverviewCard(
                title: "Care Impact",
                value: "\(Int(careImpactScore * 100))%",
                subtitle: "Growth correlation",
                color: .purple,
                icon: "heart.fill"
            )
        }
        .padding(.horizontal)
    }
    
    private var growthRateChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Growth Rate Trends")
                .font(.title2.bold())
                .padding(.horizontal)
            
            Chart {
                ForEach(topGrowingPlants, id: \.plantId) { metrics in
                    if let plant = plants.first(where: { $0.id == metrics.plantId }) {
                        BarMark(
                            x: .value("Growth Rate", metrics.growthRate),
                            y: .value("Plant", plant.nickname)
                        )
                        .foregroundStyle(.green.gradient)
                        .cornerRadius(4)
                    }
                }
            }
            .frame(height: 200)
            .chartXAxisLabel("Growth Rate (cm/month)")
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }
    
    private var seasonalGrowthSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Seasonal Growth Patterns")
                .font(.title2.bold())
                .padding(.horizontal)
            
            Chart {
                ForEach(BotanicalSeason.allCases, id: \.self) { season in
                    BarMark(
                        x: .value("Season", season.rawValue),
                        y: .value("Growth Rate", getSeasonalGrowthRate(for: season))
                    )
                    .foregroundStyle(season.color.gradient)
                    .cornerRadius(6)
                }
            }
            .frame(height: 180)
            .chartYAxisLabel("Relative Growth Rate")
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }
    
    private var growthInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Growth Insights")
                .font(.title2.bold())
                .padding(.horizontal)
            
            ForEach(growthInsights, id: \.title) { insight in
                GrowthInsightCard(insight: insight)
                    .padding(.horizontal)
            }
        }
    }
    
    private var individualPlantGrowthSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Individual Plant Performance")
                .font(.title2.bold())
                .padding(.horizontal)
            
            let topMetrics = Array(growthMetrics.prefix(5))
            ForEach(topMetrics, id: \.plantId) { metrics in
                if let plant = plants.first(where: { $0.id == metrics.plantId }) {
                    PlantGrowthCard(plant: plant, metrics: metrics)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    private var maturityPredictionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Maturity Predictions")
                .font(.title2.bold())
                .padding(.horizontal)
            
            ForEach(upcomingMaturityPlants, id: \.plantId) { metrics in
                if let plant = plants.first(where: { $0.id == metrics.plantId }) {
                    MaturityPredictionCard(plant: plant, metrics: metrics)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private struct OverviewCard: View {
        let title: String
        let value: String
        let subtitle: String
        let color: Color
        let icon: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .font(.title2)
                    Spacer()
                }
                
                Text(value)
                    .font(.title2.bold())
                    .foregroundStyle(color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private struct GrowthInsightCard: View {
        let insight: AdvancedAnalytics.GrowthInsight
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title)
                            .font(.headline)
                        
                        Text(insight.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: trendIcon(for: insight.trend))
                            .foregroundStyle(trendColor(for: insight.trend))
                            .font(.title2)
                        
                        Text(insight.trend.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Divider()
                
                HStack {
                    Image(systemName: "crystal.ball.fill")
                        .foregroundStyle(.purple)
                        .font(.subheadline)
                    
                    Text(insight.prediction)
                        .font(.subheadline)
                        .italic()
                    
                    Spacer()
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        
        private func trendIcon(for trend: AdvancedAnalytics.GrowthTrend) -> String {
            switch trend {
            case .accelerating: return "arrow.up.right.circle.fill"
            case .steady: return "arrow.right.circle.fill"
            case .slowing: return "arrow.down.right.circle.fill"
            case .dormant: return "pause.circle.fill"
            }
        }
        
        private func trendColor(for trend: AdvancedAnalytics.GrowthTrend) -> Color {
            switch trend {
            case .accelerating: return .green
            case .steady: return .blue
            case .slowing: return .orange
            case .dormant: return .gray
            }
        }
    }
    
    private struct PlantGrowthCard: View {
        let plant: Plant
        let metrics: AdvancedAnalytics.GrowthMetrics
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plant.nickname)
                            .font(.headline)
                        
                        Text(metrics.species)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: "%.1f cm/mo", metrics.growthRate))
                            .font(.title3.bold())
                            .foregroundStyle(.green)
                        
                        Text("Growth Rate")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack {
                    ProgressView(value: metrics.healthCorrelation) {
                        Text("Health Impact: \(Int(metrics.healthCorrelation * 100))%")
                            .font(.caption)
                    }
                    .tint(.blue)
                    
                    Spacer()
                    
                    ProgressView(value: metrics.careImpact) {
                        Text("Care Impact: \(Int(metrics.careImpact * 100))%")
                            .font(.caption)
                    }
                    .tint(.purple)
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private struct MaturityPredictionCard: View {
        let plant: Plant
        let metrics: AdvancedAnalytics.GrowthMetrics
        
        var body: some View {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plant.nickname)
                        .font(.headline)
                    
                    Text("Expected maturity")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatMaturityTime(metrics.maturityEstimate))
                        .font(.title3.bold())
                        .foregroundStyle(.orange)
                    
                    Text("months remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Image(systemName: "clock.fill")
                    .foregroundStyle(.orange)
                    .font(.title2)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        
        private func formatMaturityTime(_ timeInterval: TimeInterval) -> String {
            let months = Int(timeInterval / (30 * 24 * 3600))
            return "\(months)"
        }
    }
    
    // MARK: - Data Loading
    private func loadGrowthData() {
        growthMetrics = analytics.analyzeGrowthPatterns(plants: plants, careEvents: careEvents)
        growthInsights = analytics.generateGrowthInsights(growthMetrics: growthMetrics, plants: plants)
    }
    
    // MARK: - Computed Properties
    private var averageGrowthRate: Double {
        let rates = growthMetrics.map { $0.growthRate }
        return rates.isEmpty ? 0 : rates.reduce(0, +) / Double(rates.count)
    }
    
    private var fastestGrowingPlant: Plant? {
        guard let fastestMetrics = growthMetrics.max(by: { $0.growthRate < $1.growthRate }) else { return nil }
        return plants.first { $0.id == fastestMetrics.plantId }
    }
    
    private var fastestGrowthRate: Double {
        growthMetrics.map { $0.growthRate }.max() ?? 0
    }
    
    private var springGrowthBoost: Double {
        let springRates = growthMetrics.compactMap { $0.seasonalVariation[.spring] }
        return springRates.isEmpty ? 0 : springRates.reduce(0, +) / Double(springRates.count)
    }
    
    private var careImpactScore: Double {
        let impacts = growthMetrics.map { $0.careImpact }
        return impacts.isEmpty ? 0 : impacts.reduce(0, +) / Double(impacts.count)
    }
    
    private var topGrowingPlants: [AdvancedAnalytics.GrowthMetrics] {
        Array(growthMetrics.sorted { $0.growthRate > $1.growthRate }.prefix(5))
    }
    
    private var upcomingMaturityPlants: [AdvancedAnalytics.GrowthMetrics] {
        growthMetrics.filter { metrics in
            let monthsToMaturity = metrics.maturityEstimate / (30 * 24 * 3600)
            return monthsToMaturity < 12 && monthsToMaturity > 1
        }.sorted { $0.maturityEstimate < $1.maturityEstimate }
    }
    
    private func getSeasonalGrowthRate(for season: BotanicalSeason) -> Double {
        let seasonalRates = growthMetrics.compactMap { $0.seasonalVariation[season] }
        return seasonalRates.isEmpty ? 0 : seasonalRates.reduce(0, +) / Double(seasonalRates.count)
    }
}