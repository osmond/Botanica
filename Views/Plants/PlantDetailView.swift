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
    @State private var showAllHistory: Bool = false
    @State private var showingDeletePlantConfirmation = false
    @State private var scheduleExpanded = false
    @State private var conditionsExpanded = false

    private let sectionGap: CGFloat = 24
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
                VStack(spacing: BotanicaTheme.Spacing.lg) {
                    // Hero section with photo or gradient
                    heroSection
                        .padding(.bottom, -BotanicaTheme.CornerRadius.large)
                    
                    // Today / primary actions
                    careStateCard
                        .padding(.top, -BotanicaTheme.CornerRadius.large)
                        .padding(.bottom, BotanicaTheme.Spacing.md)
                    
                    belowHeroSections
                        .padding(.top, BotanicaTheme.Spacing.sm)
                    
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
                            .font(.system(size: 18, weight: .semibold))
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
    
    private var heroSection: some View {
        let heroHeight: CGFloat = 210
        let gradientHeight: CGFloat = 150
        return ZStack(alignment: .topLeading) {
            if let primaryPhoto = plant.primaryPhoto {
                AsyncPlantImageFill(
                    photo: primaryPhoto,
                    cornerRadius: BotanicaTheme.CornerRadius.large
                )
                .frame(height: heroHeight)
                .overlay(alignment: .bottom) {
                    heroBottomGradient
                        .frame(height: gradientHeight)
                        .frame(maxWidth: .infinity, alignment: .bottom)
                        .allowsHitTesting(false)
                        .padding(.bottom, -1)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 6)
                }
            } else if let referenceImage {
                Image(uiImage: referenceImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: heroHeight)
                    .overlay(alignment: .bottom) {
                        heroBottomGradient
                            .frame(height: gradientHeight)
                            .frame(maxWidth: .infinity, alignment: .bottom)
                            .allowsHitTesting(false)
                            .padding(.bottom, -1)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 6)
                    }
            } else {
                RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                    .fill(BotanicaTheme.Gradients.primary)
                    .frame(height: heroHeight)
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
        .frame(height: heroHeight)
        .clipShape(RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large))
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
                .padding(.top, BotanicaTheme.Spacing.sm)
                .padding(.trailing, BotanicaTheme.Spacing.sm)
            }
        }
        .overlay(alignment: .topLeading) {
            statusChip
                .padding(.top, BotanicaTheme.Spacing.sm)
                .padding(.leading, BotanicaTheme.Spacing.sm)
        }
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 6) {
                Text(plant.displayName)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                
                Text("In your collection · \(plantAge)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                
                if let statusLine = primaryStatusLine {
                    Text(statusLine)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, BotanicaTheme.Spacing.lg)
            .padding(.bottom, BotanicaTheme.Spacing.md)
        }
        .onTapGesture {
            HapticManager.shared.light()
            showingPhotoManager = true
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
    
    private var belowHeroSections: some View {
        VStack(alignment: .leading, spacing: sectionGap) {
            upNextSection
            logCareSection
            careHistorySection
            careScheduleSection
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
                Text("No care logged yet.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
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
    private var primaryStatusLine: String? {
        if plant.healthStatus == .excellent || plant.healthStatus == .healthy {
            return nil
        }
        
        return plant.healthStatus.rawValue
    }
    
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

    private var statusChip: some View {
        let label = careState.statusType == .needsAction ? "Needs care" : "All set"
        let color = careState.statusType == .needsAction ? BotanicaTheme.Colors.warning : BotanicaTheme.Colors.success

        return Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(color.opacity(0.9))
            )
    }
    
    private var upNextSection: some View {
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
            sectionHeaderRow("Up Next")

            if limited.isEmpty {
                Text("Nothing else is queued.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
            } else {
                VStack(alignment: .leading, spacing: rowGap) {
                    ForEach(limited) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: BotanicaTheme.Spacing.sm) {
                                Text(item.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                                Spacer()
                                Text(nextDateText(for: item.date))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                            }

                            if let note = item.note {
                                Text(note)
                                    .font(.system(size: 12, weight: .medium))
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
                    .foregroundStyle(BotanicaTheme.Colors.primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Log care")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                    Text("Record watering, feeding, or other care")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary.opacity(0.8))
            }
            .padding(BotanicaTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
    
    private var careScheduleSection: some View {
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
                    sectionHeader("Care Schedule")
                    Spacer()
                    Image(systemName: scheduleExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BotanicaTheme.Colors.textSecondary.opacity(0.8))
                }
            }
            .buttonStyle(.plain)

            Text(summary)
                .font(.system(size: 13, weight: .medium))
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
                    .font(.system(size: 14, weight: .semibold))
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
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BotanicaTheme.Colors.textSecondary.opacity(0.8))
                }
            }
            .buttonStyle(.plain)

            Text(summary)
                .font(.system(size: 13, weight: .medium))
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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BotanicaTheme.Colors.textSecondary.opacity(0.7))
            Text(value)
                .font(.system(size: 14, weight: .medium))
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
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                } else {
                    Text(trailingTitle)
                        .font(.system(size: 12, weight: .semibold))
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
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(BotanicaTheme.Colors.textPrimary)
            Text(shortDateFormatter.string(from: event.date))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(BotanicaTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
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

extension PlantDetailView {
    private var heroBottomGradient: some View {
        LinearGradient(
            colors: [
                .black.opacity(0.75),
                .black.opacity(0.4),
                .clear
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }
}

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
