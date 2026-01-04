import Foundation
import SwiftData

enum AutoBackupDefaults {
    static let enabledKey = "auto_backup_enabled"
    static let includePhotosKey = "auto_backup_include_photos"
    static let includeCareHistoryKey = "auto_backup_include_care_history"
    static let includeRemindersKey = "auto_backup_include_reminders"
    static let frequencyKey = "auto_backup_frequency"
    static let lastRunKey = "auto_backup_last_run"
    static let lastFileKey = "auto_backup_last_file"
    static let lastLocationKey = "auto_backup_last_location"
    static let preferredDestinationKey = "auto_backup_destination"
}

enum AutoBackupFrequency: String, CaseIterable {
    case daily
    case weekly
    case monthly
    
    var interval: TimeInterval {
        switch self {
        case .daily: return 60 * 60 * 24
        case .weekly: return 60 * 60 * 24 * 7
        case .monthly: return 60 * 60 * 24 * 30
        }
    }
    
    var label: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

enum AutoBackupDestination: String, CaseIterable {
    case iCloudDrive
    case localDocuments
    
    var label: String {
        switch self {
        case .iCloudDrive: return "iCloud Drive"
        case .localDocuments: return "On My iPhone"
        }
    }
}

enum AutoBackupError: LocalizedError {
    case iCloudUnavailable
    
    var errorDescription: String? {
        switch self {
        case .iCloudUnavailable:
            return "iCloud Drive is not available on this device."
        }
    }
}

@MainActor
final class AutoBackupService {
    static let shared = AutoBackupService()
    
    private let fileManager = FileManager.default
    private let maxBackupFiles = 10
    
    func maybeRunBackup(context: ModelContext) async {
        guard isEnabled else { return }
        guard shouldRunBackup else { return }
        do {
            _ = try runBackup(context: context)
        } catch {
            // Silent fail for background backup attempts.
        }
    }
    
    func runBackup(context: ModelContext) throws -> DataExportResult {
        let destination = preferredDestination
        let directory = try backupDirectory(for: destination)
        let options = DataExportOptions(
            includePhotos: includePhotos,
            includeCareHistory: includeCareHistory,
            includeReminders: includeReminders
        )
        
        let result = try DataExportService.shared.exportData(
            context: context,
            format: .json,
            options: options,
            filePrefix: "Botanica Backup",
            destinationDirectory: directory.url
        )
        
        saveBackupMetadata(result: result, locationLabel: destinationLabel(for: destination, fallback: directory.isFallback))
        cleanupOldBackups(in: directory.url)
        return result
    }
    
    var lastBackupDate: Date? {
        let timestamp = UserDefaults.standard.double(forKey: AutoBackupDefaults.lastRunKey)
        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }
    
    var lastBackupFileName: String? {
        UserDefaults.standard.string(forKey: AutoBackupDefaults.lastFileKey)
    }
    
    var lastBackupLocation: String? {
        UserDefaults.standard.string(forKey: AutoBackupDefaults.lastLocationKey)
    }
    
    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: AutoBackupDefaults.enabledKey) as? Bool ?? true
    }
    
    var includePhotos: Bool {
        UserDefaults.standard.object(forKey: AutoBackupDefaults.includePhotosKey) as? Bool ?? false
    }
    
    var includeCareHistory: Bool {
        UserDefaults.standard.object(forKey: AutoBackupDefaults.includeCareHistoryKey) as? Bool ?? true
    }
    
    var includeReminders: Bool {
        UserDefaults.standard.object(forKey: AutoBackupDefaults.includeRemindersKey) as? Bool ?? true
    }
    
    var preferredDestination: AutoBackupDestination {
        if let raw = UserDefaults.standard.string(forKey: AutoBackupDefaults.preferredDestinationKey),
           let destination = AutoBackupDestination(rawValue: raw) {
            return destination
        }
        return .iCloudDrive
    }
    
    var frequency: AutoBackupFrequency {
        if let raw = UserDefaults.standard.string(forKey: AutoBackupDefaults.frequencyKey),
           let frequency = AutoBackupFrequency(rawValue: raw) {
            return frequency
        }
        return .daily
    }
    
    private var shouldRunBackup: Bool {
        guard let lastRun = lastBackupDate else { return true }
        return Date().timeIntervalSince(lastRun) >= frequency.interval
    }
    
    private func backupDirectory(for destination: AutoBackupDestination) throws -> (url: URL, isFallback: Bool) {
        switch destination {
        case .iCloudDrive:
            if let ubiquity = fileManager.url(forUbiquityContainerIdentifier: nil) {
                let dir = ubiquity
                    .appendingPathComponent("Documents", isDirectory: true)
                    .appendingPathComponent("Botanica Backups", isDirectory: true)
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
                return (dir, false)
            } else {
                let fallback = localBackupDirectory()
                return (fallback, true)
            }
        case .localDocuments:
            let dir = localBackupDirectory()
            return (dir, false)
        }
    }
    
    private func localBackupDirectory() -> URL {
        let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Backups", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        return dir
    }
    
    private func destinationLabel(for destination: AutoBackupDestination, fallback: Bool) -> String {
        if destination == .iCloudDrive && fallback {
            return "On My iPhone (iCloud unavailable)"
        }
        return destination.label
    }
    
    private func saveBackupMetadata(result: DataExportResult, locationLabel: String) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: AutoBackupDefaults.lastRunKey)
        UserDefaults.standard.set(result.fileURL.lastPathComponent, forKey: AutoBackupDefaults.lastFileKey)
        UserDefaults.standard.set(locationLabel, forKey: AutoBackupDefaults.lastLocationKey)
    }
    
    private func cleanupOldBackups(in directory: URL) {
        guard let files = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        
        let backups = files.filter { $0.lastPathComponent.hasPrefix("Botanica Backup") }
        guard backups.count > maxBackupFiles else { return }
        
        let sorted = backups.sorted { lhs, rhs in
            let l = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let r = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return l < r
        }
        
        let toRemove = sorted.prefix(sorted.count - maxBackupFiles)
        for url in toRemove {
            try? fileManager.removeItem(at: url)
        }
    }
}
