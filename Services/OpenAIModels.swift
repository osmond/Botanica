import Foundation

/// Data models for OpenAI API communication
/// Handles request and response structures for chat completions

// MARK: - Request Models

struct OpenAIChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let maxTokens: Int
    let temperature: Double
    let stream: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
        case temperature
        case stream
    }
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

// MARK: - Response Models

struct OpenAIChatResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [ChatChoice]
    let usage: Usage?
}

struct ChatChoice: Codable {
    let index: Int
    let message: ChatMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index
        case message
        case finishReason = "finish_reason"
    }
}

struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Error Models

struct OpenAIError: Codable, Error {
    let error: ErrorDetails
}

struct ErrorDetails: Codable {
    let message: String
    let type: String
    let code: String?
}

// MARK: - Plant Care Response Models

/// Structured response for plant care recommendations
struct PlantCareRecommendation: Codable {
    let wateringSchedule: WateringSchedule
    let lightRequirements: LightRequirements
    let fertilizingSchedule: FertilizingSchedule
    let generalCare: GeneralCare
    let seasonalTips: [SeasonalTip]
    let commonIssues: [CommonIssue]
}

struct WateringSchedule: Codable {
    let frequency: String
    let amount: String
    let technique: String
    let seasonalAdjustments: String
}

struct LightRequirements: Codable {
    let intensity: String
    let duration: String
    let placement: String
    let seasonalConsiderations: String
}

struct FertilizingSchedule: Codable {
    let frequency: String
    let type: String
    let amount: String
    let seasonalSchedule: String
}

struct GeneralCare: Codable {
    let humidity: String
    let temperature: String
    let repotting: String
    let pruning: String
    let propagation: String?
}

struct SeasonalTip: Codable {
    let season: String
    let tip: String
}

struct CommonIssue: Codable {
    let issue: String
    let symptoms: String
    let solution: String
}

// PlantIdentificationResult is defined in AIService.swift to match view usage.
