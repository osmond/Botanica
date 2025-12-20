import SwiftUI
import SwiftData

struct MultiCareLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var plants: [Plant]
    @Query(sort: \CareEvent.date, order: .reverse) private var careEvents: [CareEvent]
    
    @State private var selectedPlantIDs: Set<UUID> = []
    @State private var selectedType: CareType = .watering
    @State private var date = Date()
    @State private var notes = ""
    @State private var showAmount = true
    @State private var useRecommended = true
    @State private var amount: Double = 0
    @State private var amountUnit: WaterUnit = .milliliters
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: plantHeader) {
                    if plants.isEmpty {
                        Text("Add plants to log care.")
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(plants) { plant in
                            Button {
                                toggleSelection(for: plant)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(plant.displayName)
                                            .font(BotanicaTheme.Typography.bodyEmphasized)
                                        Text(plant.scientificName)
                                            .font(BotanicaTheme.Typography.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: selectedPlantIDs.contains(plant.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedPlantIDs.contains(plant.id) ? BotanicaTheme.Colors.primary : .secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Section("Care") {
                    Picker("Care Type", selection: $selectedType) {
                        ForEach(CareType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    if amountEligible {
                        Toggle("Include Amount", isOn: $showAmount)
                        
                        if showAmount {
                            Toggle("Use recommended per plant", isOn: $useRecommended)
                        }
                    }
                }
                
                if amountEligible && showAmount {
                    Section("Amount") {
                        if useRecommended {
                            Text("Each plant will use its recommended amount.")
                                .font(BotanicaTheme.Typography.caption)
                                .foregroundColor(.secondary)
                        } else {
                            HStack {
                                Text("Amount")
                                Spacer()
                                TextField("0", value: $amount, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                                    .keyboardType(.decimalPad)
                            }
                            
                            Picker("Unit", selection: $amountUnit) {
                                ForEach(WaterUnit.allCases, id: \.self) { unit in
                                    Text(unit.description).tag(unit)
                                }
                            }
                            
                            if !recentPresets.isEmpty {
                                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                                    Text("Recent presets")
                                        .font(BotanicaTheme.Typography.caption)
                                        .foregroundColor(.secondary)
                                    LazyVGrid(
                                        columns: [GridItem(.adaptive(minimum: 100), spacing: 8)],
                                        alignment: .leading,
                                        spacing: 8
                                    ) {
                                        ForEach(recentPresets, id: \.label) { preset in
                                            Button(preset.label) {
                                                amount = preset.amount
                                                amountUnit = preset.unit
                                            }
                                            .buttonStyle(.bordered)
                                            .tint(BotanicaTheme.Colors.primary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Add a note for all selected plants", text: $notes, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Care")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveCareEvents() }
                        .disabled(selectedPlantIDs.isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                syncAmountState()
            }
            .onChange(of: selectedType) { _, _ in
                syncAmountState()
            }
            .onChange(of: showAmount) { _, _ in
                if showAmount == false {
                    useRecommended = false
                }
            }
        }
    }
    
    private var amountEligible: Bool {
        selectedType == .watering || selectedType == .fertilizing
    }
    
    private var plantHeader: some View {
        HStack {
            Text("Plants")
            Spacer()
            if !plants.isEmpty {
                Button(selectedPlantIDs.count == plants.count ? "Clear" : "Select All") {
                    toggleSelectAll()
                }
                .font(.caption)
            }
        }
    }
    
    private var recentPresets: [AmountPreset] {
        guard amountEligible else { return [] }
        let candidateEvents = careEvents.filter { event in
            event.type == selectedType && event.amount != nil && !event.unit.isEmpty
        }
        
        let filtered = candidateEvents.filter { event in
            guard !selectedPlantIDs.isEmpty else { return true }
            return event.plant.map { selectedPlantIDs.contains($0.id) } ?? false
        }
        
        var seen: Set<String> = []
        var presets: [AmountPreset] = []
        for event in filtered {
            guard let amount = event.amount else { continue }
            let unit = waterUnit(from: event.unit)
            let label = "\(Int(round(amount))) \(unit.description)"
            guard !seen.contains(label) else { continue }
            seen.insert(label)
            presets.append(AmountPreset(label: label, amount: amount, unit: unit))
            if presets.count == 3 { break }
        }
        return presets
    }
    
    private func toggleSelection(for plant: Plant) {
        if selectedPlantIDs.contains(plant.id) {
            selectedPlantIDs.remove(plant.id)
        } else {
            selectedPlantIDs.insert(plant.id)
        }
    }
    
    private func toggleSelectAll() {
        if selectedPlantIDs.count == plants.count {
            selectedPlantIDs.removeAll()
        } else {
            selectedPlantIDs = Set(plants.map(\.id))
        }
    }
    
    private func syncAmountState() {
        if amountEligible {
            showAmount = true
            useRecommended = true
            amount = 0
        } else {
            showAmount = false
            useRecommended = false
            amount = 0
        }
        
        if let first = selectedPlants.first {
            amountUnit = first.waterUnit
        }
    }
    
    private var selectedPlants: [Plant] {
        plants.filter { selectedPlantIDs.contains($0.id) }
    }
    
    private func saveCareEvents() {
        guard !selectedPlants.isEmpty else { return }
        
        for plant in selectedPlants {
            let event = CareEvent(
                type: selectedType,
                date: date,
                amount: resolvedAmount(for: plant),
                unit: resolvedUnit(for: plant),
                notes: notes
            )
            event.plant = plant
            modelContext.insert(event)
        }
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            HapticManager.shared.error()
        }
    }
    
    private func resolvedAmount(for plant: Plant) -> Double? {
        guard amountEligible, showAmount else { return nil }
        if useRecommended {
            switch selectedType {
            case .watering:
                return Double(plant.recommendedWateringAmount.amount)
            case .fertilizing:
                return plant.recommendedFertilizerAmount.amount
            case .repotting, .pruning, .cleaning, .rotating, .misting, .inspection:
                return nil
            }
        }
        return amount > 0 ? amount : nil
    }
    
    private func resolvedUnit(for plant: Plant) -> String {
        guard amountEligible, showAmount else { return "" }
        if useRecommended {
            switch selectedType {
            case .watering:
                return plant.recommendedWateringAmount.unit
            case .fertilizing:
                return plant.recommendedFertilizerAmount.unit
            case .repotting, .pruning, .cleaning, .rotating, .misting, .inspection:
                return ""
            }
        }
        return amountUnit.description
    }
    
    private func waterUnit(from text: String) -> WaterUnit {
        let lower = text.lowercased()
        if lower.contains("oz") { return .ounces }
        if lower.contains("cup") { return .cups }
        if lower.contains("l") && !lower.contains("ml") { return .liters }
        return .milliliters
    }
}

private struct AmountPreset {
    let label: String
    let amount: Double
    let unit: WaterUnit
}
