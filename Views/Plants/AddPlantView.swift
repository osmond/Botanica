import SwiftUI
import SwiftData
import PhotosUI
import UIKit

/// Comprehensive view for adding new plants with photo picker, botanical fields, and care requirements
struct CustomPicker<T: CaseIterable & Hashable & RawRepresentable>: View where T.RawValue == String {
    let title: String
    @Binding var selection: T
    let options: [T]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(BotanicaTheme.Typography.callout)
                .foregroundColor(.primary)
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option.rawValue.capitalized)
                        .tag(option)
                }
            }
            .pickerStyle(.menu)
            .padding(12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct CustomSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let suffix: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(BotanicaTheme.Typography.callout)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(Int(value))\(suffix)")
                    .font(BotanicaTheme.Typography.callout)
                    .foregroundColor(.secondary)
            }
            Slider(value: $value, in: range, step: 1)
                .tint(BotanicaTheme.Colors.leafGreen)
        }
    }
}

struct RangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let range: ClosedRange<Double>
    var body: some View {
        VStack {
            HStack {
                Slider(value: $minValue, in: range.lowerBound...maxValue, step: 1)
                    .tint(BotanicaTheme.Colors.leafGreen)
                Slider(value: $maxValue, in: minValue...range.upperBound, step: 1)
                    .tint(BotanicaTheme.Colors.leafGreen)
            }
            RoundedRectangle(cornerRadius: 4)
                .fill(BotanicaTheme.Colors.leafGreen.opacity(0.3))
                .frame(height: 8)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(BotanicaTheme.Colors.leafGreen)
                        .frame(width: CGFloat((maxValue - minValue) / (range.upperBound - range.lowerBound)) * 200)
                        .offset(x: CGFloat((minValue - range.lowerBound) / (range.upperBound - range.lowerBound)) * 200)
                }
        }
    }
}

struct AddPlantView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var formViewModel = PlantFormViewModel()
    
    // MARK: - AI Integration
    private let prefilledData: PlantIdentificationResult?
    private let prefilledImage: UIImage?
    
    // MARK: - Draft Persistence
    @AppStorage("addPlant.draft.nickname") private var draftNickname = ""
    @AppStorage("addPlant.draft.scientificName") private var draftScientificName = ""
    @AppStorage("addPlant.draft.location") private var draftLocation = ""
    
    // MARK: - Plant Basic Info
    @State private var nickname = ""
    @State private var scientificName = ""
    @State private var commonNames: [String] = []
    @State private var commonNamesText = ""
    @State private var family = ""
    @State private var selectedGrowthHabit: GrowthHabit = .upright
    @State private var matureSize = ""
    
    // MARK: - Photo Selection
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoData: [Data] = []
    @State private var showingPhotosPicker = false
    @State private var showingCamera = false
    
    // MARK: - Care Requirements
    @State private var selectedLightLevel: LightLevel = .medium
    @State private var wateringFrequency = 7.0
    @State private var fertilizingFrequency = 30.0
    @State private var humidityPreference = 50.0
    @State private var minTemperature = 65.0
    @State private var maxTemperature = 80.0
    @State private var recommendedWaterAmount = 0.0
    @State private var selectedWaterUnit: WaterUnit = .milliliters
    
    // MARK: - Additional Info
    @State private var source = ""
    @State private var location = ""
    @State private var potSizeValue = 6.0
    @State private var notes = ""
    @State private var selectedHealthStatus: HealthStatus = .healthy
    
    // MARK: - Care History
    @State private var lastWatered: Date? = Date()
    @State private var lastFertilized: Date? = Date()
    @State private var hasBeenWatered = true
    @State private var hasBeenFertilized = true
    
    // MARK: - UI State
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSaving = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    // Enhancement states
    @State private var showLowConfidenceWarning = false
    @State private var showPersonalizedTips = false
    @State private var showSuccessAnimation = false

    // For location autocomplete
    @Query(sort: \Plant.dateAdded, order: .reverse) private var plants: [Plant]
    
    // MARK: - Initializers
    
    init(prefilledData: PlantIdentificationResult? = nil, prefilledImage: UIImage? = nil) {
        self.prefilledData = prefilledData
        self.prefilledImage = prefilledImage
        
        print("🌱 AddPlantView: Initialized with prefilledData: \(prefilledData?.commonName ?? "nil"), prefilledImage: \(prefilledImage != nil ? "present" : "nil")")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        BotanicaTheme.Colors.background,
                        BotanicaTheme.Colors.background.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: BotanicaTheme.Spacing.xl) {
                            // Hero header
                            headerSection
                            
                            if let validation = formViewModel.validationMessage {
                                Text(validation)
                                    .font(BotanicaTheme.Typography.caption)
                                    .foregroundColor(BotanicaTheme.Colors.error)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.08))
                                    .cornerRadius(BotanicaTheme.CornerRadius.medium)
                                    .accessibilityLabel("Validation: \(validation)")
                            }
                            
                            // Photo Section
                            photoSection
                            
                            // Basic Information
                            basicInfoSection(proxy: proxy)
                            
                            // Botanical Details
                            botanicalDetailsSection
                            
                            // Care Requirements
                            careRequirementsSection
                            
                            // Care History
                            careHistorySection
                            
                            // Location & Notes
                            locationNotesSection
                            
                            // Bottom spacing for save button
                            Spacer(minLength: 80)
                        }
                        .padding(BotanicaTheme.Spacing.lg)
                        .padding(.bottom, keyboardHeight)
                    }
                }
            }
            .navigationTitle("Add Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticManager.shared.selection()
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await savePlant()
                        }
                    } label: {
                        if isSaving {
                            HStack(spacing: BotanicaTheme.Spacing.xs) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Saving...")
                            }
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    // Animated success overlay
                    if showSuccessAnimation {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                if #available(iOS 18.0, *) {
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(BotanicaTheme.Colors.leafGreen)
                                        .transition(.scale.combined(with: .opacity))
                                        .symbolEffect(.bounce, options: .repeating)
                                } else {
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(BotanicaTheme.Colors.leafGreen)
                                        .transition(.scale.combined(with: .opacity))
                                }
                                Spacer()
                            }
                            Text("Plant Added!")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(BotanicaTheme.Colors.primary)
                                .transition(.opacity)
                            Spacer()
                        }
                        .background(Color.black.opacity(0.2).ignoresSafeArea())
                    }
                    }
                    .disabled(nickname.isEmpty || isSaving)
                    .foregroundColor(nickname.isEmpty ? .secondary : BotanicaTheme.Colors.primary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Enhanced floating save button with loading state
                if !nickname.isEmpty {
                    Button {
                        Task {
                            await savePlant()
                        }
                    } label: {
                        HStack(spacing: BotanicaTheme.Spacing.sm) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                Image(systemName: "leaf.fill")
                                    .font(.caption)
                                    .transition(.scale.combined(with: .opacity))
                            }
                            
                            Text(isSaving ? "Saving..." : "Save Plant")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                                .fill(BotanicaTheme.Gradients.primary)
                                .shadow(
                                    color: BotanicaTheme.Colors.primary.opacity(0.4),
                                    radius: isSaving ? 8 : 12,
                                    x: 0,
                                    y: isSaving ? 2 : 4
                                )
                        )
                        .foregroundColor(.white)
                        .scaleEffect(isSaving ? 0.98 : 1.0)
                        .animation(BotanicaTheme.Animation.spring, value: isSaving)
                    }
                    .disabled(nickname.isEmpty || isSaving)
                    .opacity(nickname.isEmpty ? 0.5 : 1.0)
                    .padding(BotanicaTheme.Spacing.lg)
                    .background(.regularMaterial)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        keyboardHeight = keyboardFrame.cgRectValue.height
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = 0
                }
            }
            .onAppear {
                print("🌱 AddPlantView: onAppear called, prefilledData: \(prefilledData?.commonName ?? "nil")")
                loadDraft()
                populateFromAI()
                if let confidence = prefilledData?.confidence, confidence < 0.6 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showLowConfidenceWarning = true
                    }
                }
                recalculateRecommendedWater()
            }
            .onChange(of: potSizeValue) { _, _ in recalculateRecommendedWater() }
            .onChange(of: scientificName) { _, _ in updateFrequencyRecommendations() }
            .onChange(of: family) { _, _ in updateFrequencyRecommendations() }
            .onChange(of: commonNamesText) { _, _ in updateFrequencyRecommendations() }
            .onChange(of: selectedGrowthHabit) { _, _ in updateFrequencyRecommendations() }
            .onChange(of: selectedLightLevel) { _, _ in updateFrequencyRecommendations() }
            .onChange(of: nickname) { _, _ in persistDraft() }
            .onChange(of: scientificName) { _, _ in persistDraft() }
            .onChange(of: location) { _, _ in persistDraft() }
            .photosPicker(isPresented: $showingPhotosPicker, selection: $selectedPhotos, maxSelectionCount: 10, matching: .images)
            .onChange(of: selectedPhotos) { _, _ in
                Task { await loadPhotos() }
            }
            .sheet(isPresented: $showingCamera) {
                CameraCapture(capturedImage: Binding(
                    get: { nil },
                    set: { newImage in
                        if let image = newImage,
                           let data = ImageProcessor.normalizedJPEGData(from: image) {
                            photoData.append(data)
                        }
                    }
                ), isPresented: $showingCamera)
                .ignoresSafeArea()
            }
        }
    }
    
    // MARK: - Header Section
    @ViewBuilder
    var headerSection: some View {
        VStack(spacing: BotanicaTheme.Spacing.md) {
            // Plant icon with gradient background
            ZStack {
                Circle()
                    .fill(BotanicaTheme.Gradients.primary)
                    .frame(width: 80, height: 80)
                    .shadow(color: BotanicaTheme.Colors.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                
                Image(systemName: "leaf.fill")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: BotanicaTheme.Spacing.xs) {
                Text("Add New Plant")
                    .font(BotanicaTheme.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Fill in the details to start caring for your new plant")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                // Low confidence warning
                .alert("Low Confidence", isPresented: $showLowConfidenceWarning) {
                    Button("Add More Photos") { showingPhotosPicker = true }
                    Button("Continue Anyway", role: .cancel) {}
                } message: {
                    Text("The AI wasn't very confident in its identification. You can add more photos for better accuracy or continue anyway.")
                }

                // Personalized tips after saving
                .sheet(isPresented: $showPersonalizedTips) {
                    PersonalizedTipsView(plantName: nickname, lightLevel: selectedLightLevel, wateringFrequency: wateringFrequency, humidity: humidityPreference)
                }
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, BotanicaTheme.Spacing.lg)
    }
    
    // MARK: - Photo Section
    @ViewBuilder
    var photoSection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            HStack {
                SectionHeader(title: "Photos")
                Spacer()
                
                Menu {
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera.fill")
                    }
                    
                    Button {
                        showingPhotosPicker = true
                    } label: {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "camera")
                        Text("Add Photos")
                    }
                    .font(BotanicaTheme.Typography.caption)
                    .foregroundColor(BotanicaTheme.Colors.leafGreen)
                }
            }
            

            if photoData.isEmpty {
                // Placeholder photo area
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("Add photos of your plant")
                                .font(BotanicaTheme.Typography.callout)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onTapGesture {
                        showingPhotosPicker = true
                    }
            } else {
                // Photo grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(Array(photoData.enumerated()), id: \.offset) { index, data in
                        if let uiImage = UIImage(data: data) {
                            PlantPhotoThumbnail(uiImage: uiImage, index: index)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Photo Thumbnail Subview
    func PlantPhotoThumbnail(uiImage: UIImage, index: Int) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 100)
            .clipped()
            .cornerRadius(8)
            .overlay(alignment: .topTrailing) {
                Button(action: { removePhoto(at: index) }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .background(Circle().fill(.black.opacity(0.6)))
                }
                .padding(4)
            }
    }
    
    // MARK: - Basic Information Section
    @ViewBuilder
    func basicInfoSection(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            HStack {
                SectionHeader(title: "Basic Information", isComplete: !nickname.isEmpty)
                Spacer()
            }
            
            VStack(spacing: BotanicaTheme.Spacing.md) {
                CustomTextField(title: "Plant Nickname *", text: $nickname, placeholder: "My Monstera")
                if nickname.isEmpty {
                    Text("Required")
                        .font(BotanicaTheme.Typography.caption2)
                        .foregroundColor(BotanicaTheme.Colors.error)
                }
                
                CustomTextField(title: "Scientific Name", text: $scientificName, placeholder: "Monstera deliciosa")
                
                CustomTextField(title: "Common Names", text: $commonNamesText, placeholder: "Swiss Cheese Plant, Split-leaf Philodendron")
                
                CustomTextField(title: "Plant Family", text: $family, placeholder: "Araceae")

                // Pot-size-first prompt
                if recommendedWaterAmount == 0 {
                    HStack(alignment: .center, spacing: BotanicaTheme.Spacing.md) {
                        Image(systemName: "info.circle")
                            .foregroundColor(BotanicaTheme.Colors.primary)
                        Text("Tip: Set pot size to personalize water amount and schedules.")
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Set Pot Size") { proxy.scrollTo("potSizeAnchor", anchor: .top) }
                            .font(BotanicaTheme.Typography.caption)
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Physical Characteristics Section
    @ViewBuilder
    var botanicalDetailsSection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            SectionHeader(title: "Physical Characteristics", isComplete: Int(potSizeValue) > 0)
            
            VStack(spacing: BotanicaTheme.Spacing.md) {
                CustomPicker(title: "Growth Habit", selection: $selectedGrowthHabit, options: GrowthHabit.allCases)
                
                CustomTextField(title: "Mature Size", text: $matureSize, placeholder: "3-6 feet tall")
                
                CustomSlider(title: "Pot Size", value: $potSizeValue, range: 4...20, suffix: " inches")
                    .id("potSizeAnchor")
                
                CustomTextField(title: "Source/Where Acquired", text: $source, placeholder: "Plant shop, online, cutting")
            }
        }
        .cardStyle()
    }
    
    // MARK: - Care Requirements Section
    @ViewBuilder
    var careRequirementsSection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            SectionHeader(title: "Care Requirements")
            
            VStack(spacing: BotanicaTheme.Spacing.md) {
                CustomPicker(title: "Light Level", selection: $selectedLightLevel, options: LightLevel.allCases)
                
                CustomSlider(title: "Watering Frequency", value: $wateringFrequency, range: 1...30, suffix: " days")
                
                // Water Amount Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended Water Amount (based on pot size)")
                        .font(BotanicaTheme.Typography.callout)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: BotanicaTheme.Spacing.md) {
                        // Amount input
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Amount")
                                .font(BotanicaTheme.Typography.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                TextField(recommendedWaterAmount == 0 ? "Select pot size" : String(Int(recommendedWaterAmount)), value: $recommendedWaterAmount, format: .number)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 80)
                                
                                Text(selectedWaterUnit.description)
                                    .font(BotanicaTheme.Typography.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Unit picker
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Unit")
                                .font(BotanicaTheme.Typography.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("Water Unit", selection: $selectedWaterUnit) {
                                ForEach(WaterUnit.allCases, id: \.self) { unit in
                                    Text(unit.fullName).tag(unit)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(BotanicaTheme.Colors.primary)
                        }
                    }
                    if recommendedWaterAmount == 0 {
                        Text("Select a pot size to auto-calculate a recommended amount.")
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                CustomSlider(title: "Fertilizing Frequency", value: $fertilizingFrequency, range: 7...180, suffix: " days")
                
                CustomSlider(title: "Humidity Preference", value: $humidityPreference, range: 20...90, suffix: "%")
                
                // Temperature Range
                VStack(alignment: .leading, spacing: 8) {
                    Text("Temperature Range")
                        .font(BotanicaTheme.Typography.callout)
                        .foregroundColor(.primary)
                    
                    HStack {
                        VStack {
                            Text("Min")
                                .font(BotanicaTheme.Typography.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(minTemperature))°F")
                                .font(BotanicaTheme.Typography.callout)
                        }
                        
                        RangeSlider(minValue: $minTemperature, maxValue: $maxTemperature, range: 50...95)
                        
                        VStack {
                            Text("Max")
                                .font(BotanicaTheme.Typography.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(maxTemperature))°F")
                                .font(BotanicaTheme.Typography.callout)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Additional Information Section
    @ViewBuilder
    var locationNotesSection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            SectionHeader(title: "Additional Information", isComplete: !location.isEmpty)
            
            VStack(spacing: BotanicaTheme.Spacing.md) {
                    CustomTextField(title: "Location", text: $location, placeholder: "Living Room, Kitchen, Bedroom Window...")

                    // Location autocomplete suggestions
                    if !location.isEmpty {
                        let usedLocations = Set(plants.compactMap { $0.location.isEmpty ? nil : $0.location })
                        let filtered = usedLocations.filter { $0.localizedCaseInsensitiveContains(location) && $0 != location }
                        if !filtered.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Suggestions:")
                                    .font(BotanicaTheme.Typography.caption)
                                    .foregroundColor(.secondary)
                        ForEach(Array(filtered.prefix(4)), id: \.self) { suggestion in
                                    Button(action: { location = suggestion }) {
                                        Text(suggestion)
                                            .font(BotanicaTheme.Typography.body)
                                            .foregroundColor(BotanicaTheme.Colors.primary)
                                            .padding(.vertical, 2)
                                    }
                                }
                            }
                        }
                    }
                
                CustomPicker(title: "Current Health Status", selection: $selectedHealthStatus, options: HealthStatus.allCases)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(BotanicaTheme.Typography.callout)
                        .foregroundColor(.primary)
                    
                    TextField("Additional care notes, observations, special requirements...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Care History Section
    @ViewBuilder
    var careHistorySection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            Text("Care History")
                .font(BotanicaTheme.Typography.headline)
                .foregroundColor(.primary)
            
            Text("When was this plant last cared for? This helps calculate when it's next due.")
                .font(BotanicaTheme.Typography.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: BotanicaTheme.Spacing.md) {
                // Last Watered
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $hasBeenWatered) {
                        HStack(spacing: 8) {
                            Image(systemName: "drop.fill")
                                .foregroundColor(BotanicaTheme.Colors.waterBlue)
                            Text("Last Watered")
                                .font(BotanicaTheme.Typography.callout)
                                .foregroundColor(.primary)
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
                
                // Last Fertilized
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $hasBeenFertilized) {
                        HStack(spacing: 8) {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(BotanicaTheme.Colors.leafGreen)
                            Text("Last Fertilized")
                                .font(BotanicaTheme.Typography.callout)
                                .foregroundColor(.primary)
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
        }
        .cardStyle()
    }
    
    // MARK: - Helper Methods
    
    func recalculateRecommendedWater() {
        // Determine plant type from entered names/family
        let type = PlantWateringType.from(
            commonNames: commonNames.isEmpty ? commonNamesText.components(separatedBy: ",").map{ $0.trimmingCharacters(in: .whitespaces) } : commonNames,
            family: family,
            scientificName: scientificName
        )
        let recommendation = CareCalculator.recommendedWateringAmount(
            potSize: Int(potSizeValue),
            plantType: type,
            season: Season.spring,
            environment: CareEnvironment.indoor
        )
        recommendedWaterAmount = Double(recommendation.amount)
        selectedWaterUnit = .milliliters
    }

    func removePhoto(at index: Int) {
        HapticManager.shared.selection()
        photoData.remove(at: index)
        selectedPhotos.remove(at: index)
    }
    
    @MainActor
    func loadPhotos() async {
        photoData.removeAll()
        
        for item in selectedPhotos {
            if let data = try? await item.loadTransferable(type: Data.self) {
                photoData.append(data)
            }
        }
    }
    
    @MainActor
    func populateFromAI() {
        guard let aiData = prefilledData else { 
            print("🌱 AddPlantView: No AI data to populate with")
            return 
        }
        
        print("🌱 AddPlantView: Starting to populate from AI data - \(aiData.commonName)")
        
        // Auto-populate form fields from AI identification
        nickname = aiData.commonName
        scientificName = aiData.scientificName
        family = aiData.family
        matureSize = aiData.matureSize
        
        // Populate common names from AI (join with commas for the text field)
        commonNames = aiData.commonNames
        commonNamesText = aiData.commonNames.joined(separator: ", ")
        
        // Combine description and care instructions in notes
        var notesText = aiData.description
        if !aiData.careInstructions.isEmpty {
            if !notesText.isEmpty {
                notesText += "\n\nCare Instructions:\n"
            }
            notesText += aiData.careInstructions
        }
        notes = notesText
        
        // Set photo from AI capture
        if let image = prefilledImage {
            // Convert UIImage to Data for photoData array
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                photoData = [imageData]
                print("🌱 AddPlantView: Successfully added captured image to photoData")
            } else {
                print("🌱 AddPlantView: Failed to convert captured image to JPEG data")
            }
        } else {
            print("🌱 AddPlantView: No captured image to add")
        }
        
        print("🌱 AddPlantView: Successfully populated all fields from AI data")
        print("🌱 AddPlantView: - Nickname: '\(nickname)'")
        print("🌱 AddPlantView: - Scientific name: '\(scientificName)'")
        print("🌱 AddPlantView: - Family: '\(family)'")
        print("🌱 AddPlantView: - Common names: '\(commonNamesText)'")
        print("🌱 AddPlantView: - Photo count: \(photoData.count)")
        
        // Enhanced parsing of care instructions
        let careText = aiData.careInstructions.lowercased()
        
        // Parse light requirements
        if careText.contains("full sun") || careText.contains("bright light") || careText.contains("direct sun") {
            selectedLightLevel = .bright
        } else if careText.contains("low light") || careText.contains("shade") || careText.contains("indirect") {
            selectedLightLevel = .low
        } else if careText.contains("partial") || careText.contains("medium") {
            selectedLightLevel = .medium
        }
        
        // Parse watering frequency
        if careText.contains("daily") || careText.contains("every day") {
            wateringFrequency = 1.0
        } else if careText.contains("twice a week") {
            wateringFrequency = 3.5
        } else if careText.contains("weekly") || careText.contains("once a week") {
            wateringFrequency = 7.0
        } else if careText.contains("every two weeks") || careText.contains("biweekly") {
            wateringFrequency = 14.0
        } else if careText.contains("monthly") || careText.contains("once a month") {
            wateringFrequency = 30.0
        } else {
            // Default based on plant type
            if careText.contains("succulent") || careText.contains("cactus") {
                wateringFrequency = 14.0 // Less frequent for succulents
            } else if careText.contains("tropical") || careText.contains("humid") {
                wateringFrequency = 5.0 // More frequent for tropical plants
            } else {
                wateringFrequency = 7.0 // Default weekly
            }
        }
        
        // Parse humidity preferences
        if careText.contains("high humidity") || careText.contains("tropical") {
            humidityPreference = 70.0
        } else if careText.contains("low humidity") || careText.contains("dry") {
            humidityPreference = 30.0
        } else {
            humidityPreference = 50.0 // Medium humidity default
        }
        
        // Set temperature defaults based on plant type
        if careText.contains("tropical") {
            minTemperature = 70.0
            maxTemperature = 85.0
        } else if careText.contains("cool") || careText.contains("temperate") {
            minTemperature = 60.0
            maxTemperature = 75.0
        } else {
            minTemperature = 65.0
            maxTemperature = 80.0
        }
        
        // Set fertilizing frequency defaults
        if careText.contains("regular fertiliz") || careText.contains("monthly fertiliz") {
            fertilizingFrequency = 30.0
        } else if careText.contains("weekly fertiliz") {
            fertilizingFrequency = 7.0
        } else {
            fertilizingFrequency = 30.0 // Default monthly
        }
        // Nudge frequencies using CareCalculator if we have enough info
        updateFrequencyRecommendations()
    }

    // Derive numeric defaults from CareCalculator text frequency
    func updateFrequencyRecommendations() {
        let type = PlantWateringType.from(
            commonNames: commonNames.isEmpty ? commonNamesText.components(separatedBy: ",").map{ $0.trimmingCharacters(in: .whitespaces) } : commonNames,
            family: family,
            scientificName: scientificName
        )
        let waterRec = CareCalculator.recommendedWateringAmount(
            potSize: Int(potSizeValue),
            plantType: type,
            season: .spring,
            environment: .indoor
        )
        // Parse "Every X-Y days" to midpoint
        let days = parseDays(from: waterRec.frequency)
        if wateringFrequency == 7.0 || wateringFrequency == 0 { // only nudge defaults
            if let d = days { wateringFrequency = Double(d) }
        }

        let fertRec = CareCalculator.recommendedFertilizerAmount(
            potSize: Int(potSizeValue),
            plantType: type
        )
        let fertDays = parseDays(from: fertRec.frequency)
        if fertilizingFrequency == 30.0 || fertilizingFrequency == 0 {
            if let d = fertDays { fertilizingFrequency = Double(d) }
        }
    }

    func parseDays(from frequency: String) -> Int? {
        // Extract numbers and detect weeks vs days
        let numbers = frequency
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        guard !numbers.isEmpty else { return nil }
        let isWeek = frequency.lowercased().contains("week")
        let value: Int
        if numbers.count >= 2 { value = (numbers[0] + numbers[1]) / 2 } else { value = numbers[0] }
        return isWeek ? value * 7 : value
    }
    
    @MainActor
    func savePlant() async {
        isSaving = true
        
        do {
            // Parse common names from comma-separated text
            let parsedCommonNames = commonNamesText
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            let formData = PlantFormData(
                nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                scientificName: scientificName.trimmingCharacters(in: .whitespacesAndNewlines),
                family: family.trimmingCharacters(in: .whitespacesAndNewlines),
                commonNames: parsedCommonNames,
                potSize: Int(potSizeValue),
                potHeight: nil,
                potMaterial: nil,
                growthHabit: selectedGrowthHabit,
                matureSize: matureSize.trimmingCharacters(in: .whitespacesAndNewlines),
                lightLevel: selectedLightLevel,
                wateringFrequency: Int(wateringFrequency),
                fertilizingFrequency: Int(fertilizingFrequency),
                humidityPreference: Int(humidityPreference),
                temperatureRange: TemperatureRange(min: Int(minTemperature), max: Int(maxTemperature)),
                recommendedWaterAmount: recommendedWaterAmount,
                waterUnit: selectedWaterUnit,
                source: source.trimmingCharacters(in: .whitespacesAndNewlines),
                location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                healthStatus: selectedHealthStatus,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                lastWatered: hasBeenWatered ? lastWatered : nil,
                lastFertilized: hasBeenFertilized ? lastFertilized : nil,
                photosData: photoData
            )
            
            guard formViewModel.validate(formData) else {
                alertMessage = formViewModel.validationMessage ?? "Please correct the highlighted fields."
                showingAlert = true
                HapticManager.shared.error()
                isSaving = false
                return
            }
            
            _ = try formViewModel.saveNewPlant(formData, in: modelContext)
            HapticManager.shared.success()
            clearDraft()
            dismiss()
            
        } catch {
            alertMessage = "Failed to save plant: \(error.localizedDescription)"
            showingAlert = true
            HapticManager.shared.error()
        }
        
        isSaving = false
    }
    
    private func loadDraft() {
        if nickname.isEmpty { nickname = draftNickname }
        if scientificName.isEmpty { scientificName = draftScientificName }
        if location.isEmpty { location = draftLocation }
    }
    
    private func persistDraft() {
        draftNickname = nickname
        draftScientificName = scientificName
        draftLocation = location
    }
    
    private func clearDraft() {
        draftNickname = ""
        draftScientificName = ""
        draftLocation = ""
    }
}

// MARK: - Custom UI Components

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(BotanicaTheme.Typography.callout)
                .foregroundColor(.primary)
            
            TextField(placeholder, text: $text)
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

// Standardized Section Header
    struct SectionHeader: View {
        let title: String
    var isComplete: Bool = false
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.sm) {
            Text(title)
                .font(BotanicaTheme.Typography.headline)
                .foregroundColor(.primary)
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(BotanicaTheme.Colors.success)
                    .font(.footnote)
            }
            Spacer()
        }
    }
}
#Preview {
    NavigationStack {
        AddPlantView()
    }
    .modelContainer(MockDataGenerator.previewContainer())
}
