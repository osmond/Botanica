import SwiftUI
import UIKit
import SwiftData

/// Main tab view container for the Botanica app
/// Provides navigation between Activity, Plants, AI, and Settings sections
@MainActor
struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var plants: [Plant]
    
    @StateObject private var coordinator = MainTabCoordinator(notificationService: AppServices.shared.notifications)
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $coordinator.selectedTab) {
                TodayView()
                    .tabItem {
                        Label("Today", systemImage: "sun.max")
                    }
                    .tag(Tab.today)
                
                MyPlantsView()
                    .tabItem {
                        Label("My Plants", systemImage: "leaf.fill")
                    }
                    .tag(Tab.plants)
                
            AIHubView()
                .tabItem {
                    Label("AI", systemImage: "sparkles")
                }
                .tag(Tab.ai)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                    .tag(Tab.settings)
            }
            
            FloatingActionButton(icon: "plus") {
                coordinator.handleAddButtonTap()
            }
            .padding(.trailing, BotanicaTheme.Spacing.lg)
            .padding(.bottom, BotanicaTheme.Spacing.xl)
            .accessibilityLabel("Add new plant")
            .accessibilityHint("Choose AI identification or add manually")
        }
        .environmentObject(coordinator)
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
        .sheet(isPresented: $coordinator.showingPlantIdentification) {
            PlantIdentificationView { result, image in
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
    case today = "Today"
    case ai = "AI"
    case settings = "Settings"
    
    var systemImage: String {
        switch self {
        case .plants: return "leaf.fill"
        case .today: return "sun.max"
        case .ai: return "sparkles"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Today

struct TodayView: View {
    @Query(sort: \CareEvent.date, order: .reverse) private var careEvents: [CareEvent]
    @Query private var plants: [Plant]
    @Query(sort: \Reminder.nextNotification, order: .forward) private var reminders: [Reminder]
    @Environment(\.modelContext) private var modelContext
    @State private var showingMultiCareLog = false
    @State private var reminderToSnooze: Reminder?
    @State private var showingSnoozeOptions = false
    
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
        
        return base.sorted { lhs, rhs in
            let lhsOverdue = isOverdue(lhs.plant)
            let rhsOverdue = isOverdue(rhs.plant)
            if lhsOverdue == rhsOverdue {
                return lhs.date < rhs.date
            }
            return lhsOverdue && !rhsOverdue
        }
    }
    
    private var overdueItems: [SyntheticUpcoming] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        return upcomingItems.filter { item in
            isOverdue(item) || item.date < start
        }
    }
    
    private var dueTodayItems: [SyntheticUpcoming] {
        let cal = Calendar.current
        return upcomingItems.filter { cal.isDateInToday($0.date) && !isOverdue($0) }
    }
    
    private var upcomingItemsNextWeek: [SyntheticUpcoming] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 7, to: start) ?? start
        return upcomingItems.filter { $0.date > start && $0.date <= end }
            .filter { !cal.isDateInToday($0.date) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TodaySummaryCard(
                        overdue: overdueItems.count,
                        dueToday: dueTodayItems.count,
                        upcoming: upcomingItemsNextWeek.count
                    )
                }
                .listRowBackground(Color.clear)
                
                Section {
                    Button {
                        showingMultiCareLog = true
                    } label: {
                        HStack(spacing: BotanicaTheme.Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(BotanicaTheme.Colors.primary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Log care")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                                Text("Quickly log care for multiple plants")
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
                .listRowBackground(Color.clear)
                
                if !overdueItems.isEmpty {
                    Section(header: Text("Overdue").font(BotanicaTheme.Typography.headline)) {
                        ForEach(overdueItems) { item in
                            NavigationLink(destination: PlantDetailView(plant: item.plant)) {
                                ActivityRow(item: .upcoming(item)) { upcoming in
                                    logUpcoming(upcoming)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                if !dueTodayItems.isEmpty {
                    Section(header: Text("Due today").font(BotanicaTheme.Typography.headline)) {
                        ForEach(dueTodayItems) { item in
                            NavigationLink(destination: PlantDetailView(plant: item.plant)) {
                                ActivityRow(item: .upcoming(item)) { upcoming in
                                    logUpcoming(upcoming)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                if overdueItems.isEmpty && dueTodayItems.isEmpty {
                    Section {
                        Text("You are all caught up today.")
                            .font(BotanicaTheme.Typography.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !upcomingItemsNextWeek.isEmpty {
                    Section(header: Text("Next 7 days").font(BotanicaTheme.Typography.headline)) {
                        ForEach(upcomingItemsNextWeek) { item in
                            NavigationLink(destination: PlantDetailView(plant: item.plant)) {
                                ActivityRow(item: .upcoming(item)) { upcoming in
                                    logUpcoming(upcoming)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                reminderSection
            }
            .scrollContentBackground(.hidden)
            .background(BotanicaTheme.Colors.background)
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: HistoryView()) {
                        Text("History")
                    }
                }
            }
            .confirmationDialog("Snooze reminder", isPresented: $showingSnoozeOptions, titleVisibility: .visible) {
                Button("Snooze 1 day") { applySnooze(days: 1) }
                Button("Snooze 3 days") { applySnooze(days: 3) }
                Button("Snooze 7 days") { applySnooze(days: 7) }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingMultiCareLog) {
                MultiCareLogView()
            }
        }
    }
    
    private func isOverdue(_ plant: Plant) -> Bool {
        plant.isWateringOverdue || plant.isFertilizingOverdue || plant.isRepottingOverdue
    }
    
    private func isOverdue(_ item: SyntheticUpcoming) -> Bool {
        switch item.type {
        case .watering: return item.plant.isWateringOverdue
        case .fertilizing: return item.plant.isFertilizingOverdue
        case .repotting: return item.plant.isRepottingOverdue
        case .pruning, .cleaning, .rotating, .misting, .inspection:
            return false
        }
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
            notes: "Logged from Today"
        )
        event.plant = upcoming.plant
        modelContext.insert(event)
    }
    
    @ViewBuilder
    private var reminderSection: some View {
        let upcomingReminders = reminders.filter { $0.isActive && $0.nextNotification >= Date() }
        if !upcomingReminders.isEmpty {
            Section(header: Text("Reminders").font(BotanicaTheme.Typography.headline)) {
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

// MARK: - History

struct HistoryView: View {
    @Query(sort: \CareEvent.date, order: .reverse) private var careEvents: [CareEvent]
    @Query private var plants: [Plant]
    @Query(sort: \Reminder.nextNotification, order: .forward) private var reminders: [Reminder]
    @State private var filter: ActivityFilter = .all
    @State private var mode: ActivityMode = .recent
    @State private var searchText: String = ""
    @Environment(\.modelContext) private var modelContext
    @State private var reminderToSnooze: Reminder?
    @State private var showingSnoozeOptions = false
    @State private var showOverdueOnly = false
    @State private var showingMultiCareLog = false
    
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
            let cal = Calendar.current
            return upcomingItems
                .filter { !cal.isDateInToday($0.date) }
                .map { .upcoming($0) }
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
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingMultiCareLog = true
                    } label: {
                        Label("Log Care", systemImage: "checkmark.circle.fill")
                    }
                }
            }
            .confirmationDialog("Snooze reminder", isPresented: $showingSnoozeOptions, titleVisibility: .visible) {
                Button("Snooze 1 day") { applySnooze(days: 1) }
                Button("Snooze 3 days") { applySnooze(days: 3) }
                Button("Snooze 7 days") { applySnooze(days: 7) }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingMultiCareLog) {
                MultiCareLogView()
            }
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
            Text(mode == .upcoming ? "Upcoming care" : mode == .recent ? "Recent activity" : "Calendar")
                .font(BotanicaTheme.Typography.headline)
            Text(mode == .upcoming ? "Next water/fertilize across all plants" : mode == .recent ? "Logged care events" : "Care events by day")
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
            Text(mode == .upcoming ? "No upcoming care" : "No history yet")
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

private struct SyntheticUpcoming: Identifiable {
    let date: Date
    let plant: Plant
    let type: CareType
    
    var id: String {
        "\(type.rawValue)-\(plant.id.uuidString)-\(date.timeIntervalSince1970)"
    }
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
                .foregroundColor(statusColor)
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
        case .upcoming(let u):
            if isUpcomingOverdue {
                return overdueText(since: u.date)
            }
            return formatter.string(from: u.date)
        }
    }
    
    private var title: String { plantName }
    
    private var typeText: String {
        switch item {
        case .event(let e): return e.type.rawValue
        case .upcoming:
            if isUpcomingOverdue {
                return "Overdue"
            }
            if isUpcomingDueToday {
                return "Due today"
            }
            return "Upcoming"
        }
    }
    
    private var statusColor: Color {
        if case .upcoming = item, isUpcomingOverdue {
            return BotanicaTheme.Colors.warning
        }
        return color
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
            return "\(plantName). \(typeText) \(careType.rawValue). \(dateText). \(amountString)"
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
    
    private var isUpcomingOverdue: Bool {
        guard case .upcoming(let upcoming) = item else { return false }
        let cal = Calendar.current
        let startToday = cal.startOfDay(for: Date())
        return upcoming.date < startToday
    }
    
    private var isUpcomingDueToday: Bool {
        guard case .upcoming(let upcoming) = item else { return false }
        let cal = Calendar.current
        return cal.isDateInToday(upcoming.date) && !isUpcomingOverdue
    }
    
    private func overdueText(since date: Date) -> String {
        let cal = Calendar.current
        let startDue = cal.startOfDay(for: date)
        let startToday = cal.startOfDay(for: Date())
        let days = max(cal.dateComponents([.day], from: startDue, to: startToday).day ?? 0, 0)
        let value = max(days, 1)
        return value == 1 ? "1 day late" : "\(value) days late"
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

private struct TodaySummaryCard: View {
    let overdue: Int
    let dueToday: Int
    let upcoming: Int
    
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.md) {
            summaryMetric(title: "Overdue", count: overdue, color: BotanicaTheme.Colors.warning)
            summarySeparator
            summaryMetric(title: "Due today", count: dueToday, color: BotanicaTheme.Colors.waterBlue)
            summarySeparator
            summaryMetric(title: "Next 7 days", count: upcoming, color: BotanicaTheme.Colors.leafGreen)
        }
        .padding(BotanicaTheme.Spacing.md)
        .background(BotanicaTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large))
    }
    
    private func summaryMetric(title: String, count: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xxs) {
            Text("\(count)")
                .font(BotanicaTheme.Typography.title3)
                .foregroundColor(color)
            Text(title)
                .font(BotanicaTheme.Typography.caption2)
                .foregroundColor(BotanicaTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var summarySeparator: some View {
        Rectangle()
            .fill(BotanicaTheme.Colors.textSecondary.opacity(0.2))
            .frame(width: 1, height: 32)
    }
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



#Preview {
    let container = MockDataGenerator.previewContainer()
    MainTabView()
        .modelContainer(container)
        .environment(\.modelContext, container.mainContext)
}
