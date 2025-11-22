//
//  ErrorMessageFormatterTests.swift
//  BotanicaTests
//
//  Created by Assistant on 10/5/25.
//

import XCTest
@testable import Botanica

@MainActor
final class ErrorMessageFormatterTests: XCTestCase {
    
    // MARK: - AIServiceError Formatting Tests
    
    func testAIServiceError_NotConfigured() {
        // Given: Not configured error
        let error = AIServiceError.notConfigured
        
        // When: Format error message
        let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
        
        // Then: Should mention API key setup
        XCTAssertTrue(message.contains("API key"), "Message should mention API key")
        XCTAssertTrue(message.contains("Settings"), "Message should mention Settings")
        XCTAssertFalse(message.contains("Error"), "Should be user-friendly without 'Error' word")
    }
    
    func testAIServiceError_InvalidURL() {
        // Given: Invalid URL error
        let error = AIServiceError.invalidURL
        
        // When: Format error message
        let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
        
        // Then: Should be descriptive
        XCTAssertTrue(message.contains("URL") || message.contains("configuration"), "Message should mention URL or configuration")
    }
    
    func testAIServiceError_Timeout() {
        // Given: Timeout error
        let error = AIServiceError.timeout
        
        // When: Format error message
        let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
        
        // Then: Should mention timeout and suggest checking connection
        XCTAssertTrue(message.contains("timed out") || message.contains("timeout"), "Message should mention timeout")
        XCTAssertTrue(message.contains("connection") || message.contains("internet"), "Message should mention connection")
    }
    
    func testAIServiceError_ImageProcessing() {
        // Given: Image processing error
        let error = AIServiceError.imageProcessingError
        
        // When: Format error message
        let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
        
        // Then: Should mention image processing
        XCTAssertTrue(message.contains("image") || message.contains("process"), "Message should mention image processing")
    }
    
    func testAIServiceError_APIError_QuotaExceeded() {
        // Given: API error with quota message
        let error = AIServiceError.apiError("insufficient quota remaining")
        
        // When: Format error message
        let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
        
        // Then: Should mention quota and suggest upgrade
        XCTAssertTrue(message.contains("quota"), "Message should mention quota")
        XCTAssertTrue(message.contains("upgrade") || message.contains("plan"), "Message should suggest upgrade")
    }
    
    func testAIServiceError_APIError_InvalidKey() {
        // Given: API error with invalid key message
        let error = AIServiceError.apiError("Incorrect API key provided")
        
        // When: Format error message
        let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
        
        // Then: Should mention API key check
        XCTAssertTrue(message.contains("API key"), "Message should mention API key")
        XCTAssertTrue(message.contains("Settings"), "Message should mention Settings")
    }
    
    func testAIServiceError_HTTPError_401() {
        // Given: HTTP 401 error
        let error = AIServiceError.httpError(401)
        
        // When: Format error message
        let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
        
        // Then: Should mention authentication
        XCTAssertTrue(message.contains("Authentication") || message.contains("API key"), "Message should mention authentication")
    }
    
    func testAIServiceError_HTTPError_429() {
        // Given: HTTP 429 (rate limit) error
        let error = AIServiceError.httpError(429)
        
        // When: Format error message
        let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
        
        // Then: Should mention rate limit
        XCTAssertTrue(message.contains("rate limit") || message.contains("429"), "Message should mention rate limit")
        XCTAssertTrue(message.contains("minutes") || message.contains("moment"), "Message should suggest waiting")
    }
    
    func testAIServiceError_HTTPError_500() {
        // Given: HTTP 500 (server error)
        let error = AIServiceError.httpError(500)
        
        // When: Format error message
        let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
        
        // Then: Should mention server error
        XCTAssertTrue(message.contains("server") || message.contains("500"), "Message should mention server")
        XCTAssertTrue(message.contains("later") || message.contains("temporarily"), "Message should suggest trying later")
    }
    
    // MARK: - URLError Formatting Tests
    
    func testURLError_NotConnectedToInternet() {
        // Given: No internet error
        let error = URLError(.notConnectedToInternet)
        
        // When: Format error message
        let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
        
        // Then: Should clearly state no internet
        XCTAssertTrue(message.contains("internet") || message.contains("network"), "Message should mention internet/network")
        XCTAssertTrue(message.contains("check") || message.contains("connect"), "Message should suggest checking connection")
    }
    
    func testURLError_TimedOut() {
        // Given: Timeout error
        let error = URLError(.timedOut)
        
        // When: Format error message
        let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
        
        // Then: Should mention timeout
        XCTAssertTrue(message.contains("timed out") || message.contains("timeout"), "Message should mention timeout")
    }
    
    func testURLError_CannotConnectToHost() {
        // Given: Cannot connect error
        let error = URLError(.cannotConnectToHost)
        
        // When: Format error message
        let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
        
        // Then: Should mention connection issue
        XCTAssertTrue(message.contains("connect") || message.contains("server"), "Message should mention connection")
    }
    
    // MARK: - DecodingError Formatting Tests
    
    func testDecodingError_KeyNotFound() {
        // Given: Missing key error
        let key = CodingKey(stringValue: "scientificName")
        let context = DecodingError.Context(codingPath: [key], debugDescription: "Key not found")
        let error = DecodingError.keyNotFound(key, context)
        
        // When: Format error message
        let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
        
        // Then: Should mention missing field
        XCTAssertTrue(message.contains("scientificName") || message.contains("field"), "Message should mention field name")
        XCTAssertTrue(message.contains("missing") || message.contains("expected"), "Message should indicate missing data")
    }
    
    func testDecodingError_TypeMismatch() {
        // Given: Type mismatch error
        let key = CodingKey(stringValue: "confidence")
        let context = DecodingError.Context(codingPath: [key], debugDescription: "Type mismatch")
        let error = DecodingError.typeMismatch(Double.self, context)
        
        // When: Format error message
        let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
        
        // Then: Should mention data format issue
        XCTAssertTrue(message.contains("format") || message.contains("type"), "Message should mention format/type")
    }
    
    // MARK: - WeatherError Formatting Tests
    
    func testWeatherError_LocationPermissionDenied() {
        // Given: Permission denied error
        let error = WeatherError.locationPermissionDenied
        
        // When: Format error message
        let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
        
        // Then: Should mention permissions
        XCTAssertTrue(message.contains("permission") || message.contains("denied"), "Message should mention permission")
        XCTAssertTrue(message.contains("Settings") || message.contains("enable"), "Message should suggest enabling permissions")
    }
    
    // MARK: - Error Title Tests
    
    func testErrorTitle_AIServiceError() {
        // Given: AI service error
        let error = AIServiceError.notConfigured
        
        // When: Get error title
        let title = ErrorMessageFormatter.errorTitle(for: error)
        
        // Then: Should be appropriate title
        XCTAssertTrue(title.contains("AI"), "Title should mention AI")
    }
    
    func testErrorTitle_NetworkError() {
        // Given: Network error
        let error = URLError(.notConnectedToInternet)
        
        // When: Get error title
        let title = ErrorMessageFormatter.errorTitle(for: error)
        
        // Then: Should be appropriate title
        XCTAssertTrue(title.contains("Network"), "Title should mention Network")
    }
    
    // MARK: - Suggested Action Tests
    
    func testSuggestedAction_NotConfigured() {
        // Given: Not configured error
        let error = AIServiceError.notConfigured
        
        // When: Get suggested action
        let action = ErrorMessageFormatter.suggestedAction(for: error)
        
        // Then: Should suggest configuring API key
        XCTAssertEqual(action, .configureAPIKey, "Should suggest configuring API key")
    }
    
    func testSuggestedAction_NetworkError() {
        // Given: Network error
        let error = URLError(.notConnectedToInternet)
        
        // When: Get suggested action
        let action = ErrorMessageFormatter.suggestedAction(for: error)
        
        // Then: Should suggest checking network
        XCTAssertEqual(action, .checkNetwork, "Should suggest checking network")
    }
    
    func testSuggestedAction_RateLimit() {
        // Given: Rate limit error
        let error = AIServiceError.httpError(429)
        
        // When: Get suggested action
        let action = ErrorMessageFormatter.suggestedAction(for: error)
        
        // Then: Should suggest waiting and retrying
        XCTAssertEqual(action, .waitAndRetry, "Should suggest waiting and retrying")
    }
    
    func testSuggestedAction_Timeout() {
        // Given: Timeout error
        let error = URLError(.timedOut)
        
        // When: Get suggested action
        let action = ErrorMessageFormatter.suggestedAction(for: error)
        
        // Then: Should suggest retry
        XCTAssertEqual(action, .retry, "Should suggest retry")
    }
    
    // MARK: - Error Severity Tests
    
    func testSeverity_NotConfigured() {
        // Given: Not configured error (blocks features)
        let error = AIServiceError.notConfigured
        
        // When: Get severity
        let severity = ErrorMessageFormatter.severity(for: error)
        
        // Then: Should be high severity
        XCTAssertEqual(severity, .high, "Configuration errors should be high severity")
    }
    
    func testSeverity_NetworkError() {
        // Given: No internet error
        let error = URLError(.notConnectedToInternet)
        
        // When: Get severity
        let severity = ErrorMessageFormatter.severity(for: error)
        
        // Then: Should be high severity (no connectivity)
        XCTAssertEqual(severity, .high, "No internet should be high severity")
    }
    
    func testSeverity_Timeout() {
        // Given: Timeout error (temporary)
        let error = URLError(.timedOut)
        
        // When: Get severity
        let severity = ErrorMessageFormatter.severity(for: error)
        
        // Then: Should be medium severity (retryable)
        XCTAssertEqual(severity, .medium, "Timeout should be medium severity")
    }
    
    func testSeverity_WeatherError() {
        // Given: Weather service error (non-critical feature)
        let error = WeatherError.locationUnavailable
        
        // When: Get severity
        let severity = ErrorMessageFormatter.severity(for: error)
        
        // Then: Should be low severity
        XCTAssertEqual(severity, .low, "Weather errors should be low severity")
    }
    
    // MARK: - Error Action Properties Tests
    
    func testErrorAction_Titles() {
        // Verify all action titles are user-friendly
        XCTAssertEqual(ErrorAction.retry.title, "Try Again")
        XCTAssertEqual(ErrorAction.checkNetwork.title, "Check Network")
        XCTAssertEqual(ErrorAction.checkPermissions.title, "Check Permissions")
        XCTAssertEqual(ErrorAction.configureAPIKey.title, "Configure API Key")
        XCTAssertEqual(ErrorAction.waitAndRetry.title, "Wait and Retry")
        XCTAssertEqual(ErrorAction.contactSupport.title, "Contact Support")
        XCTAssertEqual(ErrorAction.updateApp.title, "Update App")
    }
    
    func testErrorAction_Descriptions() {
        // Verify all action descriptions are present and helpful
        XCTAssertFalse(ErrorAction.retry.description.isEmpty)
        XCTAssertFalse(ErrorAction.checkNetwork.description.isEmpty)
        XCTAssertFalse(ErrorAction.checkPermissions.description.isEmpty)
        XCTAssertFalse(ErrorAction.configureAPIKey.description.isEmpty)
        XCTAssertFalse(ErrorAction.waitAndRetry.description.isEmpty)
        
        // Verify descriptions are actionable
        XCTAssertTrue(ErrorAction.checkNetwork.description.contains("check") || 
                     ErrorAction.checkNetwork.description.contains("Check"))
    }
    
    // MARK: - Error Severity Properties Tests
    
    func testErrorSeverity_Colors() {
        // Verify severity colors are appropriate
        XCTAssertEqual(ErrorSeverity.low.color, "yellow")
        XCTAssertEqual(ErrorSeverity.medium.color, "orange")
        XCTAssertEqual(ErrorSeverity.high.color, "red")
    }
    
    func testErrorSeverity_Icons() {
        // Verify severity icons are appropriate SF Symbols
        XCTAssertEqual(ErrorSeverity.low.icon, "info.circle.fill")
        XCTAssertEqual(ErrorSeverity.medium.icon, "exclamationmark.triangle.fill")
        XCTAssertEqual(ErrorSeverity.high.icon, "xmark.octagon.fill")
    }
    
    // MARK: - Generic Error Handling Tests
    
    func testGenericError_LocalizedError() {
        // Given: Custom LocalizedError
        struct CustomError: LocalizedError {
            var errorDescription: String? {
                return "Custom error description"
            }
        }
        let error = CustomError()
        
        // When: Format error message
        let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
        
        // Then: Should use localized description
        XCTAssertEqual(message, "Custom error description")
    }
    
    func testGenericError_NSError() {
        // Given: NSError with description
        let error = NSError(
            domain: "TestDomain",
            code: 123,
            userInfo: [NSLocalizedDescriptionKey: "Test error description"]
        )
        
        // When: Format error message
        let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
        
        // Then: Should use localized description
        XCTAssertEqual(message, "Test error description")
    }
    
    func testGenericError_UnknownError() {
        // Given: Unknown error type
        struct UnknownError: Error {}
        let error = UnknownError()
        
        // When: Format error message
        let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
        
        // Then: Should provide generic helpful message
        XCTAssertTrue(message.contains("error"), "Message should mention error")
        XCTAssertTrue(message.contains("try again") || message.contains("Try again"), "Message should suggest retry")
        XCTAssertFalse(message.isEmpty, "Should provide some message")
    }
    
    // MARK: - File System Error Tests
    
    func testNSError_FileNotFound() {
        // Given: File not found error
        let error = NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
        
        // When: Format error message
        let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
        
        // Then: Should mention file not found
        XCTAssertTrue(message.contains("file") || message.contains("File"), "Message should mention file")
        XCTAssertTrue(message.contains("found") || message.contains("not found"), "Message should indicate file not found")
    }
    
    func testNSError_OutOfSpace() {
        // Given: Out of space error
        let error = NSError(domain: NSCocoaErrorDomain, code: NSFileWriteOutOfSpaceError, userInfo: nil)
        
        // When: Format error message
        let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
        
        // Then: Should mention storage space
        XCTAssertTrue(message.contains("space") || message.contains("storage"), "Message should mention space/storage")
        XCTAssertTrue(message.contains("free") || message.contains("available"), "Message should suggest freeing space")
    }
    
    // MARK: - Message Quality Tests
    
    func testMessageQuality_NoTechnicalJargon() {
        // Test various errors for user-friendly language
        let errors: [Error] = [
            AIServiceError.notConfigured,
            URLError(.notConnectedToInternet),
            WeatherError.locationPermissionDenied
        ]
        
        for error in errors {
            let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
            
            // Should not contain overly technical terms
            XCTAssertFalse(message.contains("NULL"), "Should not contain NULL")
            XCTAssertFalse(message.contains("nil"), "Should not contain nil")
            XCTAssertFalse(message.contains("Exception"), "Should not contain Exception")
            XCTAssertFalse(message.contains("thrown"), "Should not contain thrown")
        }
    }
    
    func testMessageQuality_ProvidesGuidance() {
        // Test that messages provide actionable guidance
        let errors: [Error] = [
            AIServiceError.notConfigured,
            URLError(.notConnectedToInternet),
            AIServiceError.httpError(429)
        ]
        
        for error in errors {
            let message = ErrorMessageFormatter.userFriendlyMessage(for: error)
            
            // Should contain action verbs
            let hasActionGuidance = message.contains("Please") ||
                                   message.contains("try") ||
                                   message.contains("check") ||
                                   message.contains("enable") ||
                                   message.contains("configure")
            
            XCTAssertTrue(hasActionGuidance, "Message should provide actionable guidance: \(message)")
        }
    }
}

// MARK: - Helper Extensions

private extension CodingKey {
    init(stringValue: String) {
        struct Key: CodingKey {
            var stringValue: String
            var intValue: Int? { nil }
            init(stringValue: String) {
                self.stringValue = stringValue
            }
            init?(intValue: Int) {
                return nil
            }
        }
        self = Key(stringValue: stringValue)
    }
}
