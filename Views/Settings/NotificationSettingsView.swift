import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingPermissionAlert = false
    @State private var preferredNotificationTime = Date()
    @State private var loadState: LoadState = .idle
    @State private var errorMessage: String?
    
    // User preferences stored in UserDefaults
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("wateringRemindersEnabled") private var wateringRemindersEnabled = true
    @AppStorage("fertilizingRemindersEnabled") private var fertilizingRemindersEnabled = true
    @AppStorage("healthCheckRemindersEnabled") private var healthCheckRemindersEnabled = true
    @AppStorage("overdueNotificationsEnabled") private var overdueNotificationsEnabled = true
    @AppStorage("notificationTimeHour") private var notificationTimeHour = 9
    @AppStorage("notificationTimeMinute") private var notificationTimeMinute = 0
    
    var body: some View {
        NavigationView {
            List {
                // Permission Status Section
                permissionStatusSection
                
                // General Settings Section
                generalSettingsSection
                
                // Notification Types Section
                notificationTypesSection
                
                // Timing Section
                timingSection
                
                // Management Section
                managementSection
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                updatePreferredTime()
            }
            .overlay(alignment: .bottom) {
                if loadState == .loading {
                    HStack(spacing: BotanicaTheme.Spacing.sm) {
                        ProgressView()
                        Text("Updating notifications…")
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, BotanicaTheme.Spacing.md)
                }
            }
            .alert("Notifications Disabled", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    openAppSettings()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable notifications for Botanica in your device settings to receive plant care reminders.")
            }
            .alert("Notification Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { _ in errorMessage = nil }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Something went wrong.")
            }
        }
    }
    
    // MARK: - View Components
    
    private var permissionStatusSection: some View {
        Section {
            HStack {
                Image(systemName: notificationStatusIcon)
                    .foregroundColor(notificationStatusColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notification Status")
                        .font(BotanicaTheme.Typography.headline)
                    
                    Text(notificationStatusText)
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if notificationManager.authorizationStatus == .denied {
                    Button("Fix") {
                        showingPermissionAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(BotanicaTheme.Colors.primary)
                } else if notificationManager.authorizationStatus == .notDetermined {
                    Button("Enable") {
                        Task { await requestPermission() }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(BotanicaTheme.Colors.primary)
                }
            }
            .padding(.vertical, BotanicaTheme.Spacing.xs)
        } header: {
            Text("Permission")
        }
    }
    
    private var generalSettingsSection: some View {
        Section {
            Toggle("Plant Care Notifications", isOn: $notificationsEnabled)
                .onChange(of: notificationsEnabled) { _, newValue in
                    notificationManager.isEnabled = newValue
                    if !newValue {
                        Task {
                            await notificationManager.removeAllNotifications()
                        }
                    }
                }
                .disabled(!notificationManager.canSendNotifications)
        } header: {
            Text("General")
        } footer: {
            Text("Enable or disable all plant care notifications. When disabled, you won't receive any reminders.")
        }
    }
    
    private var notificationTypesSection: some View {
        Section {
            Toggle("Watering Reminders", isOn: $wateringRemindersEnabled)
                .disabled(!effectiveNotificationsEnabled)
            
            Toggle("Fertilizing Reminders", isOn: $fertilizingRemindersEnabled)
                .disabled(!effectiveNotificationsEnabled)
            
            Toggle("Health Check Alerts", isOn: $healthCheckRemindersEnabled)
                .disabled(!effectiveNotificationsEnabled)
            
            Toggle("Overdue Notifications", isOn: $overdueNotificationsEnabled)
                .disabled(!effectiveNotificationsEnabled)
        } header: {
            Text("Notification Types")
        } footer: {
            Text("Choose which types of plant care reminders you'd like to receive.")
        }
    }
    
    private var timingSection: some View {
        Section {
            HStack {
                Text("Preferred Time")
                Spacer()
                Text(formatPreferredTime())
                    .foregroundColor(.secondary)
            }
            
            DatePicker(
                "Notification Time",
                selection: $preferredNotificationTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .onChange(of: preferredNotificationTime) { _, newValue in
                savePreferredTime(newValue)
            }
            .disabled(!effectiveNotificationsEnabled)
        } header: {
            Text("Timing")
        } footer: {
            Text("Set your preferred time to receive daily plant care reminders.")
        }
    }
    
    private var managementSection: some View {
        Section {
            Button("Refresh All Notifications", role: .none) {
                Task { await refreshAllNotifications() }
            }
            .disabled(!effectiveNotificationsEnabled)
            
            Button("Clear All Notifications", role: .destructive) {
                Task { await clearAllNotifications() }
            }
            .disabled(!effectiveNotificationsEnabled)
        } header: {
            Text("Management")
        } footer: {
            Text("Refresh notifications after changing plant care schedules, or clear all notifications to start fresh.")
        }
    }
    
    // MARK: - Computed Properties
    
    private var notificationStatusIcon: String {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        case .provisional, .ephemeral:
            return "clock.circle.fill"
        @unknown default:
            return "questionmark.circle.fill"
        }
    }
    
    private var notificationStatusColor: Color {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return BotanicaTheme.Colors.success
        case .denied:
            return BotanicaTheme.Colors.error
        case .notDetermined:
            return BotanicaTheme.Colors.warning
        case .provisional, .ephemeral:
            return BotanicaTheme.Colors.sunYellow
        @unknown default:
            return .secondary
        }
    }
    
    private var notificationStatusText: String {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return "Notifications are enabled and working"
        case .denied:
            return "Notifications are disabled in Settings"
        case .notDetermined:
            return "Tap 'Enable' to allow notifications"
        case .provisional:
            return "Provisional authorization granted"
        case .ephemeral:
            return "Temporary authorization granted"
        @unknown default:
            return "Unknown notification status"
        }
    }
    
    private var effectiveNotificationsEnabled: Bool {
        return notificationsEnabled && notificationManager.canSendNotifications
    }
    
    // MARK: - Actions
    
    private func requestPermission() async {
        loadState = .loading
        let granted = await notificationManager.requestNotificationPermission()
        await notificationManager.updateAuthorizationStatus()
        if !granted {
            showingPermissionAlert = true
        }
        loadState = .loaded
    }
    
    private func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    private func refreshAllNotifications() async {
        loadState = .loading
        await notificationManager.updateAuthorizationStatus()
        guard notificationManager.authorizationStatus == .authorized else {
            showingPermissionAlert = true
            loadState = .idle
            return
        }
        // TODO: inject plants and reschedule via NotificationService
        loadState = .loaded
    }
    
    private func clearAllNotifications() async {
        loadState = .loading
        await notificationManager.removeAllNotifications()
        loadState = .loaded
    }
    
    // MARK: - Time Management
    
    private func updatePreferredTime() {
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = notificationTimeHour
        dateComponents.minute = notificationTimeMinute
        
        if let date = calendar.date(from: dateComponents) {
            preferredNotificationTime = date
        }
    }
    
    private func savePreferredTime(_ date: Date) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        
        notificationTimeHour = components.hour ?? 9
        notificationTimeMinute = components.minute ?? 0
    }
    
    private func formatPreferredTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: preferredNotificationTime)
    }
}

#Preview {
    NotificationSettingsView()
}
