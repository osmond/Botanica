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
    @State private var showingAddNote = false
    @State private var noteText: String = ""

    private var waterAmountText: String {
        let rec = plant.recommendedWateringAmount
        let amountValue = Double(rec.amount)
        let amountString: String = amountValue.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", amountValue)
            : String(format: "%.1f", amountValue)
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
    
    private var nextRepotDate: Date? {
        let months = plant.repotFrequencyMonths ?? 12
        let cal = Calendar.current
        return plant.nextRepottingDate ?? cal.date(byAdding: .month, value: months, to: plant.dateAdded)
    }
    
    private var repotDueSoon: Bool {
        guard let nextRepotDate else { return false }
        let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: nextRepotDate).day ?? 0
        return daysUntil <= 14
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
                VStack(spacing: BotanicaTheme.Spacing.sm) {
                    // Hero section with photo or gradient
                    heroSection
                    
                    // Plant info card
                    plantInfoCard
                    
                    // Care reminders if needed
                    if plant.isWateringOverdue || plant.isFertilizingOverdue || plant.isRepottingOverdue || repotDueSoon {
                        careRemindersCard
                    }
                    
                    // Today / primary actions
                    todayCard
                        .padding(.top, -BotanicaTheme.Spacing.sm)
                    
                    // Coming up preview
                    comingUpCard
                    
                    // Care rhythm
                    careRhythmCard
                    
                    // Placement
                    placementCard
                    
                    // Environment
                    environmentCard
                    
                    // Container
                    containerCard
                    
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
        .sheet(isPresented: $showingAddNote) {
            NavigationStack {
                VStack(spacing: BotanicaTheme.Spacing.md) {
                    Text("Add a note for \(plant.nickname)")
                        .font(BotanicaTheme.Typography.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TextEditor(text: $noteText)
                        .frame(minHeight: 200)
                        .padding(.horizontal, BotanicaTheme.Spacing.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                                .stroke(Color.secondary.opacity(0.2))
                        )
                    
                    Spacer()
                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddNote = false; noteText = "" }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveNote()
                        }
                        .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
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
                
                if plant.isRepottingOverdue {
                    HStack {
                        Image(systemName: "flowerpot.fill")
                            .foregroundStyle(BotanicaTheme.Colors.soilBrown)
                        Text("Repotting overdue")
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                        Button("Plan repot") {
                            showingEditPlant = true
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, BotanicaTheme.Spacing.sm)
                        .padding(.vertical, BotanicaTheme.Spacing.xs)
                        .background(BotanicaTheme.Colors.soilBrown)
                        .cornerRadius(BotanicaTheme.CornerRadius.small)
                    }
                    
                    Text("Update last repot date once you finish to reset reminders.")
                        .font(.system(size: 12))
                        .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                        .padding(.leading, 20)
                } else if let nextRepotDate {
                    let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: nextRepotDate).day ?? 0
                    if daysUntil <= 14 {
                        HStack(spacing: BotanicaTheme.Spacing.xs) {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(BotanicaTheme.Colors.soilBrown)
                            Text(daysUntil <= 0 ? "Repotting due now" : "Repot soon (\(daysUntil) days)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                        }
                    }
                }
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
    private func saveNote() {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let separator = plant.notes.isEmpty ? "" : "\n"
        plant.notes.append("\(separator)\(trimmed)")
        try? modelContext.save()
        noteText = ""
        showingAddNote = false
    }
    
    // Combined pot size/height text
    private var potSizeText: String {
        if let potH = plant.potHeight, potH > 0 {
            return "\(plant.potSize) in (H \(potH) in)"
        }
        return "\(plant.potSize) in"
    }
    
}

// MARK: - New Card Stack Views

private enum CareStatusState {
    case overdue(Int)
    case today
    case soon(Int)
    case scheduled(Date)
    case unset
}

extension PlantDetailView {
    private func careStatus(for date: Date?, overdue: Bool) -> CareStatusState {
        guard let date else { return .unset }
        if overdue { // explicit overdue flag from model
            let days = max(1, Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 1)
            return .overdue(days)
        }
        if Calendar.current.isDateInToday(date) { return .today }
        if date < Date() { // fallback overdue
            let days = max(1, Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 1)
            return .overdue(days)
        }
        let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if daysUntil <= 3 { return .soon(max(1, daysUntil)) }
        return .scheduled(date)
    }
    
    private func statusLabel(for state: CareStatusState) -> String {
        switch state {
        case .overdue(let days): return days <= 1 ? "Overdue" : "Overdue \(days)d"
        case .today: return "Due today"
        case .soon(let days): return "Due in \(days)d"
        case .scheduled(let date): return nextDateText(for: date)
        case .unset: return "Not set"
        }
    }
    
    private func statusColor(for state: CareStatusState) -> Color {
        switch state {
        case .overdue: return .red
        case .today: return BotanicaTheme.Colors.waterBlue
        case .soon: return BotanicaTheme.Colors.sunYellow
        case .scheduled, .unset: return BotanicaTheme.Colors.leafGreen
        }
    }
    
    private func showAction(for state: CareStatusState) -> Bool {
        switch state {
        case .overdue, .today: return true
        default: return false
        }
    }
    
    private var todayCard: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                    Text("Today")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                    Text("What needs attention right now")
                        .font(.system(size: 14))
                        .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                }
                Spacer()
            }
            
            VStack(spacing: BotanicaTheme.Spacing.sm) {
                todayRow(
                    title: "Water",
                    icon: "drop.fill",
                    accent: BotanicaTheme.Colors.waterBlue,
                    date: nextWaterDate,
                    overdue: plant.isWateringOverdue,
                    actionTitle: "Log Water",
                    action: { vm.quickWaterPlant(plant, context: modelContext) },
                    detailText: "Use \(waterAmountText)"
                )
                
                todayRow(
                    title: "Fertilize",
                    icon: "leaf.arrow.circlepath",
                    accent: BotanicaTheme.Colors.leafGreen,
                    date: nextFertilizeDate,
                    overdue: plant.isFertilizingOverdue,
                    actionTitle: "Log Fertilizer",
                    action: { vm.quickFertilizePlant(plant, context: modelContext) }
                )
                
                todayRow(
                    title: "Repot",
                    icon: "calendar.badge.plus",
                    accent: BotanicaTheme.Colors.soilBrown,
                    date: nextRepotDate,
                    overdue: plant.isRepottingOverdue,
                    actionTitle: "Plan Repot",
                    action: { showingEditPlant = true }
                )
            }
        }
        .padding(BotanicaTheme.Spacing.lg)
        .cardStyle()
    }
    
    private func todayRow(
        title: String,
        icon: String,
        accent: Color,
        date: Date?,
        overdue: Bool,
        actionTitle: String,
        action: @escaping () -> Void,
        detailText: String? = nil
    ) -> some View {
        let state = careStatus(for: date, overdue: overdue)
        let status = statusLabel(for: state)
        let stateColor = statusColor(for: state)
        let actionable = showAction(for: state)
        
        return HStack(alignment: .center, spacing: BotanicaTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent)
            }
            
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                Text(status)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(stateColor)
                
                if let detailText {
                    Text(detailText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            if actionable {
                Button(actionTitle) {
                    guard !vm.isPerformingAction else { return }
                    HapticManager.shared.light()
                    action()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, BotanicaTheme.Spacing.sm)
                .padding(.vertical, BotanicaTheme.Spacing.xs)
                .background(stateColor)
                .clipShape(Capsule())
                .disabled(vm.isPerformingAction)
            }
        }
        .padding(.horizontal, BotanicaTheme.Spacing.sm)
        .padding(.vertical, BotanicaTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                .fill(BotanicaTheme.Colors.surface.opacity(0.1))
        )
    }
    
    private var comingUpCard: some View {
        let upcomingItems: [(String, String, Color, Date?)] = [
            ("Water", "calendar.badge.clock", BotanicaTheme.Colors.waterBlue, nextWaterDate),
            ("Fertilize", "calendar", BotanicaTheme.Colors.leafGreen, nextFertilizeDate),
            ("Repot", "calendar.badge.plus", BotanicaTheme.Colors.soilBrown, nextRepotDate)
        ].filter { entry in
            guard let date = entry.3 else { return false }
            return !Calendar.current.isDateInToday(date) && date > Date()
        }
        
        return VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            HStack {
                Text("Up Next")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                Spacer()
            }
            
            if upcomingItems.isEmpty {
                Text("Nothing else is queued. You’re all set.")
                    .font(.system(size: 14))
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                    .padding(.vertical, BotanicaTheme.Spacing.sm)
            } else {
                VStack(spacing: BotanicaTheme.Spacing.sm) {
                    ForEach(upcomingItems, id: \.0) { item in
                        upcomingRow(
                            title: item.0,
                            icon: item.1,
                            color: item.2,
                            date: item.3
                        )
                    }
                }
            }
        }
        .padding(BotanicaTheme.Spacing.lg)
        .cardStyle()
    }
    
    private func upcomingRow(
        title: String,
        icon: String,
        color: Color,
        date: Date?
    ) -> some View {
        HStack(spacing: BotanicaTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(BotanicaTheme.Colors.textPrimary)
            Spacer()
            Text(nextDateText(for: date))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(BotanicaTheme.Colors.textSecondary)
        }
        .padding(.horizontal, BotanicaTheme.Spacing.sm)
        .padding(.vertical, BotanicaTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                .fill(BotanicaTheme.Colors.surface.opacity(0.1))
        )
    }
    
    private var careRhythmCard: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            Text("Care Rhythm")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(BotanicaTheme.Colors.textPrimary)
            
            VStack(spacing: BotanicaTheme.Spacing.sm) {
                rhythmRow(
                    title: "Water",
                    value: "Every \(plant.wateringFrequency) days",
                    icon: "drop.fill",
                    color: BotanicaTheme.Colors.waterBlue
                )
                
                rhythmRow(
                    title: "Fertilize",
                    value: "Every \(plant.fertilizingFrequency) days",
                    icon: "leaf.arrow.circlepath",
                    color: BotanicaTheme.Colors.leafGreen
                )
                
                rhythmRow(
                    title: "Repot",
                    value: "Every \(plant.repotFrequencyMonths ?? 12) months",
                    icon: "calendar.badge.plus",
                    color: BotanicaTheme.Colors.soilBrown
                )
            }
        }
        .padding(BotanicaTheme.Spacing.lg)
        .cardStyle()
    }
    
    private func rhythmRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: BotanicaTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, BotanicaTheme.Spacing.sm)
        .padding(.vertical, BotanicaTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                .fill(BotanicaTheme.Colors.surface.opacity(0.2))
        )
    }
    
    private var placementCard: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            Text("Placement")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(BotanicaTheme.Colors.textPrimary)
            
            VStack(spacing: BotanicaTheme.Spacing.sm) {
                placementRow(icon: "location.fill", title: "Location", value: plant.location.isEmpty ? "Not set" : plant.location)
                placementRow(icon: "sun.max.fill", title: "Light", value: plant.lightLevel.displayName)
            }
        }
        .padding(BotanicaTheme.Spacing.lg)
        .cardStyle()
    }
    
    private func placementRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: BotanicaTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BotanicaTheme.Colors.primary)
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, BotanicaTheme.Spacing.sm)
        .padding(.vertical, BotanicaTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                .fill(BotanicaTheme.Colors.surface.opacity(0.2))
        )
    }
    
    private var environmentCard: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            Text("Environment")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(BotanicaTheme.Colors.textPrimary)
            
            HStack(spacing: BotanicaTheme.Spacing.md) {
                Image(systemName: "thermometer")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                Text("Temperature")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("\(plant.temperatureRange.min)–\(plant.temperatureRange.max)°F")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
            }
            .padding(.horizontal, BotanicaTheme.Spacing.sm)
            .padding(.vertical, BotanicaTheme.Spacing.xs)
            .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                .fill(BotanicaTheme.Colors.surface.opacity(0.1))
            )
        }
        .padding(BotanicaTheme.Spacing.lg)
        .cardStyle()
    }
    
    private var containerCard: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            Text("Container")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(BotanicaTheme.Colors.textPrimary)
            
            VStack(spacing: BotanicaTheme.Spacing.sm) {
                containerRow(icon: "ruler", title: "Pot Size", value: potSizeText)
                containerRow(icon: "cube.box.fill", title: "Pot Material", value: plant.potMaterial?.rawValue ?? "Unknown")
            }
        }
        .padding(BotanicaTheme.Spacing.lg)
        .cardStyle()
    }
    
    private func containerRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: BotanicaTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BotanicaTheme.Colors.textSecondary)
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, BotanicaTheme.Spacing.sm)
        .padding(.vertical, BotanicaTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                .fill(BotanicaTheme.Colors.surface.opacity(0.1))
        )
    }
}

// MARK: - Helper Views

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let isUrgent: Bool
    let subtitle: String?
    @State private var isConfirming = false
    @State private var showUndo = false
    @State private var toastText: String = ""
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
            guard !isConfirming else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isConfirming = true
                toastText = "Logged \(title.lowercased())"
                showUndo = true
            }
            HapticManager.shared.light()
            action()
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isConfirming = false
                        showUndo = false
                    }
                }
            }
        } label: {
            VStack(spacing: BotanicaTheme.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(isConfirming ? color.opacity(0.35) : color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    let checkOverlay = Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .opacity(isConfirming ? 1 : 0)
                    
                    if #available(iOS 18, *) {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isConfirming ? .white : color)
                            .symbolEffect(.bounce, options: isConfirming ? .nonRepeating : .default)
                            .overlay(checkOverlay)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isConfirming ? .white : color)
                            .overlay(checkOverlay)
                    }
                }
                
                VStack(spacing: 2) {
                    Text(isConfirming ? "Logged" : title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isConfirming ? color : (isUrgent ? color : BotanicaTheme.Colors.textPrimary))
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(isConfirming ? color.opacity(0.8) : BotanicaTheme.Colors.textSecondary)
                    }
                }
                
                if showUndo {
                    Text("Undo")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.12))
                        .clipShape(Capsule())
                        .onTapGesture {
                            withAnimation { showUndo = false; isConfirming = false }
                            // Future: wire actual undo when CareEvent supports it
                        }
                        .transition(.opacity.combined(with: .scale))
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
