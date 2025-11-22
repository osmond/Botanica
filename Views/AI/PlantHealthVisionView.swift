import SwiftUI
import PhotosUI
import UIKit

/// Plant Health Vision Analysis view showcasing AI-powered health assessment from photos
struct PlantHealthVisionView: View {
    let plant: Plant
    
    @StateObject private var visionAnalyzer = PlantHealthVisionAnalyzer()
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var currentAnalysis: PlantHealthAnalysis?
    @State private var quickScreenResult: QuickHealthScreen?
    @State private var showingDetailedAnalysis = false
    @State private var analysisHistory: [PlantHealthAnalysis] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: BotanicaTheme.Spacing.lg) {
                    // Image Selection Section
                    imageSelectionSection
                    
                    // Quick Health Screen
                    if let quickResult = quickScreenResult {
                        quickHealthSection(quickResult)
                    }
                    
                    // Detailed Analysis
                    if let analysis = currentAnalysis {
                        detailedAnalysisSection(analysis)
                    }
                    
                    // Analysis History
                    if !analysisHistory.isEmpty {
                        historySection
                    }
                    
                    // Instructions and Tips
                    tipsSection
                }
                .padding(BotanicaTheme.Spacing.md)
            }
            .navigationTitle("Health Analysis")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Take Photo", systemImage: "camera") {
                            showingCamera = true
                        }
                        Button("Choose Photo", systemImage: "photo") {
                            showingImagePicker = true
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingCamera) {
                VisionCameraView(capturedImage: $selectedImage)
            }
            .sheet(isPresented: $showingDetailedAnalysis) {
                if let analysis = currentAnalysis {
                    DetailedAnalysisView(analysis: analysis)
                }
            }
            .onChange(of: selectedImage) { _, newImage in
                if let image = newImage {
                    Task {
                        await performQuickAnalysis(image)
                    }
                }
            }
        }
        .onAppear {
            analysisHistory = visionAnalyzer.analysisHistory
        }
    }
    
    // MARK: - Image Selection Section
    
    private var imageSelectionSection: some View {
        VStack(spacing: BotanicaTheme.Spacing.md) {
            if let image = selectedImage {
                VStack(spacing: BotanicaTheme.Spacing.md) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(BotanicaTheme.CornerRadius.medium)
                        .shadow(radius: 4)
                    
                    HStack(spacing: BotanicaTheme.Spacing.md) {
                        Button("Quick Scan") {
                            Task {
                                await performQuickAnalysis(image)
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(visionAnalyzer.isAnalyzing)
                        
                        Button("Full Analysis") {
                            Task {
                                await performFullAnalysis(image)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(visionAnalyzer.isAnalyzing)
                    }
                    
                    if visionAnalyzer.isAnalyzing {
                        ProgressView("Analyzing plant health...")
                            .font(.caption)
                    }
                }
            } else {
                VStack(spacing: BotanicaTheme.Spacing.lg) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("Take or select a photo of \(plant.nickname)")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("For best results, ensure good lighting and capture the entire plant")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: BotanicaTheme.Spacing.lg) {
                        Button("Take Photo") {
                            showingCamera = true
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Choose Photo") {
                            showingImagePicker = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(BotanicaTheme.Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                        .fill(Color(.systemGray6))
                        .strokeBorder(Color(.systemGray4), style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
            }
        }
    }
    
    // MARK: - Quick Health Section
    
    private func quickHealthSection(_ result: QuickHealthScreen) -> some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            HStack {
                Image(systemName: "stethoscope")
                    .foregroundColor(BotanicaTheme.Colors.primary)
                Text("Quick Health Screen")
                    .font(.headline)
                Spacer()
                Text("\(String(format: "%.0f", result.confidence * 100))% confidence")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: BotanicaTheme.Spacing.lg) {
                VStack(alignment: .leading) {
                    HStack {
                        Circle()
                            .fill(result.overallHealth.color)
                            .frame(width: 12, height: 12)
                        Text(result.overallHealth.description)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text("Overall Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Detailed Analysis") {
                    if let image = selectedImage {
                        Task {
                            await performFullAnalysis(image)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
            
            if !result.alerts.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                    Text("Alerts")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(result.alerts, id: \.self) { alert in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text(alert)
                                .font(.caption)
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(BotanicaTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    // MARK: - Detailed Analysis Section
    
    private func detailedAnalysisSection(_ analysis: PlantHealthAnalysis) -> some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(BotanicaTheme.Colors.primary)
                Text("AI Health Analysis")
                    .font(.headline)
                Spacer()
                Button("View Full Report") {
                    showingDetailedAnalysis = true
                }
                .font(.caption)
                .foregroundColor(BotanicaTheme.Colors.primary)
            }
            
            // Health Score
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                HStack {
                    Text("Health Score")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(String(format: "%.0f", analysis.healthScore))/100")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(healthScoreColor(analysis.healthScore))
                }
                
                ProgressView(value: analysis.healthScore, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: healthScoreColor(analysis.healthScore)))
            }
            
            // Key Insights
            if !analysis.aiAssessment.primaryInsights.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                    Text("Key Insights")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(analysis.aiAssessment.primaryInsights.prefix(3), id: \.self) { insight in
                        HStack(alignment: .top) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(insight)
                                .font(.caption)
                            Spacer()
                        }
                    }
                }
            }
            
            // Health Issues
            if !analysis.healthIssues.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                    Text("Detected Issues")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(analysis.healthIssues.prefix(3), id: \.type.rawValue) { issue in
                        HealthIssueRow(issue: issue)
                    }
                }
            }
            
            // Quick Recommendations
            if !analysis.recommendations.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                    Text("Immediate Actions")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(analysis.recommendations.filter { $0.priority == .high }.prefix(2), id: \.action) { rec in
                        HStack(alignment: .top) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(rec.action)
                                .font(.caption)
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(BotanicaTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    // MARK: - History Section
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(BotanicaTheme.Colors.primary)
                Text("Analysis History")
                    .font(.headline)
                Spacer()
            }
            
            LazyVStack(spacing: BotanicaTheme.Spacing.sm) {
                ForEach(analysisHistory.prefix(5), id: \.id) { analysis in
                    HistoryRow(analysis: analysis) {
                        currentAnalysis = analysis
                    }
                }
            }
        }
        .padding(BotanicaTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    // MARK: - Tips Section
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Photography Tips")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                TipRow(icon: "sun.max.fill", tip: "Use natural lighting when possible")
                TipRow(icon: "viewfinder", tip: "Include the entire plant in frame")
                TipRow(icon: "hand.raised.fill", tip: "Keep camera steady to avoid blur")
                TipRow(icon: "leaf.fill", tip: "Take close-ups of concerning areas")
                TipRow(icon: "camera.filters", tip: "Avoid using filters or editing")
            }
        }
        .padding(BotanicaTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Helper Methods
    
    private func performQuickAnalysis(_ image: UIImage) async {
        do {
            let result = try await visionAnalyzer.quickHealthScreen(image: image)
            quickScreenResult = result
        } catch {
            print("Quick analysis error: \(error)")
        }
    }
    
    private func performFullAnalysis(_ image: UIImage) async {
        do {
            let analysis = try await visionAnalyzer.analyzeHealthFromPhoto(image: image, plant: plant)
            currentAnalysis = analysis
            analysisHistory = visionAnalyzer.analysisHistory
        } catch {
            print("Full analysis error: \(error)")
        }
    }
    
    private func healthScoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 60...79: return .orange
        case 40...59: return .yellow
        default: return .red
        }
    }
}

// MARK: - Simple camera wrapper for vision view
struct VisionCameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VisionCameraView
        init(_ parent: VisionCameraView) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage { parent.capturedImage = image }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    }
}

// MARK: - Photo Library Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage { parent.selectedImage = image }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    }
}

// MARK: - Supporting Views

struct HealthIssueRow: View {
    let issue: HealthIssueDetection
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: severityIcon(issue.severity))
                .foregroundColor(severityColor(issue.severity))
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(issue.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(issue.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(String(format: "%.0f", issue.confidence * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func severityIcon(_ severity: IssueSeverity) -> String {
        switch severity {
        case .low: return "info.circle.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.octagon.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
    
    private func severityColor(_ severity: IssueSeverity) -> Color {
        switch severity {
        case .low: return .blue
        case .moderate: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct HistoryRow: View {
    let analysis: PlantHealthAnalysis
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(uiImage: analysis.originalImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipped()
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(analysis.analysisDate, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Score: \(String(format: "%.0f", analysis.healthScore))/100")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Circle()
                        .fill(healthScoreColor(analysis.healthScore))
                        .frame(width: 12, height: 12)
                    Text("\(analysis.healthIssues.count) issues")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func healthScoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 60...79: return .orange
        default: return .red
        }
    }
}

struct TipRow: View {
    let icon: String
    let tip: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.caption)
                .frame(width: 16)
            Text(tip)
                .font(.caption)
            Spacer()
        }
    }
}

// MARK: - Detailed Analysis View

struct DetailedAnalysisView: View {
    let analysis: PlantHealthAnalysis
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
                    // Header with image and basic info
                    VStack(spacing: BotanicaTheme.Spacing.md) {
                        Image(uiImage: analysis.originalImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .cornerRadius(BotanicaTheme.CornerRadius.medium)
                        
                        VStack {
                            Text("\(String(format: "%.0f", analysis.healthScore))/100")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(healthScoreColor(analysis.healthScore))
                            Text("Health Score")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Visual Features
                    AnalysisSection(title: "Visual Analysis", icon: "eye.fill") {
                        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                            DetailRow(label: "Leaf Count", value: "\(analysis.visualFeatures.leafCount)")
                            DetailRow(label: "Leaf Color", value: analysis.visualFeatures.leafColor.description)
                            DetailRow(label: "Plant Size", value: analysis.visualFeatures.plantSize.estimatedActualSize.description)
                            DetailRow(label: "Image Quality", value: "\(String(format: "%.0f", analysis.visualFeatures.imageQuality * 100))%")
                        }
                    }
                    
                    // Health Issues
                    if !analysis.healthIssues.isEmpty {
                        AnalysisSection(title: "Health Issues", icon: "exclamationmark.triangle.fill") {
                            VStack(spacing: BotanicaTheme.Spacing.sm) {
                                ForEach(analysis.healthIssues, id: \.type.rawValue) { issue in
                                    DetailedHealthIssueCard(issue: issue)
                                }
                            }
                        }
                    }
                    
                    // AI Assessment
                    AnalysisSection(title: "AI Assessment", icon: "brain.head.profile") {
                        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                            ForEach(analysis.aiAssessment.primaryInsights, id: \.self) { insight in
                                Text("• \(insight)")
                                    .font(.caption)
                            }
                        }
                    }
                    
                    // Recommendations
                    if !analysis.recommendations.isEmpty {
                        AnalysisSection(title: "Recommendations", icon: "checkmark.circle.fill") {
                            VStack(spacing: BotanicaTheme.Spacing.sm) {
                                ForEach(analysis.recommendations, id: \.action) { rec in
                                    RecommendationCard(recommendation: rec)
                                }
                            }
                        }
                    }
                }
                .padding(BotanicaTheme.Spacing.md)
            }
            .navigationTitle("Health Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func healthScoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 60...79: return .orange
        default: return .red
        }
    }
}

struct AnalysisSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(BotanicaTheme.Colors.primary)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            content
        }
        .padding(BotanicaTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct VisionDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct DetailedHealthIssueCard: View {
    let issue: HealthIssueDetection
    
    var body: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
            HStack {
                Text(issue.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(issue.severity.description)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(severityColor(issue.severity).opacity(0.2))
                    .foregroundColor(severityColor(issue.severity))
                    .cornerRadius(8)
            }
            
            Text(issue.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Recommended: \(issue.recommendedAction)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(BotanicaTheme.Colors.primary)
        }
        .padding(BotanicaTheme.Spacing.sm)
        .background(Color(.systemGray6))
        .cornerRadius(BotanicaTheme.CornerRadius.small)
    }
    
    private func severityColor(_ severity: IssueSeverity) -> Color {
        switch severity {
        case .low: return .blue
        case .moderate: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct RecommendationCard: View {
    let recommendation: HealthRecommendation
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: priorityIcon(recommendation.priority))
                .foregroundColor(priorityColor(recommendation.priority))
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.action)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(recommendation.reason)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(BotanicaTheme.Spacing.sm)
        .background(Color(.systemGray6))
        .cornerRadius(BotanicaTheme.CornerRadius.small)
    }
    
    private func priorityIcon(_ priority: RecommendationPriority) -> String {
        switch priority {
        case .low: return "info.circle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .urgent: return "exclamationmark.octagon.fill"
        }
    }
    
    private func priorityColor(_ priority: RecommendationPriority) -> Color {
        switch priority {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

// MARK: - Extensions

extension LeafColorHealth {
    var description: String {
        switch self {
        case .healthy: return "Healthy Green"
        case .yellowing: return "Yellowing"
        case .browning: return "Browning"
        case .spotted: return "Spotted"
        case .wilting: return "Wilting"
        }
    }
}

extension PlantSizeCategory {
    var description: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
}

extension IssueSeverity {
    var description: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

#Preview {
    PlantHealthVisionView(plant: Plant.example)
}
