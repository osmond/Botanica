import SwiftUI
import Foundation

/// Centralized service container to keep dependencies in one place.
/// Exposed via environment for easy injection and testing.
struct AppServices {
    static let shared = AppServices()
    
    let openAI: OpenAIClient
    let notifications: NotificationService
    let analytics: AnalyticsService
    
    init(
        openAI: OpenAIClient = OpenAIClient(),
        notifications: NotificationService? = nil,
        analytics: AnalyticsService = AnalyticsService()
    ) {
        self.openAI = openAI
        self.notifications = notifications ?? NotificationService(manager: NotificationManager.shared)
        self.analytics = analytics
    }
}

private struct AppServicesKey: EnvironmentKey {
    static let defaultValue: AppServices = AppServices()
}

extension EnvironmentValues {
    var appServices: AppServices {
        get { self[AppServicesKey.self] }
        set { self[AppServicesKey.self] = newValue }
    }
}
