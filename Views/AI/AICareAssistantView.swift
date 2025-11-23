import SwiftUI

/// AI-powered plant care assistant view
/// Provides intelligent care recommendations and answers plant care questions
struct AICareAssistantView: View {
    let plant: Plant
    
    @StateObject private var aiCoach = AIPlantCoach()
    @State private var selectedTab = 0
    @State private var careQuestion = ""
    @State private var symptomDescription = ""
    @State private var carePlan: PlantCareRecommendation?
    @State private var questionResponse = ""
    @State private var diagnosisResponse = ""
    @State private var showingError = false
    @State private var errorMessage: String?
    @State private var carePlanState: LoadState = .idle
    @State private var questionState: LoadState = .idle
    @State private var diagnosisState: LoadState = .idle
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("AI Assistant Mode", selection: $selectedTab) {
                    Text("Care Plan").tag(0)
                    Text("Ask Question").tag(1)
                    Text("Diagnose").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    carePlanView
                        .tag(0)
                    
                    askQuestionView
                        .tag(1)
                    
                    diagnoseView
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("AI Plant Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                        HapticManager.shared.light()
                    }
                }
            }
            .alert("AI Error", isPresented: $showingError) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? aiCoach.lastError?.localizedDescription ?? "An error occurred")
            }
        }
    }
    
    // MARK: - Care Plan View
    
    private var carePlanView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                // Plant info header
                plantInfoHeader
                
                LoadStateView(
                    state: carePlanState,
                    retry: { generateCarePlan() },
                    loading: { loadingView("Generating care plan...") },
                    content: {
                        if let plan = carePlan {
                            carePlanContent(plan)
                        } else {
                            generateCarePlanButton
                        }
                    }
                )
            }
            .padding()
        }
    }
    
    private var plantInfoHeader: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
            Text(plant.displayName)
                .font(BotanicaTheme.Typography.title2)
                .foregroundColor(BotanicaTheme.Colors.primary)
            
            Text(plant.scientificName)
                .font(BotanicaTheme.Typography.body)
                .foregroundColor(BotanicaTheme.Colors.textSecondary)
                .italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(BotanicaTheme.Colors.surface)
        .cornerRadius(BotanicaTheme.CornerRadius.medium)
    }
    
    private var generateCarePlanButton: some View {
        VStack(spacing: BotanicaTheme.Spacing.md) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(BotanicaTheme.Colors.primary)
            
            Text("Generate AI Care Plan")
                .font(BotanicaTheme.Typography.title3)
                .foregroundColor(BotanicaTheme.Colors.textPrimary)
            
            Text("Get personalized care recommendations based on your plant's specific needs and current conditions.")
                .font(BotanicaTheme.Typography.body)
                .foregroundColor(BotanicaTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Generate Care Plan") {
                generateCarePlan()
            }
            .buttonStyle(.borderedProminent)
            .tint(BotanicaTheme.Colors.primary)
            .disabled(carePlanState == .loading)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private func carePlanContent(_ plan: PlantCareRecommendation) -> some View {
        LazyVStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            // Watering Schedule
            careSection(
                title: "Watering Schedule",
                icon: "drop.fill",
                color: .blue
            ) {
                careDetail("Frequency", plan.wateringSchedule.frequency)
                careDetail("Amount", plan.wateringSchedule.amount)
                careDetail("Technique", plan.wateringSchedule.technique)
                careDetail("Seasonal Adjustments", plan.wateringSchedule.seasonalAdjustments)
            }
            
            // Light Requirements
            careSection(
                title: "Light Requirements",
                icon: "sun.max.fill",
                color: .yellow
            ) {
                careDetail("Intensity", plan.lightRequirements.intensity)
                careDetail("Duration", plan.lightRequirements.duration)
                careDetail("Placement", plan.lightRequirements.placement)
                careDetail("Seasonal Notes", plan.lightRequirements.seasonalConsiderations)
            }
            
            // Fertilizing Schedule
            careSection(
                title: "Fertilizing Schedule",
                icon: "leaf.fill",
                color: .green
            ) {
                careDetail("Frequency", plan.fertilizingSchedule.frequency)
                careDetail("Type", plan.fertilizingSchedule.type)
                careDetail("Amount", plan.fertilizingSchedule.amount)
                careDetail("Seasonal Schedule", plan.fertilizingSchedule.seasonalSchedule)
            }
            
            // General Care
            careSection(
                title: "General Care",
                icon: "heart.fill",
                color: .red
            ) {
                careDetail("Humidity", plan.generalCare.humidity)
                careDetail("Temperature", plan.generalCare.temperature)
                careDetail("Repotting", plan.generalCare.repotting)
                careDetail("Pruning", plan.generalCare.pruning)
                if let propagation = plan.generalCare.propagation {
                    careDetail("Propagation", propagation)
                }
            }
            
            // Seasonal Tips
            if !plan.seasonalTips.isEmpty {
                careSection(
                    title: "Seasonal Tips",
                    icon: "calendar",
                    color: .orange
                ) {
                    ForEach(plan.seasonalTips, id: \.season) { tip in
                        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                            Text(tip.season)
                                .font(BotanicaTheme.Typography.bodyEmphasized)
                                .foregroundColor(BotanicaTheme.Colors.primary)
                            Text(tip.tip)
                                .font(BotanicaTheme.Typography.body)
                                .foregroundColor(BotanicaTheme.Colors.textPrimary)
                        }
                    }
                }
            }
            
            // Common Issues
            if !plan.commonIssues.isEmpty {
                careSection(
                    title: "Common Issues",
                    icon: "exclamationmark.triangle.fill",
                    color: .orange
                ) {
                    ForEach(plan.commonIssues, id: \.issue) { issue in
                        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                            Text(issue.issue)
                                .font(BotanicaTheme.Typography.bodyEmphasized)
                                .foregroundColor(BotanicaTheme.Colors.primary)
                            Text("Symptoms: \(issue.symptoms)")
                                .font(BotanicaTheme.Typography.caption)
                                .foregroundColor(BotanicaTheme.Colors.textSecondary)
                            Text("Solution: \(issue.solution)")
                                .font(BotanicaTheme.Typography.body)
                                .foregroundColor(BotanicaTheme.Colors.textPrimary)
                        }
                        .padding(.bottom, BotanicaTheme.Spacing.sm)
                    }
                }
            }
        }
    }
    
    // MARK: - Ask Question View
    
    private var askQuestionView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                plantInfoHeader
                
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                    Text("Ask a Care Question")
                        .font(BotanicaTheme.Typography.title3)
                        .foregroundColor(BotanicaTheme.Colors.textPrimary)
                    
                    TextField("What would you like to know about caring for your plant?", text: $careQuestion, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                    
                    Button("Ask AI Coach") {
                        askAIQuestion()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BotanicaTheme.Colors.primary)
                    .disabled(careQuestion.isEmpty || questionState == .loading)
                }
                .padding()
                .background(BotanicaTheme.Colors.surface)
                .cornerRadius(BotanicaTheme.CornerRadius.medium)
                
                LoadStateView(
                    state: questionState,
                    retry: { askAIQuestion() },
                    loading: { loadingView("AI Coach is thinking...") },
                    content: {
                        if !questionResponse.isEmpty {
                            responseView(questionResponse)
                        }
                    }
                )
            }
            .padding()
        }
    }
    
    // MARK: - Diagnose View
    
    private var diagnoseView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                plantInfoHeader
                
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                    Text("Describe Plant Symptoms")
                        .font(BotanicaTheme.Typography.title3)
                        .foregroundColor(BotanicaTheme.Colors.textPrimary)
                    
                    Text("Describe any concerning symptoms you've noticed (leaf color changes, wilting, spots, pests, etc.)")
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(BotanicaTheme.Colors.textSecondary)
                    
                    TextField("Describe the symptoms...", text: $symptomDescription, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(4...8)
                    
                    Button("Get Diagnosis") {
                        runDiagnosis()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BotanicaTheme.Colors.primary)
                    .disabled(symptomDescription.isEmpty || diagnosisState == .loading)
                }
                .padding()
                .background(BotanicaTheme.Colors.surface)
                .cornerRadius(BotanicaTheme.CornerRadius.medium)
                
                LoadStateView(
                    state: diagnosisState,
                    retry: { runDiagnosis() },
                    loading: { loadingView("Generating diagnosis...") },
                    content: {
                        if !diagnosisResponse.isEmpty {
                            responseView(diagnosisResponse)
                        }
                    }
                )
            }
            .padding()
        }
    }
    
    // MARK: - Helper Views
    
    private func loadingView(_ text: String) -> some View {
        VStack(spacing: BotanicaTheme.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text(text)
                .font(BotanicaTheme.Typography.body)
                .foregroundColor(BotanicaTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private func generateCarePlan() {
        Task {
            carePlanState = .loading
            errorMessage = nil
            do {
                carePlan = try await aiCoach.generateCarePlan(for: plant)
                carePlanState = .loaded
                HapticManager.shared.success()
            } catch {
                let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
                errorMessage = message
                carePlanState = .failed(message)
                showingError = true
                HapticManager.shared.error()
            }
        }
    }
    
    private func askAIQuestion() {
        Task {
            questionState = .loading
            errorMessage = nil
            do {
                questionResponse = try await aiCoach.askCareQuestion(careQuestion, about: plant)
                questionState = .loaded
                HapticManager.shared.success()
            } catch {
                let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
                errorMessage = message
                questionState = .failed(message)
                showingError = true
                HapticManager.shared.error()
            }
        }
    }
    
    private func runDiagnosis() {
        Task {
            diagnosisState = .loading
            errorMessage = nil
            do {
                diagnosisResponse = try await aiCoach.diagnosePlantIssues(symptoms: symptomDescription, for: plant)
                diagnosisState = .loaded
                HapticManager.shared.success()
            } catch {
                let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
                errorMessage = message
                diagnosisState = .failed(message)
                showingError = true
                HapticManager.shared.error()
            }
        }
    }
    
    private func responseView(_ response: String) -> some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
            HStack {
                Image(systemName: "brain.head.profile.fill")
                    .foregroundColor(BotanicaTheme.Colors.primary)
                Text("AI Coach Response")
                    .font(BotanicaTheme.Typography.headline)
                    .foregroundColor(BotanicaTheme.Colors.textPrimary)
                Spacer()
            }
            
            Text(response)
                .font(BotanicaTheme.Typography.body)
                .foregroundColor(BotanicaTheme.Colors.textPrimary)
        }
        .padding()
        .background(BotanicaTheme.Colors.surface)
        .cornerRadius(BotanicaTheme.CornerRadius.medium)
    }
    
    private func careSection<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(BotanicaTheme.Typography.headline)
                    .foregroundColor(BotanicaTheme.Colors.textPrimary)
                Spacer()
            }
            
            content()
        }
        .padding()
        .background(BotanicaTheme.Colors.surface)
        .cornerRadius(BotanicaTheme.CornerRadius.medium)
    }
    
    private func careDetail(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
            Text(label)
                .font(BotanicaTheme.Typography.bodyEmphasized)
                .foregroundColor(BotanicaTheme.Colors.primary)
            Text(value)
                .font(BotanicaTheme.Typography.body)
                .foregroundColor(BotanicaTheme.Colors.textPrimary)
        }
    }
}
