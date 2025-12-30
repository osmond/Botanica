import SwiftUI
import Security

// MARK: - Local SecureStorage Helper

/// Minimal secure storage for API keys - embedded to avoid build configuration issues
private struct SecureStorageHelper {
    private static let keychainKey = "com.botanica.openai.apikey"
    
    static func set(_ value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        delete() // Remove existing
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }
    
    static func get() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
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
    
    static func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey
        ]
        _ = SecItemDelete(query as CFDictionary)
    }
}

/// Settings view for configuring AI features
/// Allows users to configure OpenAI API integration with secure Keychain storage
struct AISettingsView: View {
    @State private var apiKey = ""
    @AppStorage("coachEnabled") private var coachEnabled: Bool = true
    @AppStorage("coachRuleOverdueWatering") private var coachRuleOverdueWatering: Bool = true
    @AppStorage("coachRuleStreakNudge") private var coachRuleStreakNudge: Bool = true
    @AppStorage("coachResetToken") private var coachResetToken: String = ""
    @AppStorage("developerOptionsEnabled") private var developerOptionsEnabled: Bool = false
    @AppStorage("thumbnailCacheCapacity") private var thumbnailCacheCapacity: Double = 200
    @AppStorage("useAIReferenceImages") private var useAIReferenceImages: Bool = false
    @State private var showingInfo = false
    @State private var testingConnection = false
    @State private var testResult: TestResult?
    
    enum TestResult {
        case success
        case failure(String)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                        HStack {
                            Image(systemName: "brain.head.profile.fill")
                                .foregroundColor(BotanicaTheme.Colors.primary)
                            Text("AI Plant Coach")
                                .font(BotanicaTheme.Typography.title3)
                                .foregroundColor(BotanicaTheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            Button {
                                showingInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundColor(BotanicaTheme.Colors.primary)
                            }
                        }
                        
                        Text("Get personalized plant care recommendations powered by AI")
                            .font(BotanicaTheme.Typography.body)
                            .foregroundColor(BotanicaTheme.Colors.textSecondary)
                    }
                    .padding(.vertical, BotanicaTheme.Spacing.xs)
                }
                
                Section(header: Text("API Configuration")) {
                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                        Text("OpenAI API Key")
                            .font(BotanicaTheme.Typography.bodyEmphasized)
                        
                        SecureField("Enter your OpenAI API key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: apiKey) { _, newValue in
                                // Save to secure storage when changed
                                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                if trimmed.isEmpty {
                                    SecureStorageHelper.delete()
                                    testResult = nil
                                } else {
                                    _ = SecureStorageHelper.set(trimmed)
                                }
                            }
                        
                        if !apiKey.isEmpty {
                            Button {
                                testConnection()
                            } label: {
                                HStack {
                                    if testingConnection {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "checkmark.circle")
                                    }
                                    Text("Test Connection")
                                }
                            }
                            .disabled(testingConnection)
                            
                            if let result = testResult {
                                switch result {
                                case .success:
                                    Label("Connection successful!", systemImage: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(BotanicaTheme.Typography.caption)
                                case .failure(let error):
                                    Label("Connection failed: \(error)", systemImage: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(BotanicaTheme.Typography.caption)
                                }
                            }
                        }
                        
                        Text("Your API key is stored securely in Keychain and never shared.")
                            .font(BotanicaTheme.Typography.caption2)
                            .foregroundColor(BotanicaTheme.Colors.textSecondary)
                    }
                }
                
                Section(header: Text("Features")) {
                    Toggle("Enable AI Coach (local tips by default)", isOn: $coachEnabled)
                    FeatureRow(
                        icon: "wand.and.stars",
                        title: "Care Plan Generation",
                        description: "Get comprehensive care plans tailored to your plants"
                    )
                    
                    FeatureRow(
                        icon: "questionmark.circle",
                        title: "Care Questions",
                        description: "Ask specific questions about plant care"
                    )
                    
                    FeatureRow(
                        icon: "stethoscope",
                        title: "Plant Diagnosis",
                        description: "Diagnose plant health issues from symptoms"
                    )
                    
                    Toggle("Use AI placeholders for plant photos", isOn: $useAIReferenceImages)
                        .font(BotanicaTheme.Typography.body)
                        .foregroundColor(BotanicaTheme.Colors.textPrimary)
                        .tint(BotanicaTheme.Colors.primary)
                        .padding(.top, BotanicaTheme.Spacing.sm)
                        .onChange(of: useAIReferenceImages) { _, enabled in
                            if !enabled {
                                PlantImageService.shared.clearCache()
                            }
                        }
                }
                if coachEnabled {
                    Section(header: Text("Coach Rules"), footer: Text("Coach runs locally by default. Disable specific rules to reduce suggestions.").font(BotanicaTheme.Typography.caption).foregroundColor(.secondary)) {
                        Toggle("Overdue Watering Suggestions", isOn: $coachRuleOverdueWatering)
                        // Preview
                        CoachCard(suggestion: CoachSuggestion(
                            id: UUID(),
                            title: "Water soon: Monstera",
                            message: "~200ml. Check top inch is dry.",
                            reason: "Demo preview",
                            plantId: nil,
                            surface: .today,
                            expiresAt: Date().addingTimeInterval(3600)
                        ), onAction: nil)
                        .disabled(true)
                        .opacity(0.8)
                        Toggle("Streak Nudges", isOn: $coachRuleStreakNudge)
                        CoachCard(suggestion: CoachSuggestion(
                            id: UUID(),
                            title: "Quick win: log one care",
                            message: "Keep your streak going with any small task.",
                            reason: "Demo preview",
                            plantId: nil,
                            surface: .today,
                            expiresAt: Date().addingTimeInterval(3600)
                        ), onAction: nil)
                        .disabled(true)
                        .opacity(0.8)
                    }
                    Section(header: Text("Coach Maintenance"), footer: Text("Clears cached suggestions and re-evaluates rules on next open.").font(BotanicaTheme.Typography.caption).foregroundColor(.secondary)) {
                        Button(role: .destructive) {
                            coachResetToken = UUID().uuidString
                            HapticManager.shared.selection()
                        } label: {
                            Label("Reset Coach Suggestions", systemImage: "arrow.counterclockwise")
                        }
                    }
                }
                
                if developerOptionsEnabled {
                    Section(header: Text("Developer Options"), footer: Text("Adjust image cache size. Use carefully.").font(BotanicaTheme.Typography.caption).foregroundColor(.secondary)) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Thumbnail Cache Capacity: \(Int(thumbnailCacheCapacity))")
                                    .font(BotanicaTheme.Typography.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Apply") {
                                    Task { await ThumbnailCache.shared.setCapacity(Int(thumbnailCacheCapacity)) }
                                }
                            }
                            Slider(value: $thumbnailCacheCapacity, in: 50...800, step: 10)
                        }
                        Button("Disable Developer Options", role: .destructive) {
                            developerOptionsEnabled = false
                        }
                    }
                }
            }
            .navigationTitle("AI Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingInfo) {
                AIInfoView()
            }
            .onAppear {
                // Load API key from secure storage
                if let storedKey = SecureStorageHelper.get() {
                    apiKey = storedKey
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Long-press to toggle Developer Options
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .simultaneousGesture(LongPressGesture(minimumDuration: 1.0).onEnded { _ in
                        developerOptionsEnabled.toggle()
                        HapticManager.shared.selection()
                    })
                }
            }
        }
    }
    
    private func testConnection() {
        testingConnection = true
        testResult = nil
        
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            testingConnection = false
            testResult = .failure("API key is empty")
            HapticManager.shared.error()
            return
        }
        
        let client = OpenAIClient()
        let messages = [OpenAIClient.ChatMessage(role: "user", content: "Ping")]

        Task {
            do {
                _ = try await client.sendChat(messages: messages, temperature: 0, maxTokens: 5)
                await MainActor.run {
                    testingConnection = false
                    testResult = .success
                    HapticManager.shared.success()
                }
            } catch {
                await MainActor.run {
                    testingConnection = false
                    testResult = .failure(error.localizedDescription)
                    HapticManager.shared.error()
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(BotanicaTheme.Colors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BotanicaTheme.Typography.bodyEmphasized)
                    .foregroundColor(BotanicaTheme.Colors.textPrimary)
                
                Text(description)
                    .font(BotanicaTheme.Typography.caption)
                    .foregroundColor(BotanicaTheme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct AIInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                        Text("About AI Plant Coach")
                            .font(BotanicaTheme.Typography.title2)
                            .foregroundColor(BotanicaTheme.Colors.textPrimary)
                        
                        Text("AI Plant Coach uses OpenAI's advanced language models to provide expert plant care advice tailored to your specific plants and conditions.")
                            .font(BotanicaTheme.Typography.body)
                            .foregroundColor(BotanicaTheme.Colors.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                        Text("Getting Your API Key")
                            .font(BotanicaTheme.Typography.title3)
                            .foregroundColor(BotanicaTheme.Colors.textPrimary)
                        
                        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                            Text("1. Visit openai.com and create an account")
                            Text("2. Go to the API section in your account")
                            Text("3. Generate a new API key")
                            Text("4. Copy and paste it into the settings")
                        }
                        .font(BotanicaTheme.Typography.body)
                        .foregroundColor(BotanicaTheme.Colors.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                        Text("Privacy & Security")
                            .font(BotanicaTheme.Typography.title3)
                            .foregroundColor(BotanicaTheme.Colors.textPrimary)
                        
                        Text("• Your API key is stored locally on your device\n• Plant data is only sent to OpenAI for analysis\n• No personal information is shared\n• You control your usage and costs")
                            .font(BotanicaTheme.Typography.body)
                            .foregroundColor(BotanicaTheme.Colors.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                        Text("Usage Costs")
                            .font(BotanicaTheme.Typography.title3)
                            .foregroundColor(BotanicaTheme.Colors.textPrimary)
                        
                        Text("OpenAI charges based on usage. Each AI interaction costs a few cents. You can monitor your usage on the OpenAI dashboard.")
                            .font(BotanicaTheme.Typography.body)
                            .foregroundColor(BotanicaTheme.Colors.textPrimary)
                    }
                }
                .padding()
            }
            .navigationTitle("AI Information")
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
}

#Preview {
    AISettingsView()
}
