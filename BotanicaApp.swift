import SwiftUI
import SwiftData
import UserNotifications

/// The main entry point for the Botanica app.
/// Configures SwiftData persistence and applies the base theme.
@main
struct BotanicaApp: App {
    @StateObject private var notificationManager = NotificationManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("theme_mode") private var themeMode = "system"
    
    var colorScheme: ColorScheme? {
        switch themeMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil // system
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootBootstrapView()
            .preferredColorScheme(colorScheme)
            .environmentObject(notificationManager)
            .onAppear {
                setupNotificationDelegate()
            }
        }
        .modelContainer(for: [
            Plant.self,
            CareEvent.self,
            Reminder.self,
            Photo.self,
            CarePlan.self
        ])
    }
    
    /// Configure notification delegate for handling notification taps
    private func setupNotificationDelegate() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
}

/// Handles notification interactions
@MainActor
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    static let shared = NotificationDelegate()
    
    /// Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is active
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Handle notification tap
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping @Sendable () -> Void
    ) {
        // Forward the original userInfo to the app's notification manager on main actor
        let userInfo = response.notification.request.content.userInfo
        Task { @MainActor in
            NotificationManager.shared.handleNotificationTap(userInfo: userInfo)
        }
        completionHandler()
    }
}

/// Preview provider for SwiftUI previews
#Preview {
    ContentView()
        .modelContainer(for: [
            Plant.self,
            CareEvent.self,
            Reminder.self,
            Photo.self,
            CarePlan.self
        ], inMemory: true)
}
