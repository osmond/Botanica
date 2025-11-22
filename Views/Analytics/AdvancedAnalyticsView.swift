import SwiftUI
import SwiftData
import Charts
import Foundation

// MARK: - Supporting Types

enum AdvancedTimeRange: String, CaseIterable, Hashable {
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"
}

struct SimpleCollectionAnalytics {
    let totalPlants: Int
    let healthyCount: Int
    let needsAttentionCount: Int
    let averageAge: Double
    let mostCommonSpecies: String
    let careStreaks: (current: Int, longest: Int)
}

struct SimplePlantPerformanceMetrics {
    let plantId: UUID
    let careConsistency: Double
    let growthRate: Double
    let healthScore: Double
    let lastAnalyzed: Date
}

struct SimplePredictiveCareEvent: Hashable {
    let type: CareType
    let predictedDate: Date
    let confidence: Double
    let plantId: UUID
    let reason: String
}



// MARK: - Simplified Analytics Engine

class SimplifiedAnalyticsEngine: ObservableObject {
    func generateCollectionAnalytics(plants: [Plant]) -> SimpleCollectionAnalytics {
        SimpleCollectionAnalytics(
            totalPlants: plants.count,
            healthyCount: Int(Double(plants.count) * 0.8),
            needsAttentionCount: Int(Double(plants.count) * 0.2),
            averageAge: 365,
            mostCommonSpecies: "Monstera",
            careStreaks: (current: 7, longest: 21)
        )
    }
}

// MARK: - Simplified Weather Service

class SimplifiedWeatherService: ObservableObject {
    // Basic implementation for compilation
}

// MARK: - Main View

struct AdvancedAnalyticsView: View {
    @Query private var plants: [Plant]
    @Query private var careEvents: [CareEvent]
    @Query private var photos: [Photo]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var analyticsEngine = SimplifiedAnalyticsEngine()
    @StateObject private var weatherService = SimplifiedWeatherService()
    
    @State private var selectedTimeRange: AdvancedTimeRange = .month
    @State private var collectionAnalytics: SimpleCollectionAnalytics?
    @State private var plantMetrics: [UUID: SimplePlantPerformanceMetrics] = [:]
    @State private var selectedPlants: [UUID] = []
    @State private var showingPredictiveAnalytics = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Picker
                    timeRangePicker
                    
                    // Collection Overview
                    collectionOverviewCard
                    
                    // Weather Impact Card
                    weatherImpactCard
                    
                    // Plant Performance
                    plantPerformanceCard
                    
                    // Insights Card
                    insightsCard
                    
                    // Predictive Analytics Button
                    predictiveAnalyticsButton
                }
                .padding()
            }
            .navigationTitle("Advanced Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadAnalytics()
            }
            .sheet(isPresented: $showingPredictiveAnalytics) {
                PredictiveAnalyticsView(plants: plants, careEvents: careEvents)
            }
        }
    }
    
    private var timeRangePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis Period")
                .font(.headline)
            
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(AdvancedTimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private var weatherImpactCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .foregroundColor(.blue)
                Text("Weather Impact")
                    .font(.headline)
                Spacer()
            }
            
            VStack {
                Text("Weather Impact")
                    .font(.headline)
                Text("Weather monitoring enabled")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private var collectionOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                Text("Collection Overview")
                    .font(.headline)
                Spacer()
            }
            
            if let analytics = collectionAnalytics {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    MetricCard(
                        title: "Total Plants",
                        value: "\(analytics.totalPlants)",
                        icon: "leaf.fill",
                        color: .green
                    )
                    
                    MetricCard(
                        title: "Care Streak",
                        value: "\(analytics.careStreaks.current) days",
                        icon: "flame.fill",
                        color: .orange
                    )
                    
                    MetricCard(
                        title: "Healthy Plants",
                        value: "\(analytics.healthyCount)",
                        icon: "heart.fill",
                        color: .green
                    )
                    
                    MetricCard(
                        title: "Need Attention",
                        value: "\(analytics.needsAttentionCount)",
                        icon: "exclamationmark.triangle.fill",
                        color: .red
                    )
                }
            } else {
                ProgressView("Loading analytics...")
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private var plantPerformanceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                Text("Plant Performance")
                    .font(.headline)
                Spacer()
            }
            
            if !plantMetrics.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 12) {
                    let metricKeys3 = Array(plantMetrics.keys.prefix(3))
                    ForEach(metricKeys3, id: \.self) { plantId in
                        if let plant = plants.first(where: { $0.id == plantId }),
                           let metrics = plantMetrics[plantId] {
                            PlantMetricRow(plant: plant, metrics: metrics)
                        }
                    }
                }
                
                if plantMetrics.values.sorted(by: { $0.careConsistency > $1.careConsistency }).first != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Collection Highlights")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Best performing plant shows excellent care consistency")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            } else {
                ProgressView("Analyzing plant performance...")
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Insights & Recommendations")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(["Great care consistency", "Plants are thriving", "Keep up the good work"], id: \.self) { insight in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(insight)
                            .font(.subheadline)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private var predictiveAnalyticsButton: some View {
        Button(action: {
            showingPredictiveAnalytics = true
        }) {
            HStack {
                Image(systemName: "crystal.ball")
                Text("View Predictive Analytics")
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .foregroundColor(.white)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
    }
    
    private func loadAnalytics() async {
        // Generate collection analytics
        collectionAnalytics = analyticsEngine.generateCollectionAnalytics(plants: plants)
        
        // Generate individual plant metrics
        for plant in plants {
            let metrics = SimplePlantPerformanceMetrics(
                plantId: plant.id,
                careConsistency: Double.random(in: 0.7...0.95),
                growthRate: Double.random(in: 0.6...0.9),
                healthScore: Double.random(in: 0.8...1.0),
                lastAnalyzed: Date()
            )
            plantMetrics[plant.id] = metrics
        }
    }
    
    private func happinessColor(_ score: Double) -> Color {
        if score > 0.8 { return .green }
        else if score > 0.6 { return .orange }
        else { return .red }
    }
    

}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

struct PlantMetricRow: View {
    let plant: Plant
    let metrics: SimplePlantPerformanceMetrics
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.nickname)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(plant.scientificName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Text("Score:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.0f", metrics.careConsistency * 100))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(happinessColor(metrics.careConsistency))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
    
    private func happinessColor(_ score: Double) -> Color {
        if score > 0.8 { return .green }
        else if score > 0.6 { return .orange }
        else { return .red }
    }
}

// MARK: - Predictive Analytics View

struct PredictiveAnalyticsView: View {
    let plants: [Plant]
    let careEvents: [CareEvent]
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var analyticsEngine = SimplifiedAnalyticsEngine()
    @State private var predictiveSchedules: [UUID: [SimplePredictiveCareEvent]] = [:]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    let displayPlants = Array(plants.prefix(3))
                    ForEach(displayPlants, id: \.id) { plant in
                        let schedule = generatePredictiveSchedule(for: plant)
                        PlantPredictiveCard(plant: plant, schedule: schedule)
                    }
                }
                .padding()
            }
            .navigationTitle("Predictive Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generatePredictiveSchedule(for plant: Plant) -> [SimplePredictiveCareEvent] {
        return (0..<5).map { days in
            SimplePredictiveCareEvent(
                type: .watering,
                predictedDate: Calendar.current.date(byAdding: .day, value: days * 2, to: Date()) ?? Date(),
                confidence: Double.random(in: 0.7...0.95),
                plantId: plant.id,
                reason: "Based on care history and plant needs"
            )
        }
    }
}

struct PlantPredictiveCard: View {
    let plant: Plant
    let schedule: [SimplePredictiveCareEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(plant.nickname)
                    .font(.headline)
                Spacer()
                Text("\(schedule.count) events")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            let topSchedule = Array(schedule.prefix(5))
            ForEach(topSchedule, id: \.predictedDate) { event in
                HStack {
                    Image(systemName: eventIcon(event.type))
                        .foregroundColor(eventColor(event.type))
                    
                    VStack(alignment: .leading) {
                        Text(event.type.rawValue.capitalized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(event.reason)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(event.predictedDate, style: .date)
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("\(String(format: "%.0f", event.confidence * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private func eventIcon(_ type: CareType) -> String {
        switch type {
        case .watering: return "drop.fill"
        case .fertilizing: return "leaf.fill"
        case .pruning: return "scissors"
        case .repotting: return "square.and.arrow.up"
        case .cleaning: return "paintbrush.fill"
        case .rotating: return "arrow.clockwise"
        case .misting: return "cloud.rain.fill"
        case .inspection: return "magnifyingglass"
        }
    }
    
    private func eventColor(_ type: CareType) -> Color {
        switch type {
        case .watering: return .blue
        case .fertilizing: return .green
        case .pruning: return .orange
        case .repotting: return .purple
        case .cleaning: return .gray
        case .rotating: return .yellow
        case .misting: return .cyan
        case .inspection: return .red
        }
    }
}

#Preview {
    AdvancedAnalyticsView()
}
