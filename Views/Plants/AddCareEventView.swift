//
//  AddCareEventView.swift
//  Botanica
//
//  Created by Assistant on 12/30/24.
//

import SwiftUI
import SwiftData

struct AddCareEventView: View {
    let plant: Plant
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedType: CareType = .watering
    @State private var date = Date()
    @State private var amount: Double = 0
    @State private var notes = ""
    @State private var showAmount = false
    @State private var showRecommendations = true
    
    private var typeOptions: [CareType] {
    [.watering, .fertilizing, .repotting, .pruning, .inspection, .cleaning, .rotating, .misting]
    }
    
    private var typeIcon: String {
        switch selectedType {
        case .watering:
            return "drop.fill"
        case .fertilizing:
            return "leaf.arrow.circlepath"
        case .repotting:
            return "move.3d"
        case .pruning:
            return "scissors"
        case .inspection:
            return "magnifyingglass"
        case .cleaning:
            return "sparkles"
        case .rotating:
            return "arrow.triangle.2.circlepath"
        case .misting:
            return "cloud.drizzle"
        }
    }
    
    private var typeColor: Color {
        switch selectedType {
        case .watering:
            return BotanicaTheme.Colors.waterBlue
        case .fertilizing:
            return BotanicaTheme.Colors.nutrientOrange
        case .repotting:
            return BotanicaTheme.Colors.soilBrown
        case .pruning:
            return BotanicaTheme.Colors.leafGreen
        case .inspection:
            return BotanicaTheme.Colors.primary
        case .cleaning:
            return BotanicaTheme.Colors.surface
        case .rotating:
            return BotanicaTheme.Colors.surface
        case .misting:
            return BotanicaTheme.Colors.surface
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    // Care type picker
                    HStack {
                        ZStack {
                            Circle()
                                .fill(typeColor.opacity(0.1))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: typeIcon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(typeColor)
                        }
                        
                        Picker("Care Type", selection: $selectedType) {
                            ForEach(typeOptions, id: \.self) { type in
                                Text(type.rawValue.capitalized)
                                    .tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // Date picker
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                // Recommendations section
                if showRecommendations && (selectedType == .watering || selectedType == .fertilizing) {
                    Section("💡 Recommendations") {
                        recommendationsView
                    }
                }
                
                Section {
                    // Amount toggle
                    Toggle("Include Amount", isOn: $showAmount)
                    
                    if showAmount {
                        HStack {
                            Text("Amount")
                            Spacer()
                            TextField("0", value: $amount, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                                .keyboardType(.decimalPad)
                            Text(amountUnit)
                                .foregroundColor(.secondary)
                        }
                        
                        if selectedType == .watering || selectedType == .fertilizing {
                            Button("Use Recommended Amount") {
                                useRecommendedAmount()
                            }
                            .foregroundColor(BotanicaTheme.Colors.primary)
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Add notes about this care event...", text: $notes, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Care Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCareEvent()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            // Automatically show amount for watering and fertilizing
            if selectedType == .watering || selectedType == .fertilizing {
                showAmount = true
                useRecommendedAmount()
            }
        }
        .onChange(of: selectedType) { _, newType in
            // Update amount when type changes
            if newType == .watering || newType == .fertilizing {
                showAmount = true
                useRecommendedAmount()
            } else {
                showAmount = false
                amount = 0
            }
        }
    }
    
    private var recommendationsView: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
            if selectedType == .watering {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(BotanicaTheme.Colors.waterBlue)
                        Text("Watering Guidance")
                            .font(BotanicaTheme.Typography.callout)
                            .fontWeight(.medium)
                    }
                    
                    Text("Amount: \(plant.recommendedWateringAmount.amount)\(plant.recommendedWateringAmount.unit)")
                        .font(BotanicaTheme.Typography.body)
                        .foregroundColor(.primary)
                    
                    Text("Frequency: Every \(plant.wateringFrequency) days")
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                        
                    Text("💡 Check soil moisture before watering")
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(BotanicaTheme.Spacing.sm)
                .background(BotanicaTheme.Colors.waterBlue.opacity(0.1))
                .cornerRadius(BotanicaTheme.CornerRadius.small)            } else if selectedType == .fertilizing {
                let fertilizerRec = plant.recommendedFertilizerAmount
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "leaf.arrow.circlepath")
                            .foregroundColor(BotanicaTheme.Colors.nutrientOrange)
                        Text("Fertilizing Guidance")
                            .font(BotanicaTheme.Typography.callout)
                            .fontWeight(.medium)
                    }
                    
                    Text("Amount: \(String(format: "%.1f", fertilizerRec.amount))\(fertilizerRec.unit)")
                        .font(BotanicaTheme.Typography.body)
                        .foregroundColor(.primary)
                    
                    Text("Dilution: \(fertilizerRec.dilution)")
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    Text("💡 \(fertilizerRec.instructions)")
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(BotanicaTheme.Spacing.sm)
                .background(BotanicaTheme.Colors.nutrientOrange.opacity(0.1))
                .cornerRadius(BotanicaTheme.CornerRadius.small)
            }
        }
    }
    
    private func useRecommendedAmount() {
        switch selectedType {
        case .watering:
            amount = plant.recommendedWaterAmount
        case .fertilizing:
            amount = plant.recommendedFertilizerAmount.amount
        case .repotting, .pruning, .inspection, .cleaning, .rotating, .misting:
            break
        }
    }
    
    private var amountUnit: String {
        switch selectedType {
        case .watering:
            return plant.waterUnit.description
        case .fertilizing:
            return "ml"
        case .repotting:
            return "cm"
        case .pruning:
            return "stems"
        case .inspection, .cleaning, .rotating, .misting:
            return ""
        }
    }
    
    private func saveCareEvent() {
        let careEvent = CareEvent(
            type: selectedType,
            date: date,
            amount: showAmount ? amount : nil,
            notes: notes
        )
        
        plant.careEvents.append(careEvent)
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            HapticManager.shared.error()
            print("Failed to save care event: \(error)")
        }
    }
}

#if DEBUG
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plant.self, configurations: config)
    let context = container.mainContext
    let plant = MockDataGenerator.shared.createSamplePlants().first!
    context.insert(plant)
    AddCareEventView(plant: plant)
        .modelContainer(container)
}
#endif
