//
//  ErrorMessageFormatter.swift
//  Botanica
//
//  Created by Assistant on 10/5/25.
//

import Foundation

/// Centralized utility for formatting error messages into user-friendly text
///
/// This formatter transforms technical errors into clear, actionable messages
/// that help users understand what went wrong and how to fix it.
///
/// # Features
/// - Detects error types and provides contextual messages
/// - Suggests specific actions users can take
/// - Handles nested errors and error chains
/// - Preserves technical details for debugging while showing friendly messages
///
/// # Usage
/// ```swift
/// do {
///     try await riskyOperation()
/// } catch {
///     errorMessage = ErrorMessageFormatter.userFriendlyMessage(for: error)
///     showingError = true
/// }
/// ```
@MainActor
struct ErrorMessageFormatter {
    
    // MARK: - Public Interface
    
    /// Convert any error into a user-friendly message
    /// - Parameter error: The error to format
    /// - Returns: A clear, actionable error message suitable for display
    static func userFriendlyMessage(for error: Error) -> String {
        // Check for specific error types in order of specificity
        
        // AI Service errors
        if let aiError = error as? AIServiceError {
            return formatAIServiceError(aiError)
        }
        
        // AI Plant Coach errors
        if let coachError = error as? AIPlantCoachError {
            return formatAIPlantCoachError(coachError)
        }
        
        // Weather service errors
        if let weatherError = error as? WeatherError {
            return formatWeatherError(weatherError)
        }
        
        // URL/Network errors
        if let urlError = error as? URLError {
            return formatURLError(urlError)
        }
        
        // Decoding errors (JSON parsing)
        if let decodingError = error as? DecodingError {
            return formatDecodingError(decodingError)
        }
        
        // LocalizedError protocol (custom errors with descriptions)
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }
        
        // Generic NSError
        let nsError = error as NSError
        return formatNSError(nsError)
    }
    
    /// Get a short title for an error (for alert titles)
    /// - Parameter error: The error to get a title for
    /// - Returns: A brief title describing the error category
    static func errorTitle(for error: Error) -> String {
        if error is AIServiceError || error is AIPlantCoachError {
            return "AI Service Error"
        }
        
        if error is WeatherError {
            return "Weather Service Error"
        }
        
        if error is URLError {
            return "Network Error"
        }
        
        if error is DecodingError {
            return "Data Error"
        }
        
        return "Error"
    }
    
    /// Determine if an error suggests a user action is needed
    /// - Parameter error: The error to analyze
    /// - Returns: Suggested action or nil if no specific action recommended
    static func suggestedAction(for error: Error) -> ErrorAction? {
        if let aiError = error as? AIServiceError {
            switch aiError {
            case .notConfigured:
                return .configureAPIKey
            case .networkError, .timeout:
                return .checkNetwork
            case .httpError(let code) where code == 429:
                return .waitAndRetry
            default:
                return .retry
            }
        }
        
        if error is WeatherError {
            return .checkPermissions
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return .checkNetwork
            case .timedOut:
                return .retry
            default:
                return .retry
            }
        }
        
        return .retry
    }
    
    // MARK: - Error Formatting Methods
    
    private static func formatAIServiceError(_ error: AIServiceError) -> String {
        // AIServiceError already implements LocalizedError with great messages
        // Use the built-in descriptions
        return error.localizedDescription
    }
    
    private static func formatAIPlantCoachError(_ error: AIPlantCoachError) -> String {
        // AIPlantCoachError already implements LocalizedError
        return error.localizedDescription
    }
    
    private static func formatWeatherError(_ error: WeatherError) -> String {
        // WeatherError already implements LocalizedError
        return error.localizedDescription
    }
    
    private static func formatURLError(_ error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet:
            return "No internet connection. Please check your network settings and try again."
            
        case .timedOut:
            return "The request timed out. Please check your connection and try again."
            
        case .cannotConnectToHost:
            return "Cannot connect to the server. Please check your internet connection."
            
        case .networkConnectionLost:
            return "Network connection was lost. Please reconnect and try again."
            
        case .cannotFindHost:
            return "Cannot find the server. Please check your internet connection."
            
        case .dnsLookupFailed:
            return "DNS lookup failed. Please check your network settings."
            
        case .badServerResponse:
            return "The server returned an invalid response. Please try again later."
            
        case .userCancelledAuthentication:
            return "Authentication was cancelled."
            
        case .userAuthenticationRequired:
            return "Authentication is required to continue."
            
        case .secureConnectionFailed:
            return "Secure connection failed. Please check your network security settings."
            
        case .serverCertificateUntrusted:
            return "Server certificate is not trusted. This may be a security risk."
            
        default:
            return "Network error: \(error.localizedDescription). Please check your connection."
        }
    }
    
    private static func formatDecodingError(_ error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, _):
            let fieldName = key.stringValue
            return "Missing expected data field '\(fieldName)'. The server response may be incomplete. Please try again."
            
        case .valueNotFound(let type, _):
            return "Missing required value of type \(type). The server response may be incomplete. Please try again."
            
        case .typeMismatch(let type, let context):
            let fieldName = context.codingPath.last?.stringValue ?? "unknown field"
            return "Unexpected data format for '\(fieldName)' (expected \(type)). The server response may be invalid. Please try again."
            
        case .dataCorrupted(let context):
            if let underlyingError = context.underlyingError {
                return "Data format error: \(underlyingError.localizedDescription). Please try again."
            } else {
                return "The received data is corrupted or invalid. Please try again."
            }
            
        @unknown default:
            return "Failed to process server response. Please try again."
        }
    }
    
    private static func formatNSError(_ error: NSError) -> String {
        let domain = error.domain
        let code = error.code
        
        // Handle common NSError domains
        switch domain {
        case NSCocoaErrorDomain:
            return formatCocoaError(error)
            
        case NSURLErrorDomain:
            // This should be caught by URLError case above, but just in case
            return "Network error (code \(code)). Please check your connection."
            
        case "CLError", "kCLErrorDomain":
            return formatLocationError(error)
            
        default:
            // Include useful information from userInfo if available
            if let description = error.userInfo[NSLocalizedDescriptionKey] as? String {
                return description
            } else if let failureReason = error.userInfo[NSLocalizedFailureReasonErrorKey] as? String {
                return failureReason
            } else {
                return "An error occurred (code \(code)). Please try again."
            }
        }
    }
    
    private static func formatCocoaError(_ error: NSError) -> String {
        switch error.code {
        case NSFileNoSuchFileError:
            return "The requested file could not be found."
            
        case NSFileReadNoPermissionError:
            return "Permission denied. Cannot read the file."
            
        case NSFileWriteNoPermissionError:
            return "Permission denied. Cannot write to the file."
            
        case NSFileReadUnknownError:
            return "An error occurred while reading the file."
            
        case NSFileWriteUnknownError:
            return "An error occurred while writing the file."
            
        case NSFileWriteOutOfSpaceError:
            return "Not enough storage space available. Please free up some space and try again."
            
        case NSPropertyListReadCorruptError:
            return "The data file is corrupted. Please try reinstalling the app."
            
        default:
            return "A file system error occurred (code \(error.code)). Please try again."
        }
    }
    
    private static func formatLocationError(_ error: NSError) -> String {
        switch error.code {
        case 0: // kCLErrorLocationUnknown
            return "Unable to determine your location. Please try again in a moment."
            
        case 1: // kCLErrorDenied
            return "Location permission denied. Please enable location access in Settings to use weather-based care recommendations."
            
        case 2: // kCLErrorNetwork
            return "Location services network error. Please check your internet connection."
            
        default:
            return "Location services error. Please check your location permissions in Settings."
        }
    }
    
    private static func formatGenericError(_ error: Error) -> String {
        // Last resort: use the error's description
        let description = String(describing: error)
        
        // Try to make it more user-friendly
        if description.contains("API") || description.contains("api") {
            return "An API error occurred. Please try again later."
        }
        
        if description.contains("network") || description.contains("Network") {
            return "A network error occurred. Please check your connection and try again."
        }
        
        if description.contains("permission") || description.contains("Permission") {
            return "Permission error. Please check your app permissions in Settings."
        }
        
        // Generic friendly message
        return "An unexpected error occurred. Please try again. If the problem persists, please contact support."
    }
}

// MARK: - Supporting Types

/// Suggested actions users can take in response to errors
enum ErrorAction {
    case retry
    case checkNetwork
    case checkPermissions
    case configureAPIKey
    case waitAndRetry
    case contactSupport
    case updateApp
    
    var title: String {
        switch self {
        case .retry:
            return "Try Again"
        case .checkNetwork:
            return "Check Network"
        case .checkPermissions:
            return "Check Permissions"
        case .configureAPIKey:
            return "Configure API Key"
        case .waitAndRetry:
            return "Wait and Retry"
        case .contactSupport:
            return "Contact Support"
        case .updateApp:
            return "Update App"
        }
    }
    
    var description: String {
        switch self {
        case .retry:
            return "Please try the operation again."
        case .checkNetwork:
            return "Please check your internet connection and try again."
        case .checkPermissions:
            return "Please check app permissions in Settings."
        case .configureAPIKey:
            return "Please configure your API key in Settings > AI Settings."
        case .waitAndRetry:
            return "Please wait a moment and try again."
        case .contactSupport:
            return "Please contact support if this problem persists."
        case .updateApp:
            return "Please update to the latest version of the app."
        }
    }
}

// MARK: - Extension for Error Severity

extension ErrorMessageFormatter {
    
    /// Determine the severity level of an error
    /// - Parameter error: The error to analyze
    /// - Returns: The severity level (for UI styling/prioritization)
    static func severity(for error: Error) -> ErrorSeverity {
        // Critical errors that block functionality
        if let aiError = error as? AIServiceError {
            switch aiError {
            case .notConfigured:
                return .high // Blocks AI features entirely
            case .networkError, .timeout:
                return .medium // Temporary, retryable
            default:
                return .medium
            }
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return .high // No connectivity
            default:
                return .medium
            }
        }
        
        // Weather errors are lower priority (nice-to-have feature)
        if error is WeatherError {
            return .low
        }
        
        // Default to medium severity
        return .medium
    }
}

/// Error severity levels for UI presentation
enum ErrorSeverity {
    case low      // Informational, doesn't block core features
    case medium   // Temporary issue, retry may help
    case high     // Critical issue, blocks functionality
    
    var color: String {
        switch self {
        case .low: return "yellow"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "info.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "xmark.octagon.fill"
        }
    }
}
