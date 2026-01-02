//
//  ImportDataView.swift
//  Botanica
//
//  Created by Assistant
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Import data screen for bringing external plant data into the app
struct ImportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var loadState: LoadState = .idle
    @State private var importError: String?
    @State private var result: DataImportResult?
    @State private var showFileImporter = false

    var body: some View {
        NavigationView {
            LoadStateView(
                state: loadState,
                retry: { showPicker() },
                loading: { progressView },
                content: {
                    if result != nil || importError != nil {
                        completedView
                    } else {
                        introView
                    }
                }
            )
            .navigationTitle("Import Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                if loadState != .loading {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Choose File") { showPicker() }
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                startImport(url: url)
            case .failure(let error):
                importError = error.localizedDescription
                loadState = .failed(error.localizedDescription)
            }
        }
    }

    // MARK: - Subviews

    private var introView: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                    HStack(alignment: .top, spacing: BotanicaTheme.Spacing.md) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(BotanicaTheme.Typography.largeTitle)
                            .foregroundColor(BotanicaTheme.Colors.primary)
                        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                            Text("Import from JSON")
                                .font(BotanicaTheme.Typography.title2)
                                .fontWeight(.semibold)
                            Text("Provide a JSON file with your plants, care history, reminders, and optional base64 photos.")
                                .font(BotanicaTheme.Typography.body)
                                .foregroundColor(BotanicaTheme.Colors.textSecondary)
                        }
                    }
                    Button("Choose JSON File") { showPicker() }
                        .frame(maxWidth: .infinity)
                        .primaryButtonStyle()
                }
                .padding(.vertical, BotanicaTheme.Spacing.sm)
            }
            Section("Format") {
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                    Text("Requirements")
                        .font(BotanicaTheme.Typography.subheadline)
                    Text("• ISO 8601 dates (e.g., 2024-11-14T10:00:00Z)")
                    Text("• Enum fields accept friendly names (e.g., 'bright', 'upright')")
                    Text("• Photos as base64 data optional; large imports may be slow")
                }
                .font(BotanicaTheme.Typography.caption)
                .foregroundColor(BotanicaTheme.Colors.textSecondary)
            }
        }
    }

    private var progressView: some View {
        VStack(spacing: BotanicaTheme.Spacing.xl) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Importing…")
                .font(BotanicaTheme.Typography.title2)
                .foregroundColor(BotanicaTheme.Colors.textPrimary)
            Spacer()
        }
        .padding(BotanicaTheme.Spacing.xl)
    }

    private var completedView: some View {
        VStack(spacing: BotanicaTheme.Spacing.lg) {
            Spacer()
            if let importError = importError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: BotanicaTheme.Sizing.iconStatus))
                    .foregroundColor(BotanicaTheme.Colors.error)
                Text("Import Failed")
                    .font(BotanicaTheme.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(BotanicaTheme.Colors.textPrimary)
                Text(importError)
                    .font(BotanicaTheme.Typography.body)
                    .foregroundColor(BotanicaTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            } else if let result = result {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: BotanicaTheme.Sizing.iconStatus))
                    .foregroundColor(BotanicaTheme.Colors.leafGreen)
                Text("Import Complete")
                    .font(BotanicaTheme.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(BotanicaTheme.Colors.textPrimary)
                VStack(spacing: BotanicaTheme.Spacing.xs) {
                    Text("\(result.plantsCreated) plants • \(result.careEventsCreated) care events")
                    Text("\(result.remindersCreated) reminders • \(result.photosCreated) photos")
                }
                .font(BotanicaTheme.Typography.body)
                .foregroundColor(BotanicaTheme.Colors.textSecondary)
                if !result.notes.isEmpty {
                    List {
                        Section("Notes") {
                            ForEach(result.notes, id: \.self) { Text($0) }
                        }
                    }
                    .frame(maxHeight: 220)
                }
            }
            Button("Done") { dismiss() }
                .frame(maxWidth: .infinity)
                .secondaryButtonStyle()
            Spacer()
        }
        .padding(BotanicaTheme.Spacing.xl)
    }

    // MARK: - Actions

    private func showPicker() {
        HapticManager.shared.selection()
        showFileImporter = true
    }

    private func startImport(url: URL) {
        loadState = .loading
        importError = nil
        result = nil
        HapticManager.shared.light()
        Task {
            do {
                let data = try Data(contentsOf: url)
                let res = try DataImportService.shared.importAutoDetectingData(data, into: modelContext)
                await MainActor.run {
                    self.result = res
                    self.loadState = .loaded
                    HapticManager.shared.success()
                }
            } catch {
                await MainActor.run {
                    self.importError = error.localizedDescription
                    self.loadState = .failed(error.localizedDescription)
                    HapticManager.shared.error()
                }
            }
        }
    }
}
