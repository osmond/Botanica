import Foundation
import UIKit

/// Lightweight OpenAI client for chat and image generations.
/// Uses OpenAIConfig for configuration and secure key storage.
final class OpenAIClient {
    enum OpenAIError: LocalizedError {
        case notConfigured
        case invalidResponse
        case decodingFailed
        case server(String)
        case network(Error)
        
        var errorDescription: String? {
            switch self {
            case .notConfigured: return "OpenAI API key is missing."
            case .invalidResponse: return "Received an invalid response from OpenAI."
            case .decodingFailed: return "Failed to decode the OpenAI response."
            case .server(let message): return message
            case .network(let error): return error.localizedDescription
            }
        }
    }
    
    private let config: OpenAIConfig
    private let session: URLSession
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    
    init(config: OpenAIConfig = .shared, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }
    
    // MARK: - Chat
    
    struct ChatMessage: Codable {
        let role: String
        let content: String
    }
    
    struct ChatRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let temperature: Double
        let maxTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case model
            case messages
            case temperature
            case maxTokens = "max_tokens"
        }
    }
    
    struct ChatResponse: Codable {
        struct Choice: Codable {
            struct ChatMessage: Codable {
                let role: String
                let content: String
            }
            let message: ChatMessage
        }
        let choices: [Choice]
    }
    
    func sendChat(
        messages: [ChatMessage],
        model: String? = nil,
        temperature: Double? = nil,
        maxTokens: Int? = nil
    ) async throws -> String {
        guard let apiKey = config.apiKey, !apiKey.isEmpty else {
            throw OpenAIError.notConfigured
        }
        
        guard let url = URL(string: config.baseURL + config.chatEndpoint) else {
            throw OpenAIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ChatRequest(
            model: model ?? config.defaultModel,
            messages: messages,
            temperature: temperature ?? config.temperature,
            maxTokens: maxTokens ?? config.maxTokens
        )
        request.httpBody = try jsonEncoder.encode(payload)
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIError.invalidResponse
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw OpenAIError.server(message)
            }
            let decoded = try jsonDecoder.decode(ChatResponse.self, from: data)
            guard let first = decoded.choices.first else {
                throw OpenAIError.decodingFailed
            }
            return first.message.content
        } catch let error as OpenAIError {
            throw error
        } catch {
            throw OpenAIError.network(error)
        }
    }
    
    // MARK: - Images
    
    struct ImageRequest: Codable {
        let model: String
        let prompt: String
        let size: String
        let n: Int
        let responseFormat: String
        
        enum CodingKeys: String, CodingKey {
            case model, prompt, size, n
            case responseFormat = "response_format"
        }
    }
    
    struct ImageResponse: Codable {
        struct ImageData: Codable {
            let b64_json: String
        }
        let data: [ImageData]
    }
    
    func generateImage(prompt: String, size: String = "1024x1024") async throws -> UIImage {
        guard let apiKey = config.apiKey, !apiKey.isEmpty else {
            throw OpenAIError.notConfigured
        }
        
        guard let url = URL(string: config.baseURL + "/images/generations") else {
            throw OpenAIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ImageRequest(
            model: "gpt-image-1",
            prompt: prompt,
            size: size,
            n: 1,
            responseFormat: "b64_json"
        )
        request.httpBody = try jsonEncoder.encode(payload)
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIError.invalidResponse
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Image generation failed"
                throw OpenAIError.server(message)
            }
            
            let decoded = try jsonDecoder.decode(ImageResponse.self, from: data)
            guard let b64 = decoded.data.first?.b64_json,
                  let imageData = Data(base64Encoded: b64),
                  let image = UIImage(data: imageData) else {
                throw OpenAIError.decodingFailed
            }
            return image
        } catch let error as OpenAIError {
            throw error
        } catch {
            throw OpenAIError.network(error)
        }
    }
}
