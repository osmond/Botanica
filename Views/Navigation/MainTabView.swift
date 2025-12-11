import SwiftUI
import PhotosUI
import UIKit
import SwiftData

/// Main tab view container for the Botanica app
/// Provides navigation between My Plants, Analytics, and Settings sections
@MainActor
struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var plants: [Plant]
    
    @StateObject private var coordinator = MainTabCoordinator(notificationService: AppServices.shared.notifications)
    @State private var fabPressed = false
    
    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            ActivityView()
                .tabItem {
                    Label("Activity", systemImage: "bell.badge")
                }
                .tag(Tab.activity)
            
            MyPlantsView()
                .tabItem {
                    Label("My Plants", systemImage: "leaf.fill")
                }
                .tag(Tab.plants)
            
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.analytics)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(BotanicaTheme.Colors.primary)
        .onAppear {
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // Setup notifications for all plants
            coordinator.scheduleNotificationsIfNeeded(plants: plants)
        }
        .onChange(of: plants.count) { _, _ in
            // Reschedule notifications when plants are added/removed
            coordinator.refreshNotifications(plants: plants)
        }
        .overlay(alignment: .bottomTrailing) {
            // Floating Action Button
            Button {
                HapticManager.shared.medium()
                coordinator.handleAddButtonTap()
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(BotanicaTheme.Gradients.primary)
                            .shadow(
                                color: BotanicaTheme.Colors.primary.opacity(0.3),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                    )
            }
            .interactiveScale(pressed: fabPressed)
            .onLongPressGesture(minimumDuration: 0) { pressing in
                fabPressed = pressing
            } perform: {}
            .padding(.trailing, BotanicaTheme.Spacing.lg)
            .padding(.bottom, 100) // Account for tab bar
        }
        .sheet(isPresented: $coordinator.showingPlantIdentification) {
            InlinePlantIdentificationView { result, image in
                print("🔄 MainTabView: AI identification completed for \(result.commonName), preparing AddPlantView with AI data")
                coordinator.handleIdentificationCompletion(result: result, image: image)
            }
        }
        .sheet(isPresented: $coordinator.showingManualAdd) {
            AddPlantView()
        }
        .sheet(isPresented: $coordinator.showingAddPlantWithAI) {
            AddPlantView(
                prefilledData: coordinator.aiIdentificationResult,
                prefilledImage: coordinator.aiCapturedImage
            )
        }
        .onChange(of: coordinator.showingAddPlantWithAI) { _, isShowing in
            // Clear AI data when the sheet is dismissed to prevent stale data
            if !isShowing {
                print("🔄 MainTabView: AddPlantView sheet dismissed, clearing AI data")
                coordinator.clearAIState()
            }
        }
        .sheet(isPresented: $coordinator.showingAddPlant) {
            NavigationView {
                VStack(spacing: BotanicaTheme.Spacing.xl) {
                    Text("Add New Plant")
                        .font(BotanicaTheme.Typography.title1)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: BotanicaTheme.Spacing.lg) {
                        Button(action: {
                            coordinator.handleAIAddSelection()
                            HapticManager.shared.light()
                        }) {
                            HStack(spacing: BotanicaTheme.Spacing.sm) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.title3)
                                Text("Take Photo & Identify")
                                    .fontWeight(.semibold)
                            }
                        }
                        .primaryButtonStyle()
                        
                        Button(action: {
                            coordinator.handleManualAddSelection()
                            HapticManager.shared.light()
                        }) {
                            HStack(spacing: BotanicaTheme.Spacing.sm) {
                                Image(systemName: "plus.circle")
                                    .font(.title3)
                                Text("Add Manually")
                                    .fontWeight(.semibold)
                            }
                        }
                        .secondaryButtonStyle()
                    }
                    
                    Spacer()
                }
                .padding(BotanicaTheme.Spacing.xl)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            coordinator.showingAddPlant = false
                        }
                        .foregroundColor(BotanicaTheme.Colors.primary)
                    }
                }
            }
        }
    }
}

// MARK: - Tab Enum

enum Tab: String, CaseIterable {
    case plants = "My Plants"
    case analytics = "Analytics"
    case activity = "Activity"
    case settings = "Settings"
    
    var systemImage: String {
        switch self {
        case .plants: return "leaf.fill"
        case .analytics: return "chart.line.uptrend.xyaxis"
        case .activity: return "bell.badge"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Activity Feed

struct ActivityView: View {
    @Query(sort: \CareEvent.date, order: .reverse) private var careEvents: [CareEvent]
    @Query private var plants: [Plant]
    @Query(sort: \Reminder.nextNotification, order: .forward) private var reminders: [Reminder]
    @State private var filter: ActivityFilter = .all
    @State private var mode: ActivityMode = .upcoming
    @State private var searchText: String = ""
    @Environment(\.modelContext) private var modelContext
    @State private var reminderToSnooze: Reminder?
    @State private var showingSnoozeOptions = false
    @State private var showOverdueOnly = false
    
    private var recentEvents: [CareEvent] {
        careEvents
            .filter { matchesFilter(type: $0.type) }
            .filter { event in
                guard !searchText.isEmpty else { return true }
                return event.plant?.nickname.lowercased().contains(searchText.lowercased()) ?? false
                    || event.notes.lowercased().contains(searchText.lowercased())
            }
    }
    
    private var groupedRecent: [(Date, [CareEvent])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: recentEvents) { event in
            calendar.startOfDay(for: event.date)
        }
        return groups
            .map { ($0.key, $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.0 > $1.0 }
    }
    
    private var upcomingItems: [SyntheticUpcoming] {
        let base = plants.flatMap { plant -> [SyntheticUpcoming] in
            var items: [SyntheticUpcoming] = []
            if let nextWater = plant.nextWateringDate {
                items.append(SyntheticUpcoming(date: nextWater, plant: plant, type: .watering))
            }
            if let nextFert = plant.nextFertilizingDate {
                items.append(SyntheticUpcoming(date: nextFert, plant: plant, type: .fertilizing))
            }
            if let nextRepot = plant.nextRepottingDate {
                items.append(SyntheticUpcoming(date: nextRepot, plant: plant, type: .repotting))
            }
            return items
        }
        .filter { matchesFilter(type: $0.type) && matchesSearch(plantName: $0.plant.nickname) }
        
        let sorted = base.sorted { lhs, rhs in
            let lhsOverdue = lhs.plant.isWateringOverdue || lhs.plant.isFertilizingOverdue || lhs.plant.isRepottingOverdue
            let rhsOverdue = rhs.plant.isWateringOverdue || rhs.plant.isFertilizingOverdue || rhs.plant.isRepottingOverdue
            if lhsOverdue == rhsOverdue {
                return lhs.date < rhs.date
            }
            return lhsOverdue && !rhsOverdue
        }
        if showOverdueOnly {
            return sorted.filter { $0.plant.isWateringOverdue || $0.plant.isFertilizingOverdue || $0.plant.isRepottingOverdue }
        }
        return sorted
    }
    
    private var items: [ActivityItem] {
        switch mode {
        case .upcoming:
            return upcomingItems.map { .upcoming($0) }
        case .recent:
            return recentEvents.map { .event($0) }
        }
    }
    
    private var todayItems: [ActivityItem] {
        let cal = Calendar.current
        return upcomingItems
            .filter { cal.isDateInToday($0.date) }
            .map { .upcoming($0) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Mode", selection: $mode) {
                Text("Upcoming").tag(ActivityMode.upcoming)
                Text("Recent").tag(ActivityMode.recent)
            }
            .pickerStyle(.segmented)
        }
        .listRowBackground(Color.clear)
                
                if mode == .upcoming {
                    Section(header: header) {
                        if !todayItems.isEmpty {
                            Section(header: Text("Due today").font(BotanicaTheme.Typography.subheadline)) {
                                ForEach(todayItems) { item in
                                    if let destinationPlant = plantFor(item) {
                                        NavigationLink(destination: PlantDetailView(plant: destinationPlant)) {
                                            ActivityRow(item: item) { upcoming in
                                                logUpcoming(upcoming)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        ActivityRow(item: item) { upcoming in
                                            logUpcoming(upcoming)
                                        }
                                    }
                                }
                            }
                        }
                        
                        if items.isEmpty {
                            emptyState
                        } else {
                            ForEach(items) { item in
                                if let destinationPlant = plantFor(item) {
                                    NavigationLink(destination: PlantDetailView(plant: destinationPlant)) {
                                        ActivityRow(item: item) { upcoming in
                                            logUpcoming(upcoming)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    ActivityRow(item: item) { upcoming in
                                        logUpcoming(upcoming)
                                    }
                                }
                            }
                        }
                    }
                    
                    reminderSection
                } else {
                    ForEach(groupedRecent, id: \.0) { group in
                        Section(header: dateHeader(group.0)) {
                            ForEach(group.1) { event in
                                if let plant = event.plant {
                                    NavigationLink(destination: PlantDetailView(plant: plant)) {
                                        ActivityRow(item: .event(event), onLog: nil)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    ActivityRow(item: .event(event), onLog: nil)
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(BotanicaTheme.Colors.background)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
            .navigationTitle(mode == .upcoming ? "Upcoming" : "Activity")
            .confirmationDialog("Snooze reminder", isPresented: $showingSnoozeOptions, titleVisibility: .visible) {
                Button("Snooze 1 day") { applySnooze(days: 1) }
                Button("Snooze 3 days") { applySnooze(days: 3) }
                Button("Snooze 7 days") { applySnooze(days: 7) }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(mode == .upcoming ? "Upcoming care" : mode == .recent ? "Recent activity" : "Calendar")
                    .font(BotanicaTheme.Typography.headline)
                Text(mode == .upcoming ? "Next water/fertilize across all plants" : mode == .recent ? "Last recorded care events" : "Care events by day")
                    .font(BotanicaTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if mode == .upcoming {
                Picker("Filter", selection: $filter) {
                    ForEach(ActivityFilter.allCases, id: \.self) { f in
                        Text(f.title).tag(f)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
        .padding(.vertical, BotanicaTheme.Spacing.sm)
    }
    
    private var emptyState: some View {
        VStack(spacing: BotanicaTheme.Spacing.md) {
            Image(systemName: "calendar.badge.clock")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(mode == .upcoming ? "No upcoming care" : "No recent activity")
                .font(BotanicaTheme.Typography.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowSeparator(.hidden)
    }
    
    
    private func matchesFilter(type: CareType) -> Bool {
        switch filter {
        case .all: return true
        case .watering: return type == .watering
        case .fertilizing: return type == .fertilizing
        case .other: return type != .watering && type != .fertilizing
        }
    }
    
    @ViewBuilder
    private var reminderSection: some View {
        let upcomingReminders = reminders.filter { $0.isActive && $0.nextNotification >= Date() }
        if !upcomingReminders.isEmpty {
            Section(header: Text("Care Reminders").font(BotanicaTheme.Typography.headline)) {
                ForEach(upcomingReminders) { reminder in
                    ReminderListRow(
                        reminder: reminder,
                        onTap: {
                            if let plant = reminder.plant {
                                logReminder(reminder, for: plant)
                            }
                        },
                        onSnooze: {
                            reminderToSnooze = reminder
                            showingSnoozeOptions = true
                        }
                    )
                }
            }
        }
    }
    
    private func matchesSearch(plantName: String) -> Bool {
        guard !searchText.isEmpty else { return true }
        return plantName.lowercased().contains(searchText.lowercased())
    }
    
    private func plantFor(_ item: ActivityItem) -> Plant? {
        switch item {
        case .event(let e):
            return e.plant
        case .upcoming(let u):
            return u.plant
        }
    }
    
    private func dateHeader(_ date: Date) -> some View {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let title: String
        if cal.isDateInToday(date) {
            title = "Today"
        } else if cal.isDateInYesterday(date) {
            title = "Yesterday"
        } else {
            title = formatter.string(from: date)
        }
        return Text(title)
            .font(BotanicaTheme.Typography.subheadline)
            .foregroundColor(.secondary)
    }
    
    private func logUpcoming(_ upcoming: SyntheticUpcoming) {
        let recAmount: Double
        let recUnit: String
        switch upcoming.type {
        case .watering:
            let rec = upcoming.plant.recommendedWateringAmount
            recAmount = Double(rec.amount)
            recUnit = rec.unit
        case .fertilizing:
            let rec = upcoming.plant.recommendedFertilizerAmount
            recAmount = rec.amount
            recUnit = rec.unit
        default:
            recAmount = 0
            recUnit = ""
        }
        let event = CareEvent(
            type: upcoming.type,
            date: Date(),
            amount: recAmount,
            unit: recUnit,
            notes: "Logged from Activity"
        )
        event.plant = upcoming.plant
        modelContext.insert(event)
    }
    
    private func logReminder(_ reminder: Reminder, for plant: Plant) {
        let recAmount: Double
        let recUnit: String
        switch reminder.taskType {
        case .watering:
            let rec = plant.recommendedWateringAmount
            recAmount = Double(rec.amount)
            recUnit = rec.unit
        case .fertilizing:
            let rec = plant.recommendedFertilizerAmount
            recAmount = rec.amount
            recUnit = rec.unit
        default:
            recAmount = 0
            recUnit = ""
        }
        let event = CareEvent(
            type: reminder.taskType,
            date: Date(),
            amount: recAmount,
            unit: recUnit,
            notes: "Logged from reminder"
        )
        event.plant = plant
        modelContext.insert(event)
    }
    
    private func applySnooze(days: Int) {
        guard let reminder = reminderToSnooze else { return }
        let next = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        reminder.snoozedUntil = next
        reminder.nextNotification = next
        reminderToSnooze = nil
    }
}

private enum ActivityItem: Identifiable {
    case event(CareEvent)
    case upcoming(SyntheticUpcoming)
    
    var id: String {
        switch self {
        case .event(let e): return "event-\(e.id.uuidString)"
        case .upcoming(let u): return "upcoming-\(u.type)-\(u.date.timeIntervalSince1970)-\(u.plant.id.uuidString)"
        }
    }
}

private struct SyntheticUpcoming {
    let date: Date
    let plant: Plant
    let type: CareType
}

private struct ActivityRow: View {
    let item: ActivityItem
    let onLog: ((SyntheticUpcoming) -> Void)?
    
    private var formatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: BotanicaTheme.Spacing.md) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 6, height: 6)
            }
            
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                HStack {
                    Text(title)
                        .font(BotanicaTheme.Typography.callout)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(dateText)
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                Text(typeText)
                    .font(BotanicaTheme.Typography.caption)
                    .foregroundColor(color)
                if let amount = amountText {
                    Text(amount)
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                if let notes = notes, !notes.isEmpty {
                    Text(notes)
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if case .upcoming(let upcoming) = item, let onLog {
                    Button {
                        onLog(upcoming)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Log now")
                        }
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, BotanicaTheme.Spacing.sm)
                        .padding(.vertical, BotanicaTheme.Spacing.xs)
                        .background(BotanicaTheme.Colors.primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, BotanicaTheme.Spacing.sm)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(accessibilityHintText)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if case .upcoming(let upcoming) = item, let onLog {
                Button {
                    onLog(upcoming)
                } label: {
                    Label("Log", systemImage: "checkmark.circle.fill")
                }
                .tint(BotanicaTheme.Colors.primary)
            }
        }
    }
    
    private var color: Color {
        switch careType {
        case .watering: return BotanicaTheme.Colors.waterBlue
        case .fertilizing: return BotanicaTheme.Colors.leafGreen
        default: return BotanicaTheme.Colors.textSecondary
        }
    }
    
    private var icon: String { careType.icon }
    
    private var careType: CareType {
        switch item {
        case .event(let e): return e.type
        case .upcoming(let u): return u.type
        }
    }
    
    private var plantName: String {
        switch item {
        case .event(let e): return e.plant?.nickname ?? "Plant"
        case .upcoming(let u): return u.plant.nickname
        }
    }
    
    private var dateText: String {
        switch item {
        case .event(let e): return formatter.string(from: e.date)
        case .upcoming(let u): return formatter.string(from: u.date)
        }
    }
    
    private var title: String { plantName }
    
    private var typeText: String {
        switch item {
        case .event(let e): return e.type.rawValue
        case .upcoming: return "Upcoming"
        }
    }
    
    private var amountText: String? {
        switch item {
        case .event(let e):
            if let amount = e.amount, !e.unit.isEmpty {
                return "Amount: \(amount) \(e.unit)"
            }
            return nil
        case .upcoming(let u):
            if u.type == .watering {
                let rec = u.plant.recommendedWateringAmount
                let amountString = formatAmount(Double(rec.amount))
                return "Recommended: \(amountString) \(rec.unit)"
            } else {
                let rec = u.plant.recommendedFertilizerAmount
                let amountString = formatAmount(rec.amount)
                return "Recommended: \(amountString) \(rec.unit)"
            }
        }
    }
    
    private func formatAmount(_ value: Double) -> String {
        if abs(value.rounded() - value) < 0.01 {
            return String(format: "%.0f", value.rounded())
        }
        return String(format: "%.1f", value)
    }
    
    private var notes: String? {
        switch item {
        case .event(let e): return e.notes
        case .upcoming: return nil
        }
    }
    
    private var accessibilityLabelText: String {
        switch item {
        case .event(let e):
            let amountString = amountText ?? ""
            return "\(plantName). \(e.type.rawValue). \(dateText). \(amountString)"
        case .upcoming:
            let amountString = amountText ?? ""
            return "\(plantName). Upcoming \(careType.rawValue). \(dateText). \(amountString)"
        }
    }
    
    private var accessibilityHintText: String {
        switch item {
        case .event:
            return "Recent care event."
        case .upcoming:
            return "Double tap to log now."
        }
    }
}

private enum ActivityFilter: CaseIterable {
    case all, watering, fertilizing, other
    var title: String {
        switch self {
        case .all: return "All"
        case .watering: return "Watering"
        case .fertilizing: return "Fertilizing"
        case .other: return "Other"
        }
    }
}

private enum ActivityMode {
    case upcoming
    case recent
}

private struct ReminderListRow: View {
    let reminder: Reminder
    let onTap: () -> Void
    let onSnooze: () -> Void
    
    private var plantName: String {
        reminder.plant?.nickname ?? "Plant"
    }
    
    private var formattedDate: String {
        reminder.formattedNextNotification
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: BotanicaTheme.Spacing.md) {
                Image(systemName: reminder.taskType.icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                    Text(plantName)
                        .font(BotanicaTheme.Typography.callout)
                        .fontWeight(.semibold)
                    Text(reminder.taskType.rawValue)
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: BotanicaTheme.Spacing.xs) {
                    Text(formattedDate)
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, BotanicaTheme.Spacing.sm)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                onSnooze()
            } label: {
                Label("Snooze", systemImage: "zzz")
            }
            .tint(.orange)
            
            Button {
                onTap()
            } label: {
                Label("Log", systemImage: "checkmark.circle.fill")
            }
            .tint(BotanicaTheme.Colors.primary)
        }
    }
    
    private var color: Color {
        switch reminder.taskType {
        case .watering: return BotanicaTheme.Colors.waterBlue
        case .fertilizing: return BotanicaTheme.Colors.leafGreen
        default: return BotanicaTheme.Colors.textSecondary
        }
    }
}



// MARK: - CameraView

struct InlineCameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: InlineCameraView
        
        init(_ parent: InlineCameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Onboarding Views

// MARK: - Sample Data Manager

/// Manages creation and cleanup of sample plants for onboarding
class SampleDataManager {
    
    /// Creates realistic sample plants for onboarding demonstration
    static func createSamplePlants(in context: ModelContext) {
        // Skip creating samples if any real plants already exist
        if let anyCount = try? context.fetch(FetchDescriptor<Plant>()).count, anyCount > 0 {
            return
        }

        // Check if sample plants already exist
        let descriptor = FetchDescriptor<Plant>(
            predicate: #Predicate<Plant> { plant in
                plant.notes.contains("SAMPLE_PLANT")
            }
        )
        
        if let existingCount = try? context.fetch(descriptor).count, existingCount > 0 {
            return // Sample plants already exist
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Sample Plant 1: Monstera Deliciosa (Popular houseplant)
        let monstera = Plant(
            scientificName: "Monstera deliciosa",
            nickname: "Swiss Cheese Plant",
            family: "Araceae",
            commonNames: ["Swiss Cheese Plant", "Split-leaf Philodendron"],
            potSize: 10,
            growthHabit: .climbing,
            matureSize: "6-8 feet indoors",
            lightLevel: .bright,
            wateringFrequency: 7,
            fertilizingFrequency: 30,
            humidityPreference: 65,
            temperatureRange: TemperatureRange(min: 65, max: 80),
            source: "Local nursery",
            healthStatus: .healthy,
            notes: "SAMPLE_PLANT - Beautiful climbing plant with iconic split leaves. Perfect for beginners!"
        )
        
        // Add some care history
        let monsteraWatering1 = CareEvent(type: .watering, date: calendar.date(byAdding: .day, value: -3, to: now)!, notes: "Watered thoroughly")
        let monsteraWatering2 = CareEvent(type: .watering, date: calendar.date(byAdding: .day, value: -10, to: now)!, notes: "Regular watering")
        let monsteraFertilizing = CareEvent(type: .fertilizing, date: calendar.date(byAdding: .day, value: -15, to: now)!, notes: "Liquid fertilizer")
        
        monsteraWatering1.plant = monstera
        monsteraWatering2.plant = monstera
        monsteraFertilizing.plant = monstera
        
        // Sample Plant 2: Pothos (Easy care)
        let pothos = Plant(
            scientificName: "Epipremnum aureum",
            nickname: "Golden Pothos",
            family: "Araceae",
            commonNames: ["Golden Pothos", "Devil's Ivy"],
            potSize: 6,
            growthHabit: .trailing,
            matureSize: "6-10 feet trailing",
            lightLevel: .medium,
            wateringFrequency: 10,
            fertilizingFrequency: 45,
            humidityPreference: 50,
            temperatureRange: TemperatureRange(min: 60, max: 85),
            source: "Friend's cutting",
            healthStatus: .excellent,
            notes: "SAMPLE_PLANT - Super easy to care for! Great for beginners and looks amazing trailing from shelves."
        )
        
        // Add care history
        let pothosWatering = CareEvent(type: .watering, date: calendar.date(byAdding: .day, value: -5, to: now)!, notes: "Light watering")
        let pothosPruning = CareEvent(type: .pruning, date: calendar.date(byAdding: .day, value: -20, to: now)!, notes: "Trimmed long vines")
        
        pothosWatering.plant = pothos
        pothosPruning.plant = pothos
        
        // Sample Plant 3: Snake Plant (Low maintenance)
        let snakePlant = Plant(
            scientificName: "Sansevieria trifasciata",
            nickname: "Mother-in-Law's Tongue",
            family: "Asparagaceae",
            commonNames: ["Snake Plant", "Mother-in-Law's Tongue"],
            potSize: 8,
            growthHabit: .upright,
            matureSize: "2-4 feet tall",
            lightLevel: .low,
            wateringFrequency: 21,
            fertilizingFrequency: 60,
            humidityPreference: 30,
            temperatureRange: TemperatureRange(min: 55, max: 85),
            source: "Home Depot",
            healthStatus: .healthy,
            notes: "SAMPLE_PLANT - Nearly indestructible! Perfect for low-light areas and forgetful waterers."
        )
        
        // Add minimal care history (low maintenance)
        let snakeWatering = CareEvent(type: .watering, date: calendar.date(byAdding: .day, value: -14, to: now)!, notes: "Deep watering")
        
        snakeWatering.plant = snakePlant
        
        // Sample Plant 4: Fiddle Leaf Fig (Challenging but rewarding)
        let fiddleLeaf = Plant(
            scientificName: "Ficus lyrata",
            nickname: "Fiddle Leaf Fig",
            family: "Moraceae",
            commonNames: ["Fiddle Leaf Fig", "Banjo Fig"],
            potSize: 12,
            growthHabit: .upright,
            matureSize: "6-10 feet indoors",
            lightLevel: .bright,
            wateringFrequency: 7,
            fertilizingFrequency: 30,
            humidityPreference: 55,
            temperatureRange: TemperatureRange(min: 65, max: 75),
            source: "Plant shop",
            healthStatus: .fair,
            notes: "SAMPLE_PLANT - Stunning statement plant! Needs consistent care but worth the effort for the dramatic leaves."
        )
        
        // Add varied care history
        let fiddleWatering1 = CareEvent(type: .watering, date: calendar.date(byAdding: .day, value: -4, to: now)!, notes: "Careful watering - checked soil first")
        let fiddleWatering2 = CareEvent(type: .watering, date: calendar.date(byAdding: .day, value: -11, to: now)!, notes: "Weekly watering")
        let fiddleCleaning = CareEvent(type: .cleaning, date: calendar.date(byAdding: .day, value: -7, to: now)!, notes: "Cleaned leaves for better photosynthesis")
        
        fiddleWatering1.plant = fiddleLeaf
        fiddleWatering2.plant = fiddleLeaf
        fiddleCleaning.plant = fiddleLeaf
        
        // Insert all plants and care events
        context.insert(monstera)
        context.insert(pothos)
        context.insert(snakePlant)
        context.insert(fiddleLeaf)
        
        context.insert(monsteraWatering1)
        context.insert(monsteraWatering2)
        context.insert(monsteraFertilizing)
        context.insert(pothosWatering)
        context.insert(pothosPruning)
        context.insert(snakeWatering)
        context.insert(fiddleWatering1)
        context.insert(fiddleWatering2)
        context.insert(fiddleCleaning)
        
        // Save changes
        do {
            try context.save()
        } catch {
            print("Failed to save sample plants: \(error)")
        }
    }
    
    /// Removes all sample plants and their associated data
    static func removeSamplePlants(from context: ModelContext) {
        let descriptor = FetchDescriptor<Plant>(
            predicate: #Predicate<Plant> { plant in
                plant.notes.contains("SAMPLE_PLANT")
            }
        )
        
        do {
            let samplePlants = try context.fetch(descriptor)
            for plant in samplePlants {
                context.delete(plant) // Cascade delete will handle related objects
            }
            try context.save()
        } catch {
            print("Failed to remove sample plants: \(error)")
        }
    }
}

/// Main onboarding flow view that guides new users through app features
/// Includes welcome, feature highlights, permissions, and first plant setup
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep = 0
    @State private var showingAddPlant = false
    let onComplete: () -> Void
    
    private let totalSteps = 5
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    BotanicaTheme.Colors.leafGreen.opacity(0.1),
                    BotanicaTheme.Colors.waterBlue.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                
                // Content
                TabView(selection: $currentStep) {
                    WelcomeStepView(onNext: nextStep)
                        .tag(0)
                    
                    FeaturesStepView(onNext: nextStep)
                        .tag(1)
                    
                    AIFeaturesStepView(onNext: nextStep)
                        .tag(2)
                    
                    NotificationsStepView(onNext: nextStep)
                        .tag(3)
                    
                    GetStartedStepView(
                        onAddPlant: { showingAddPlant = true },
                        onComplete: onComplete
                    )
                    .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
            }
        }
        .onAppear {
            // Create sample plants for demonstration
            SampleDataManager.createSamplePlants(in: modelContext)
        }
        .sheet(isPresented: $showingAddPlant) {
            NavigationStack {
                AddPlantView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Skip") {
                                showingAddPlant = false
                                SampleDataManager.removeSamplePlants(from: modelContext)
                                onComplete()
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingAddPlant = false
                                SampleDataManager.removeSamplePlants(from: modelContext)
                                onComplete()
                            }
                        }
                    }
            }
        }
    }
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? BotanicaTheme.Colors.primary : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut, value: currentStep)
            }
        }
        .padding(.top, BotanicaTheme.Spacing.lg)
        .padding(.bottom, BotanicaTheme.Spacing.md)
    }
    
    private func nextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        }
    }
}

// MARK: - Welcome Step

struct WelcomeStepView: View {
    let onNext: () -> Void
    
    var body: some View {
        OnboardingStepContainer {
            VStack(spacing: BotanicaTheme.Spacing.xl) {
                // App icon and name
                VStack(spacing: BotanicaTheme.Spacing.md) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 80))
                        .foregroundColor(BotanicaTheme.Colors.leafGreen)
                    
                    Text("Welcome to Botanica")
                        .font(BotanicaTheme.Typography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                VStack(spacing: BotanicaTheme.Spacing.md) {
                    Text("Your AI-Powered Plant Care Companion")
                        .font(BotanicaTheme.Typography.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Keep your plants healthy and thriving with intelligent care recommendations, automated reminders, and personalized insights.")
                        .font(BotanicaTheme.Typography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BotanicaTheme.Spacing.lg)
                    
                    Text("We've added some sample plants so you can see what Botanica looks like in action!")
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(BotanicaTheme.Colors.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BotanicaTheme.Spacing.lg)
                        .padding(.top, BotanicaTheme.Spacing.sm)
                }
                
                Spacer()
                
                OnboardingButton(title: "Get Started", action: onNext)
            }
        }
    }
}

// MARK: - Features Step

struct FeaturesStepView: View {
    let onNext: () -> Void
    
    var body: some View {
        OnboardingStepContainer {
            VStack(spacing: BotanicaTheme.Spacing.xl) {
                VStack(spacing: BotanicaTheme.Spacing.md) {
                    Text("Everything You Need")
                        .font(BotanicaTheme.Typography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Powerful tools to help you become a better plant parent")
                        .font(BotanicaTheme.Typography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: BotanicaTheme.Spacing.lg) {
                    OnboardingFeatureCard(
                        icon: "calendar.badge.checkmark",
                        title: "Smart Care",
                        description: "Intelligent reminders based on your plants' needs"
                    )
                    
                    OnboardingFeatureCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Analytics",
                        description: "Track your care patterns and plant health"
                    )
                    
                    OnboardingFeatureCard(
                        icon: "bell.fill",
                        title: "Notifications",
                        description: "Never forget to water or fertilize again"
                    )
                    
                    OnboardingFeatureCard(
                        icon: "photo.on.rectangle",
                        title: "Photo Journal",
                        description: "Document your plants' growth journey"
                    )
                }
                
                Spacer()
                
                OnboardingButton(title: "Continue", action: onNext)
            }
        }
    }
}

// MARK: - AI Features Step

struct AIFeaturesStepView: View {
    let onNext: () -> Void
    
    var body: some View {
        OnboardingStepContainer {
            VStack(spacing: BotanicaTheme.Spacing.xl) {
                VStack(spacing: BotanicaTheme.Spacing.md) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundColor(BotanicaTheme.Colors.primary)
                    
                    Text("AI-Powered Intelligence")
                        .font(BotanicaTheme.Typography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Get expert advice and plant identification powered by artificial intelligence")
                        .font(BotanicaTheme.Typography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BotanicaTheme.Spacing.lg)
                }
                
                VStack(spacing: BotanicaTheme.Spacing.lg) {
                    OnboardingAIFeature(
                        icon: "camera.viewfinder",
                        title: "Plant Identification",
                        description: "Take a photo to instantly identify any plant species"
                    )
                    
                    OnboardingAIFeature(
                        icon: "message.badge.waveform",
                        title: "AI Plant Coach",
                        description: "Get personalized care advice and troubleshooting help"
                    )
                    
                    OnboardingAIFeature(
                        icon: "sparkles",
                        title: "Smart Recommendations",
                        description: "Receive intelligent suggestions for optimal plant care"
                    )
                }
                
                Spacer()
                
                OnboardingButton(title: "Amazing!", action: onNext)
            }
        }
    }
}

// MARK: - Notifications Step

struct NotificationsStepView: View {
    let onNext: () -> Void
    @State private var notificationPermissionGranted = false
    
    var body: some View {
        OnboardingStepContainer {
            VStack(spacing: BotanicaTheme.Spacing.xl) {
                VStack(spacing: BotanicaTheme.Spacing.md) {
                    Image(systemName: "bell.badge")
                        .font(.system(size: 60))
                        .foregroundColor(BotanicaTheme.Colors.waterBlue)
                    
                    Text("Stay Informed")
                        .font(BotanicaTheme.Typography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Enable notifications to receive timely reminders for watering, fertilizing, and other plant care tasks.")
                        .font(BotanicaTheme.Typography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BotanicaTheme.Spacing.lg)
                }
                
                VStack(spacing: BotanicaTheme.Spacing.md) {
                    HStack(spacing: BotanicaTheme.Spacing.md) {
                        Image(systemName: "drop.fill")
                            .foregroundColor(BotanicaTheme.Colors.waterBlue)
                        Text("Watering reminders")
                            .font(BotanicaTheme.Typography.callout)
                        Spacer()
                    }
                    
                    HStack(spacing: BotanicaTheme.Spacing.md) {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(BotanicaTheme.Colors.leafGreen)
                        Text("Fertilizing schedules")
                            .font(BotanicaTheme.Typography.callout)
                        Spacer()
                    }
                    
                    HStack(spacing: BotanicaTheme.Spacing.md) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(BotanicaTheme.Colors.warning)
                        Text("Health alerts")
                            .font(BotanicaTheme.Typography.callout)
                        Spacer()
                    }
                }
                .padding(BotanicaTheme.Spacing.lg)
                .cardStyle()
                
                Spacer()
                
                VStack(spacing: BotanicaTheme.Spacing.md) {
                    if !notificationPermissionGranted {
                        OnboardingButton(title: "Enable Notifications") {
                            Task {
                                let granted = await NotificationManager.shared.requestNotificationPermission()
                                await MainActor.run {
                                    notificationPermissionGranted = granted
                                }
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(BotanicaTheme.Colors.success)
                            Text("Notifications Enabled!")
                                .font(BotanicaTheme.Typography.callout)
                                .fontWeight(.medium)
                                .foregroundColor(BotanicaTheme.Colors.success)
                        }
                        .padding(BotanicaTheme.Spacing.md)
                        .cardStyle()
                    }
                    
                    Button("Skip for now") {
                        onNext()
                    }
                    .font(BotanicaTheme.Typography.callout)
                    .foregroundColor(.secondary)
                    
                    if notificationPermissionGranted {
                        OnboardingButton(title: "Continue", action: onNext)
                    }
                }
            }
        }
    }
}

// MARK: - Get Started Step

struct GetStartedStepView: View {
    @Environment(\.modelContext) private var modelContext
    let onAddPlant: () -> Void
    let onComplete: () -> Void
    
    var body: some View {
        OnboardingStepContainer {
            VStack(spacing: BotanicaTheme.Spacing.xl) {
                VStack(spacing: BotanicaTheme.Spacing.md) {
                    Image(systemName: "seedling")
                        .font(.system(size: 60))
                        .foregroundColor(BotanicaTheme.Colors.leafGreen)
                    
                    Text("You're All Set!")
                        .font(BotanicaTheme.Typography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Ready to start your plant care journey? Add your first plant to get personalized care recommendations.")
                        .font(BotanicaTheme.Typography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BotanicaTheme.Spacing.lg)
                }
                
                VStack(spacing: BotanicaTheme.Spacing.lg) {
                    HStack(spacing: BotanicaTheme.Spacing.md) {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(BotanicaTheme.Colors.primary)
                        Text("Add your first plant")
                            .font(BotanicaTheme.Typography.callout)
                        Spacer()
                    }
                    
                    HStack(spacing: BotanicaTheme.Spacing.md) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(BotanicaTheme.Colors.primary)
                        Text("Set up care schedule")
                            .font(BotanicaTheme.Typography.callout)
                        Spacer()
                    }
                    
                    HStack(spacing: BotanicaTheme.Spacing.md) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(BotanicaTheme.Colors.primary)
                        Text("Start caring and tracking")
                            .font(BotanicaTheme.Typography.callout)
                        Spacer()
                    }
                }
                .padding(BotanicaTheme.Spacing.lg)
                .cardStyle()
                
                Spacer()
                
                VStack(spacing: BotanicaTheme.Spacing.md) {
                    OnboardingButton(title: "Add My First Plant", action: onAddPlant)
                    
                    Button("Explore App First") {
                        SampleDataManager.removeSamplePlants(from: modelContext)
                        onComplete()
                    }
                    .font(BotanicaTheme.Typography.callout)
                    .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct OnboardingStepContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            content
                .frame(maxHeight: .infinity)
                .padding(BotanicaTheme.Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct OnboardingButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BotanicaTheme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(BotanicaTheme.Spacing.md)
                .background(BotanicaTheme.Colors.primary)
                .cornerRadius(BotanicaTheme.CornerRadius.button)
        }
    }
}

struct OnboardingFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: BotanicaTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(BotanicaTheme.Colors.primary)
            
            Text(title)
                .font(BotanicaTheme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(description)
                .font(BotanicaTheme.Typography.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(BotanicaTheme.Spacing.md)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

struct OnboardingAIFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(BotanicaTheme.Colors.primary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(BotanicaTheme.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(BotanicaTheme.Typography.callout)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(BotanicaTheme.Spacing.md)
        .cardStyle()
    }
}

#Preview {
    let container = MockDataGenerator.previewContainer()
    MainTabView()
        .modelContainer(container)
        .environment(\.modelContext, container.mainContext)
}

// MARK: - Plant Identification View (from AI folder)

/// View for capturing and identifying plants using AI
private struct InlinePlantIdentificationView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State Variables
    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var identificationResult: PlantIdentificationResult?
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingAISettings = false
    @State private var loadState: LoadState = .loaded
    
    // MARK: - Services
    @StateObject private var aiService = AIService.shared
    
    private var isIdentifying: Bool { loadState == .loading }
    
    // MARK: - Completion Handler
    let onPlantIdentified: ((PlantIdentificationResult, UIImage) -> Void)?
    
    init(onPlantIdentified: ((PlantIdentificationResult, UIImage) -> Void)? = nil) {
        self.onPlantIdentified = onPlantIdentified
    }
    
    var body: some View {
        NavigationStack {
            LoadStateView(
                state: loadState,
                retry: { retryIdentification() },
                loading: { identifyingView },
                content: {
                    VStack(spacing: 0) {
                        ScrollView {
                            VStack(spacing: BotanicaTheme.Spacing.lg) {
                                // Header section
                                headerSection
                                
                                // Image capture/display section
                                imageSection
                                
                                // Results section
                                if let result = identificationResult {
                                    resultsSection(result: result)
                                }
                                
                                // Add some bottom padding for better scrolling
                                Color.clear.frame(height: 100)
                            }
                            .padding(.horizontal, BotanicaTheme.Spacing.lg)
                            .padding(.top, BotanicaTheme.Spacing.md)
                        }
                        
                // Fixed bottom action buttons
                if selectedImage == nil || identificationResult == nil {
                    VStack(spacing: 0) {
                        Divider()
                        
                        actionButtonsSection
                                    .padding(.horizontal, BotanicaTheme.Spacing.lg)
                                    .padding(.vertical, BotanicaTheme.Spacing.md)
                                    .background(Color(UIColor.systemBackground))
                            }
                        }
                    }
                }
            )
            .navigationTitle("Plant Identification")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(BotanicaTheme.Colors.primary)
                }
                
                if identificationResult != nil, let image = selectedImage {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Use This Plant") {
                            if let result = identificationResult {
                                print("🌱 PlantIdentificationView: Use This Plant toolbar button tapped with result: \(result.commonName)")
                                onPlantIdentified?(result, image)
                            }
                            dismiss()
                        }
                        .foregroundColor(BotanicaTheme.Colors.primary)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            InlineCameraView { image in
                selectedImage = image
                identifyPlant()
            }
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let newItem = newItem,
                   let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                    identifyPlant()
                }
            }
        }
        .sheet(isPresented: $showingAISettings) {
            NavigationStack {
                AISettingsView()
                    .navigationTitle("AI Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingAISettings = false
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: BotanicaTheme.Spacing.lg) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundColor(BotanicaTheme.Colors.primary)
            
            VStack(spacing: BotanicaTheme.Spacing.sm) {
                Text("AI Plant Identification")
                    .font(BotanicaTheme.Typography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Take a photo or select from your library\nto identify your plant")
                    .font(BotanicaTheme.Typography.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, BotanicaTheme.Spacing.lg)
    }
    
    private var imageSection: some View {
        VStack(spacing: BotanicaTheme.Spacing.lg) {
            if let image = selectedImage {
                // Display selected image
                VStack(spacing: BotanicaTheme.Spacing.md) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 280)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(BotanicaTheme.Colors.primary.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    if isIdentifying {
                        HStack(spacing: BotanicaTheme.Spacing.sm) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: BotanicaTheme.Colors.primary))
                                .scaleEffect(0.9)
                            
                            Text("Identifying plant...")
                                .font(BotanicaTheme.Typography.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, BotanicaTheme.Spacing.sm)
                    }
                }
            } else {
                // Enhanced placeholder for image
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [BotanicaTheme.Colors.primary.opacity(0.05), BotanicaTheme.Colors.primary.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 240)
                    .overlay(
                        VStack(spacing: BotanicaTheme.Spacing.lg) {
                            Circle()
                                .fill(BotanicaTheme.Colors.primary.opacity(0.1))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 32))
                                        .foregroundColor(BotanicaTheme.Colors.primary)
                                )
                            
                            VStack(spacing: BotanicaTheme.Spacing.xs) {
                                Text("No image selected")
                                    .font(BotanicaTheme.Typography.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Choose a photo to get started")
                                    .font(BotanicaTheme.Typography.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [8, 6]))
                            .foregroundColor(BotanicaTheme.Colors.primary.opacity(0.2))
                    )
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: BotanicaTheme.Spacing.md) {
            if selectedImage == nil {
                // Initial image capture buttons
                VStack(spacing: BotanicaTheme.Spacing.sm) {
                    Button(action: {
                        print("📷 Camera button tapped")
                        showingCamera = true
                    }) {
                        HStack(spacing: BotanicaTheme.Spacing.sm) {
                            Image(systemName: "camera.fill")
                                .font(.title3)
                            Text("Take Photo")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BotanicaTheme.Spacing.md)
                    }
                    .primaryButtonStyle()
                    
                    Button(action: {
                        print("📱 Photo picker button tapped")
                        showingPhotoPicker = true
                    }) {
                        HStack(spacing: BotanicaTheme.Spacing.sm) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title3)
                            Text("Choose Photo")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BotanicaTheme.Spacing.md)
                    }
                    .secondaryButtonStyle()
                }
            } else {
                // Image selected - show retake/choose different buttons
                HStack(spacing: BotanicaTheme.Spacing.md) {
                    Button(action: {
                        selectedImage = nil
                        identificationResult = nil
                        errorMessage = nil
                        showingCamera = true
                    }) {
                        HStack(spacing: BotanicaTheme.Spacing.xs) {
                            Image(systemName: "camera.fill")
                                .font(.callout)
                            Text("Retake")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BotanicaTheme.Spacing.sm)
                    }
                    .secondaryButtonStyle()
                    
                    Button(action: {
                        selectedImage = nil
                        identificationResult = nil
                        errorMessage = nil
                        showingPhotoPicker = true
                    }) {
                        HStack(spacing: BotanicaTheme.Spacing.xs) {
                            Image(systemName: "photo")
                                .font(.callout)
                            Text("Choose Different")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BotanicaTheme.Spacing.sm)
                    }
                    .secondaryButtonStyle()
                }
                
                if identificationResult == nil && !isIdentifying {
                    Button("Identify Again") {
                        identifyPlant()
                    }
                    .primaryButtonStyle()
                }
            }
        }
        .disabled(isIdentifying)
    }

    private func resultsSection(result: PlantIdentificationResult) -> some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text("Plant Identified!")
                    .font(BotanicaTheme.Typography.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(result.confidence * 100))% confident")
                    .font(BotanicaTheme.Typography.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, BotanicaTheme.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                InlineResultRow(
                    title: "Scientific Name",
                    value: result.scientificName,
                    icon: "leaf.fill"
                )
                
                InlineResultRow(
                    title: "Common Name",
                    value: result.commonName,
                    icon: "tag.fill"
                )
                
                if !result.description.isEmpty {
                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(BotanicaTheme.Colors.primary)
                            
                            Text("Description")
                                .font(BotanicaTheme.Typography.callout)
                                .fontWeight(.medium)
                        }
                        
                        Text(result.description)
                            .font(BotanicaTheme.Typography.callout)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !result.careInstructions.isEmpty {
                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(BotanicaTheme.Colors.primary)
                            
                            Text("Care Instructions")
                                .font(BotanicaTheme.Typography.callout)
                                .fontWeight(.medium)
                        }
                        
                        Text(result.careInstructions)
                            .font(BotanicaTheme.Typography.callout)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Use This Information Button
                if let image = selectedImage {
                    Button(action: {
                        print("🌱 PlantIdentificationView: Use This Information tapped with result: \(result.commonName), scientificName: \(result.scientificName)")
                        onPlantIdentified?(result, image)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                            Text("Use This Information")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(BotanicaTheme.Colors.primary)
                        .cornerRadius(BotanicaTheme.CornerRadius.medium)
                    }
                    .padding(.top, BotanicaTheme.Spacing.md)
                }
            }
        }
        .padding(BotanicaTheme.Spacing.lg)
        .cardStyle()
    }
    
    // MARK: - Methods
    
    private func identifyPlant() {
        guard let image = selectedImage else { return }
        
        Task {
            loadState = .loading
            
            do {
                let result = try await aiService.identifyPlant(image: image)
                await MainActor.run {
                    identificationResult = result
                    loadState = .loaded
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    loadState = .failed(error.localizedDescription)
                    if error.localizedDescription.lowercased().contains("api key") {
                        showingAISettings = true
                    }
                }
            }
        }
    }
    
    private func retryIdentification() {
        if selectedImage != nil {
            identifyPlant()
        } else {
            showingPhotoPicker = true
        }
    }
    
    private var identifyingView: some View {
        VStack(spacing: BotanicaTheme.Spacing.md) {
            ProgressView("Identifying plant…")
                .progressViewStyle(.circular)
            Text("Analyzing your photo and matching species")
                .font(BotanicaTheme.Typography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Supporting Views

private struct InlineResultRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(BotanicaTheme.Colors.primary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BotanicaTheme.Typography.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(BotanicaTheme.Typography.callout)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

#Preview("Onboarding") {
    let container = MockDataGenerator.previewContainer()
    OnboardingView { }
        .modelContainer(container)
        .environment(\.modelContext, container.mainContext)
}
