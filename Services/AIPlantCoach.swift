import Foundation
import SwiftData
import SwiftUI
import UIKit

/// AI-powered plant care coach service
/// Integrates with OpenAI to provide personalized plant care recommendations
class AIPlantCoach: ObservableObject {
    
    // MARK: - Properties
    
    @Published var isLoading = false
    @Published var lastError: Error?
    
    private let config = OpenAIConfig.shared
    private let session = URLSession.shared
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    
    // MARK: - Public Methods
    
    /// Generate comprehensive care plan for a plant with weather integration
    /// - Parameter plant: The plant to generate care for
    /// - Parameter includeWeather: Whether to include current weather conditions
    /// - Parameter careHistory: Recent care events for context
    /// - Returns: Structured care recommendations
    func generateCarePlan(
        for plant: Plant, 
        includeWeather: Bool = true,
        careHistory: [CareEvent] = []
    ) async throws -> PlantCareRecommendation {
        guard config.isConfigured else {
            throw AIPlantCoachError.notConfigured
        }
        
        await MainActor.run { self.isLoading = true; self.lastError = nil }
        defer { Task { await MainActor.run { self.isLoading = false } } }
        
        do {
            let prompt = buildAdvancedCarePlanPrompt(
                for: plant, 
                includeWeather: includeWeather,
                careHistory: careHistory
            )
            let response = try await sendChatRequest(prompt: prompt)
            
            // Parse structured response
            let careRecommendation = try parseCarePlanResponse(response)
            return careRecommendation
            
        } catch {
            await MainActor.run { self.lastError = error }
            throw error
        }
    }
    
    /// Generate predictive care recommendations using analytics
    /// - Parameters:
    ///   - plant: The plant to analyze
    ///   - careHistory: Recent care events for analysis
    /// - Returns: Advanced predictive recommendations
    func generatePredictiveRecommendations(
        for plant: Plant,
        careHistory: [CareEvent]
    ) async throws -> String {
        guard config.isConfigured else {
            throw AIPlantCoachError.notConfigured
        }
        
        await MainActor.run { self.isLoading = true; self.lastError = nil }
        defer { Task { await MainActor.run { self.isLoading = false } } }
        
        do {
            let prompt = buildPredictivePrompt(
                plant: plant, 
                careHistory: careHistory
            )
            let response = try await sendChatRequest(prompt: prompt)
            return response
            
        } catch {
            await MainActor.run { self.lastError = error }
            throw error
        }
    }
    
    /// Analyze plant health from care patterns and provide insights
    /// - Parameters:
    ///   - plant: The plant to analyze
    ///   - careEvents: Historical care events
    ///   - photos: Plant photos for visual analysis context
    /// - Returns: Health analysis with actionable insights
    func analyzePhoto(
        _ image: UIImage,
        for plant: Plant
    ) async throws -> String {
        // This would integrate with the PlantHealthVisionAnalyzer
        // For now, return a basic analysis
        return "Photo analysis not yet implemented"
    }
    
    /// Ask specific care question about a plant
    /// - Parameters:
    ///   - question: User's care question
    ///   - plant: The plant in question
    /// - Returns: AI response as string
    func askCareQuestion(_ question: String, about plant: Plant) async throws -> String {
        guard config.isConfigured else {
            throw AIPlantCoachError.notConfigured
        }
        
        await MainActor.run { self.isLoading = true; self.lastError = nil }
        defer { Task { await MainActor.run { self.isLoading = false } } }
        
        do {
            let prompt = buildCareQuestionPrompt(question: question, plant: plant)
            let response = try await sendChatRequest(prompt: prompt)
            return response
            
        } catch {
            await MainActor.run { self.lastError = error }
            throw error
        }
    }
    
    /// Diagnose plant health issues from description
    /// - Parameters:
    ///   - symptoms: Description of plant symptoms
    ///   - plant: The affected plant
    /// - Returns: Diagnosis and treatment recommendations
    func diagnosePlantIssues(symptoms: String, for plant: Plant) async throws -> String {
        guard config.isConfigured else {
            throw AIPlantCoachError.notConfigured
        }
        
        await MainActor.run { self.isLoading = true; self.lastError = nil }
        defer { Task { await MainActor.run { self.isLoading = false } } }
        
        do {
            let prompt = buildDiagnosisPrompt(symptoms: symptoms, plant: plant)
            let response = try await sendChatRequest(prompt: prompt)
            return response
            
        } catch {
            await MainActor.run { self.lastError = error }
            throw error
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func sendChatRequest(prompt: String) async throws -> String {
        guard let apiKey = config.apiKey else {
            throw AIPlantCoachError.notConfigured
        }
        
        // Build request URL
        guard let url = URL(string: config.baseURL + config.chatEndpoint) else {
            throw AIPlantCoachError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build request body
        let chatRequest = OpenAIChatRequest(
            model: config.defaultModel,
            messages: [
                ChatMessage(role: "system", content: systemPrompt),
                ChatMessage(role: "user", content: prompt)
            ],
            maxTokens: config.maxTokens,
            temperature: config.temperature
        )
        
        request.httpBody = try jsonEncoder.encode(chatRequest)
        
        // Send request
        let (data, response) = try await session.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIPlantCoachError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to parse error response
            if let errorResponse = try? jsonDecoder.decode(OpenAIError.self, from: data) {
                throw AIPlantCoachError.apiError(errorResponse.error.message)
            } else {
                throw AIPlantCoachError.httpError(httpResponse.statusCode)
            }
        }
        
        // Parse successful response
        let chatResponse = try jsonDecoder.decode(OpenAIChatResponse.self, from: data)
        
        guard let firstChoice = chatResponse.choices.first else {
            throw AIPlantCoachError.noResponse
        }
        
        return firstChoice.message.content
    }
    
    private func buildCarePlanPrompt(for plant: Plant) -> String {
        return """
        Please create a comprehensive care plan for this plant:
        
        Plant Details:
        - Scientific Name: \(plant.scientificName)
        - Common Names: \(plant.commonNames.joined(separator: ", "))
        - Growth Habit: \(plant.growthHabit.rawValue)
        - Current Health: \(plant.healthStatus.rawValue)
        - Light Level: \(plant.lightLevel.rawValue)
        - Source: \(plant.source)
        - Care Notes: \(plant.notes.isEmpty ? "None" : plant.notes)
        
        IMPORTANT: Provide specific, actionable watering amounts based on the pot size (\(plant.potSize) inches). 
        Calculate amounts in milliliters (ml) using this guidance:
        - Small plants (4-6"): 80-120ml
        - Medium plants (6-8"): 120-200ml  
        - Large plants (8-12"): 200-400ml
        - Extra large plants (12+"): 400-600ml
        
        Please provide care recommendations in the following JSON format:
        {
          "wateringSchedule": {
            "frequency": "specific watering frequency (e.g., 'Every 7-10 days')",
            "amount": "specific amount in ml (e.g., '150-200ml')",
            "technique": "detailed watering method and soil check instructions",
            "seasonalAdjustments": "how to adjust watering by season",
            "soilCheck": "specific instructions for checking when to water"
          },
          "lightRequirements": {
            "intensity": "light intensity needed",
            "duration": "hours of light per day",
            "placement": "where to place the plant",
            "seasonalConsiderations": "seasonal light adjustments"
          },
          "fertilizingSchedule": {
            "frequency": "how often to fertilize (e.g., 'Every 2-3 weeks during growing season')",
            "type": "specific type of fertilizer recommended",
            "amount": "specific amount (e.g., '2-3ml liquid fertilizer diluted in 200ml water')",
            "seasonalSchedule": "detailed seasonal fertilizing schedule",
            "dilution": "exact dilution ratios and mixing instructions"
          },
          "generalCare": {
            "humidity": "humidity requirements",
            "temperature": "temperature range",
            "repotting": "when and how to repot",
            "pruning": "pruning guidelines",
            "propagation": "propagation methods if applicable"
          },
          "seasonalTips": [
            {"season": "Spring", "tip": "spring care tip"},
            {"season": "Summer", "tip": "summer care tip"},
            {"season": "Fall", "tip": "fall care tip"},
            {"season": "Winter", "tip": "winter care tip"}
          ],
          "commonIssues": [
            {
              "issue": "common problem name",
              "symptoms": "what to look for",
              "solution": "how to fix it"
            }
          ]
        }
        
        Please ensure all recommendations are specific to this plant species and based on current botanical best practices.
        """
    }
    
    private func buildCareQuestionPrompt(question: String, plant: Plant) -> String {
        return """
        I have a question about caring for my plant:
        
        Plant Details:
        - Scientific Name: \(plant.scientificName)
        - Common Names: \(plant.commonNames.joined(separator: ", "))
        - Growth Habit: \(plant.growthHabit.rawValue)
        - Current Health: \(plant.healthStatus.rawValue)
        - Light Level: \(plant.lightLevel.rawValue)
        - Source: \(plant.source)
        
        Question: \(question)
        
        Please provide a detailed, practical answer based on current horticultural best practices.
        """
    }
    
    private func buildDiagnosisPrompt(symptoms: String, plant: Plant) -> String {
        return """
        I'm concerned about my plant's health. Here are the symptoms I'm observing:
        
        Plant Details:
        - Scientific Name: \(plant.scientificName)
        - Common Names: \(plant.commonNames.joined(separator: ", "))
        - Growth Habit: \(plant.growthHabit.rawValue)
        - Current Health: \(plant.healthStatus.rawValue)
        - Light Level: \(plant.lightLevel.rawValue)
        - Source: \(plant.source)
        
        Symptoms: \(symptoms)
        
        Please provide:
        1. Possible diagnoses (most likely causes)
        2. Specific treatment recommendations
        3. Prevention strategies
        4. When to seek professional help if needed
        
        Base your response on current plant pathology and horticultural science.
        """
    }
    
    private func parseCarePlanResponse(_ response: String) throws -> PlantCareRecommendation {
        // Extract JSON from response (in case there's additional text)
        guard let jsonStart = response.range(of: "{"),
              let jsonEnd = response.range(of: "}", options: .backwards) else {
            throw AIPlantCoachError.invalidResponse
        }
        
        let jsonString = String(response[jsonStart.lowerBound...jsonEnd.upperBound])
        let jsonData = jsonString.data(using: .utf8)!
        
        do {
            return try jsonDecoder.decode(PlantCareRecommendation.self, from: jsonData)
        } catch {
            // If JSON parsing fails, throw a more descriptive error
            throw AIPlantCoachError.responseParsingError(error.localizedDescription)
        }
    }
    
    /// System prompt that defines the AI assistant's role and expertise
    private var systemPrompt: String {
        """
        You are an expert plant care specialist and horticulturist with extensive knowledge of:
        - Plant biology and physiology
        - Indoor and outdoor plant care
        - Plant diseases and pest management
        - Seasonal care requirements
        - Watering, fertilizing, and pruning techniques
        - Light and environmental requirements
        - Plant propagation methods
        
        Always provide:
        - Accurate, science-based advice
        - Specific, actionable recommendations
        - Seasonal and environmental considerations
        - Safety warnings when appropriate
        - Clear explanations of the reasoning behind recommendations
        
        Be concise but comprehensive. Use botanical terms appropriately while remaining accessible to home gardeners.
        """
    }
    
    // MARK: - Advanced Prompt Building Methods
    
    private func buildAdvancedCarePlanPrompt(
        for plant: Plant, 
        includeWeather: Bool,
        careHistory: [CareEvent]
    ) -> String {
        var prompt = buildCarePlanPrompt(for: plant)
        
        if includeWeather {
            // Note: Weather integration would require importing WeatherKit
            // For now, providing static weather context
            let currentTemp = 72.0 // Default temperature
            prompt += """
            
            CURRENT CONDITIONS:
            - Temperature: \(String(format: "%.1f", currentTemp))°F
            - Consider seasonal factors in your recommendations
            
            Please adjust your recommendations based on current conditions.
            """
            
            // Seasonal considerations would be added here
        }
        
        if !careHistory.isEmpty {
            let recentEvents = Array(careHistory.prefix(10).sorted { $0.date > $1.date })
            prompt += """
            
            RECENT CARE HISTORY:
            """
            for event in recentEvents {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                prompt += """
                - \(formatter.string(from: event.date)): \(event.type.rawValue)
                """
                if let amount = event.amount {
                    prompt += " (\(amount)ml)"
                }
                if !event.notes.isEmpty {
                    prompt += " - \(event.notes)"
                }
                prompt += "\n"
            }
            
            prompt += """
            
            Please analyze this care history and adjust your recommendations accordingly.
            Look for patterns that suggest the plant's specific needs.
            """
        }
        
        return prompt
    }
    
    private func buildPredictivePrompt(
        plant: Plant, 
        careHistory: [CareEvent]
    ) -> String {
        var prompt = """
        As an expert plant care AI, analyze this plant's care history and provide predictive care recommendations.
        
        PLANT: \(plant.nickname) (\(plant.scientificName))
        
        CARE HISTORY:
        """
        
        // Add care history details
                    for (_, event) in careHistory.enumerated().prefix(10) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            prompt += "- \(formatter.string(from: event.date)): \(event.type.rawValue)\n"
        }
        
        prompt += """
        
        Please provide care predictions and recommendations based on this history.
        Focus on:
        1. When the plant likely needs water next
        2. Any patterns you notice in the care
        3. Specific recommendations for improvement
        4. Any concerns about the plant's health
        """
        
        return prompt
    }
    
    private func buildHealthAnalysisPrompt(
        plant: Plant, 
        careEvents: [CareEvent], 
        photos: [Photo]
    ) -> String {
        let recentCare = careEvents.filter { 
            Calendar.current.dateInterval(of: .month, for: Date())?.contains($0.date) ?? false 
        }
        let photoCount = photos.count
        let recentPhotos = photos.filter {
            Calendar.current.dateInterval(of: .month, for: Date())?.contains($0.timestamp) ?? false
        }.count
        
        return """
        Analyze the health status of this plant based on care patterns and photo documentation.
        
        PLANT: \(plant.nickname) (\(plant.scientificName))
        Current Health Status: \(plant.healthStatus.rawValue)
        Plant Age: \(Calendar.current.dateComponents([.day], from: plant.dateAdded, to: Date()).day ?? 0) days in collection
        
        CARE PATTERNS (Last 30 Days):
        - Total Care Events: \(recentCare.count)
        - Watering Events: \(recentCare.filter { $0.type == .watering }.count)
        - Fertilizing Events: \(recentCare.filter { $0.type == .fertilizing }.count)
        - Other Care Events: \(recentCare.filter { $0.type != .watering && $0.type != .fertilizing }.count)
        
        PHOTO DOCUMENTATION:
        - Total Photos: \(photoCount)
        - Recent Photos (30 days): \(recentPhotos)
        - Total Photos Available: \(photos.count)
        
        RECENT CARE NOTES:
        \(recentCare.compactMap { event in
            guard !event.notes.isEmpty else { return nil }
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "- \(formatter.string(from: event.date)): \(event.notes)"
        }.joined(separator: "\n"))
        
        Please provide health analysis in JSON format:
        {
          "currentHealth": {
            "score": "0-100 health score",
            "status": "excellent/good/fair/concerning/poor",
            "confidence": "confidence in assessment"
          },
          "trends": {
            "direction": "improving/stable/declining",
            "indicators": ["list of health indicators observed"],
            "photoEvidence": "assessment based on photo documentation"
          },
          "concerns": [
            {
              "issue": "specific concern",
              "severity": "low/medium/high",
              "symptoms": "observed symptoms",
              "recommendation": "what to do about it"
            }
          ],
          "strengths": [
            {
              "aspect": "what's going well",
              "evidence": "supporting evidence"
            }
          ],
          "recommendations": {
            "immediate": ["urgent actions needed"],
            "shortTerm": ["actions for next 1-2 weeks"],
            "longTerm": ["ongoing care improvements"]
          }
        }
        """
    }
    
    // MARK: - Advanced Response Parsing
    
    // Simplified response parsing - returns raw text for now
    private func parseSimpleResponse(_ response: String) -> String {
        return response
    }
    
    private func parseHealthAnalysisResponse(_ response: String) throws -> String {
        // For now, return the response as a simple string
        // In the future, this could parse structured health analysis
        return response
    }
}

// MARK: - Error Types

enum AIPlantCoachError: LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case noResponse
    case apiError(String)
    case httpError(Int)
    case responseParsingError(String)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "OpenAI API is not properly configured. Please check your API key."
        case .invalidURL:
            return "Invalid API URL configuration."
        case .invalidResponse:
            return "Received invalid response from OpenAI API."
        case .noResponse:
            return "No response received from OpenAI API."
        case .apiError(let message):
            return "OpenAI API Error: \(message)"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .responseParsingError(let details):
            return "Failed to parse AI response: \(details)"
        }
    }
}
