//
//  DataManagementView.swift
//  Botanica
//
//  Created by Assistant on 12/30/24.
//

import SwiftUI
import SwiftData

/// Data management screen for viewing and managing app data
struct DataManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var plants: [Plant]
    @Query private var careEvents: [CareEvent]
    @Query private var reminders: [Reminder]
    @Query private var photos: [Photo]
    
    @State private var showingClearDataAlert = false
    @State private var showingClearPhotosAlert = false
    @State private var dataCleared = false
    
    var body: some View {
        NavigationView {
            List {
                // Data Overview Section
                dataOverviewSection
                
                // Storage Section
                storageSection
                
                // Data Actions Section
                dataActionsSection
            }
            .navigationTitle("Data Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All Data", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will permanently delete all your plants, care events, reminders, and photos. This action cannot be undone.")
        }
        .alert("Clear All Photos", isPresented: $showingClearPhotosAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear Photos", role: .destructive) {
                clearAllPhotos()
            }
        } message: {
            Text("This will permanently delete all plant photos. Your plants and care data will remain intact.")
        }
    }
    
    // MARK: - Data Overview Section
    
    private var dataOverviewSection: some View {
        Section("Data Overview") {
            DataStatRow(
                title: "Plants",
                count: plants.count,
                icon: "leaf.fill",
                color: BotanicaTheme.Colors.leafGreen
            )
            
            DataStatRow(
                title: "Care Events",
                count: careEvents.count,
                icon: "drop.fill",
                color: BotanicaTheme.Colors.waterBlue
            )
            
            DataStatRow(
                title: "Reminders",
                count: reminders.count,
                icon: "bell.fill",
                color: BotanicaTheme.Colors.nutrientOrange
            )
            
            DataStatRow(
                title: "Photos",
                count: photos.count,
                icon: "photo.fill",
                color: BotanicaTheme.Colors.terracotta
            )
        }
    }
    
    // MARK: - Storage Section
    
    private var storageSection: some View {
        Section("Storage") {
            HStack {
                Image(systemName: "externaldrive.fill")
                    .foregroundColor(BotanicaTheme.Colors.soilBrown)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("App Data Size")
                        .font(BotanicaTheme.Typography.subheadline)
                        .foregroundColor(.primary)
                    
                    Text("Estimated storage usage")
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(estimatedDataSize)
                    .font(BotanicaTheme.Typography.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
            
            HStack {
                Image(systemName: "photo.stack.fill")
                    .foregroundColor(BotanicaTheme.Colors.terracotta)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Photos Size")
                        .font(BotanicaTheme.Typography.subheadline)
                        .foregroundColor(.primary)
                    
                    Text("Storage used by plant photos")
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(estimatedPhotosSize)
                    .font(BotanicaTheme.Typography.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        }
    }
    
    // MARK: - Data Actions Section
    
    private var dataActionsSection: some View {
        Section("Data Actions") {
            Button {
                // In a real app, this would trigger a data export
                HapticManager.shared.light()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up.fill")
                        .foregroundColor(BotanicaTheme.Colors.primary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Export Data")
                            .font(BotanicaTheme.Typography.subheadline)
                            .foregroundColor(.primary)
                        
                        Text("Export your data as JSON")
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
            
            Button {
                showingClearPhotosAlert = true
            } label: {
                HStack {
                    Image(systemName: "photo.badge.minus.fill")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clear All Photos")
                            .font(BotanicaTheme.Typography.subheadline)
                            .foregroundColor(.primary)
                        
                        Text("Remove all plant photos")
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
            
            Button {
                showingClearDataAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clear All Data")
                            .font(BotanicaTheme.Typography.subheadline)
                            .foregroundColor(.red)
                        
                        Text("Permanently delete all app data")
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
    
    // MARK: - Computed Properties
    
    private var estimatedDataSize: String {
        // Rough estimation based on data counts
        let plantsSize = plants.count * 2 // ~2KB per plant
        let eventsSize = careEvents.count * 1 // ~1KB per event
        let remindersSize = reminders.count * 1 // ~1KB per reminder
        let photosMetaSize = photos.count * 1 // ~1KB per photo metadata
        
        let totalKB = plantsSize + eventsSize + remindersSize + photosMetaSize
        
        if totalKB < 1024 {
            return "\\(totalKB) KB"
        } else {
            let totalMB = Double(totalKB) / 1024.0
            return String(format: "%.1f MB", totalMB)
        }
    }
    
    private var estimatedPhotosSize: String {
        // Rough estimation: ~500KB per photo on average
        let totalPhotosKB = photos.count * 500
        
        if totalPhotosKB < 1024 {
            return "\\(totalPhotosKB) KB"
        } else {
            let totalMB = Double(totalPhotosKB) / 1024.0
            return String(format: "%.1f MB", totalMB)
        }
    }
    
    // MARK: - Actions
    
    private func clearAllData() {
        // Delete all data
        for plant in plants {
            modelContext.delete(plant)
        }
        
        for event in careEvents {
            modelContext.delete(event)
        }
        
        for reminder in reminders {
            modelContext.delete(reminder)
        }
        
        for photo in photos {
            modelContext.delete(photo)
        }
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
            dataCleared = true
        } catch {
            HapticManager.shared.error()
            print("Failed to clear data: \\(error)")
        }
    }
    
    private func clearAllPhotos() {
        // Delete all photos but keep other data
        for photo in photos {
            modelContext.delete(photo)
        }
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            HapticManager.shared.error()
            print("Failed to clear photos: \\(error)")
        }
    }
}

// MARK: - Data Stat Row

struct DataStatRow: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(BotanicaTheme.Typography.subheadline)
                    .foregroundColor(.primary)
                
                Text("\\(count) \\(count == 1 ? title.lowercased().dropLast() : title.lowercased())")
                    .font(BotanicaTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\\(count)")
                .font(BotanicaTheme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview
// Preview temporarily commented out due to compilation issues
/*
#Preview("Data Management View") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plant.self, configurations: config)
    let context = container.mainContext
    
    // Add some sample data
    let plants = MockDataGenerator.shared.createSamplePlants()
    plants.forEach { context.insert($0) }
    
    DataManagementView()
        .modelContainer(container)
}
*/