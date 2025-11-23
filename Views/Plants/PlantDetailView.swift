// 
//  PlantDetailView.swift
//  Botanica
//
//  Modern redesigned plant detail view
//

import SwiftUI
import SwiftData
import UIKit

struct PlantDetailView: View {
    let plant: Plant
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = PlantDetailViewModel()
    
    @State private var showingEditPlant = false
    @State private var showingAddCareEvent = false
    @State private var selectedTab = 0
    @State private var showingPhotoManager = false
    @State private var referenceImage: UIImage?
    
    private var waterAmountText: String {
        let amount = plant.recommendedWateringAmount.amount
        let unit = plant.recommendedWateringAmount.unit
        return "\(amount) \(unit)"
    }
    
    private var fertilizerAmountText: String {
        let rec = plant.recommendedFertilizerAmount
        let amountString: String = rec.amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", rec.amount)
            : String(format: "%.1f", rec.amount)
        return "\(amountString) \(rec.unit)"
    }

    // MARK: - Formatting Helpers
    private var shortDateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }

    private func nextDateText(for date: Date?) -> String {
        guard let date = date else { return "—" }
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInTomorrow(date) { return "Tomorrow" }
        if date < Date() {
            let days = max(1, cal.dateComponents([.day], from: date, to: Date()).day ?? 0)
            return "Overdue \(days)d"
        }
        return shortDateFormatter.string(from: date)
    }

    private var nextWaterDate: Date? {
        let cal = Calendar.current
        return plant.nextWateringDate ?? cal.date(byAdding: .day, value: plant.wateringFrequency, to: plant.dateAdded)
    }

    private var nextFertilizeDate: Date? {
        let cal = Calendar.current
        return plant.nextFertilizingDate ?? cal.date(byAdding: .day, value: plant.fertilizingFrequency, to: plant.dateAdded)
    }
    
    private var plantAge: String {
        let calendar = Calendar.current
        let now = Date()
        let dateAcquired = plant.dateAcquired ?? plant.dateAdded
        let components = calendar.dateComponents([.day, .month, .year], from: dateAcquired, to: now)
        
        if let years = components.year, years > 0 {
            return years == 1 ? "1 year" : "\(years) years"
        } else if let months = components.month, months > 0 {
            return months == 1 ? "1 month" : "\(months) months"
        } else if let days = components.day, days > 0 {
            return days == 1 ? "1 day" : "\(days) days"
        } else {
            return "Today"
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BotanicaTheme.Spacing.lg) {
                    // Hero section with photo or gradient
                    heroSection
                    
                    // Plant info card
                    plantInfoCard
                    
                    // Care reminders if needed
                    if plant.isWateringOverdue || plant.isFertilizingOverdue {
                        careRemindersCard
                    }
                    
                    // Quick care actions
                    quickActionsCard
                    
                    // Plant details
                    detailsCard
                    
                    // Care history
                    careHistoryCard
                }
                .padding(.horizontal, BotanicaTheme.Spacing.lg)
                .padding(.top, BotanicaTheme.Spacing.md)
                .padding(.bottom, BotanicaTheme.Spacing.jumbo)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 120)
            }
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Plant detail for \(plant.displayName)")
            .accessibilityHint("Scroll for care status, reminders, and details")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        showingEditPlant = true
                    }
                    .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .sheet(isPresented: $showingEditPlant) {
            EditPlantView(plant: plant)
        }
        .sheet(isPresented: $showingAddCareEvent) {
            Text("Add Care Event View - Coming Soon")
        }
        .sheet(isPresented: $showingPhotoManager) {
            PhotoManager(plant: plant)
        }
        .alert("Action Failed", isPresented: Binding(
            get: { vm.actionError != nil },
            set: { _ in vm.actionError = nil }
        )) {
            Button("OK", role: .cancel) { vm.actionError = nil }
        } message: {
            Text(vm.actionError ?? "Something went wrong.")
        }
    }
    
    // MARK: - View Components
    
    private var heroSection: some View {
        ZStack {
            // Subtle background card to give the hero image a pedestal
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                .fill(BotanicaTheme.Gradients.hero)
                .shadow(
                    color: Color.black.opacity(0.18),
                    radius: 14,
                    x: 0,
                    y: 8
                )
            
            if let primaryPhoto = plant.primaryPhoto {
                AsyncPlantImageFill(
                    photo: primaryPhoto,
                    cornerRadius: BotanicaTheme.CornerRadius.large
                )
                .frame(height: 220)
                .overlay(
                    RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            } else if let referenceImage {
                Image(uiImage: referenceImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large))
                    .overlay(
                        RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                    .fill(BotanicaTheme.Gradients.primary)
                    .frame(height: 220)
                    .overlay {
                        VStack(spacing: BotanicaTheme.Spacing.md) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 32, weight: .light))
                                .foregroundStyle(.white.opacity(0.85))
                            
                            Text("Add Plant Photo")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
            }
        }
        .frame(height: 240)
        .overlay(alignment: .topTrailing) {
            if plant.primaryPhoto == nil, referenceImage != nil {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .medium))
                    Text("AI")
                        .font(.system(size: 10, weight: .bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    BotanicaTheme.Colors.primary,
                                    BotanicaTheme.Colors.leafGreen
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .foregroundColor(.white)
                .padding(10)
            }
        }
        .onTapGesture {
            if !plant.photos.isEmpty {
                HapticManager.shared.light()
                showingPhotoManager = true
            }
        }
        .task(id: plant.id) {
            // Only try to fetch a reference image if the user hasn't added one.
            if plant.primaryPhoto == nil, referenceImage == nil {
                let descriptor = PlantImageDescriptor(
                    id: plant.id,
                    displayName: plant.displayName,
                    scientificName: plant.scientificName,
                    commonNames: plant.commonNames
                )
                if let image = await PlantImageService.shared.referenceImage(for: descriptor) {
                    await MainActor.run {
                        referenceImage = image
                    }
                }
            }
        }
    }
    
    private var plantInfoCard: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                    Text(plant.displayName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                    
                    if !plant.scientificName.isEmpty {
                        Text(plant.scientificName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                            .italic()
                    }
                }
                
                Spacer()
                
                // Health status indicator
                VStack(spacing: BotanicaTheme.Spacing.xs) {
                    ZStack {
                        Circle()
                            .fill(plant.healthStatusColor.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Circle()
                            .fill(plant.healthStatusColor)
                            .frame(width: 10, height: 10)
                    }
                    
                    Text(plant.healthStatus.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(plant.healthStatusColor)
                }
            }
            
            Text("In collection \(plantAge)")
                .font(.system(size: 14))
                .foregroundStyle(BotanicaTheme.Colors.textSecondary)
        }
        .padding(BotanicaTheme.Spacing.lg)
        .cardStyle()
    }
    
    private var careRemindersCard: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.orange)
                
                Text("Care Needed")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.orange)
                
                Spacer()
            }
            
            VStack(spacing: BotanicaTheme.Spacing.sm) {
                if plant.isWateringOverdue {
                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundStyle(BotanicaTheme.Colors.waterBlue)
                            Text("Watering overdue")
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Button("Water Now") {
                                vm.quickWaterPlant(plant, context: modelContext)
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, BotanicaTheme.Spacing.sm)
                            .padding(.vertical, BotanicaTheme.Spacing.xs)
                            .background(BotanicaTheme.Colors.waterBlue)
                            .cornerRadius(BotanicaTheme.CornerRadius.small)
                        }
                        
                        Text("Use \(plant.recommendedWateringAmount.amount)\(plant.recommendedWateringAmount.unit) of water")
                            .font(.system(size: 12))
                            .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                            .padding(.leading, 20) // Align with text above
                    }
                }
                
                if plant.isFertilizingOverdue {
                    HStack {
                        Image(systemName: "leaf.arrow.circlepath")
                            .foregroundStyle(BotanicaTheme.Colors.leafGreen)
                        Text("Fertilizing due")
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                        Button("Fertilize") {
                            vm.quickFertilizePlant(plant, context: modelContext)
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, BotanicaTheme.Spacing.sm)
                        .padding(.vertical, BotanicaTheme.Spacing.xs)
                        .background(BotanicaTheme.Colors.leafGreen)
                        .cornerRadius(BotanicaTheme.CornerRadius.small)
                    }
                }
            }
        }
        .padding(BotanicaTheme.Spacing.lg)
        .cardStyle()
    }
    
    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(BotanicaTheme.Colors.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: BotanicaTheme.Spacing.md), count: 3), spacing: BotanicaTheme.Spacing.md) {
                QuickActionButton(
                    icon: "drop.fill",
                    title: "Water",
                    color: BotanicaTheme.Colors.waterBlue,
                    isUrgent: plant.isWateringOverdue,
                    subtitle: waterAmountText
                ) {
                    vm.quickWaterPlant(plant, context: modelContext)
                }
                
                QuickActionButton(
                    icon: "leaf.arrow.circlepath",
                    title: "Fertilize",
                    color: BotanicaTheme.Colors.leafGreen,
                    isUrgent: plant.isFertilizingOverdue,
                    subtitle: fertilizerAmountText
                ) {
                    vm.quickFertilizePlant(plant, context: modelContext)
                }
                
                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Add Care",
                    color: BotanicaTheme.Colors.primary,
                    isUrgent: false
                ) {
                    showingAddCareEvent = true
                }
            }
            .disabled(vm.isPerformingAction)
        }
        .padding(BotanicaTheme.Spacing.lg)
        .cardStyle()
    }
    
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            Text("Plant Details")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(BotanicaTheme.Colors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: BotanicaTheme.Spacing.md) {
                // Show location if available
                if !plant.location.isEmpty {
                    DetailItem(
                        icon: "location.fill",
                        title: "Location",
                        value: plant.location,
                        color: BotanicaTheme.Colors.primary
                    )
                }
                
                DetailItem(
                    icon: "sun.max.fill",
                    title: "Light",
                    value: plant.lightLevel.displayName,
                    color: BotanicaTheme.Colors.sunYellow
                )

                // Next dates
                DetailItem(
                    icon: "calendar.badge.clock",
                    title: "Next Water",
                    value: nextDateText(for: nextWaterDate),
                    color: BotanicaTheme.Colors.waterBlue
                )
                
                DetailItem(
                    icon: "calendar",
                    title: "Next Fertilize",
                    value: nextDateText(for: nextFertilizeDate),
                    color: BotanicaTheme.Colors.leafGreen
                )
                
                DetailItem(
                    icon: "drop.fill",
                    title: "Water Every",
                    value: "\(plant.wateringFrequency) days",
                    color: BotanicaTheme.Colors.waterBlue
                )
                
                DetailItem(
                    icon: "drop.triangle.fill",
                    title: "Water Amount",
                    value: "\(plant.recommendedWateringAmount.amount)\(plant.recommendedWateringAmount.unit)",
                    color: BotanicaTheme.Colors.waterBlue
                )
                
                DetailItem(
                    icon: "ruler",
                    title: "Pot Size",
                    value: "\(plant.potSize) in",
                    color: BotanicaTheme.Colors.textSecondary
                )
                
                DetailItem(
                    icon: "leaf.arrow.circlepath",
                    title: "Fertilize Every",
                    value: "\(plant.fertilizingFrequency) days",
                    color: BotanicaTheme.Colors.leafGreen
                )
                
                DetailItem(
                    icon: "thermometer",
                    title: "Temperature",
                    value: "\(plant.temperatureRange.min)-\(plant.temperatureRange.max)°F",
                    color: BotanicaTheme.Colors.textSecondary
                )

                // Pot attributes
                if let potH = plant.potHeight, potH > 0 {
                    DetailItem(
                        icon: "ruler",
                        title: "Pot Height",
                        value: "\(potH) in",
                        color: BotanicaTheme.Colors.textSecondary
                    )
                }
                
                DetailItem(
                    icon: "cube.box.fill",
                    title: "Pot Material",
                    value: (plant.potMaterial?.rawValue ?? "Unknown"),
                    color: BotanicaTheme.Colors.textSecondary
                )
            }
            
            if !plant.notes.isEmpty {
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                    Text("Notes")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                    
                    Text(plant.notes)
                        .font(.system(size: 14))
                        .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                }
                .padding(.top, BotanicaTheme.Spacing.sm)
            }
        }
        .padding(BotanicaTheme.Spacing.lg)
        .cardStyle()
    }
    
    private var careHistoryCard: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            HStack {
                Text("Care History")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                
                Spacer()
                
                if !plant.careEvents.isEmpty {
                    Button("View All") {
                        showingAddCareEvent = true
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BotanicaTheme.Colors.primary)
                }
            }
            
            if plant.careEvents.isEmpty {
                VStack(spacing: BotanicaTheme.Spacing.md) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 32))
                        .foregroundStyle(BotanicaTheme.Colors.textTertiary)
                    
                    VStack(spacing: BotanicaTheme.Spacing.xs) {
                        Text("No Care History")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                        
                        Text("Start caring for your plant to see history here")
                            .font(.system(size: 14))
                            .foregroundStyle(BotanicaTheme.Colors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, BotanicaTheme.Spacing.xl)
            } else {
                VStack(spacing: BotanicaTheme.Spacing.sm) {
                    let recentEvents = Array(plant.careEvents.sorted { $0.date > $1.date }.prefix(5))
                    ForEach(recentEvents, id: \.id) { event in
                        CareEventRow(event: event)
                    }
                }
            }
        }
        .padding(BotanicaTheme.Spacing.lg)
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Care history")
        .accessibilityHint("Recent care events and history actions")
    }
    
    // MARK: - Helper Functions
    
}

// MARK: - Helper Views

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let isUrgent: Bool
    let subtitle: String?
    let action: () -> Void
    
    init(
        icon: String,
        title: String,
        color: Color,
        isUrgent: Bool,
        subtitle: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.color = color
        self.isUrgent = isUrgent
        self.subtitle = subtitle
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: BotanicaTheme.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(color)
                }
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isUrgent ? color : BotanicaTheme.Colors.textPrimary)
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            subtitle != nil ? "\(title). \(subtitle!)" : title
        )
        .accessibilityHint("Quick action: \(title)")
    }
}

struct DetailItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(BotanicaTheme.Colors.textPrimary)
            }
        }
        .padding(BotanicaTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                .fill(color.opacity(0.08))
        )
    }
}

// ...existing code...

#Preview {
    let container = MockDataGenerator.previewContainer()
    let mockPlant = MockDataGenerator.shared.createSamplePlants().first!
    NavigationStack {
        PlantDetailView(plant: mockPlant)
    }
    .modelContainer(container)
    .environment(\.modelContext, container.mainContext)
}
