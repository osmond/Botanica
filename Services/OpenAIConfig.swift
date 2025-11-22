import Foundation
import Security

// MARK: - Secure Storage for API Keys

/// Secure storage utility for sensitive data using iOS Keychain Services
///
/// This class provides a type-safe wrapper around the Keychain Services API for storing
/// sensitive data like API keys. Data is encrypted and persisted securely by the system.
///
/// # Thread Safety
/// - This class is marked as `@unchecked Sendable` because Keychain operations are thread-safe
/// - The underlying Security framework handles synchronization internally
/// - Can be safely called from any thread or actor context
///
/// # Usage Example
/// ```swift
/// // Store a value
/// SecureStorage.shared.set("sk-abc123", forKey: "openai_api_key")
///
/// // Retrieve a value
/// if let apiKey = SecureStorage.shared.get(forKey: "openai_api_key") {
///     print("API Key retrieved")
/// }
///
/// // Delete a value
/// SecureStorage.shared.delete(forKey: "openai_api_key")
/// ```
///
/// # Security Considerations
/// - Data is encrypted and stored in the iOS Keychain
/// - Uses `kSecAttrAccessibleWhenUnlocked` - data accessible only when device is unlocked
/// - Survives app deletion/reinstall (by iOS design)
/// - Not backed up to iCloud/iTunes by default
///
/// # Error Handling
/// - Methods return `Bool` to indicate success/failure
/// - Failures typically indicate permission issues or corrupted keychain
/// - Check return values and handle appropriately in calling code
///
/// Embedded in OpenAIConfig to avoid Xcode project configuration complexity.
import Foundation
import Security

// MARK: - Secure Storage for API Keys

/// Secure storage utility for sensitive data using iOS Keychain Services
///
/// This class provides a type-safe wrapper around the Keychain Services API for storing
/// sensitive data like API keys. Data is encrypted and persisted securely by the system.
///
/// # Thread Safety
/// - This class is marked as `@unchecked Sendable` because Keychain operations are thread-safe
/// - The underlying Security framework handles synchronization internally
/// - Can be safely called from any thread or actor context
///
/// # Usage Example
/// ```swift
/// // Store a value
/// SecureStorage.shared.set("sk-abc123", forKey: "openai_api_key")
///
/// // Retrieve a value
/// if let apiKey = SecureStorage.shared.get(forKey: "openai_api_key") {
///     print("API Key retrieved")
/// }
///
/// // Delete a value
/// SecureStorage.shared.delete(forKey: "openai_api_key")
/// ```
///
/// # Security Considerations
/// - Data is encrypted and stored in the iOS Keychain
/// - Uses `kSecAttrAccessibleWhenUnlocked` - data accessible only when device is unlocked
/// - Survives app deletion/reinstall (by iOS design)
/// - Not backed up to iCloud/iTunes by default
///
/// # Error Handling
/// - Methods return `Bool` to indicate success/failure
/// - Failures typically indicate permission issues or corrupted keychain
/// - Check return values and handle appropriately in calling code
///
/// Embedded in OpenAIConfig to avoid Xcode project configuration complexity.
private final class SecureStorage: @unchecked Sendable {
    static let shared = SecureStorage()
    private init() {}
    
    func set(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        // Delete existing
        _ = delete(forKey: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }
    
    func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &dataTypeRef) == errSecSuccess,
              let data = dataTypeRef as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// MARK: - OpenAI Configuration

/// Configuration manager for OpenAI API integration
///
/// This struct manages all configuration settings for communicating with OpenAI's API,
/// including secure API key storage, endpoint URLs, model selection, and request parameters.
///
/// # Thread Safety
/// - Value type (struct) - thread-safe by default
/// - API key storage uses thread-safe Keychain operations via SecureStorage
/// - Can be accessed from any thread or actor context
///
/// # Usage Example
/// ```swift
/// // Access configuration
/// let config = OpenAIConfig.shared
///
/// // Set API key (stored securely in Keychain)
/// config.apiKey = "sk-abc123..."
///
/// // Check configuration
/// if config.isConfigured {
///     // Ready to make API calls
///     let url = config.baseURL + config.chatEndpoint
/// }
/// ```
///
/// # Configuration Properties
/// - `apiKey`: OpenAI API key (stored securely in Keychain)
/// - `baseURL`: OpenAI API base URL (default: https://api.openai.com/v1)
/// - `defaultModel`: GPT model to use (default: gpt-4o-mini for cost efficiency)
/// - `temperature`: Response randomness (0.0-2.0, default: 0.7 for balanced creativity)
/// - `maxTokens`: Maximum tokens per response (default: 2000)
///
/// # API Key Security
/// - API keys are stored in iOS Keychain using SecureStorage
/// - Automatic migration from insecure UserDefaults on first access
/// - Keys are encrypted and only accessible when device is unlocked
/// - Uses keychain key: "com.botanica.openai.apikey"
///
/// # Error Handling
/// - `isConfigured` property checks if API key is set
/// - Always verify configuration before making API calls
/// - Handle `notConfigured` errors by prompting user to set API key in Settings
///
/// # Performance Notes
/// - API key access reads from Keychain each time (slight overhead)
/// - Configuration is a lightweight struct - no caching needed
/// - Minimal overhead for checking configuration state
struct OpenAIConfig {
    static let shared = OpenAIConfig()
    
    private static let keychainKey = "com.botanica.openai.apikey"
    private static let referenceImagesFlagKey = "useAIReferenceImages"
    
    // MARK: - Configuration Properties
    
    /// OpenAI API base URL
    let baseURL = "https://api.openai.com/v1"
    
    /// Chat completions endpoint
    let chatEndpoint = "/chat/completions"
    
    /// Default model for plant care analysis
    let defaultModel = "gpt-4o-mini"
    
    /// Maximum tokens for responses
    let maxTokens = 2000
    
    /// Temperature for response creativity (0.0 = deterministic, 1.0 = creative)
    let temperature: Double = 0.7
    
    /// API key - retrieved from secure Keychain storage
    var apiKey: String? {
        get {
            SecureStorage.shared.get(forKey: Self.keychainKey)
        }
        set {
            if let newValue = newValue, !newValue.isEmpty {
                _ = SecureStorage.shared.set(newValue, forKey: Self.keychainKey)
            } else {
                _ = SecureStorage.shared.delete(forKey: Self.keychainKey)
            }
        }
    }
    
    /// Check if API is properly configured
    var isConfigured: Bool {
        guard let key = apiKey else { return false }
        return !key.isEmpty
    }
    
    /// Whether AI-generated reference images should be used when a plant
    /// has no user photos. Backed by UserDefaults.
    var useAIReferenceImages: Bool {
        get { UserDefaults.standard.bool(forKey: Self.referenceImagesFlagKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.referenceImagesFlagKey) }
    }
    
    // MARK: - Private Init
    
    private init() {
        // Perform one-time migration from UserDefaults to Keychain
        migrateAPIKeyIfNeeded()
    }
    
    /// Migrate existing API key from UserDefaults to Keychain
    private func migrateAPIKeyIfNeeded() {
        if let oldKey = UserDefaults.standard.string(forKey: "openai_api_key"), !oldKey.isEmpty {
            _ = SecureStorage.shared.set(oldKey, forKey: Self.keychainKey)
            UserDefaults.standard.removeObject(forKey: "openai_api_key")
            print("OpenAIConfig: Migrated API key to secure storage")
        }
    }
}
