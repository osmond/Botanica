import SwiftUI
import SwiftData
import Foundation

/// AI-powered plant care assistant view
/// Provides intelligent care recommendations and answers plant care questions
struct AICareAssistantView: View {
    let plant: Plant
    
    @Environment(\.modelContext) private var modelContext
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
    @State private var applyingCarePlan = false
    @State private var showingApplySuccess = false
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
            .alert("Care Plan Applied", isPresented: $showingApplySuccess) {
                Button("OK") { }
            } message: {
                Text("Your schedule and conditions have been updated.")
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
            applyCarePlanCard(plan)
            
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
    
    private func applyCarePlanCard(_ plan: PlantCareRecommendation) -> some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
            Text("Apply to this plant")
                .font(BotanicaTheme.Typography.headline)
                .foregroundColor(BotanicaTheme.Colors.textPrimary)
            
            Text(applySummary(for: plan))
                .font(BotanicaTheme.Typography.caption)
                .foregroundColor(BotanicaTheme.Colors.textSecondary)
            
            Text("Water amount uses pot size, material, and light to stay accurate.")
                .font(BotanicaTheme.Typography.caption2)
                .foregroundColor(BotanicaTheme.Colors.textSecondary)
            
            Button(action: { applyCarePlan(plan) }) {
                HStack {
                    if applyingCarePlan {
                        ProgressView()
                            .scaleEffect(0.9)
                    }
                    Text(applyingCarePlan ? "Applying..." : "Apply Care Plan")
                        .font(BotanicaTheme.Typography.button)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(BotanicaTheme.Colors.primary)
            .disabled(applyingCarePlan)
        }
        .padding()
        .background(BotanicaTheme.Colors.surface)
        .cornerRadius(BotanicaTheme.CornerRadius.medium)
    }
    
    private func applySummary(for plan: PlantCareRecommendation) -> String {
        let waterLine = planLine(from: plan.wateringSchedule.frequency, fallbackPrefix: "Water")
        let feedLine = planLine(from: plan.fertilizingSchedule.frequency, fallbackPrefix: "Fertilize")
        let lightLine = plan.lightRequirements.intensity.isEmpty ? "Light stays as-is" : "Light: \(plan.lightRequirements.intensity)"
        return [waterLine, feedLine, lightLine].joined(separator: " · ")
    }
    
    private func planLine(from frequency: String, fallbackPrefix: String) -> String {
        if let days = parseIntervalDays(frequency) {
            return "\(fallbackPrefix) every \(days) days"
        }
        return "\(fallbackPrefix): \(frequency)"
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
    
    private func applyCarePlan(_ plan: PlantCareRecommendation) {
        applyingCarePlan = true
        errorMessage = nil
        
        let wateringDays = parseIntervalDays(plan.wateringSchedule.frequency) ?? plant.wateringFrequency
        let fertilizingDays = parseIntervalDays(plan.fertilizingSchedule.frequency) ?? plant.fertilizingFrequency
        let repotMonths = parseIntervalMonths(plan.generalCare.repotting) ?? (plant.repotFrequencyMonths ?? 12)
        let lightLevel = parseLightLevel(plan.lightRequirements.intensity) ?? plant.lightLevel
        let humidity = parseHumidityPreference(plan.generalCare.humidity) ?? plant.humidityPreference
        let temperatureRange = parseTemperatureRange(plan.generalCare.temperature) ?? plant.temperatureRange
        
        plant.wateringFrequency = max(1, wateringDays)
        plant.fertilizingFrequency = max(1, fertilizingDays)
        plant.repotFrequencyMonths = max(1, repotMonths)
        plant.lightLevel = lightLevel
        plant.humidityPreference = min(max(humidity, 20), 90)
        plant.temperatureRange = temperatureRange
        
        let recommendation = CareCalculator.recommendedWateringAmount(
            potSize: plant.potSize,
            plantType: PlantWateringType.from(
                commonNames: plant.commonNames,
                family: plant.family,
                scientificName: plant.scientificName
            ),
            season: .current,
            environment: .indoor,
            potMaterial: plant.potMaterial ?? .unknown,
            lightLevel: plant.lightLevel,
            potHeight: plant.potHeight
        )
        plant.recommendedWaterAmount = Double(recommendation.amount)
        plant.waterUnit = waterUnit(for: recommendation.unit)
        
        upsertCarePlan(plan, wateringDays: plant.wateringFrequency, fertilizingDays: plant.fertilizingFrequency)
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
            showingApplySuccess = true
        } catch {
            let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
            errorMessage = message
            showingError = true
            HapticManager.shared.error()
        }
        
        applyingCarePlan = false
    }
    
    private func upsertCarePlan(_ plan: PlantCareRecommendation, wateringDays: Int, fertilizingDays: Int) {
        let planModel = plant.carePlan ?? CarePlan(source: .ai)
        if plant.carePlan == nil {
            modelContext.insert(planModel)
            plant.carePlan = planModel
        }
        
        planModel.source = .ai
        planModel.wateringInterval = wateringDays
        planModel.fertilizingInterval = fertilizingDays
        planModel.lightRequirements = [plan.lightRequirements.intensity, plan.lightRequirements.placement]
            .filter { !$0.isEmpty }
            .joined(separator: " | ")
        planModel.humidityRequirements = plan.generalCare.humidity
        planModel.temperatureRequirements = plan.generalCare.temperature
        
        let seasonalPieces = [
            plan.wateringSchedule.seasonalAdjustments,
            plan.lightRequirements.seasonalConsiderations,
            plan.fertilizingSchedule.seasonalSchedule
        ]
        planModel.seasonalNotes = seasonalPieces
            .filter { !$0.isEmpty }
            .joined(separator: " | ")
        planModel.aiExplanation = "Applied from AI Care Assistant."
        planModel.userApproved = true
        planModel.lastUpdated = Date()
    }
    
    private func parseIntervalDays(_ text: String) -> Int? {
        let lower = normalizedText(text)
        if lower.contains("every other day") { return 2 }
        if lower.contains("every other week") { return 14 }
        if lower.contains("every other month") { return 60 }
        if lower.contains("fortnight") { return 14 }
        if lower.contains("biweekly") { return 14 }
        
        if let perWeek = parseTimesPerUnit(lower, unit: "week") {
            return max(1, Int(round(7.0 / perWeek)))
        }
        if let perMonth = parseTimesPerUnit(lower, unit: "month") {
            return max(1, Int(round(30.0 / perMonth)))
        }
        if let perDay = parseTimesPerUnit(lower, unit: "day") {
            return max(1, Int(round(1.0 / perDay)))
        }
        
        if lower.contains("daily") || lower.contains("every day") { return 1 }
        if lower.contains("weekly") || lower.contains("every week") { return 7 }
        if lower.contains("monthly") || lower.contains("every month") { return 30 }
        
        let numbers = extractNumbers(lower)
        let value = numbers.isEmpty ? nil : averageIfRange(numbers, in: lower)
        let wordValue = wordNumberValue(in: lower)
        
        if let value, lower.contains("week") { return max(1, Int(round(value * 7))) }
        if let value, lower.contains("month") { return max(1, Int(round(value * 30))) }
        if let value, lower.contains("year") { return max(1, Int(round(value * 365))) }
        if let value, lower.contains("day") { return max(1, Int(round(value))) }
        
        if let wordValue, lower.contains("day") { return max(1, Int(round(wordValue))) }
        if let wordValue, lower.contains("week") { return max(1, Int(round(wordValue * 7))) }
        if let wordValue, lower.contains("month") { return max(1, Int(round(wordValue * 30))) }
        if let wordValue, lower.contains("year") { return max(1, Int(round(wordValue * 365))) }
        
        if let first = numbers.first { return max(1, Int(round(first))) }
        return nil
    }
    
    private func parseIntervalMonths(_ text: String) -> Int? {
        let lower = normalizedText(text)
        if lower.contains("every other year") { return 24 }
        if lower.contains("biannual") || lower.contains("semiannual") { return 6 }
        if lower.contains("quarterly") { return 3 }
        
        if let perYear = parseTimesPerUnit(lower, unit: "year") {
            return max(1, Int(round(12.0 / perYear)))
        }
        
        if lower.contains("yearly") || lower.contains("annually") { return 12 }
        
        let numbers = extractNumbers(lower)
        let value = numbers.isEmpty ? nil : averageIfRange(numbers, in: lower)
        let wordValue = wordNumberValue(in: lower)
        
        if let value, lower.contains("month") { return max(1, Int(round(value))) }
        if let value, lower.contains("year") { return max(1, Int(round(value * 12))) }
        
        if let wordValue, lower.contains("month") { return max(1, Int(round(wordValue))) }
        if let wordValue, lower.contains("year") { return max(1, Int(round(wordValue * 12))) }
        
        if let first = numbers.first { return max(1, Int(round(first))) }
        return nil
    }
    
    private func parseHumidityPreference(_ text: String) -> Int? {
        let lower = normalizedText(text)
        let numbers = extractNumbers(lower)
        if !numbers.isEmpty {
            return Int(round(averageIfRange(numbers, in: lower)))
        }
        
        if lower.contains("high") || lower.contains("humid") { return 70 }
        if lower.contains("medium") || lower.contains("moderate") { return 50 }
        if lower.contains("low") || lower.contains("dry") { return 35 }
        
        return nil
    }
    
    private func parseTemperatureRange(_ text: String) -> TemperatureRange? {
        let lower = normalizedText(text)
        let numbers = extractNumbers(lower)
        guard !numbers.isEmpty else { return nil }
        
        let isCelsius = lower.contains("celsius") || (!lower.contains("f") && numbers.allSatisfy { $0 <= 45 })
        let temps = numbers.map { isCelsius ? ($0 * 9 / 5 + 32) : $0 }
        
        let minValue = temps.min() ?? 65
        let maxValue = temps.max() ?? 80
        let minTemp = Int(round(minValue))
        let maxTemp = Int(round(maxValue))
        
        if minTemp == maxTemp {
            return TemperatureRange(
                min: max(40, minTemp - 5),
                max: min(95, maxTemp + 5)
            )
        }
        
        return TemperatureRange(
            min: max(40, minTemp),
            max: min(95, maxTemp)
        )
    }
    
    private func parseLightLevel(_ text: String) -> LightLevel? {
        let lower = normalizedText(text)
        if lower.contains("direct") { return .direct }
        if lower.contains("bright") { return .bright }
        if lower.contains("indirect") { return .bright }
        if lower.contains("low") { return .low }
        if lower.contains("medium") || lower.contains("moderate") { return .medium }
        return nil
    }
    
    private func waterUnit(for unit: String) -> WaterUnit {
        let lower = unit.lowercased()
        if lower.contains("oz") { return .ounces }
        if lower.contains("cup") { return .cups }
        if lower.contains("l") && !lower.contains("ml") { return .liters }
        return .milliliters
    }
    
    private func extractNumbers(_ text: String) -> [Double] {
        let pattern = #"\d+(\.\d+)?"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex?.matches(in: text, options: [], range: range) ?? []
        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return Double(text[range])
        }
    }
    
    private func averageIfRange(_ numbers: [Double], in text: String) -> Double {
        guard numbers.count >= 2 else { return numbers.first ?? 0 }
        if text.contains("-") || text.contains(" to ") || text.contains(" through ") || text.contains("between") {
            return (numbers[0] + numbers[1]) / 2
        }
        return numbers[0]
    }
    
    private func normalizedText(_ text: String) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            if scalar.value == 0x2013 || scalar.value == 0x2014 {
                scalars.append(UnicodeScalar(45)!)
            } else {
                scalars.append(scalar)
            }
        }
        return String(scalars).lowercased()
    }
    
    private func parseTimesPerUnit(_ text: String, unit: String) -> Double? {
        let hasUnit = text.contains("per \(unit)") || text.contains("a \(unit)") || text.contains("\(unit)ly")
        guard hasUnit else { return nil }
        
        if text.contains("once") { return 1 }
        if text.contains("twice") { return 2 }
        if text.contains("thrice") { return 3 }
        
        let numbers = extractNumbers(text)
        if !numbers.isEmpty {
            return max(1, averageIfRange(numbers, in: text))
        }
        
        if let wordValue = wordNumberValue(in: text) {
            return max(1, wordValue)
        }
        
        if text.contains("\(unit)ly") {
            return 1
        }
        
        return nil
    }
    
    private func wordNumberValue(in text: String) -> Double? {
        let words: [(String, Double)] = [
            ("one", 1),
            ("two", 2),
            ("three", 3),
            ("four", 4),
            ("five", 5),
            ("six", 6),
            ("seven", 7),
            ("eight", 8),
            ("nine", 9),
            ("ten", 10),
            ("couple", 2),
            ("few", 3),
            ("several", 4)
        ]
        
        for (word, value) in words where containsWord(text, word) {
            return value
        }
        
        return nil
    }
    
    private func containsWord(_ text: String, _ word: String) -> Bool {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return false }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
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
