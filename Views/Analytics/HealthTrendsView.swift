import SwiftUI
import SwiftData
import Charts

// MARK: - Health Trends Detail View
struct HealthTrendsView: View {
    @Query private var plants: [Plant]
    @Query private var careEvents: [CareEvent]
    @StateObject private var analytics = AdvancedAnalytics()
    @State private var healthTrends: [AdvancedAnalytics.HealthTrend] = []
    @State private var healthInsights: [AdvancedAnalytics.PlantHealthInsight] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Health Trends")
                        .font(.largeTitle.bold())
                    
                    Text("Collection health patterns and insights")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                // Health Score Trend Chart
                healthTrendChart
                
                // Key Metrics Cards
                healthMetricsGrid
                
                // Health Insights
                healthInsightsSection
                
                // Species Performance
                speciesPerformanceSection
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            loadHealthData()
        }
    }
    
    private var healthTrendChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("30-Day Health Trend")
                .font(.title2.bold())
                .padding(.horizontal)
            
            Chart {
                ForEach(healthTrends, id: \.date) { trend in
                    LineMark(
                        x: .value("Date", trend.date),
                        y: .value("Health Score", trend.overallScore)
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Date", trend.date),
                        y: .value("Health Score", trend.overallScore)
                    )
                    .foregroundStyle(.green.opacity(0.2))
                }
            }
            .frame(height: 200)
            .chartYScale(domain: 0...10)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                        }
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }
    
    private var healthMetricsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            MetricCard(
                title: "Avg Health Score",
                value: String(format: "%.1f", currentHealthScore),
                subtitle: "Collection average",
                color: .green,
                icon: "heart.fill"
            )
            
            MetricCard(
                title: "Recovery Rate",
                value: "\(Int(recoveryRate * 100))%",
                subtitle: "Plants improving",
                color: .blue,
                icon: "arrow.up.circle.fill"
            )
            
            MetricCard(
                title: "Issues Detected",
                value: "\(currentIssueCount)",
                subtitle: "Needs attention",
                color: currentIssueCount > 0 ? .orange : .green,
                icon: "exclamationmark.triangle.fill"
            )
            
            MetricCard(
                title: "Care Frequency",
                value: String(format: "%.1f/week", careFrequency),
                subtitle: "Average care events",
                color: .purple,
                icon: "calendar.circle.fill"
            )
        }
        .padding(.horizontal)
    }
    
    private var healthInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Insights")
                .font(.title2.bold())
                .padding(.horizontal)
            
            ForEach(healthInsights, id: \.title) { insight in
                InsightCard(insight: insight)
                    .padding(.horizontal)
            }
        }
    }
    
    private var speciesPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Species Performance")
                .font(.title2.bold())
                .padding(.horizontal)
            
            let speciesData = getSpeciesPerformanceData()
            
            ForEach(speciesData, id: \.species) { data in
                SpeciesPerformanceRow(data: data)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Views
    private struct MetricCard: View {
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
                    .font(.title.bold())
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
    
    private struct InsightCard: View {
        let insight: AdvancedAnalytics.PlantHealthInsight
        
        var body: some View {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(insight.severity.color))
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.headline)
                    
                    Text(insight.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if insight.actionable {
                    Button("Fix") {
                        // Handle insight action
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private struct SpeciesPerformanceRow: View {
        let data: SpeciesPerformanceData
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(data.species)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(data.count) plants")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Health Score")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f", data.avgHealth))
                        .font(.subheadline.bold())
                        .foregroundStyle(data.avgHealth > 7 ? .green : data.avgHealth > 4 ? .orange : .red)
                }
                
                ProgressView(value: data.avgHealth / 10.0)
                    .tint(data.avgHealth > 7 ? .green : data.avgHealth > 4 ? .orange : .red)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Data Loading
    private func loadHealthData() {
        healthTrends = analytics.analyzeHealthTrends(plants: plants, careEvents: careEvents)
        healthInsights = analytics.generateHealthInsights(plants: plants, careEvents: careEvents)
    }
    
    // MARK: - Computed Properties
    private var currentHealthScore: Double {
        let scores = plants.compactMap { $0.healthScore }
        return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }
    
    private var recoveryRate: Double {
        let healthyPlants = plants.filter { $0.healthScore >= 7 }.count
        return Double(healthyPlants) / Double(max(plants.count, 1))
    }
    
    private var currentIssueCount: Int {
        plants.filter { $0.healthScore < 4 }.count
    }
    
    private var careFrequency: Double {
        let recentCareEvents = careEvents.filter { event in
            event.date > Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        }
        return Double(recentCareEvents.count) / 7.0
    }
    
    private func getSpeciesPerformanceData() -> [SpeciesPerformanceData] {
        let speciesGroups = Dictionary(grouping: plants) { $0.scientificName.isEmpty ? "Unknown" : $0.scientificName }
        
        let performanceData = speciesGroups.compactMap { species, plants -> SpeciesPerformanceData? in
            guard !plants.isEmpty else { return nil }
            let totalHealth = plants.map { $0.healthScore }.reduce(0, +)
            let avgHealth = totalHealth / Double(plants.count)
            return SpeciesPerformanceData(species: species, count: plants.count, avgHealth: avgHealth)
        }
        
        return performanceData.sorted { $0.avgHealth > $1.avgHealth }
    }
}

private struct SpeciesPerformanceData {
    let species: String
    let count: Int
    let avgHealth: Double
}