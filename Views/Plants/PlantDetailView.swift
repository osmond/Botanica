// 
//  PlantDetailView.swift
//  Botanica
//
//  Modern redesigned plant detail view
//

import SwiftUI
import SwiftData

struct PlantDetailView: View {
    let plant: Plant
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = PlantDetailViewModel()
    
    @State private var showingEditPlant = false
    @State private var showingAddCareEvent = false
    @State private var selectedTab = 0
    @State private var showingPhotoManager = false
    @State private var showingAddNote = false
    @State private var noteText: String = ""
    @State private var showAllHistory: Bool = false
    @State private var showingDeletePlantConfirmation = false
    @State private var scheduleExpanded = false
    @State private var conditionsExpanded = false
    @State private var showingCarePlanAssistant = false

    private let sectionGap: CGFloat = 20
    private let rowGap: CGFloat = 10
    private let sectionHeaderGap: CGFloat = 8
    
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
    
    private var lastWateredDate: Date? {
        if let eventDate = plant.careEvents
            .filter({ $0.type == .watering })
            .sorted(by: { $0.date > $1.date })
            .first?
            .date {
            return eventDate
        }
        return plant.lastWatered
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

    private var careState: PlantDetailViewModel.CareState {
        let scheduleIntervalText = "Fertilize every \(plant.fertilizingFrequency) days"
        let recommendedMl = plant.recommendedWateringAmount.amount > 0
            ? Double(plant.recommendedWateringAmount.amount)
            : nil
        return vm.careState(
            nextWaterDate: nextWaterDate,
            nextFertilizeDate: nextFertilizeDate,
            nextRepotDate: nextRepotDate,
            lastWateredDate: lastWateredDate,
            recommendedWaterMl: recommendedMl,
            scheduleIntervalText: scheduleIntervalText
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BotanicaTheme.Spacing.section) {
                    headerSection
                    
                    careStateCard
                        .padding(.bottom, BotanicaTheme.Spacing.sm)
                    
                    belowHeroSections
                }
                .padding(.horizontal, BotanicaTheme.Spacing.screenPadding)
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
                    Menu {
                        Button("Edit Plant") {
                            showingEditPlant = true
                        }
                        Button("Edit Schedule") {
                            showingEditPlant = true
                        }
                        Button("Edit Conditions") {
                            showingEditPlant = true
                        }
                        Divider()
                        Button("Delete Plant", role: .destructive) {
                            showingDeletePlantConfirmation = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(BotanicaTheme.Typography.headlineLarge)
                            .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditPlant) {
            EditPlantView(plant: plant)
        }
        .sheet(isPresented: $showingAddCareEvent) {
            AddCareEventView(plant: plant)
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
                                .stroke(BotanicaTheme.Colors.border.opacity(0.6))
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
        .confirmationDialog("Delete Plant", isPresented: $showingDeletePlantConfirmation, titleVisibility: .visible) {
            Button("Delete Plant", role: .destructive) {
                deletePlant()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove this plant, its care history, and photos.")
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        Button {
            HapticManager.shared.light()
            showingPhotoManager = true
        } label: {
            HStack(spacing: BotanicaTheme.Spacing.md) {
                AsyncPlantThumbnail(
                    photo: plant.primaryPhoto,
                    plant: plant,
                    size: 72,
                    cornerRadius: BotanicaTheme.CornerRadius.medium
                )
                
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                    Text(plant.displayName)
                        .font(BotanicaTheme.Typography.title2)
                        .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                        .lineLimit(2)
                    
                    if !plant.location.isEmpty {
                        Text(plant.location)
                            .font(BotanicaTheme.Typography.callout)
                            .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: BotanicaTheme.Spacing.xs) {
                        healthBadge
                        Text("In your collection · \(plantAge)")
                            .font(BotanicaTheme.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(BotanicaTheme.Typography.captionEmphasized)
                    .foregroundStyle(BotanicaTheme.Colors.textTertiary)
            }
            .padding(BotanicaTheme.Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                    .fill(BotanicaTheme.Colors.surfaceAlt)
            )
        }
        .buttonStyle(.plain)
    }

    private var healthBadge: some View {
        let color = healthStatusColor(for: plant.healthStatus)
        return HStack(spacing: BotanicaTheme.Spacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(plant.healthStatus.rawValue)
                .font(BotanicaTheme.Typography.caption2Emphasized)
                .foregroundStyle(color)
        }
        .padding(.horizontal, BotanicaTheme.Spacing.sm)
        .padding(.vertical, BotanicaTheme.Spacing.xs)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
        )
    }

    private func healthStatusColor(for status: HealthStatus) -> Color {
        switch status {
        case .excellent, .healthy:
            return BotanicaTheme.Colors.success
        case .fair:
            return BotanicaTheme.Colors.warning
        case .poor, .critical:
            return BotanicaTheme.Colors.error
        }
    }
    
    private var belowHeroSections: some View {
        VStack(alignment: .leading, spacing: sectionGap) {
            careOverviewSection
            logCareSection
            careHistorySection
            carePlanSection
            growingConditionsSection
        }
    }
    
    private var careHistorySection: some View {
        let sortedEvents = plant.careEvents.sorted { $0.date > $1.date }
        let recentEvents = showAllHistory ? sortedEvents : Array(sortedEvents.prefix(2))
        
        return VStack(alignment: .leading, spacing: sectionHeaderGap) {
            if plant.careEvents.isEmpty {
                sectionHeaderRow("Recent")
            } else {
                sectionHeaderRow(
                    "Recent",
                    trailingTitle: showAllHistory ? "Show less" : "View all"
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAllHistory.toggle()
                    }
                }
            }

            if recentEvents.isEmpty {
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                    Text("No care logged yet.")
                        .font(BotanicaTheme.Typography.callout)
                        .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                    Button("Log first care") {
                        showingAddCareEvent = true
                    }
                    .font(BotanicaTheme.Typography.calloutEmphasized)
                    .foregroundStyle(BotanicaTheme.Colors.primary)
                }
            } else {
                VStack(alignment: .leading, spacing: rowGap) {
                    ForEach(recentEvents, id: \.id) { event in
                        careHistoryRow(for: event)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
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

    private func deletePlant() {
        modelContext.delete(plant)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            vm.actionError = error.localizedDescription
        }
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

extension PlantDetailView {
    private var careStateCard: some View {
        CareStateCard(
            statusType: careState.statusType,
            title: careState.primaryTitle,
            subtitle: careState.primarySubtitle,
            meta: careState.primaryMeta,
            cta: careState.primaryCTA
        ) { actionType in
            guard !vm.isPerformingAction else { return }
            HapticManager.shared.light()
            switch actionType {
            case .logWater:
                vm.quickWaterPlant(plant, context: modelContext)
            case .logFertilize:
                vm.quickFertilizePlant(plant, context: modelContext)
            }
        }
    }
    
    private var careOverviewSection: some View {
        VStack(alignment: .leading, spacing: sectionHeaderGap) {
            sectionHeaderRow("Care Overview")

            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
                upNextContent
                careScheduleContent
            }
            .padding(BotanicaTheme.Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                    .fill(BotanicaTheme.Colors.surfaceAlt)
            )
        }
    }

    private var upNextContent: some View {
        let upcomingItems: [UpcomingItem] = [
            ("Water", nextWaterDate, nil),
            ("Fertilize", nextFertilizeDate, nil),
            ("Repot", nextRepotDate, repotDueSoon ? "Due soon" : nil)
        ]
        .compactMap { title, date, note in
            guard let date, !isDueTodayOrOverdue(date) else { return nil }
            return UpcomingItem(title: title, date: date, note: note)
        }
        .sorted { $0.date < $1.date }

        let limited = Array(upcomingItems.prefix(2))

        return VStack(alignment: .leading, spacing: sectionHeaderGap) {
            Text("Up Next")
                .font(BotanicaTheme.Typography.captionEmphasized)
                .foregroundStyle(BotanicaTheme.Colors.textSecondary)

            if limited.isEmpty {
                Text("Nothing else is queued.")
                    .font(BotanicaTheme.Typography.callout)
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
            } else {
                VStack(alignment: .leading, spacing: rowGap) {
                    ForEach(limited) { item in
                        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                            HStack(spacing: BotanicaTheme.Spacing.sm) {
                                Text(item.title)
                                    .font(BotanicaTheme.Typography.labelEmphasized)
                                    .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                                Spacer()
                                Text(nextDateText(for: item.date))
                                    .font(BotanicaTheme.Typography.callout)
                                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                            }

                            if let note = item.note {
                                Text(note)
                                    .font(BotanicaTheme.Typography.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var logCareSection: some View {
        Button {
            showingAddCareEvent = true
        } label: {
            HStack(spacing: BotanicaTheme.Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                    Text("Log care")
                        .font(BotanicaTheme.Typography.button)
                        .foregroundStyle(.white)
                    Text("Record watering, feeding, or other care")
                        .font(BotanicaTheme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(BotanicaTheme.Typography.captionEmphasized)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(BotanicaTheme.Spacing.cardPadding)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                    .fill(BotanicaTheme.Gradients.primary)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var careScheduleContent: some View {
        let repotMonths = plant.repotFrequencyMonths ?? 12
        let repotText = repotMonths >= 12 ? "Repot yearly" : "Repot every \(repotMonths) months"
        let summary = "Water every \(plant.wateringFrequency) days · Fertilize every \(plant.fertilizingFrequency) days · \(repotText)"

        return VStack(alignment: .leading, spacing: sectionHeaderGap) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    scheduleExpanded.toggle()
                }
            } label: {
                HStack(spacing: BotanicaTheme.Spacing.sm) {
                    Text("Care Schedule")
                        .font(BotanicaTheme.Typography.captionEmphasized)
                        .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                    Spacer()
                    Image(systemName: scheduleExpanded ? "chevron.down" : "chevron.right")
                        .font(BotanicaTheme.Typography.captionEmphasized)
                        .foregroundStyle(BotanicaTheme.Colors.textSecondary.opacity(0.8))
                }
            }
            .buttonStyle(.plain)

            Text(summary)
                .font(BotanicaTheme.Typography.callout)
                .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                .lineLimit(1)

            if scheduleExpanded {
                VStack(alignment: .leading, spacing: rowGap) {
                    infoRow(title: "Water", value: "Every \(plant.wateringFrequency) days")
                    infoRow(title: "Fertilize", value: "Every \(plant.fertilizingFrequency) days")
                    infoRow(title: "Repot", value: repotText)

                    Button("Edit Schedule") {
                        showingEditPlant = true
                    }
                    .font(BotanicaTheme.Typography.labelEmphasized)
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var growingConditionsSection: some View {
        let locationText = plant.location.isEmpty ? "Location not set" : plant.location
        let summary = "\(locationText) · \(plant.lightLevel.displayName) · \(plant.temperatureRange.min) to \(plant.temperatureRange.max)°F"

        return VStack(alignment: .leading, spacing: sectionHeaderGap) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    conditionsExpanded.toggle()
                }
            } label: {
                HStack(spacing: BotanicaTheme.Spacing.sm) {
                    sectionHeader("Growing Conditions")
                    Spacer()
                    Image(systemName: conditionsExpanded ? "chevron.down" : "chevron.right")
                        .font(BotanicaTheme.Typography.captionEmphasized)
                        .foregroundStyle(BotanicaTheme.Colors.textSecondary.opacity(0.8))
                }
            }
            .buttonStyle(.plain)

            Text(summary)
                .font(BotanicaTheme.Typography.callout)
                .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                .lineLimit(1)

            if conditionsExpanded {
                VStack(alignment: .leading, spacing: rowGap) {
                    infoRow(title: "Location", value: locationText)
                    infoRow(title: "Light", value: plant.lightLevel.displayName)
                    infoRow(title: "Temperature", value: "\(plant.temperatureRange.min)–\(plant.temperatureRange.max)°F")

                    Button("Edit Conditions") {
                        showingEditPlant = true
                    }
                    .font(BotanicaTheme.Typography.labelEmphasized)
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var carePlanSection: some View {
        VStack(alignment: .leading, spacing: sectionHeaderGap) {
            sectionHeaderRow("Care Plan")
            
            if let plan = plant.carePlan {
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                    HStack(spacing: BotanicaTheme.Spacing.sm) {
                        Image(systemName: plan.source.icon)
                            .foregroundStyle(BotanicaTheme.Colors.primary)
                        Text(plan.source.rawValue)
                            .font(BotanicaTheme.Typography.labelEmphasized)
                            .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                        Spacer()
                        Text(shortDateFormatter.string(from: plan.lastUpdated))
                            .font(BotanicaTheme.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                    }
                    
                    Text("Water every \(plan.wateringInterval) days · Fertilize every \(plan.fertilizingInterval) days")
                        .font(BotanicaTheme.Typography.callout)
                        .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                }
                .padding(BotanicaTheme.Spacing.cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                        .fill(BotanicaTheme.Colors.surfaceAlt)
                )
            } else {
                Text("No care plan applied yet.")
                    .font(BotanicaTheme.Typography.callout)
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
            }
            
            Button(plant.carePlan == nil ? "Create AI Care Plan" : "Review in AI") {
                showingCarePlanAssistant = true
            }
            .font(BotanicaTheme.Typography.labelEmphasized)
            .foregroundStyle(BotanicaTheme.Colors.primary)
        }
        .sheet(isPresented: $showingCarePlanAssistant) {
            AICareAssistantView(plant: plant)
        }
    }
    
    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
            Text(title)
                .font(BotanicaTheme.Typography.calloutEmphasized)
                .foregroundStyle(BotanicaTheme.Colors.textSecondary.opacity(0.7))
            Text(value)
                .font(BotanicaTheme.Typography.label)
                .fontWeight(.medium)
                .foregroundStyle(BotanicaTheme.Colors.textPrimary)
        }
    }

    private func sectionHeaderRow(
        _ title: String,
        trailingTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        HStack(spacing: BotanicaTheme.Spacing.sm) {
            sectionHeader(title)
            Spacer()
            if let trailingTitle {
                if let action {
                    Button(trailingTitle, action: action)
                        .font(BotanicaTheme.Typography.captionEmphasized)
                        .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                } else {
                    Text(trailingTitle)
                        .font(BotanicaTheme.Typography.captionEmphasized)
                        .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                }
            }
        }
    }
    private func careHistoryRow(for event: CareEvent) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            let amountText: String? = {
                guard let amount = event.amount else { return nil }
                return "\(Int(amount)) ml"
            }()
            
            Text(amountText != nil ? "\(event.type.rawValue) · \(amountText!)" : event.type.rawValue)
                .font(BotanicaTheme.Typography.labelEmphasized)
                .foregroundStyle(BotanicaTheme.Colors.textPrimary)
            Text(shortDateFormatter.string(from: event.date))
                .font(BotanicaTheme.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(BotanicaTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(BotanicaTheme.Typography.captionEmphasized)
            .textCase(.uppercase)
            .foregroundStyle(BotanicaTheme.Colors.textSecondary)
    }
}

// MARK: - Upcoming Helpers

extension PlantDetailView {
    private struct UpcomingItem: Identifiable {
        let title: String
        let date: Date
        let note: String?

        var id: String { title }
    }

    private func isDueTodayOrOverdue(_ date: Date) -> Bool {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return true }
        return date < calendar.startOfDay(for: Date())
    }
}

// MARK: - Helper Views

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let isUrgent: Bool
    let subtitle: String?
    let undoAction: (() -> Void)?
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
        undoAction: (() -> Void)? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.color = color
        self.isUrgent = isUrgent
        self.subtitle = subtitle
        self.undoAction = undoAction
        self.action = action
    }
    
    var body: some View {
        Button {
            guard !isConfirming else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isConfirming = true
                toastText = "Logged \(title.lowercased())"
                showUndo = undoAction != nil
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
                        .font(BotanicaTheme.Typography.labelEmphasized)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .opacity(isConfirming ? 1 : 0)
                    
                    if #available(iOS 18, *) {
                        Image(systemName: icon)
                            .font(BotanicaTheme.Typography.headlineLarge)
                            .foregroundStyle(isConfirming ? .white : color)
                            .symbolEffect(.bounce, options: isConfirming ? .nonRepeating : .default)
                            .overlay(checkOverlay)
                    } else {
                        Image(systemName: icon)
                            .font(BotanicaTheme.Typography.headlineLarge)
                            .foregroundStyle(isConfirming ? .white : color)
                            .overlay(checkOverlay)
                    }
                }
                
                VStack(spacing: 2) {
                    Text(isConfirming ? "Logged" : title)
                        .font(BotanicaTheme.Typography.captionEmphasized)
                        .foregroundStyle(isConfirming ? color : (isUrgent ? color : BotanicaTheme.Colors.textPrimary))
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(BotanicaTheme.Typography.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(isConfirming ? color.opacity(0.8) : BotanicaTheme.Colors.textSecondary)
                    }
                }
                
                if showUndo {
                    Text("Undo")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(color)
                        .padding(.horizontal, BotanicaTheme.Spacing.sm)
                        .padding(.vertical, BotanicaTheme.Spacing.xs)
                        .background(color.opacity(0.12))
                        .clipShape(Capsule())
                        .onTapGesture {
                            withAnimation { showUndo = false; isConfirming = false }
                            undoAction?()
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
                    .font(BotanicaTheme.Typography.headlineSmall)
                    .foregroundStyle(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                Text(title)
                    .font(BotanicaTheme.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                
                Text(value)
                    .font(BotanicaTheme.Typography.labelEmphasized)
                    .fontWeight(.bold)
                    .foregroundStyle(BotanicaTheme.Colors.textPrimary)
            }
        }
        .padding(BotanicaTheme.Spacing.cardPadding)
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
