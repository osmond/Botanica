//
//  SettingsView.swift
//  Botanica
//
//  Created by Assistant on 12/30/24.
//

import SwiftUI
import SwiftData

/// Main settings screen for the Botanica app
/// Provides access to user preferences, notifications, AI configuration, and app information
struct SettingsView: View {
    @Query private var plants: [Plant]
    @Query private var careEvents: [CareEvent]
    
    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("care_reminders_enabled") private var careRemindersEnabled = true
    @AppStorage("daily_summary_enabled") private var dailySummaryEnabled = true
    @AppStorage("photo_backup_enabled") private var photoBackupEnabled = false
    @AppStorage("default_view_mode") private var defaultViewMode = "grid"
    @AppStorage("theme_mode") private var themeMode = "system"
    
    @State private var showingAISettings = false
    @State private var showingAbout = false
    @State private var showingDataManagement = false
    @State private var showingExportData = false
    @State private var showingImportData = false
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                profileSection
                
                // Notifications Section
                notificationsSection
                
                // Display Preferences Section
                displaySection
                
                // AI Features Section
                aiSection
                
                // Data & Privacy Section
                dataSection
                
                // Support & Info Section
                supportSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingAISettings) {
            AISettingsView()
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
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        Section {
            HStack(spacing: BotanicaTheme.Spacing.md) {
                // Profile avatar
                ZStack {
                    Circle()
                        .fill(BotanicaTheme.Colors.primary.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 35))
                        .foregroundColor(BotanicaTheme.Colors.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Plant Parent")
                        .font(BotanicaTheme.Typography.headline)
                        .foregroundColor(.primary)
                    
                    Text("\\(plants.count) plants • \\(careEvents.count) care events")
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Member since \\(memberSinceText)")
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, BotanicaTheme.Spacing.sm)
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        Section("Notifications") {
            NavigationLink(destination: SimpleNotificationSettingsView()) {
                HStack(spacing: BotanicaTheme.Spacing.md) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(BotanicaTheme.Colors.primary.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "bell.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(BotanicaTheme.Colors.primary)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notification Settings")
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
            
            SettingsToggleRow(
                title: "Care Reminders",
                subtitle: "Get notified when plants need care",
                icon: "drop.fill",
                color: BotanicaTheme.Colors.waterBlue,
                isOn: $careRemindersEnabled
            )
            
            SettingsToggleRow(
                title: "Daily Summary",
                subtitle: "Morning overview of today's plant tasks",
                icon: "sun.max.fill",
                color: BotanicaTheme.Colors.nutrientOrange,
                isOn: $dailySummaryEnabled
            )
        }
    }
    
    // MARK: - Display Section
    
    private var displaySection: some View {
        Section("Display Preferences") {
            SettingsPickerRow(
                title: "Default Plant View",
                subtitle: "How plants are displayed in lists",
                icon: "square.grid.2x2",
                color: BotanicaTheme.Colors.leafGreen,
                selection: $defaultViewMode,
                options: [
                    ("grid", "Grid View"),
                    ("list", "List View")
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
    
    // MARK: - AI Section
    
    private var aiSection: some View {
        Section("AI Features") {
            SettingsActionRow(
                title: "AI Plant Coach",
                subtitle: "Configure OpenAI integration",
                icon: "brain.head.profile.fill",
                color: BotanicaTheme.Colors.primary
            ) {
                showingAISettings = true
            }
            
            SettingsInfoRow(
                title: "Plant Identification",
                subtitle: "AI-powered plant recognition",
                icon: "camera.viewfinder",
                color: BotanicaTheme.Colors.leafGreen,
                value: OpenAIConfig.shared.isConfigured ? "Enabled" : "Setup Required"
            )
        }
    }
    
    // MARK: - Data Section
    
    private var dataSection: some View {
        Section("Data & Privacy") {
            SettingsToggleRow(
                title: "Photo Backup",
                subtitle: "Automatically backup plant photos",
                icon: "icloud.and.arrow.up.fill",
                color: BotanicaTheme.Colors.waterBlue,
                isOn: $photoBackupEnabled
            )
            
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
        }
    }
    
    // MARK: - Support Section
    
    private var supportSection: some View {
        Section("Support & Information") {
            SettingsActionRow(
                title: "About Botanica",
                subtitle: "App version and information",
                icon: "info.circle.fill",
                color: BotanicaTheme.Colors.primary
            ) {
                showingAbout = true
            }
            
            SettingsLinkRow(
                title: "Help & Support",
                subtitle: "Get help with using the app",
                icon: "questionmark.circle.fill",
                color: BotanicaTheme.Colors.leafGreen,
                url: "https://botanica.app/support"
            )
            
            SettingsLinkRow(
                title: "Privacy Policy",
                subtitle: "How we protect your data",
                icon: "hand.raised.fill",
                color: BotanicaTheme.Colors.terracotta,
                url: "https://botanica.app/privacy"
            )
            
            SettingsActionRow(
                title: "Rate Botanica",
                subtitle: "Leave a review on the App Store",
                icon: "star.fill",
                color: BotanicaTheme.Colors.nutrientOrange
            ) {
                requestAppStoreReview()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var memberSinceText: String {
        // In a real app, this would come from user account creation date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date().addingTimeInterval(-TimeInterval.random(in: 86400*30...86400*365)))
    }
    
    private func requestAppStoreReview() {
        // In a real app, this would trigger the App Store review prompt
        HapticManager.shared.success()
    }
}

// MARK: - Simple Notification Settings View (Temporary)

struct SimpleNotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var notificationsEnabled = true
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: notificationManager.authorizationStatus == .authorized ? "bell.fill" : "bell.slash.fill")
                            .foregroundColor(notificationManager.authorizationStatus == .authorized ? .green : .red)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notification Permission")
                                .font(.headline)
                            Text(notificationManager.authorizationStatus == .authorized ? "Notifications are enabled" : "Notifications are disabled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if notificationManager.authorizationStatus != .authorized {
                            Button("Enable") {
                                Task {
                                    await notificationManager.requestNotificationPermission()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Permission")
            }
            
            if notificationManager.authorizationStatus == .authorized {
                Section {
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.blue)
                        Text("Watering Reminders")
                        Spacer()
                        Toggle("", isOn: $notificationsEnabled)
                    }
                    
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                        Text("Fertilizing Reminders")
                        Spacer()
                        Toggle("", isOn: $notificationsEnabled)
                    }
                } header: {
                    Text("Notification Types")
                }
            }
        }
        .navigationTitle("Notification Settings")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await notificationManager.updateAuthorizationStatus()
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
