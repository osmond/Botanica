//
//  EditPlantView.swift
//  Botanica
//
//  Created by Assistant on 10/1/25.
//

import SwiftUI
import SwiftData
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

struct EditPlantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var formViewModel = PlantFormViewModel()
    
    let plant: Plant
    
    // Form fields
    @State private var displayName: String
    @State private var scientificName: String
    @State private var commonNames: String
    @State private var notes: String
    @State private var location: String
    @State private var sourceDescription: String
    @State private var wateringFrequency: Int
    @State private var fertilizingFrequency: Int
    @State private var lightLevel: LightLevel
    @State private var humidityPreference: Double
    @State private var temperatureMin: Double
    @State private var temperatureMax: Double
    @State private var healthStatus: HealthStatus
    @State private var recommendedWaterAmount: Double
    @State private var waterUnit: WaterUnit
    @State private var potSizeInches: Int
    @State private var potHeightInches: Int
    @State private var potMaterial: PotMaterial
    @State private var repotFrequencyMonths: Int
    @State private var lastRepotted: Date?
    @State private var useCentimeters: Bool = false
    @State private var potSizeInput: String
    @State private var potHeightInput: String
    // Manual vs recommended state flags
    @State private var isWaterFreqManual: Bool = true
    @State private var isWaterDoseManual: Bool = true
    
    // Care history
    @State private var lastWatered: Date?
    @State private var lastFertilized: Date?
    @State private var hasBeenRepotted: Bool
    @State private var hasBeenWatered: Bool
    @State private var hasBeenFertilized: Bool
    
    // Photo management
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false
    @State private var showingDeleteConfirmation = false
    @State private var photoToDelete: Photo?
    
    // UI state
    @State private var showingDeletePlantConfirmation = false
    
    init(plant: Plant) {
        self.plant = plant
        _displayName = State(initialValue: plant.displayName)
        _scientificName = State(initialValue: plant.scientificName)
        _commonNames = State(initialValue: plant.commonNames.joined(separator: ", "))
        _notes = State(initialValue: plant.notes)
        _location = State(initialValue: plant.location)
        _sourceDescription = State(initialValue: plant.source)
        _wateringFrequency = State(initialValue: plant.wateringFrequency)
        _fertilizingFrequency = State(initialValue: plant.fertilizingFrequency)
        _lightLevel = State(initialValue: plant.lightLevel)
        _humidityPreference = State(initialValue: Double(plant.humidityPreference))
        _temperatureMin = State(initialValue: Double(plant.temperatureRange.min))
        _temperatureMax = State(initialValue: Double(plant.temperatureRange.max))
        _healthStatus = State(initialValue: plant.healthStatus)
        _recommendedWaterAmount = State(initialValue: plant.recommendedWaterAmount)
        _waterUnit = State(initialValue: plant.waterUnit)
        _lastWatered = State(initialValue: plant.lastWatered)
        _lastFertilized = State(initialValue: plant.lastFertilized)
        _lastRepotted = State(initialValue: plant.lastRepotted)
        _hasBeenWatered = State(initialValue: plant.lastWatered != nil)
        _hasBeenFertilized = State(initialValue: plant.lastFertilized != nil)
        _hasBeenRepotted = State(initialValue: plant.lastRepotted != nil)
        _potSizeInches = State(initialValue: plant.potSize)
        _potHeightInches = State(initialValue: plant.potHeight ?? 0)
        _potMaterial = State(initialValue: plant.potMaterial ?? .unknown)
        _potSizeInput = State(initialValue: String(plant.potSize))
        _potHeightInput = State(initialValue: String(plant.potHeight ?? 0))
        _repotFrequencyMonths = State(initialValue: plant.repotFrequencyMonths ?? 12)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Hero Section
                heroSection
                
                // Care Summary
                careSummarySection
                
                // Photos Section
                photosSection
                
                // Basic Information
                basicInfoSection
                
                // Pot & Environment
                potEnvironmentSection
                
                // Water Every
                waterEverySection
                
                // Water Dose
                waterDoseSection
                
                // Additional Information
                additionalInfoSection
                
                // Danger Zone
                dangerZoneSection
            }
            .navigationTitle("Edit Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePlant()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotos, maxSelectionCount: 10, matching: .images)
        .onChange(of: selectedPhotos) { _, newItems in
            Task {
                await addSelectedPhotos(newItems)
            }
        }
        .onChange(of: useCentimeters) { _, isCM in
            // Refresh input fields to current units when toggled
            potSizeInput = isCM ? String(format: "%.1f", Double(potSizeInches) * 2.54) : String(potSizeInches)
            potHeightInput = isCM ? String(format: "%.1f", Double(max(potHeightInches,0)) * 2.54) : String(max(potHeightInches,0))
        }
        .onChange(of: lightLevel) { _, _ in
            recalcWaterAmountFromCurrentInputs()
            announce("Recommendations updated for light level")
        }
        .onChange(of: potMaterial) { _, _ in
            recalcWaterAmountFromCurrentInputs()
            announce("Recommendations updated for pot material")
        }
        .onChange(of: potSizeInches) { _, _ in announce("Recommendations updated for pot size") }
        .onChange(of: potHeightInches) { _, _ in announce("Recommendations updated for pot height") }
        .confirmationDialog("Delete Photo", isPresented: $showingDeleteConfirmation, presenting: photoToDelete) { photo in
            Button("Delete Photo", role: .destructive) {
                deletePhoto(photo)
            }
        }
        .confirmationDialog("Delete Plant", isPresented: $showingDeletePlantConfirmation) {
            Button("Delete Plant", role: .destructive) {
                deletePlant()
            }
        } message: {
            Text("This action cannot be undone. All care history will be lost.")
        }
        .sheet(isPresented: $showingCamera) {
            CameraCapture(capturedImage: Binding(
                get: { nil },
                set: { newImage in
                    if let image = newImage,
                       let data = ImageProcessor.normalizedJPEGData(from: image) {
                        Task {
                            await addSelectedPhotosData([data])
                        }
                    }
                }
            ), isPresented: $showingCamera)
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        Section {
            VStack(spacing: BotanicaTheme.Spacing.md) {
                // Plant image or placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                        .fill(BotanicaTheme.Gradients.hero)
                        .frame(height: 200)
                    
                    if plant.primaryPhoto != nil {
                        AsyncPlantImageFill(photo: plant.primaryPhoto, cornerRadius: BotanicaTheme.CornerRadius.large)
                            .frame(height: 200)
                    } else {
                        VStack(spacing: BotanicaTheme.Spacing.sm) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                            
                            Text("Add Photo")
                                .font(BotanicaTheme.Typography.callout)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
                .onTapGesture {
                    showingPhotoPicker = true
                }
                
                // Plant name preview
                VStack(spacing: 4) {
                    Text(displayName.isEmpty ? "Plant Name" : displayName)
                        .font(BotanicaTheme.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if !scientificName.isEmpty {
                        Text(scientificName)
                            .font(BotanicaTheme.Typography.scientificName)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, BotanicaTheme.Spacing.sm)
        }
    }
    
    // MARK: - Care Summary
    private var careSummarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                Text("Care Summary")
                    .font(BotanicaTheme.Typography.headline)
                HStack {
                    summaryItem(title: "Water Every", value: "\(recommendedFrequencyDays) days", isManual: isWaterFreqManual)
                    Spacer()
                    summaryItem(title: "Water Dose", value: "\(Int(recommendedDoseMl)) ml", isManual: isWaterDoseManual)
                }
                if let next = previewNextWaterDate {
                    Text("Next Water: \(dateString(next))")
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                Button {
                    applyRecommendedBoth()
                } label: {
                    Label("Apply Recommended", systemImage: "wand.and.stars")
                        .font(.callout.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(BotanicaTheme.Colors.primary)
                .accessibilityLabel("Apply recommended water dose and frequency")
            }
        }
    }
    
    // MARK: - Photos Section
    
    private var photosSection: some View {
        Section("Photos") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BotanicaTheme.Spacing.sm) {
                    // Add photo button
                    Menu {
                        Button {
                            showingCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera.fill")
                        }
                        Button {
                            showingPhotoPicker = true
                        } label: {
                            Label("Choose from Library", systemImage: "photo.on.rectangle")
                        }
                    } label: {
                        RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                            .fill(BotanicaTheme.Colors.primary.opacity(0.1))
                            .frame(width: 80, height: 80)
                            .overlay {
                                VStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.title2)
                                        .foregroundColor(BotanicaTheme.Colors.primary)
                                    
                                    Text("Add")
                                        .font(.caption2)
                                        .foregroundColor(BotanicaTheme.Colors.primary)
                                }
                            }
                    }
                    
                    // Existing photos
                    ForEach(plant.photos) { photo in
                        AsyncPlantThumbnail(photo: photo, size: 80, cornerRadius: BotanicaTheme.CornerRadius.medium)
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    photoToDelete = photo
                                    showingDeleteConfirmation = true
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.white, .red)
                                }
                                .offset(x: 8, y: -8)
                            }
                    }
                }
                .padding(.horizontal, BotanicaTheme.Spacing.sm)
            }
        }
    }
    
    // MARK: - Pot & Environment
    private var potEnvironmentSection: some View {
        Section("Pot & Environment") {
            // Units + Pot Size / Height
            VStack(alignment: .leading, spacing: 8) {
                // Units toggle
                Picker("Units", selection: $useCentimeters) {
                    Text("in").tag(false)
                    Text("cm").tag(true)
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("Pot Size")
                        .font(BotanicaTheme.Typography.headline)
                    Spacer()
                    Text(displayPotSize)
                        .font(BotanicaTheme.Typography.callout)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: BotanicaTheme.Spacing.md) {
                    TextField(useCentimeters ? "Size (cm)" : "Size (in)", text: $potSizeInput)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: potSizeInput) { _, newVal in
                            updatePotSizeFromInput(newVal)
                        }
                }

                HStack {
                    Text("Pot Height")
                        .font(BotanicaTheme.Typography.headline)
                    Spacer()
                    Text(displayPotHeight)
                        .font(BotanicaTheme.Typography.callout)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: BotanicaTheme.Spacing.md) {
                    TextField(useCentimeters ? "Height (cm)" : "Height (in)", text: $potHeightInput)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: potHeightInput) { _, newVal in
                            updatePotHeightFromInput(newVal)
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Pot Material")
                        .font(BotanicaTheme.Typography.headline)
                    Picker("Pot Material", selection: $potMaterial) {
                        ForEach(PotMaterial.allCases, id: \.self) { mat in
                            Text(mat.rawValue).tag(mat)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            // Light Level
            VStack(alignment: .leading, spacing: 8) {
                Text("Light Level")
                    .font(BotanicaTheme.Typography.headline)
                Picker("Light Level", selection: $lightLevel) {
                    ForEach(LightLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - Water Every
    private var waterEverySection: some View {
        Section("Water Every") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Every \(wateringFrequency) days")
                        .font(BotanicaTheme.Typography.headline)
                        .accessibilityValue(isWaterFreqManual ? "Manual" : "Recommended")
                    Spacer()
                    ValueChip(text: "Recommended: \(recommendedFrequencyDays) d") {
                        wateringFrequency = recommendedFrequencyDays
                        isWaterFreqManual = false
                        announce("Frequency set to \(recommendedFrequencyDays) days")
                    }
                }

                Slider(value: Binding(
                    get: { Double(wateringFrequency) },
                    set: { newVal in
                        wateringFrequency = Int(newVal)
                        isWaterFreqManual = (wateringFrequency != recommendedFrequencyDays)
                    }
                ), in: 1...30, step: 1)
                .tint(BotanicaTheme.Colors.waterBlue)
            }
        }
    }

    // MARK: - Water Dose
    private var waterDoseSection: some View {
        Section("Water Dose") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Amount")
                        .font(BotanicaTheme.Typography.headline)
                        .accessibilityValue(isWaterDoseManual ? "Manual" : "Recommended")
                    Spacer()
                    ValueChip(text: "Recommended: \(Int(recommendedDoseMl)) ml") {
                        recommendedWaterAmount = recommendedDoseMl
                        waterUnit = .milliliters
                        isWaterDoseManual = false
                        announce("Water dose set to \(Int(recommendedDoseMl)) milliliters")
                    }
                }

                HStack(spacing: BotanicaTheme.Spacing.md) {
                    // Amount input
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Value")
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(.secondary)
                        TextField("250", value: $recommendedWaterAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: 120)
                            .onChange(of: recommendedWaterAmount) { _, _ in
                                isWaterDoseManual = (Int(recommendedWaterAmount) != Int(recommendedDoseMl))
                            }
                    }

                    // Unit picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unit")
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(.secondary)
                        Picker("Water Unit", selection: $waterUnit) {
                            ForEach(WaterUnit.allCases, id: \.self) { unit in
                                Text(unit.fullName).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(BotanicaTheme.Colors.primary)
                    }

                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Current")
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(recommendedWaterAmount))\(waterUnit.description)")
                            .font(BotanicaTheme.Typography.callout)
                            .foregroundColor(BotanicaTheme.Colors.waterBlue)
                    }
                }
            }
        }
    }
    
    // MARK: - Basic Information Section
    
    private var basicInfoSection: some View {
        Section("Basic Information") {
            TextField("Plant Nickname", text: $displayName)
                .textFieldStyle(.roundedBorder)
            
            TextField("Scientific Name", text: $scientificName)
                .textFieldStyle(.roundedBorder)
            
            TextField("Common Names (separated by commas)", text: $commonNames)
                .textFieldStyle(.roundedBorder)
            
            TextField("Location (e.g., Living room window)", text: $location)
                .textFieldStyle(.roundedBorder)
            
            TextField("Source/Where Acquired", text: $sourceDescription)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    // (Removed legacy careRequirementsSection – superseded by Pot & Environment, Water Every, and Water Dose sections)
    
    // MARK: - Additional Information Section (Advanced)
    private var additionalInfoSection: some View {
        Section("Advanced") {
            DisclosureGroup("Details") {
                // Fertilizing Frequency
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Fertilizing Frequency")
                            .font(BotanicaTheme.Typography.headline)
                        Spacer()
                        Text("\(fertilizingFrequency) days")
                            .font(BotanicaTheme.Typography.callout)
                            .foregroundColor(.secondary)
                    }
                    Slider(value: Binding(
                        get: { Double(fertilizingFrequency) },
                        set: { fertilizingFrequency = Int($0) }
                    ), in: 7...180, step: 7)
                    .tint(BotanicaTheme.Colors.leafGreen)
                }
                
                // Repotting
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Repot Every")
                            .font(BotanicaTheme.Typography.headline)
                        Spacer()
                        Text("\(repotFrequencyMonths) mo")
                            .font(BotanicaTheme.Typography.callout)
                            .foregroundColor(.secondary)
                    }
                    Slider(value: Binding(
                        get: { Double(repotFrequencyMonths) },
                        set: { repotFrequencyMonths = Int($0) }
                    ), in: 6...36, step: 3)
                    .tint(BotanicaTheme.Colors.nutrientOrange)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $hasBeenRepotted) {
                            HStack(spacing: 8) {
                                Image(systemName: "flowerpot.fill")
                                    .foregroundColor(BotanicaTheme.Colors.nutrientOrange)
                                Text("Last Repotted")
                            }
                        }
                        if hasBeenRepotted {
                            DatePicker("Date", selection: Binding(
                                get: { lastRepotted ?? Date() },
                                set: { lastRepotted = $0 }
                            ), displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .padding(.leading, 32)
                        }
                    }
                }

                // Humidity Preference
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Humidity Preference")
                            .font(BotanicaTheme.Typography.headline)
                        Spacer()
                        Text("\(Int(humidityPreference))%")
                            .font(BotanicaTheme.Typography.callout)
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $humidityPreference, in: 20...90, step: 5)
                        .tint(BotanicaTheme.Colors.primary)
                }

                // Temperature Range
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Temperature Range")
                            .font(BotanicaTheme.Typography.headline)
                        Spacer()
                        Text("\(Int(temperatureMin))° - \(Int(temperatureMax))°F")
                            .font(BotanicaTheme.Typography.callout)
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: BotanicaTheme.Spacing.sm) {
                        VStack {
                            Text("Min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(value: $temperatureMin, in: 50...85, step: 1)
                                .tint(BotanicaTheme.Colors.primary)
                        }
                        VStack {
                            Text("Max")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(value: $temperatureMax, in: 60...95, step: 1)
                                .tint(BotanicaTheme.Colors.primary)
                        }
                    }
                }

                // Location
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(BotanicaTheme.Typography.headline)
                    TextField("Living Room, Kitchen, Bedroom Window...", text: $location)
                        .textFieldStyle(.roundedBorder)
                }

                // Health Status
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Health Status")
                        .font(BotanicaTheme.Typography.headline)
                    Picker("Health Status", selection: $healthStatus) {
                        ForEach(HealthStatus.allCases, id: \.self) { status in
                            Label(status.rawValue, systemImage: status.systemImage)
                                .tag(status)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Care History
                VStack(alignment: .leading, spacing: 12) {
                    Text("Care History")
                        .font(BotanicaTheme.Typography.headline)
                    Text("Track last water and fertilizer dates to compute next due.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $hasBeenWatered) {
                            HStack(spacing: 8) {
                                Image(systemName: "drop.fill")
                                    .foregroundColor(BotanicaTheme.Colors.waterBlue)
                                Text("Last Watered")
                            }
                        }
                        if hasBeenWatered {
                            DatePicker("Date", selection: Binding(
                                get: { lastWatered ?? Date() },
                                set: { lastWatered = $0 }
                            ), displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .padding(.leading, 32)
                        }
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $hasBeenFertilized) {
                            HStack(spacing: 8) {
                                Image(systemName: "leaf.fill")
                                    .foregroundColor(BotanicaTheme.Colors.leafGreen)
                                Text("Last Fertilized")
                            }
                        }
                        if hasBeenFertilized {
                            DatePicker("Date", selection: Binding(
                                get: { lastFertilized ?? Date() },
                                set: { lastFertilized = $0 }
                            ), displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .padding(.leading, 32)
                        }
                    }
                }

                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(BotanicaTheme.Typography.headline)
                    TextField("Add observations, care notes, or reminders...", text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
            }
        }
    }
    
    // MARK: - Danger Zone Section
    
    private var dangerZoneSection: some View {
        Section {
            Button("Delete Plant") {
                showingDeletePlantConfirmation = true
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity, alignment: .center)
        } header: {
            Text("Danger Zone")
        } footer: {
            Text("Deleting this plant will permanently remove all associated care history and photos. This action cannot be undone.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Helper Methods
    
    private var displayPotSize: String {
        if useCentimeters { return String(format: "%.1f cm", Double(potSizeInches) * 2.54) }
        return "\(potSizeInches) in"
    }
    private var displayPotHeight: String {
        if useCentimeters { return String(format: "%.1f cm", Double(max(potHeightInches,0)) * 2.54) }
        return "\(max(potHeightInches,0)) in"
    }
    
    private func updatePotSizeFromInput(_ text: String) {
        guard let val = Double(text.replacingOccurrences(of: ",", with: ".")) else { return }
        if useCentimeters {
            potSizeInches = max(1, Int((val / 2.54).rounded()))
        } else {
            potSizeInches = max(1, Int(val.rounded()))
        }
        recalcWaterAmountFromCurrentInputs()
    }
    
    private func updatePotHeightFromInput(_ text: String) {
        guard let val = Double(text.replacingOccurrences(of: ",", with: ".")) else { return }
        if useCentimeters {
            potHeightInches = max(0, Int((val / 2.54).rounded()))
        } else {
            potHeightInches = max(0, Int(val.rounded()))
        }
    }

    private func recalcWaterAmountFromCurrentInputs() {
        // Do not overwrite the user's manual value; only update the manual flag
        isWaterDoseManual = (Int(recommendedWaterAmount) != Int(recommendedDoseMl))
    }
    
    private func savePlant() {
        let parsedCommonNames = commonNames.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let data = PlantFormData(
            nickname: displayName,
            scientificName: scientificName,
            family: plant.family,
            commonNames: parsedCommonNames,
            potSize: potSizeInches,
            potHeight: potHeightInches == 0 ? nil : potHeightInches,
            potMaterial: potMaterial,
            growthHabit: plant.growthHabit,
            matureSize: plant.matureSize,
            lightLevel: lightLevel,
            wateringFrequency: wateringFrequency,
            fertilizingFrequency: fertilizingFrequency,
            humidityPreference: Int(humidityPreference),
            temperatureRange: TemperatureRange(min: Int(temperatureMin), max: Int(temperatureMax)),
            recommendedWaterAmount: recommendedWaterAmount,
            waterUnit: waterUnit,
            source: sourceDescription,
            location: location,
            healthStatus: healthStatus,
            notes: notes,
            lastWatered: hasBeenWatered ? lastWatered : nil,
            lastFertilized: hasBeenFertilized ? lastFertilized : nil,
            repotFrequencyMonths: repotFrequencyMonths,
            lastRepotted: hasBeenRepotted ? lastRepotted : nil,
            photosData: []
        )
        
        do {
            try formViewModel.update(plant, with: data, in: modelContext)
            HapticManager.shared.success()
            dismiss()
        } catch {
            HapticManager.shared.error()
        }
    }
    
    private func addSelectedPhotos(_ items: [PhotosPickerItem]) async {
        var newData: [Data] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                newData.append(data)
            }
        }
        selectedPhotos.removeAll()
        await addSelectedPhotosData(newData)
    }
    
    @MainActor
    private func addSelectedPhotosData(_ dataItems: [Data]) async {
        for data in dataItems {
            if let image = UIImage(data: data),
               let normalized = ImageProcessor.normalizedJPEGData(from: image) {
                plant.addPhoto(from: normalized)
            }
        }
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            HapticManager.shared.error()
        }
    }
    
    private func deletePhoto(_ photo: Photo) {
        if let index = plant.photos.firstIndex(of: photo) {
            plant.photos.remove(at: index)
            
            do {
                try modelContext.save()
                HapticManager.shared.light()
            } catch {
                HapticManager.shared.error()
            }
        }
    }
    
    private func deletePlant() {
        modelContext.delete(plant)
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            HapticManager.shared.error()
        }
    }

    // MARK: - Recommendation helpers
    private var namesArray: [String] {
        commonNames.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    private var derivedPlantType: PlantWateringType {
        PlantWateringType.from(commonNames: namesArray, family: plant.family, scientificName: scientificName)
    }
    private var recommendedDoseMl: Double {
        let rec = CareCalculator.recommendedWateringAmount(
            potSize: potSizeInches,
            plantType: derivedPlantType,
            season: .current,
            environment: .indoor,
            potMaterial: potMaterial,
            lightLevel: lightLevel,
            potHeight: potHeightInches == 0 ? nil : potHeightInches
        )
        return Double(rec.amount)
    }
    private var recommendedFrequencyDays: Int {
        CareCalculator.autoWateringFrequencyDays(
            potSize: potSizeInches,
            potHeight: potHeightInches == 0 ? nil : potHeightInches,
            plantType: derivedPlantType,
            potMaterial: potMaterial,
            lightLevel: lightLevel,
            season: .current,
            environment: .indoor
        )
    }
    private var previewNextWaterDate: Date? {
        let freq = isWaterFreqManual ? wateringFrequency : recommendedFrequencyDays
        if let last = lastWatered ?? plant.lastWatered {
            return Calendar.current.date(byAdding: .day, value: freq, to: last)
        }
        return nil
    }
    private func applyRecommendedBoth() {
        wateringFrequency = recommendedFrequencyDays
        recommendedWaterAmount = recommendedDoseMl
        waterUnit = .milliliters
        isWaterFreqManual = false
        isWaterDoseManual = false
        announce("Applied recommended watering: every \(recommendedFrequencyDays) days, \(Int(recommendedDoseMl)) milliliters")
    }
    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
    private func summaryItem(title: String, value: String, isManual: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(BotanicaTheme.Typography.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 6) {
                Text(value)
                    .font(BotanicaTheme.Typography.callout)
                if !isManual {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(BotanicaTheme.Colors.primary)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityHint(isManual ? "Manual value" : "Recommended value applied")
    }
    private func announce(_ text: String) {
        #if canImport(UIKit)
        UIAccessibility.post(notification: .announcement, argument: text)
        #endif
    }
}

// MARK: - Extensions

extension HealthStatus {
    var systemImage: String {
        switch self {
        case .excellent:
            return "checkmark.circle.fill"
        case .healthy:
            return "checkmark.circle.fill"
        case .fair:
            return "exclamationmark.triangle.fill"
        case .poor:
            return "xmark.circle.fill"
        case .critical:
            return "xmark.circle.fill"
        }
    }
    
    var displayText: String {
        switch self {
        case .excellent:
            return "Excellent"
        case .healthy:
            return "Healthy"
        case .fair:
            return "Fair"
        case .poor:
            return "Poor"
        case .critical:
            return "Critical"
        }
    }
}

// MARK: - Small Reusable Components
private struct ValueChip: View {
    let text: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption.weight(.semibold))
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(BotanicaTheme.Colors.primary.opacity(0.1))
                .foregroundColor(BotanicaTheme.Colors.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Apply recommended value")
    }
}

#Preview {
    EditPlantView(plant: MockDataGenerator.shared.createSamplePlants().first!)
        .modelContainer(MockDataGenerator.previewContainer())
}
