//
//  CareHistoryView.swift
//  Botanica
//
//  Created by Assistant on 12/30/24.
//

import SwiftUI
import SwiftData

struct CareHistoryView: View {
    let plant: Plant
    @Environment(\.dismiss) private var dismiss
    
    private var sortedCareEvents: [CareEvent] {
        plant.careEvents.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                if sortedCareEvents.isEmpty {
                    // Empty state
                    VStack(spacing: BotanicaTheme.Spacing.lg) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: BotanicaTheme.Sizing.iconJumbo))
                            .foregroundColor(BotanicaTheme.Colors.primary.opacity(0.6))
                        
                        VStack(spacing: BotanicaTheme.Spacing.sm) {
                            Text("No Care History")
                                .font(BotanicaTheme.Typography.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(BotanicaTheme.Colors.textPrimary)
                            
                            Text("Start tracking care events for \(plant.displayName) to see them here.")
                                .font(BotanicaTheme.Typography.body)
                                .foregroundColor(BotanicaTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(BotanicaTheme.Spacing.xl)
                } else {
                    // Care events list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(sortedCareEvents) { careEvent in
                                VStack(spacing: 0) {
                                    CareEventRow(event: careEvent)
                                        .padding(.horizontal, BotanicaTheme.Spacing.md)
                                    
                                    if careEvent.id != sortedCareEvents.last?.id {
                                        Divider()
                                            .padding(.leading, BotanicaTheme.Spacing.xl)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, BotanicaTheme.Spacing.md)
                    }
                }
            }
            .navigationTitle("Care History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plant.self, configurations: config)
    let context = container.mainContext
    // Create sample plant with care events
    let plant = MockDataGenerator.shared.createSamplePlants().first!
    context.insert(plant)
    return CareHistoryView(plant: plant)
        .modelContainer(container)
}
