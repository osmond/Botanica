//
//  ExportDataView.swift
//  Botanica
//
//  Created by Assistant on 12/30/24.
//

import SwiftUI
import SwiftData

/// Export data screen for exporting user plant data
struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var plants: [Plant]
    @Query private var careEvents: [CareEvent]
    @Query private var reminders: [Reminder]
    
    @State private var includePhotos = false
    @State private var includeReminders = true
    @State private var includeCareHistory = true
    @State private var exportFormat: DataExportFormat = .json
    @State private var loadState: LoadState = .idle
    @State private var exportFinished = false
    @State private var exportError: String?
    @State private var exportResult: DataExportResult?
    
    var body: some View {
        NavigationView {
            LoadStateView(
                state: loadState,
                retry: { startExport() },
                loading: { exportingView },
                content: {
                    if exportFinished {
                        exportCompletedView
                    } else {
                        exportOptionsView
                    }
                }
            )
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if loadState != .loading && !exportFinished {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Export") {
                            startExport()
                        }
                        .fontWeight(.semibold)
                        .disabled(plants.isEmpty)
                    }
                }
            }
        }
    }
    
    // MARK: - Export Options View
    
    private var exportOptionsView: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                    HStack {
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(BotanicaTheme.Typography.largeTitle)
                            .foregroundColor(BotanicaTheme.Colors.primary)
                        
                        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                            Text("Export Your Data")
                                .font(BotanicaTheme.Typography.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(BotanicaTheme.Colors.textPrimary)
                            
                            Text("Create a backup of your plant collection and care history")
                                .font(BotanicaTheme.Typography.body)
                                .foregroundColor(BotanicaTheme.Colors.textSecondary)
                        }
                    }
                    
                    if plants.isEmpty {
                        Text("No plants to export. Add some plants first!")
                            .font(BotanicaTheme.Typography.body)
                            .foregroundColor(BotanicaTheme.Colors.textSecondary)
                            .padding(.top, BotanicaTheme.Spacing.sm)
                    }
                }
                .padding(.vertical, BotanicaTheme.Spacing.sm)
            }
            
            Section("Export Format") {
                ForEach(DataExportFormat.allCases, id: \.self) { format in
                    Button {
                        exportFormat = format
                        HapticManager.shared.selection()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                                Text(format.rawValue)
                                    .font(BotanicaTheme.Typography.subheadline)
                                    .foregroundColor(BotanicaTheme.Colors.textPrimary)
                                
                                Text(formatDescription(format))
                                    .font(BotanicaTheme.Typography.caption)
                                    .foregroundColor(BotanicaTheme.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            if exportFormat == format {
                                Image(systemName: "checkmark")
                                    .foregroundColor(BotanicaTheme.Colors.primary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Section("Include in Export") {
                Toggle(isOn: $includeCareHistory) {
                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                        Text("Care History")
                            .font(BotanicaTheme.Typography.subheadline)
                        Text("\(careEvents.count) care events")
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(BotanicaTheme.Colors.textSecondary)
                    }
                }
                
                Toggle(isOn: $includeReminders) {
                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                        Text("Reminders")
                            .font(BotanicaTheme.Typography.subheadline)
                        Text("\(reminders.count) active reminders")
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(BotanicaTheme.Colors.textSecondary)
                    }
                }
                
                Toggle(isOn: $includePhotos) {
                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                        Text("Photos")
                            .font(BotanicaTheme.Typography.subheadline)
                        Text("Export photos as base64 data")
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(BotanicaTheme.Colors.textSecondary)
                    }
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                    Text("Export Summary")
                        .font(BotanicaTheme.Typography.headline)
                        .foregroundColor(BotanicaTheme.Colors.textPrimary)
                    
                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                        Text("• \(plants.count) plants")
                        if includeCareHistory {
                            Text("• \(careEvents.count) care events")
                        }
                        if includeReminders {
                            Text("• \(reminders.count) reminders")
                        }
                        if includePhotos {
                            Text("• \(photoCount) photos")
                        }
                    }
                    .font(BotanicaTheme.Typography.caption)
                    .foregroundColor(BotanicaTheme.Colors.textSecondary)
                }
                .padding(.vertical, BotanicaTheme.Spacing.sm)
            }
        }
    }
    
    // MARK: - Exporting View
    
    private var exportingView: some View {
        VStack(spacing: BotanicaTheme.Spacing.xl) {
            Spacer()
            
            VStack(spacing: BotanicaTheme.Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                
                VStack(spacing: BotanicaTheme.Spacing.sm) {
                    Text("Exporting Data")
                        .font(BotanicaTheme.Typography.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(BotanicaTheme.Colors.textPrimary)
                    
                    Text("Preparing your plant data for export...")
                        .font(BotanicaTheme.Typography.body)
                        .foregroundColor(BotanicaTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
        }
        .padding(BotanicaTheme.Spacing.xl)
    }
    
    // MARK: - Export Completed View
    
    private var exportCompletedView: some View {
        VStack(spacing: BotanicaTheme.Spacing.xl) {
            Spacer()
            
            VStack(spacing: BotanicaTheme.Spacing.lg) {
                if let error = exportError {
                    // Error state
                    VStack(spacing: BotanicaTheme.Spacing.md) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: BotanicaTheme.Sizing.iconJumbo))
                            .foregroundColor(BotanicaTheme.Colors.error)
                        
                        VStack(spacing: BotanicaTheme.Spacing.sm) {
                            Text("Export Failed")
                                .font(BotanicaTheme.Typography.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(BotanicaTheme.Colors.textPrimary)
                            
                            Text(error)
                                .font(BotanicaTheme.Typography.body)
                                .foregroundColor(BotanicaTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                } else {
                    // Success state
                    VStack(spacing: BotanicaTheme.Spacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: BotanicaTheme.Sizing.iconJumbo))
                            .foregroundColor(BotanicaTheme.Colors.leafGreen)
                        
                        VStack(spacing: BotanicaTheme.Spacing.sm) {
                            Text("Export Complete")
                                .font(BotanicaTheme.Typography.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(BotanicaTheme.Colors.textPrimary)
                            
                            Text("Your plant data has been exported successfully. Find it in Files → On My iPhone → Botanica → Exports.")
                                .font(BotanicaTheme.Typography.body)
                                .foregroundColor(BotanicaTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                            
                            if let exportResult {
                                VStack(spacing: BotanicaTheme.Spacing.xs) {
                                    Text("File size: \(formattedSize(exportResult.byteCount))")
                                    Text("Plants: \(exportResult.summary.plants)")
                                }
                                .font(BotanicaTheme.Typography.caption)
                                .foregroundColor(BotanicaTheme.Colors.textSecondary)
                            }
                        }
                    }
                }
            }
            
            VStack(spacing: BotanicaTheme.Spacing.md) {
                if exportError == nil {
                    if let exportResult {
                        ShareLink(item: exportResult.fileURL) {
                            Text("Share Export File")
                                .frame(maxWidth: .infinity)
                                .primaryButtonStyle()
                        }
                    }
                }
                
                Button(exportError == nil ? "Done" : "Try Again") {
                    if exportError == nil {
                        dismiss()
                    } else {
                        exportError = nil
                        exportFinished = false
                        loadState = .idle
                    }
                }
                .frame(maxWidth: .infinity)
                .secondaryButtonStyle()
            }
            
            Spacer()
        }
        .padding(BotanicaTheme.Spacing.xl)
    }
    
    // MARK: - Helper Methods
    
    private func formatDescription(_ format: DataExportFormat) -> String {
        switch format {
        case .json:
            return "Structured data format, preserves all information"
        case .csv:
            return "Spreadsheet format with your plant list"
        }
    }
    
    private func startExport() {
        loadState = .loading
        exportFinished = false
        exportError = nil
        exportResult = nil
        HapticManager.shared.light()
        
        Task { @MainActor in
            do {
                let options = DataExportOptions(
                    includePhotos: includePhotos,
                    includeCareHistory: includeCareHistory,
                    includeReminders: includeReminders
                )
                let result = try DataExportService.shared.exportData(
                    context: modelContext,
                    format: exportFormat,
                    options: options,
                    filePrefix: "Botanica Export",
                    destinationDirectory: exportDirectory()
                )
                exportResult = result
                exportFinished = true
                loadState = .loaded
                HapticManager.shared.success()
            } catch {
                exportError = error.localizedDescription
                exportFinished = true
                loadState = .loaded
                HapticManager.shared.error()
            }
        }
    }

    private func formattedSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func exportDirectory() -> URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Exports", isDirectory: true)
    }
    
    private var photoCount: Int {
        plants.reduce(0) { $0 + $1.photos.count }
    }
}

/*
#Preview("Export Data View") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plant.self, configurations: config)
    let context = container.mainContext
    
    // Add some sample data
    let plants = MockDataGenerator.shared.createSamplePlants()
    plants.forEach { context.insert($0) }
    
    ExportDataView()
        .modelContainer(container)
}
*/
