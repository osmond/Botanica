import SwiftUI
import SwiftData
import UIKit

/// AI-powered plant care assistant providing personalized recommendations and health analysis
struct AICoachView: View {
    let plant: Plant
    @Environment(\.dismiss) private var dismiss
    @StateObject private var coach = AIPlantCoach()
    @State private var currentQuestion = ""
    @State private var aiResponse = ""
    @State private var chatLoadState: LoadState = .idle
    @State private var conversationHistory: [ConversationMessage] = []
    @State private var selectedQuickQuestion: String? = nil
    @State private var showingHealthDiagnosis = false
    @State private var healthDiagnosisResult: String = ""
    @State private var healthLoadState: LoadState = .idle
    @State private var healthErrorMessage: String?
    @State private var showingHealthError = false
    @State private var lastQuestion: String?
    
    // Pre-defined quick questions for common plant care concerns
    private let quickQuestions = [
        "Why are my leaves turning yellow?",
        "How often should I water this plant?",
        "What's the best lighting for this plant?",
        "How do I know if my plant is healthy?",
        "When should I fertilize?",
        "How do I prevent pests?",
        "Is my plant getting too much/too little water?",
        "What temperature is best for this plant?"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with plant info
                headerSection
                
                // Health Analysis Button
                healthAnalysisSection
                
                // Quick Questions
                quickQuestionsSection
                
                // Conversation Area
                conversationSection
                
                // Input Area
                inputSection
            }
            .navigationTitle("AI Plant Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(BotanicaTheme.Colors.primary)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: BotanicaTheme.Spacing.md) {
            HStack(spacing: BotanicaTheme.Spacing.md) {
                AsyncPlantThumbnail(
                    photo: plant.primaryPhoto,
                    plant: plant,
                    size: 60,
                    cornerRadius: BotanicaTheme.CornerRadius.medium
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(plant.displayName)
                        .font(BotanicaTheme.Typography.headline)
                        .foregroundColor(.primary)
                    
                    Text(plant.scientificName)
                        .font(BotanicaTheme.Typography.scientificName)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: BotanicaTheme.Spacing.xs) {
                        Circle()
                            .fill(plant.healthStatusColor)
                            .frame(width: 8, height: 8)
                        Text(plant.healthStatus.rawValue.capitalized)
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, BotanicaTheme.Spacing.lg)
            .padding(.vertical, BotanicaTheme.Spacing.md)
        }
        .background(.regularMaterial)
    }
    
    // MARK: - Health Analysis Section
    
    private var healthAnalysisSection: some View {
        VStack(spacing: BotanicaTheme.Spacing.md) {
                    Button {
                        performHealthAnalysis()
                    } label: {
                        HStack(spacing: BotanicaTheme.Spacing.sm) {
                    if healthLoadState == .loading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "stethoscope")
                            .font(.title3)
                    }
                    
                    Text(healthLoadState == .loading ? "Analyzing..." : "AI Health Diagnosis")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                        .fill(BotanicaTheme.Gradients.primary)
                )
                .foregroundColor(.white)
            }
            .disabled(healthLoadState == .loading)
            .padding(.horizontal, BotanicaTheme.Spacing.lg)
            
            if !healthDiagnosisResult.isEmpty {
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                    Text("Health Analysis")
                        .font(BotanicaTheme.Typography.headline)
                        .foregroundColor(.primary)
                    
                    Text(healthDiagnosisResult)
                        .font(BotanicaTheme.Typography.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(BotanicaTheme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                        .fill(Color.blue.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, BotanicaTheme.Spacing.lg)
            }
        }
        .alert("Health Analysis Failed", isPresented: Binding(
            get: { showingHealthError },
            set: { _ in showingHealthError = false }
        )) {
            Button("Retry") { performHealthAnalysis() }
            Button("Cancel", role: .cancel) { healthLoadState = .idle }
        } message: {
            Text(healthErrorMessage ?? "Unable to run health analysis.")
        }
    }
    
    // MARK: - Quick Questions Section
    
    private var quickQuestionsSection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
            Text("Quick Questions")
                .font(BotanicaTheme.Typography.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, BotanicaTheme.Spacing.lg)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BotanicaTheme.Spacing.sm) {
                    ForEach(quickQuestions, id: \.self) { question in
                        Button(question) {
                            askQuestion(question)
                        }
                        .padding(.horizontal, BotanicaTheme.Spacing.md)
                        .padding(.vertical, BotanicaTheme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                                .fill(selectedQuickQuestion == question ? 
                                      BotanicaTheme.Colors.primary.opacity(0.1) : 
                                      Color.gray.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                                .stroke(
                                    selectedQuickQuestion == question ? 
                                    BotanicaTheme.Colors.primary : 
                                    Color.clear, 
                                    lineWidth: 1
                                )
                        )
                        .foregroundColor(selectedQuickQuestion == question ? 
                                       BotanicaTheme.Colors.primary : .primary)
                        .font(BotanicaTheme.Typography.callout)
                    }
                }
                .padding(.horizontal, BotanicaTheme.Spacing.lg)
            }
        }
        .padding(.vertical, BotanicaTheme.Spacing.md)
    }
    
    // MARK: - Conversation Section
    
    private var conversationSection: some View {
        LoadStateView(
            state: chatLoadState,
            retry: { retryLastQuestion() },
            loading: { conversationView(showThinking: true) },
            content: { conversationView(showThinking: false) }
        )
    }
    
    // MARK: - Input Section
    
    private var inputSection: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: BotanicaTheme.Spacing.sm) {
                TextField("Ask about your plant's care...", text: $currentQuestion, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(BotanicaTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .lineLimit(1...4)
                
                Button {
                    if !currentQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        askQuestion(currentQuestion)
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                    .foregroundColor(currentQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                                   .secondary : BotanicaTheme.Colors.primary)
                }
                .disabled(currentQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatLoadState == .loading)
            }
            .padding(BotanicaTheme.Spacing.lg)
            .background(.regularMaterial)
        }
    }
    
    // MARK: - Helper Methods
    
    private func askQuestion(_ question: String) {
        lastQuestion = question
        let userMessage = ConversationMessage(
            id: UUID(),
            content: question,
            isFromUser: true,
            timestamp: Date()
        )
        
        conversationHistory.append(userMessage)
        selectedQuickQuestion = question
        currentQuestion = ""
        chatLoadState = .loading
        
        Task {
            do {
                let response = try await coach.askCareQuestion(
                    question,
                    about: plant
                )
                
                let aiMessage = ConversationMessage(
                    id: UUID(),
                    content: response,
                    isFromUser: false,
                    timestamp: Date()
                )
                
                await MainActor.run {
                    conversationHistory.append(aiMessage)
                    chatLoadState = .loaded
                    selectedQuickQuestion = nil
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ConversationMessage(
                        id: UUID(),
                        content: "I'm sorry, I couldn't process your question right now. Please try again later.",
                        isFromUser: false,
                        timestamp: Date()
                    )
                    conversationHistory.append(errorMessage)
                    chatLoadState = .failed(error.localizedDescription)
                    selectedQuickQuestion = nil
                }
            }
        }
    }
    
    private func retryLastQuestion() {
        guard let lastQuestion else { return }
        chatLoadState = .loading
        
        Task {
            do {
                let response = try await coach.askCareQuestion(
                    lastQuestion,
                    about: plant
                )
                
                let aiMessage = ConversationMessage(
                    id: UUID(),
                    content: response,
                    isFromUser: false,
                    timestamp: Date()
                )
                
                await MainActor.run {
                    conversationHistory.append(aiMessage)
                    chatLoadState = .loaded
                }
            } catch {
                await MainActor.run {
                    chatLoadState = .failed(error.localizedDescription)
                }
            }
        }
    }
    
    private func performHealthAnalysis() {
        healthLoadState = .loading
        
        Task {
            do {
                let diagnosis = try await coach.diagnosePlantIssues(symptoms: "", for: plant)
                
                await MainActor.run {
                    healthDiagnosisResult = diagnosis
                    healthErrorMessage = nil
                    healthLoadState = .loaded
                    showingHealthError = false
                }
            } catch {
                await MainActor.run {
                    healthDiagnosisResult = "Unable to perform health analysis at this time. Please try again later."
                    healthErrorMessage = ErrorMessageFormatter.userFriendlyMessage(for: error)
                    healthLoadState = .failed(healthErrorMessage ?? "Unknown error")
                    showingHealthError = true
                }
            }
        }
    }

    // MARK: - Conversation Builder
    
    @ViewBuilder
    private func conversationView(showThinking: Bool) -> some View {
        ScrollView {
            LazyVStack(spacing: BotanicaTheme.Spacing.md) {
                ForEach(conversationHistory) { message in
                    ConversationBubbleView(message: message)
                }
                
                if showThinking {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: BotanicaTheme.Colors.primary))
                            .scaleEffect(0.8)
                        Text("Thinking...")
                            .font(BotanicaTheme.Typography.callout)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, BotanicaTheme.Spacing.lg)
                }
            }
            .padding(.vertical, BotanicaTheme.Spacing.md)
        }
    }
}

// MARK: - Supporting Models

struct ConversationMessage: Identifiable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
}

// MARK: - Conversation Bubble View

struct ConversationBubbleView: View {
    let message: ConversationMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: BotanicaTheme.Spacing.xs) {
                    Text(message.content)
                        .font(BotanicaTheme.Typography.body)
                        .foregroundColor(.white)
                        .padding(BotanicaTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                                .fill(BotanicaTheme.Colors.primary)
                        )
                    
                    Text(message.timestamp, style: .time)
                        .font(BotanicaTheme.Typography.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
            } else {
                HStack(alignment: .top, spacing: BotanicaTheme.Spacing.sm) {
                    // AI Avatar
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundColor(BotanicaTheme.Colors.primary)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(BotanicaTheme.Colors.primary.opacity(0.1))
                        )
                    
                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                        Text(message.content)
                            .font(BotanicaTheme.Typography.body)
                            .foregroundColor(.primary)
                            .padding(BotanicaTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                                    .fill(Color.gray.opacity(0.1))
                            )
                        
                        Text(message.timestamp, style: .time)
                            .font(BotanicaTheme.Typography.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, BotanicaTheme.Spacing.lg)
    }
}

#Preview {
    AICoachView(plant: MockDataGenerator.samplePlant)
        .modelContainer(MockDataGenerator.previewContainer())
}
