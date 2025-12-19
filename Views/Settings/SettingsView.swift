//
//  SettingsView.swift
//  Botanica
//
//  Created by Assistant on 12/30/24.
//

import SwiftUI

/// Main settings screen for the Botanica app
/// Provides access to preferences, notifications, data management, and app information
struct SettingsView: View {
    @AppStorage("default_view_mode") private var defaultViewMode = ViewMode.grid.rawValue
    @AppStorage("theme_mode") private var themeMode = "system"
    
    @State private var showingAbout = false
    @State private var showingDataManagement = false
    @State private var showingExportData = false
    @State private var showingImportData = false
    
    var body: some View {
        NavigationStack {
            List {
                careSection
                appearanceSection
                dataSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingDataManagement) {
            DataManagementView()
        }
        .sheet(isPresented: $showingExportData) {
            ExportDataView()
        }
        .sheet(isPresented: $showingImportData) {
            ImportDataView()
        }
    }
    
    // MARK: - Care & Notifications
    
    private var careSection: some View {
        Section("Care & Notifications") {
            NavigationLink(destination: NotificationSettingsView()) {
                HStack(spacing: BotanicaTheme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(BotanicaTheme.Colors.primary.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "bell.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(BotanicaTheme.Colors.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notifications")
                            .font(BotanicaTheme.Typography.subheadline)
                            .foregroundColor(.primary)
                        
                        Text("Manage plant care reminders")
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Appearance
    
    private var appearanceSection: some View {
        Section("Appearance") {
            SettingsPickerRow(
                title: "Default Plant View",
                subtitle: "How plants are displayed in lists",
                icon: "square.grid.2x2",
                color: BotanicaTheme.Colors.leafGreen,
                selection: $defaultViewMode,
                options: [
                    (ViewMode.grid.rawValue, "Grid View"),
                    (ViewMode.list.rawValue, "List View")
                ]
            )
            
            SettingsPickerRow(
                title: "Theme",
                subtitle: "App appearance",
                icon: "paintbrush.fill",
                color: BotanicaTheme.Colors.terracotta,
                selection: $themeMode,
                options: [
                    ("system", "System"),
                    ("light", "Light"),
                    ("dark", "Dark")
                ]
            )
        }
    }
    
    // MARK: - Data & App
    
    private var dataSection: some View {
        Section("Data & App") {
            SettingsActionRow(
                title: "Manage Data",
                subtitle: "View and manage your plant data",
                icon: "externaldrive.fill",
                color: BotanicaTheme.Colors.soilBrown
            ) {
                showingDataManagement = true
            }
            
            SettingsActionRow(
                title: "Export Data",
                subtitle: "Export your plants and care history",
                icon: "square.and.arrow.up.fill",
                color: BotanicaTheme.Colors.nutrientOrange
            ) {
                showingExportData = true
            }

            SettingsActionRow(
                title: "Import Data",
                subtitle: "Import plants from a JSON file",
                icon: "arrow.down.doc.fill",
                color: BotanicaTheme.Colors.primary
            ) {
                showingImportData = true
            }
            
            SettingsActionRow(
                title: "About Botanica",
                subtitle: "App version and information",
                icon: "info.circle.fill",
                color: BotanicaTheme.Colors.primary
            ) {
                showingAbout = true
            }
        }
    }
}

/*
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plant.self, configurations: config)
    let context = container.mainContext
    
    // Add some sample data
    let plants = MockDataGenerator.generateSamplePlants()
    for plant in plants {
        context.insert(plant)
    }
    
    SettingsView()
        .modelContainer(container)
}
*/
