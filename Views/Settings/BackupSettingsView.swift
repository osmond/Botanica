import SwiftUI
import SwiftData

struct BackupSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage(AutoBackupDefaults.enabledKey) private var autoBackupEnabled = true
    @AppStorage(AutoBackupDefaults.includePhotosKey) private var includePhotos = false
    @AppStorage(AutoBackupDefaults.includeCareHistoryKey) private var includeCareHistory = true
    @AppStorage(AutoBackupDefaults.includeRemindersKey) private var includeReminders = true
    @AppStorage(AutoBackupDefaults.frequencyKey) private var frequencyRaw = AutoBackupFrequency.daily.rawValue
    @AppStorage(AutoBackupDefaults.preferredDestinationKey) private var destinationRaw = AutoBackupDestination.iCloudDrive.rawValue
    @AppStorage(AutoBackupDefaults.lastRunKey) private var lastRunTimestamp = 0.0
    @AppStorage(AutoBackupDefaults.lastFileKey) private var lastFileName = ""
    @AppStorage(AutoBackupDefaults.lastLocationKey) private var lastLocation = ""
    
    @State private var isRunningBackup = false
    @State private var backupError: String?
    @State private var backupSuccess = false
    
    private var frequency: AutoBackupFrequency {
        AutoBackupFrequency(rawValue: frequencyRaw) ?? .daily
    }
    
    private var destination: AutoBackupDestination {
        AutoBackupDestination(rawValue: destinationRaw) ?? .iCloudDrive
    }
    
    private var iCloudAvailable: Bool {
        FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil
    }
    
    private var lastBackupText: String {
        guard lastRunTimestamp > 0 else { return "Not backed up yet" }
        let date = Date(timeIntervalSince1970: lastRunTimestamp)
        return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    SettingsToggleRow(
                        title: "Automatic Backups",
                        subtitle: "Keep a daily backup of your plants",
                        icon: "arrow.clockwise.icloud",
                        color: BotanicaTheme.Colors.primary,
                        isOn: $autoBackupEnabled
                    )
                }
                
                Section("Backup Details") {
                    SettingsInfoRow(
                        title: "Last Backup",
                        subtitle: lastFileName.isEmpty ? nil : lastFileName,
                        icon: "clock.fill",
                        color: BotanicaTheme.Colors.leafGreen,
                        value: lastBackupText
                    )
                    
                    SettingsInfoRow(
                        title: "Location",
                        subtitle: "Backups are stored in Files",
                        icon: "folder.fill",
                        color: BotanicaTheme.Colors.soilBrown,
                        value: lastLocation.isEmpty ? destination.label : lastLocation
                    )
                }
                
                Section("Preferences") {
                    Picker("Frequency", selection: $frequencyRaw) {
                        ForEach(AutoBackupFrequency.allCases, id: \.rawValue) { option in
                            Text(option.label).tag(option.rawValue)
                        }
                    }
                    
                    Picker("Destination", selection: $destinationRaw) {
                        ForEach(AutoBackupDestination.allCases, id: \.rawValue) { option in
                            Text(option.label).tag(option.rawValue)
                        }
                    }
                    
                    if destination == .iCloudDrive && !iCloudAvailable {
                        Text("iCloud Drive isn’t available right now. Backups will be stored on this device.")
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(BotanicaTheme.Colors.textSecondary)
                    }
                    
                    Toggle("Include Care History", isOn: $includeCareHistory)
                    Toggle("Include Reminders", isOn: $includeReminders)
                    Toggle("Include Photos", isOn: $includePhotos)
                }
                
                Section {
                    Button(isRunningBackup ? "Backing Up…" : "Run Backup Now") {
                        runBackup()
                    }
                    .disabled(isRunningBackup)
                    
                    if let backupError {
                        Text(backupError)
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(BotanicaTheme.Colors.error)
                    } else if backupSuccess {
                        Text("Backup complete.")
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(BotanicaTheme.Colors.success)
                    }
                }
            }
            .navigationTitle("Backups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func runBackup() {
        backupError = nil
        backupSuccess = false
        isRunningBackup = true
        
        Task { @MainActor in
            do {
                _ = try AutoBackupService.shared.runBackup(context: modelContext)
                backupSuccess = true
            } catch {
                backupError = error.localizedDescription
            }
            isRunningBackup = false
        }
    }
}

/*
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plant.self, configurations: config)
    BackupSettingsView()
        .modelContainer(container)
}
*/
