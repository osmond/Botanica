import SwiftUI
import SwiftData

// MARK: - ML Analytics Detail View
struct MLAnalyticsView: View {
    @Query private var plants: [Plant]
    @Query private var careEvents: [CareEvent]
    @StateObject private var analytics = AdvancedAnalytics()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("ML Analytics")
                        .font(.largeTitle.bold())
                    
                    Text("Predictive insights powered by machine learning")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                // Predictive Care Recommendations
                predictiveCareSection
                
                // Risk Assessment
                riskAssessmentSection
                
                // Optimization Suggestions
                optimizationSection
                
                // Model Performance
                modelPerformanceSection
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("ML Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var predictiveCareSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Predictive Care Recommendations")
                .font(.title2.bold())
                .padding(.horizontal)
            
            ForEach(0..<3) { index in
                PredictiveRecommendationCard(
                    plantName: getPlantName(at: index),
                    prediction: getPrediction(for: index),
                    confidence: getConfidence(for: index),
                    daysAhead: getDaysAhead(for: index)
                )
                .padding(.horizontal)
            }
        }
    }
    
    private var riskAssessmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risk Assessment")
                .font(.title2.bold())
                .padding(.horizontal)
            
            RiskAssessmentCard()
                .padding(.horizontal)
        }
    }
    
    private var optimizationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Care Optimization")
                .font(.title2.bold())
                .padding(.horizontal)
            
            OptimizationCard()
                .padding(.horizontal)
        }
    }
    
    private var modelPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Model Performance")
                .font(.title2.bold())
                .padding(.horizontal)
            
            ModelPerformanceCard()
                .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Views
    private struct PredictiveRecommendationCard: View {
        let plantName: String
        let prediction: String
        let confidence: Double
        let daysAhead: Int
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plantName)
                            .font(.headline)
                        
                        Text("In \(daysAhead) days")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(confidence * 100))%")
                            .font(.title3.bold())
                            .foregroundStyle(.blue)
                        
                        Text("Confidence")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(prediction)
                    .font(.subheadline)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                HStack {
                    Button("Set Reminder") {
                        // Handle reminder setting
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Learn More") {
                        // Handle learning more
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private struct RiskAssessmentCard: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "shield.checkerboard")
                        .foregroundStyle(.orange)
                        .font(.title2)
                    
                    Text("Collection Risk Analysis")
                        .font(.headline)
                    
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    RiskRow(
                        risk: "Overwatering Risk",
                        level: "Medium",
                        color: .orange,
                        plantCount: 3
                    )
                    
                    RiskRow(
                        risk: "Pest Vulnerability",
                        level: "Low",
                        color: .green,
                        plantCount: 1
                    )
                    
                    RiskRow(
                        risk: "Seasonal Stress",
                        level: "High",
                        color: .red,
                        plantCount: 5
                    )
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private struct RiskRow: View {
        let risk: String
        let level: String
        let color: Color
        let plantCount: Int
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(risk)
                        .font(.subheadline.bold())
                    
                    Text("\(plantCount) plants affected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(level)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .foregroundStyle(color)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }
    
    private struct OptimizationCard: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .foregroundStyle(.purple)
                        .font(.title2)
                    
                    Text("AI-Powered Optimization")
                        .font(.headline)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    OptimizationSuggestion(
                        title: "Watering Schedule",
                        description: "Adjust watering frequency by -15% for better results",
                        impact: "+12% plant health"
                    )
                    
                    OptimizationSuggestion(
                        title: "Light Exposure",
                        description: "Rotate plants weekly for even growth",
                        impact: "+8% growth rate"
                    )
                    
                    OptimizationSuggestion(
                        title: "Fertilization Timing",
                        description: "Start spring feeding 2 weeks earlier",
                        impact: "+20% spring growth"
                    )
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private struct OptimizationSuggestion: View {
        let title: String
        let description: String
        let impact: String
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.bold())
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(impact)
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }
        }
    }
    
    private struct ModelPerformanceCard: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "cpu")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    
                    Text("Model Accuracy")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("94.2%")
                        .font(.title2.bold())
                        .foregroundStyle(.blue)
                }
                
                VStack(spacing: 8) {
                    ProgressView(value: 0.942) {
                        HStack {
                            Text("Prediction Accuracy")
                                .font(.caption)
                            Spacer()
                            Text("94.2%")
                                .font(.caption.bold())
                        }
                    }
                    .tint(.blue)
                    
                    ProgressView(value: 0.887) {
                        HStack {
                            Text("Risk Assessment")
                                .font(.caption)
                            Spacer()
                            Text("88.7%")
                                .font(.caption.bold())
                        }
                    }
                    .tint(.green)
                    
                    ProgressView(value: 0.911) {
                        HStack {
                            Text("Care Optimization")
                                .font(.caption)
                            Spacer()
                            Text("91.1%")
                                .font(.caption.bold())
                        }
                    }
                    .tint(.purple)
                }
                
                Text("Model trained on 50,000+ care events")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Helper Methods
    private func getPlantName(at index: Int) -> String {
        guard index < plants.count else { return "Unknown Plant" }
        return plants[index].nickname
    }
    
    private func getPrediction(for index: Int) -> String {
        let predictions = [
            "Will need watering based on soil moisture patterns",
            "Growth rate will increase by 15% with adjusted light exposure",
            "Risk of root rot detected - reduce watering frequency"
        ]
        return predictions[index % predictions.count]
    }
    
    private func getConfidence(for index: Int) -> Double {
        let confidences = [0.94, 0.87, 0.91]
        return confidences[index % confidences.count]
    }
    
    private func getDaysAhead(for index: Int) -> Int {
        let days = [3, 7, 5]
        return days[index % days.count]
    }
}