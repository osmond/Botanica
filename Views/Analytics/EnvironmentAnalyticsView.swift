import SwiftUI
import SwiftData
import Charts

// MARK: - Environment Analytics Detail View
struct EnvironmentAnalyticsView: View {
    @Query private var plants: [Plant]
    @Query private var careEvents: [CareEvent]
    @StateObject private var analytics = AdvancedAnalytics()
    @State private var environmentalImpacts: [AdvancedAnalytics.EnvironmentalImpact] = []
    @State private var locationAnalyses: [AdvancedAnalytics.LocationAnalysis] = []
    @State private var selectedSeason: BotanicalSeason = BotanicalSeason.current
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Environment Analytics")
                        .font(.largeTitle.bold())
                    
                    Text("Seasonal and location performance insights")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                // Current Season Overview
                currentSeasonCard
                
                // Seasonal Performance Chart
                seasonalPerformanceChart
                
                // Location Performance
                locationPerformanceSection
                
                // Environmental Recommendations
                environmentalRecommendationsSection
                
                // Climate Impact Predictions
                climateImpactSection
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            loadEnvironmentData()
        }
    }
    
    private var currentSeasonCard: some View {
        let currentImpact = environmentalImpacts.first { $0.season == BotanicalSeason.current }
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: BotanicalSeason.current.icon)
                            .font(.title2)
                            .foregroundStyle(BotanicalSeason.current.color)
                        
                        Text(BotanicalSeason.current.rawValue)
                            .font(.title2.bold())
                    }
                    
                    Text("Current Season Performance")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.1f", currentImpact?.avgHealthScore ?? 0))
                        .font(.title.bold())
                        .foregroundStyle(.green)
                    
                    Text("Health Score")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let impact = currentImpact {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Optimal Conditions")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(impact.optimalConditions, id: \.self) { condition in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                
                                Text(condition)
                                    .font(.caption)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private var seasonalPerformanceChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Seasonal Performance Comparison")
                .font(.title2.bold())
                .padding(.horizontal)
            
            Chart {
                ForEach(environmentalImpacts, id: \.season) { impact in
                    BarMark(
                        x: .value("Season", impact.season.rawValue),
                        y: .value("Health Score", impact.avgHealthScore)
                    )
                    .foregroundStyle(impact.season.color)
                    .cornerRadius(6)
                }
            }
            .frame(height: 200)
            .chartYScale(domain: 0...10)
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }
    
    private var locationPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location Performance")
                .font(.title2.bold())
                .padding(.horizontal)
            
            ForEach(locationAnalyses, id: \.location) { analysis in
                LocationPerformanceCard(analysis: analysis)
                    .padding(.horizontal)
            }
        }
    }
    
    private var environmentalRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Environmental Recommendations")
                .font(.title2.bold())
                .padding(.horizontal)
            
            if let currentImpact = environmentalImpacts.first(where: { $0.season == BotanicalSeason.current }) {
                ForEach(currentImpact.recommendations, id: \.self) { recommendation in
                    RecommendationCard(recommendation: recommendation)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    private var climateImpactSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Climate Impact Predictions")
                .font(.title2.bold())
                .padding(.horizontal)
            
            ClimateImpactCard()
                .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Views
    private struct LocationPerformanceCard: View {
        let analysis: AdvancedAnalytics.LocationAnalysis
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(analysis.location)
                            .font(.headline)
                        
                        Text("\(analysis.plantCount) plants")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: "%.1f", analysis.avgHealthScore))
                            .font(.title3.bold())
                            .foregroundStyle(.green)
                        
                        Text("\(Int(analysis.successRate * 100))% thriving")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Best Species")
                            .font(.subheadline.bold())
                        
                        let best3 = Array(analysis.bestSpecies.prefix(3))
                        ForEach(best3, id: \.self) { species in
                            HStack {
                                Image(systemName: "leaf.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                
                                Text(species)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Challenges")
                            .font(.subheadline.bold())
                        
                        let topChallenges = Array(analysis.challenges.prefix(2))
                        ForEach(topChallenges, id: \.self) { challenge in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                
                                Text(challenge)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private struct RecommendationCard: View {
        let recommendation: String
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                    .font(.title3)
                
                Text(recommendation)
                    .font(.subheadline)
                
                Spacer()
                
                Button("Apply") {
                    // Handle recommendation application
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private struct ClimateImpactCard: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "cloud.sun.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    
                    Text("Next 7 Days")
                        .font(.headline)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    PredictionRow(
                        icon: "drop.fill",
                        color: .blue,
                        title: "Humidity Drop Expected",
                        description: "Increase misting frequency for tropical plants"
                    )
                    
                    PredictionRow(
                        icon: "sun.max.fill",
                        color: .orange,
                        title: "Extended Sunny Period",
                        description: "Monitor soil moisture more frequently"
                    )
                    
                    PredictionRow(
                        icon: "thermometer",
                        color: .red,
                        title: "Temperature Fluctuation",
                        description: "Move sensitive plants away from windows"
                    )
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private struct PredictionRow: View {
        let icon: String
        let color: Color
        let title: String
        let description: String
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Data Loading
    private func loadEnvironmentData() {
        environmentalImpacts = analytics.analyzeEnvironmentalImpact(plants: plants, careEvents: careEvents)
        locationAnalyses = analytics.analyzeLocationPerformance(plants: plants)
    }
}

// MARK: - BotanicalSeason Extensions
extension BotanicalSeason {
    var icon: String {
        switch self {
        case .spring: return "leaf.fill"
        case .summer: return "sun.max.fill"
        case .fall: return "leaf"
        case .winter: return "snowflake"
        }
    }
    
    var color: Color {
        switch self {
        case .spring: return .green
        case .summer: return .orange
        case .fall: return .brown
        case .winter: return .blue
        }
    }
}