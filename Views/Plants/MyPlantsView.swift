import SwiftUI
import SwiftData
import Combine

/// Modern, botanically-informed My Plants view designed for plant enthusiasts
/// Features intuitive care management, beautiful plant presentation, and smart organization
struct MyPlantsView: View {
    @Query(sort: \Plant.dateAdded, order: .reverse) private var plants: [Plant]
    @StateObject private var vm = MyPlantsViewModel()
    @State private var showingAddPlant = false
    @State private var viewMode: ViewMode = .grid
    @State private var searchText = ""
    @State private var filterBy: HealthStatus? = nil
    @State private var lightLevelFilter: LightLevel? = nil
    @State private var careNeededFilter: CareNeededFilter? = nil
    @State private var sortBy: SortOption = .dateAdded
    @State private var groupBy: GroupOption = .none
    @State private var scrollOffset: CGFloat = 0
    @State private var isRefreshing = false
    @State private var showingAdvancedFilters = false
    
    // Groups computed by view model (debounced)
    private var organizedPlants: [PlantGroup] { vm.groups }
    
    // Legacy computed property for backward compatibility
    private var filteredPlants: [Plant] { organizedPlants.flatMap { $0.plants } }
    
    // Modern design computed properties
    private var urgentCarePlants: [Plant] {
        plants.filter { $0.isWateringOverdue || $0.isFertilizingOverdue }
    }
    
    private var todaysCareCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return plants.filter { plant in
            guard let carePlan = plant.carePlan else { return false }
            // Get the most recent watering event
            let lastWateringDate = plant.careEvents
                .filter { $0.type == .watering }
                .max(by: { $0.date < $1.date })?.date ?? plant.dateAdded
            
            let daysSinceLastWatering = Calendar.current.dateComponents([.day], from: lastWateringDate, to: today).day ?? 0
            return daysSinceLastWatering >= carePlan.wateringInterval
        }.count
    }
    
    private var healthyPlantCount: Int {
        plants.filter { $0.healthStatus == .excellent || $0.healthStatus == .healthy }.count
    }
    
    private var collectionHealthPercentage: Int {
        plants.isEmpty ? 100 : Int((Double(healthyPlantCount) / Double(plants.count)) * 100)
    }
    
    private func sortPlants(_ plants: [Plant], by option: SortOption) -> [Plant] {
        switch option {
        case .dateAdded:
            return plants.sorted { $0.dateAdded > $1.dateAdded }
        case .alphabetical:
            return plants.sorted { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }
        case .healthStatus:
            return plants.sorted { $0.healthStatus.sortOrder < $1.healthStatus.sortOrder }
        case .careNeeded:
            return plants.sorted { plant1, plant2 in
                let care1 = (plant1.isWateringOverdue ? 2 : 0) + (plant1.isFertilizingOverdue ? 1 : 0)
                let care2 = (plant2.isWateringOverdue ? 2 : 0) + (plant2.isFertilizingOverdue ? 1 : 0)
                return care1 > care2
            }
        case .location:
            return plants.sorted { plant1, plant2 in
                plant1.notes.localizedCompare(plant2.notes) == .orderedAscending
            }
        case .wateringFrequency:
            return plants.sorted { $0.wateringFrequency < $1.wateringFrequency }
        }
    }
    
    private func groupPlants(_ plants: [Plant], by option: GroupOption) -> [PlantGroup] {
        switch option {
        case .none:
            return [PlantGroup(title: nil, plants: plants)]
        case .healthStatus:
            let grouped = Dictionary(grouping: plants) { $0.healthStatus }
            return HealthStatus.allCases.compactMap { status in
                guard let plants = grouped[status], !plants.isEmpty else { return nil }
                return PlantGroup(title: status.displayText, plants: plants)
            }
        case .location:
            // Group by the plant's location field (not notes)
            let grouped = Dictionary(grouping: plants) { $0.location.isEmpty ? "Unspecified" : $0.location }
            return grouped.keys.sorted().map { location in
                PlantGroup(title: location, plants: grouped[location] ?? [])
            }
        case .careNeeded:
            let urgent = plants.filter { $0.isWateringOverdue || $0.isFertilizingOverdue }
            let normal = plants.filter { !$0.isWateringOverdue && !$0.isFertilizingOverdue }
            var groups: [PlantGroup] = []
            if !urgent.isEmpty {
                groups.append(PlantGroup(title: "Needs Care (\(urgent.count))", plants: urgent))
            }
            if !normal.isEmpty {
                groups.append(PlantGroup(title: "Up to Date (\(normal.count))", plants: normal))
            }
            return groups
        case .lightLevel:
            let grouped = Dictionary(grouping: plants) { $0.lightLevel }
            return LightLevel.allCases.compactMap { level in
                guard let plants = grouped[level], !plants.isEmpty else { return nil }
                return PlantGroup(title: level.displayName, plants: plants)
            }
        }
    }
    
    // MARK: - Modern Design Components
    
    private var modernBackgroundView: some View {
        ZStack {
            // Primary background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            // Subtle botanical pattern overlay
            VStack {
                LinearGradient(
                    colors: [
                        BotanicaTheme.Colors.leafGreen.opacity(0.02),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .frame(height: 200)
                Spacer()
            }
            .ignoresSafeArea()
        }
    }

    // Update VM whenever inputs change
    var bodyUpdateHook: some View { EmptyView().onAppear { updateVM() }
        .onChange(of: plants) { _, _ in updateVM() }
        .onChange(of: searchText) { _, _ in updateVM() }
        .onChange(of: filterBy) { _, _ in updateVM() }
        .onChange(of: lightLevelFilter) { _, _ in updateVM() }
        .onChange(of: careNeededFilter) { _, _ in updateVM() }
        .onChange(of: sortBy) { _, _ in updateVM() }
        .onChange(of: groupBy) { _, _ in updateVM() }
    }

    // Keep VM in sync with inputs
    private func updateVM() {
        vm.update(
            sourcePlants: plants,
            searchText: searchText,
            filterBy: filterBy,
            lightLevelFilter: lightLevelFilter,
            careNeededFilter: careNeededFilter,
            sortBy: sortBy,
            groupBy: groupBy
        )
    }
    
    private var collectionInsightsHeader: some View {
        VStack(spacing: BotanicaTheme.Spacing.lg) {
            // Main collection stats
            HStack(spacing: BotanicaTheme.Spacing.lg) {
                ModernStatCard(
                    title: "Plants",
                    value: "\(plants.count)",
                    icon: "leaf.fill",
                    color: BotanicaTheme.Colors.leafGreen
                )
                
                ModernStatCard(
                    title: "Healthy",
                    value: "\(collectionHealthPercentage)%",
                    icon: "heart.fill",
                    color: BotanicaTheme.Colors.success
                )
                
                ModernStatCard(
                    title: "Care Today",
                    value: "\(todaysCareCount)",
                    icon: "drop.fill",
                    color: todaysCareCount > 0 ? BotanicaTheme.Colors.waterBlue : BotanicaTheme.Colors.textTertiary
                )
            }
            
            // Collection insight message
            if !plants.isEmpty {
                ModernInsightCard(
                    insight: collectionInsightMessage,
                    actionText: collectionActionText,
                    action: collectionAction
                )
            }
        }
        .padding(.horizontal, BotanicaTheme.Spacing.lg)
    }
    
    private var careRemindersSection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            HStack {
                Label("Care Reminders", systemImage: "bell.fill")
                    .font(BotanicaTheme.Typography.headline)
                    .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                
                Spacer()
                
                Button("View All") {
                    careNeededFilter = .needsAnyCare
                    HapticManager.shared.light()
                }
                .font(BotanicaTheme.Typography.callout)
                .foregroundStyle(BotanicaTheme.Colors.primary)
            }
            
            let urgentTop3 = Array(urgentCarePlants.prefix(3))
            LazyVStack(spacing: BotanicaTheme.Spacing.sm) {
                ForEach(urgentTop3, id: \.id) { plant in
                    PlantCareReminderRow(plant: plant)
                }
            }
        }
        .padding(.horizontal, BotanicaTheme.Spacing.lg)
    }
    
    private var quickFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BotanicaTheme.Spacing.md) {
                QuickFilterPill(
                    title: "All Plants",
                    count: plants.count,
                    isSelected: filterBy == nil,
                    action: { filterBy = nil }
                )
                
                QuickFilterPill(
                    title: "Need Water",
                    count: plants.filter { $0.isWateringOverdue }.count,
                    isSelected: careNeededFilter == .needsWatering,
                    action: { careNeededFilter = careNeededFilter == .needsWatering ? nil : .needsWatering }
                )
                
                QuickFilterPill(
                    title: "Healthy",
                    count: healthyPlantCount,
                    isSelected: filterBy == .healthy,
                    action: { filterBy = filterBy == .healthy ? nil : .healthy }
                )
                
                QuickFilterPill(
                    title: "New",
                    count: weeklyAddedCount,
                    isSelected: sortBy == .dateAdded,
                    action: { sortBy = .dateAdded }
                )
            }
            .padding(.horizontal, BotanicaTheme.Spacing.lg)
        }
    }
    
    private var plantsMainContent: some View {
        VStack(spacing: BotanicaTheme.Spacing.xl) {
            ForEach(organizedPlants, id: \.id) { group in
                ModernPlantSection(
                    group: group,
                    viewMode: viewMode
                )
            }
        }
        .padding(.horizontal, BotanicaTheme.Spacing.lg)
    }
    
    private var modernEmptyStateView: some View {
        VStack(spacing: BotanicaTheme.Spacing.xxl) {
            Spacer()
            
            VStack(spacing: BotanicaTheme.Spacing.xl) {
                // Modern empty state illustration
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    BotanicaTheme.Colors.leafGreen.opacity(0.15),
                                    BotanicaTheme.Colors.primary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    VStack(spacing: BotanicaTheme.Spacing.sm) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(BotanicaTheme.Colors.primary)
                            .breatheRepeating()
                        
                        Text("🌱")
                            .font(.system(size: 24))
                    }
                }
                
                VStack(spacing: BotanicaTheme.Spacing.lg) {
                    Text("Start Your Plant Journey")
                        .font(BotanicaTheme.Typography.title1)
                        .fontWeight(.bold)
                        .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                    
                    Text("Transform your space into a thriving garden. Track care schedules, monitor plant health, and watch your green family grow.")
                        .font(BotanicaTheme.Typography.body)
                        .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BotanicaTheme.Spacing.xl)
                }
                
                Button {
                    showingAddPlant = true
                    HapticManager.shared.medium()
                } label: {
                    HStack(spacing: BotanicaTheme.Spacing.md) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Add Your First Plant")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, BotanicaTheme.Spacing.xl)
                    .padding(.vertical, BotanicaTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.xlarge)
                            .fill(BotanicaTheme.Colors.primary)
                    )
                }
                .scaleEffect(1.0)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(BotanicaTheme.Spacing.xl)
    }
    
    // Collection insight computed properties
    private var collectionInsightMessage: String {
        if urgentCarePlants.count > plants.count / 2 {
            return "Many plants need attention - consider setting up care reminders"
        } else if collectionHealthPercentage > 85 {
            return "Your plants are thriving! Excellent care routine"
        } else if plants.count >= 10 {
            return "Impressive collection! Consider grouping by care needs"
        } else {
            return "Your garden is growing beautifully"
        }
    }
    
    private var collectionActionText: String? {
        if urgentCarePlants.count > plants.count / 2 {
            return "Set Reminders"
        } else if plants.count >= 10 {
            return "Organize"
        }
        return nil
    }
    
    private var collectionAction: (() -> Void)? {
        if urgentCarePlants.count > plants.count / 2 {
            return { careNeededFilter = .needsAnyCare }
        } else if plants.count >= 10 {
            return { showingAdvancedFilters = true }
        }
        return nil
    }
    
    private var weeklyAddedCount: Int {
        let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        return plants.filter { $0.dateAdded >= oneWeekAgo }.count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Modern botanical background
                modernBackgroundView
                // invisible updater to keep VM in sync
                bodyUpdateHook.opacity(0)
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if plants.isEmpty {
                            modernEmptyStateView
                        } else {
                            VStack(spacing: BotanicaTheme.Spacing.xl) {
                                // Redesigned collection insights
                                collectionInsightsHeader
                                
                                // Care reminders section (only if needed)
                                if !urgentCarePlants.isEmpty {
                                    careRemindersSection
                                }
                                
                                // Quick filter pills
                                quickFilterSection
                                
                                // Main plants content
                                plantsMainContent
                            }
                            .padding(.top, BotanicaTheme.Spacing.lg)
                        }
                    }
                }
                .refreshable {
                    HapticManager.shared.light()
                }
            }
            .navigationTitle("My Garden")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search your plants...")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Enhanced menu with better styling
                    Menu {
                        // View mode options with better icons and descriptions
                        Section("View Options") {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewMode = .grid
                                }
                                HapticManager.shared.light()
                            } label: {
                                Label("Grid View", systemImage: viewMode == .grid ? "square.grid.2x2.fill" : "square.grid.2x2")
                            }
                            
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewMode = .list
                                }
                                HapticManager.shared.light()
                            } label: {
                                Label("List View", systemImage: viewMode == .list ? "list.bullet.rectangle.fill" : "list.bullet.rectangle")
                            }
                        }
                        
                        // Enhanced sorting options
                        Section("Sort Plants") {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        sortBy = option
                                    }
                                    HapticManager.shared.light()
                                } label: {
                                    Label(
                                        option.displayName,
                                        systemImage: sortBy == option ? option.selectedIcon : option.icon
                                    )
                                }
                            }
                        }
                        
                        // Grouping options
                        Section("Group Plants") {
                            ForEach(GroupOption.allCases, id: \.self) { option in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        groupBy = option
                                    }
                                    HapticManager.shared.light()
                                } label: {
                                    Label(
                                        option.displayName,
                                        systemImage: groupBy == option ? option.selectedIcon : option.icon
                                    )
                                }
                            }
                        }
                        
                        // Enhanced filter options
                        Section("Quick Filters") {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    filterBy = nil
                                    lightLevelFilter = nil
                                    careNeededFilter = nil
                                }
                                HapticManager.shared.light()
                            } label: {
                                Label(
                                    "All Plants (\(plants.count))", 
                                    systemImage: (filterBy == nil && lightLevelFilter == nil && careNeededFilter == nil) ? "leaf.fill" : "leaf"
                                )
                            }
                            
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    careNeededFilter = .needsAnyCare
                                    filterBy = nil
                                    lightLevelFilter = nil
                                }
                                HapticManager.shared.light()
                            } label: {
                                let needsCareCount = plants.filter { $0.isWateringOverdue || $0.isFertilizingOverdue }.count
                                Label(
                                    "Needs Care (\(needsCareCount))", 
                                    systemImage: careNeededFilter == .needsAnyCare ? "exclamationmark.triangle.fill" : "exclamationmark.triangle"
                                )
                            }
                            
                            Button {
                                showingAdvancedFilters = true
                                HapticManager.shared.light()
                            } label: {
                                Label("Advanced Filters", systemImage: "slider.horizontal.3")
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title3)
                            .foregroundStyle(BotanicaTheme.Colors.primary)
                    }
                    .menuStyle(.borderlessButton)
                    

                }
            }
            .sheet(isPresented: $showingAddPlant) {
                AddPlantView()
            }
            .sheet(isPresented: $showingAdvancedFilters) {
                AdvancedFiltersView(
                    healthFilter: $filterBy,
                    lightLevelFilter: $lightLevelFilter,
                    careNeededFilter: $careNeededFilter,
                    plantCount: plants.count
                )
            }
        }
    }
    
    // MARK: - Collection Statistics
    
    private var collectionStatsHeader: some View {
        VStack(spacing: BotanicaTheme.Spacing.lg) {
            // Enhanced Statistics Cards with improved visual design
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: BotanicaTheme.Spacing.md) {
                EnhancedStatCard(
                    title: "Total Plants",
                    value: "\(plants.count)",
                    icon: "leaf.fill",
                    color: BotanicaTheme.Colors.leafGreen,
                    trend: recentlyAddedCount > 0 ? "+\(recentlyAddedCount)" : nil
                )
                
                EnhancedStatCard(
                    title: "Need Care",
                    value: "\(plantsNeedingCare.count)",
                    icon: plantsNeedingCare.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                    color: plantsNeedingCare.isEmpty ? BotanicaTheme.Colors.success : BotanicaTheme.Colors.error,
                    trend: nil
                )
                
                EnhancedStatCard(
                    title: "Healthy",
                    value: "\(healthyPlantsCount)",
                    icon: "heart.fill",
                    color: BotanicaTheme.Colors.success,
                    trend: healthyPercentage > 0 ? "\(healthyPercentage)%" : nil
                )
            }
            
            // Quick insights
            if !plants.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                        Text("Collection Insights")
                            .font(BotanicaTheme.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                        
                        Text(collectionInsight)
                            .font(BotanicaTheme.Typography.caption2)
                            .foregroundStyle(BotanicaTheme.Colors.textTertiary)
                    }
                    
                    Spacer()
                    
                    // Growth rate indicator
                    HStack(spacing: BotanicaTheme.Spacing.xs) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 12))
                            .foregroundStyle(BotanicaTheme.Colors.primary)
                        
                        Text("\(recentlyAddedCount) added this month")
                            .font(BotanicaTheme.Typography.caption2)
                            .foregroundStyle(BotanicaTheme.Colors.textTertiary)
                    }
                }
            }
        }
        .padding(.horizontal, BotanicaTheme.Spacing.lg)
        .padding(.vertical, BotanicaTheme.Spacing.md)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(BotanicaTheme.Colors.primary.opacity(0.1))
                        .frame(height: 1)
                }
        )
    }
    
    // Collection statistics computed properties
    private var plantsNeedingCare: [Plant] {
        plants.filter { $0.isWateringOverdue || $0.isFertilizingOverdue }
    }
    
    private var healthyPlantsCount: Int {
        plants.filter { $0.healthStatus == .excellent || $0.healthStatus == .healthy }.count
    }
    
    private var recentlyAddedCount: Int {
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return plants.filter { $0.dateAdded >= oneMonthAgo }.count
    }
    
    private var healthyPercentage: Int {
        plants.isEmpty ? 0 : Int((Double(healthyPlantsCount) / Double(plants.count)) * 100)
    }
    
    private var collectionInsight: String {
        let carePercentage = plants.isEmpty ? 0 : Int((Double(plantsNeedingCare.count) / Double(plants.count)) * 100)
        
        if carePercentage > 50 {
            return "Many plants need attention - consider setting care reminders"
        } else if healthyPercentage > 80 {
            return "Excellent care! Your plants are thriving"
        } else if plants.count >= 10 {
            return "Growing collection! Consider organizing by care needs"
        } else {
            return "Building a beautiful plant collection"
        }
    }
    
    // MARK: - View Components
    
    private var emptyStateView: some View {
        GeometryReader { geometry in
            VStack(spacing: BotanicaTheme.Spacing.xxl) {
                Spacer()
                
                // Enhanced empty state with improved visual hierarchy
                VStack(spacing: BotanicaTheme.Spacing.xl) {
                    // Enhanced animated plant icon with modern design
                    ZStack {
                        // Background circle with enhanced gradient
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        BotanicaTheme.Colors.leafGreen,
                                        BotanicaTheme.Colors.forestGreen,
                                        BotanicaTheme.Colors.primary
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 160, height: 160)
                            .shadow(
                                color: BotanicaTheme.Colors.primary.opacity(0.3),
                                radius: 32,
                                x: 0,
                                y: 16
                            )
                        
                        // Subtle ring effect
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.3),
                                        .white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 160, height: 160)
                        
                        // Animated plant icons
                        VStack(spacing: BotanicaTheme.Spacing.xs) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 36, weight: .light))
                                .foregroundStyle(.white)
                                .breatheRepeating()
                            
                            HStack(spacing: BotanicaTheme.Spacing.xs) {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 16, weight: .light))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .breatheRepeating()
                                
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .breatheRepeating()
                            }
                        }
                    }
                    
                    VStack(spacing: BotanicaTheme.Spacing.lg) {
                        Text("Start Your Garden")
                            .font(BotanicaTheme.Typography.title1)
                            .fontWeight(.bold)
                            .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                        
                        Text("Begin your plant care journey! Add your first plant to track watering schedules, monitor health, and watch your garden flourish.")
                            .font(BotanicaTheme.Typography.body)
                            .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, BotanicaTheme.Spacing.xl)
                            .lineSpacing(4)
                    }
                    
                    Button {
                        showingAddPlant = true
                        HapticManager.shared.medium()
                    } label: {
                        HStack(spacing: BotanicaTheme.Spacing.md) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .bounceByLayerNonRepeating()
                            Text("Add Your First Plant")
                                .fontWeight(.semibold)
                                .font(.system(size: 16))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, BotanicaTheme.Spacing.xxl)
                        .padding(.vertical, BotanicaTheme.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.xlarge)
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.xlarge)
                                        .stroke(
                                            .white.opacity(0.2),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(
                                    color: BotanicaTheme.Colors.primary.opacity(0.5),
                                    radius: 16,
                                    x: 0,
                                    y: 8
                                )
                        )
                    }
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.2), value: UUID())
                }
                
                Spacer()
            }
            .frame(width: geometry.size.width)
            .padding(BotanicaTheme.Spacing.xl)
        }
    }
    
    private var plantsContentView: some View {
        ScrollView {
            LazyVStack(spacing: BotanicaTheme.Spacing.lg) {
                // Enhanced filter indicator with better visual treatment
                if let filter = filterBy {
                    HStack(spacing: BotanicaTheme.Spacing.md) {
                        HStack(spacing: BotanicaTheme.Spacing.sm) {
                            Circle()
                                .fill(BotanicaTheme.Colors.primary)
                                .frame(width: 10, height: 10)
                                .overlay {
                                    Circle()
                                        .stroke(BotanicaTheme.Colors.primary.opacity(0.3), lineWidth: 3)
                                        .scaleEffect(1.8)
                                }
                            
                            Text("Showing \(filteredPlants.count) \(filter.rawValue.lowercased()) plant\(filteredPlants.count == 1 ? "" : "s")")
                                .font(BotanicaTheme.Typography.callout)
                                .fontWeight(.medium)
                                .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                filterBy = nil
                            }
                            HapticManager.shared.light()
                        } label: {
                            HStack(spacing: BotanicaTheme.Spacing.xs) {
                                Image(systemName: "xmark.circle.fill")
                                Text("Clear")
                            }
                            .font(BotanicaTheme.Typography.callout)
                            .fontWeight(.medium)
                            .foregroundStyle(BotanicaTheme.Colors.primary)
                        }
                    }
                    .padding(.horizontal, BotanicaTheme.Spacing.lg)
                    .padding(.vertical, BotanicaTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                            .fill(.thinMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                                    .stroke(BotanicaTheme.Colors.primary.opacity(0.15), lineWidth: 1)
                            }
                    )
                    .padding(.horizontal, BotanicaTheme.Spacing.lg)
                }
                
                // Plants content with improved spacing and transitions
                Group {
                    if viewMode == .grid {
                        plantsGridView
                            .padding(.horizontal, BotanicaTheme.Spacing.lg)
                            .padding(.top, BotanicaTheme.Spacing.md)
                            .transition(
                                .asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .opacity
                                )
                            )
                    } else {
                        plantsListView
                            .padding(.horizontal, BotanicaTheme.Spacing.lg)
                            .transition(
                                .asymmetric(
                                    insertion: .slide.combined(with: .opacity),
                                    removal: .opacity
                                )
                            )
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: viewMode)
            }
            .padding(.top, BotanicaTheme.Spacing.md)
            .padding(.bottom, 120) // Extra padding for tab bar and FAB
        }
    }
    
    private var plantsGridView: some View {
        LazyVStack(spacing: BotanicaTheme.Spacing.xl * 1.5) {
            ForEach(organizedPlants, id: \.id) { group in
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xl) {
                    // Group header
                    if let title = group.title {
                        HStack {
                            Text(title)
                                .font(BotanicaTheme.Typography.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            Text("\(group.plants.count)")
                                .font(BotanicaTheme.Typography.callout)
                                .fontWeight(.medium)
                                .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                                .padding(.horizontal, BotanicaTheme.Spacing.sm)
                                .padding(.vertical, BotanicaTheme.Spacing.xs)
                                .background(
                                    Capsule()
                                        .fill(BotanicaTheme.Colors.primary.opacity(0.1))
                                )
                        }
                        .padding(.horizontal, BotanicaTheme.Spacing.lg)
                    }
                    
                    // Enhanced plants grid with optimized spacing
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: BotanicaTheme.Spacing.lg),
                        GridItem(.flexible(), spacing: BotanicaTheme.Spacing.lg)
                    ], spacing: BotanicaTheme.Spacing.lg) {
                        ForEach(group.plants, id: \.id) { plant in
                            NavigationLink(destination: PlantDetailView(plant: plant)) {
                                PlantGridCard(plant: plant)
                            }
                            .buttonStyle(ModernCardButtonStyle())
                            .accessibilityLabel("\(plant.displayName), \(plant.scientificName)")
                            .accessibilityHint("Double tap to view plant details")
                        }
                    }
                    .padding(.horizontal, BotanicaTheme.Spacing.lg)
                    .padding(.bottom, BotanicaTheme.Spacing.lg)
                }
            }
        }
    }
    
    private var plantsListView: some View {
        LazyVStack(spacing: BotanicaTheme.Spacing.xl) {
            ForEach(organizedPlants, id: \.id) { group in
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
                    // Group header
                    if let title = group.title {
                        HStack {
                            Text(title)
                                .font(BotanicaTheme.Typography.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            Text("\(group.plants.count)")
                                .font(BotanicaTheme.Typography.callout)
                                .fontWeight(.medium)
                                .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                                .padding(.horizontal, BotanicaTheme.Spacing.sm)
                                .padding(.vertical, BotanicaTheme.Spacing.xs)
                                .background(
                                    Capsule()
                                        .fill(BotanicaTheme.Colors.primary.opacity(0.1))
                                )
                        }
                        .padding(.horizontal, BotanicaTheme.Spacing.lg)
                    }
                    
                    // Plants list
                    LazyVStack(spacing: BotanicaTheme.Spacing.md) {
                        ForEach(group.plants, id: \.id) { plant in
                            NavigationLink(destination: PlantDetailView(plant: plant)) {
                                PlantListCard(plant: plant)
                            }
                            .buttonStyle(CardButtonStyle())
                            .accessibilityLabel("\(plant.displayName), \(plant.scientificName)")
                            .accessibilityHint("Double tap to view plant details")
                        }
                    }
                    .padding(.horizontal, BotanicaTheme.Spacing.lg)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct PlantGridCard: View {
    let plant: Plant
    @State private var animateHealth = false
    @State private var showingQuickActions = false
    @State private var isPressed = false
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Enhanced plant image container with modern design
            ZStack(alignment: .topTrailing) {
                // Main image container with improved styling
                ZStack {
                    RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                        .fill(
                            LinearGradient(
                                colors: [
                                    BotanicaTheme.Colors.leafGreen.opacity(0.06),
                                    BotanicaTheme.Colors.primary.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(1.4, contentMode: .fit)
                        .overlay {
                            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                                .stroke(BotanicaTheme.Colors.primary.opacity(0.1), lineWidth: 1)
                        }
                    
                    AsyncPlantImageFill(photo: plant.primaryPhoto, plant: plant, cornerRadius: BotanicaTheme.CornerRadius.large)
                        .overlay {
                            LinearGradient(
                                colors: [Color.clear, Color.clear, Color.black.opacity(0.08)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .clipShape(RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large))
                        }
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Refined corner status badge with better visual design
                if plant.isWateringOverdue || plant.isFertilizingOverdue {
                    HStack(spacing: 3) {
                        if plant.isWateringOverdue {
                            Image(systemName: "drop.fill")
                                .foregroundStyle(.white)
                                .font(.system(size: 9, weight: .medium))
                                .pulseRepeatingByLayer()
                        }
                        
                        if plant.isFertilizingOverdue {
                            Image(systemName: "leaf.fill")
                                .foregroundStyle(.white)
                                .font(.system(size: 9, weight: .medium))
                                .pulseRepeatingByLayer()
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        BotanicaTheme.Colors.error,
                                        BotanicaTheme.Colors.error.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: BotanicaTheme.Colors.error.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                    .offset(x: -6, y: 6)
                }
            }
            
            // Redesigned information section with modern layout
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                // Plant names with improved typography hierarchy
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(plant.displayName)
                                .font(.system(size: 15, weight: .semibold, design: .default))
                                .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                            
                            if !plant.scientificName.isEmpty {
                                Text(plant.scientificName)
                                    .font(.system(size: 12, weight: .medium, design: .serif))
                                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                                    .italic()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.9)
                            }
                        }
                        
                        Spacer()
                        
                        // Modern health status indicator
                        VStack(spacing: 2) {
                            Circle()
                                .fill(plant.healthStatusColor)
                                .frame(width: 8, height: 8)
                                .scaleEffect(animateHealth ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateHealth)
                            
                            Text(plant.healthStatus.displayText)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(BotanicaTheme.Colors.textTertiary)
                        }
                    }
                }
                
                // Improved care schedule info with better visual design
                if let carePlan = plant.carePlan {
                    HStack(spacing: BotanicaTheme.Spacing.sm) {
                        Image(systemName: "drop.circle.fill")
                            .foregroundStyle(BotanicaTheme.Colors.waterBlue)
                            .font(.system(size: 11))
                        
                        Text("Every \(carePlan.wateringInterval) days")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                        
                        Spacer()
                        
                        // Water amount indicator
                        if plant.recommendedWaterAmount > 0 {
                            let amount = Int(plant.recommendedWateringAmount.amount)
                            let unit = plant.waterUnit == .milliliters ? "ml" : "oz"
                            Text("\(amount)\(unit)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(BotanicaTheme.Colors.waterBlue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(BotanicaTheme.Colors.waterBlue.opacity(0.1))
                                )
                        }
                    }
                }
                
                // Enhanced care status indicators with modern design
                HStack(spacing: BotanicaTheme.Spacing.md) {
                    // Water status with improved visual feedback
                    HStack(spacing: 4) {
                        Image(systemName: plant.isWateringOverdue ? "drop.fill" : "drop")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(plant.isWateringOverdue ? BotanicaTheme.Colors.error : BotanicaTheme.Colors.waterBlue.opacity(0.7))
                            .bounceRepeating(if: plant.isWateringOverdue)
                        
                        if plant.isWateringOverdue {
                            Text("Water")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(BotanicaTheme.Colors.error)
                        }
                    }
                    
                    // Fertilizer status
                    HStack(spacing: 4) {
                        Image(systemName: plant.isFertilizingOverdue ? "leaf.fill" : "leaf")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(plant.isFertilizingOverdue ? BotanicaTheme.Colors.error : BotanicaTheme.Colors.leafGreen.opacity(0.7))
                            .bounceRepeating(if: plant.isFertilizingOverdue)
                        
                        if plant.isFertilizingOverdue {
                            Text("Feed")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(BotanicaTheme.Colors.error)
                        }
                    }
                    
                    Spacer()
                    
                    // Last care with improved styling
                    if let lastCare = plant.careEvents.max(by: { $0.date < $1.date }) {
                        Text(lastCare.timeAgo)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(BotanicaTheme.Colors.textTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(BotanicaTheme.Colors.textTertiary.opacity(0.08))
                            )
                    }
                }
            }
            .padding(.horizontal, BotanicaTheme.Spacing.lg)
            .padding(.vertical, BotanicaTheme.Spacing.lg)
        }
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.xlarge)
                .fill(Color(.systemBackground))
                .shadow(
                    color: BotanicaTheme.Colors.primary.opacity(0.08),
                    radius: 12,
                    x: 0,
                    y: 4
                )
                .shadow(
                    color: .black.opacity(0.04),
                    radius: 2,
                    x: 0,
                    y: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.xlarge))
        .overlay(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.xlarge)
                .stroke(BotanicaTheme.Colors.primary.opacity(0.06), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onAppear {
            if plant.healthStatus != .healthy {
                animateHealth = true
            }
        }
    }
    
    // MARK: - Quick Actions
    
    private func handleQuickWatering() {
        let careEvent = CareEvent(
            type: .watering,
            date: Date(),
            notes: "Quick watering from My Garden"
        )
        plant.careEvents.append(careEvent)
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            print("Failed to save watering event: \(error)")
            HapticManager.shared.error()
        }
    }
    
    private func handleQuickFertilizing() {
        let careEvent = CareEvent(
            type: .fertilizing,
            date: Date(),
            notes: "Quick fertilizing from My Garden"
        )
        plant.careEvents.append(careEvent)
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            print("Failed to save fertilizing event: \(error)")
            HapticManager.shared.error()
        }
    }
    
    private func handleQuickPhoto() {
        // This would trigger a camera/photo picker
        // For now, we'll show a placeholder action
        HapticManager.shared.light()
    }
}

struct PlantListCard: View {
    let plant: Plant
    @State private var animateHealth = false
    
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.lg) {
            // Enhanced plant image with better proportions
            ZStack {
                RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                    .fill(
                        LinearGradient(
                            colors: [
                                BotanicaTheme.Colors.leafGreen.opacity(0.12),
                                BotanicaTheme.Colors.forestGreen.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .overlay {
                        RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                            .stroke(BotanicaTheme.Colors.primary.opacity(0.1), lineWidth: 1)
                    }
                
                AsyncPlantThumbnail(photo: plant.primaryPhoto, plant: plant, size: 70, cornerRadius: BotanicaTheme.CornerRadius.medium)
            }
            
            // Enhanced content layout
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                Text(plant.displayName)
                    .font(BotanicaTheme.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                    .lineLimit(1)
                
                Text(plant.scientificName)
                    .font(BotanicaTheme.Typography.scientificName)
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                    .lineLimit(1)
                
                HStack(spacing: BotanicaTheme.Spacing.md) {
                    // Health status with simple styling
                    HStack(spacing: BotanicaTheme.Spacing.xs) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(plant.healthStatusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(plant.healthStatus.rawValue)
                            .font(BotanicaTheme.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                    }
                    .plantHealthAccessibility(status: plant.healthStatus)
                    
                    Spacer()
                    
                    // Enhanced care indicators
                    HStack(spacing: BotanicaTheme.Spacing.xs) {
                        if plant.isWateringOverdue {
                            Image(systemName: "drop.fill")
                                .foregroundStyle(BotanicaTheme.Colors.waterBlue)
                                .font(.caption)
                                .pulseRepeatingByLayer()
                                .careIndicatorAccessibility(isOverdue: true, careType: "Watering")
                        }
                        
                        if plant.isFertilizingOverdue {
                            Image(systemName: "leaf.arrow.circlepath")
                                .foregroundStyle(BotanicaTheme.Colors.leafGreen)
                                .font(.caption)
                                .pulseRepeatingByLayer()
                                .careIndicatorAccessibility(isOverdue: true, careType: "Fertilizing")
                        }
                    }
                }
            }
            
            Spacer()
            
            // Enhanced chevron with better styling
            Image(systemName: "chevron.right")
                .foregroundStyle(BotanicaTheme.Colors.textTertiary)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(BotanicaTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                .fill(.regularMaterial)
                .shadow(
                    color: .black.opacity(0.08),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                .stroke(
                    BotanicaTheme.Colors.primary.opacity(0.06),
                    lineWidth: 0.5
                )
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Supporting Types
// Debounced, memoizing view model for MyPlantsView
final class MyPlantsViewModel: ObservableObject {
    @Published private(set) var groups: [PlantGroup] = []
    private var work: Task<Void, Never>?

    func update(
        sourcePlants: [Plant],
        searchText: String,
        filterBy: HealthStatus?,
        lightLevelFilter: LightLevel?,
        careNeededFilter: CareNeededFilter?,
        sortBy: SortOption,
        groupBy: GroupOption
    ) {
        work?.cancel()
        work = Task { [weak self] in
            // debounce ~150ms
            try? await Task.sleep(nanoseconds: 150_000_000)
            if Task.isCancelled { return }

            let computed = Self.computeGroups(
                plants: sourcePlants,
                searchText: searchText,
                filterBy: filterBy,
                lightLevelFilter: lightLevelFilter,
                careNeededFilter: careNeededFilter,
                sortBy: sortBy,
                groupBy: groupBy
            )

            if Task.isCancelled { return }
            guard let self else { return }

            await MainActor.run {
                self.groups = computed
            }
        }
    }

    private static func computeGroups(
        plants: [Plant],
        searchText: String,
        filterBy: HealthStatus?,
        lightLevelFilter: LightLevel?,
        careNeededFilter: CareNeededFilter?,
        sortBy: SortOption,
        groupBy: GroupOption
    ) -> [PlantGroup] {
        var filtered = plants
        if !searchText.isEmpty {
            filtered = filtered.filter { plant in
                plant.displayName.localizedCaseInsensitiveContains(searchText) ||
                plant.scientificName.localizedCaseInsensitiveContains(searchText) ||
                plant.commonNames.joined().localizedCaseInsensitiveContains(searchText) ||
                plant.notes.localizedCaseInsensitiveContains(searchText) ||
                plant.lightLevel.displayName.localizedCaseInsensitiveContains(searchText) ||
                plant.growthHabit.rawValue.localizedCaseInsensitiveContains(searchText) ||
                plant.healthStatus.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let filter = filterBy { filtered = filtered.filter { $0.healthStatus == filter } }
        if let level = lightLevelFilter { filtered = filtered.filter { $0.lightLevel == level } }
        if let careFilter = careNeededFilter {
            switch careFilter {
            case .needsWatering: filtered = filtered.filter { $0.isWateringOverdue }
            case .needsFertilizing: filtered = filtered.filter { $0.isFertilizingOverdue }
            case .needsAnyCare: filtered = filtered.filter { $0.isWateringOverdue || $0.isFertilizingOverdue }
            case .upToDate: filtered = filtered.filter { !$0.isWateringOverdue && !$0.isFertilizingOverdue }
            }
        }
        filtered = sort(plants: filtered, by: sortBy)
        return group(plants: filtered, by: groupBy)
    }

    private static func sort(plants: [Plant], by option: SortOption) -> [Plant] {
        switch option {
        case .dateAdded: return plants.sorted { $0.dateAdded > $1.dateAdded }
        case .alphabetical: return plants.sorted { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }
        case .healthStatus: return plants.sorted { $0.healthStatus.sortOrder < $1.healthStatus.sortOrder }
        case .careNeeded:
            return plants.sorted { p1, p2 in
                let c1 = (p1.isWateringOverdue ? 2 : 0) + (p1.isFertilizingOverdue ? 1 : 0)
                let c2 = (p2.isWateringOverdue ? 2 : 0) + (p2.isFertilizingOverdue ? 1 : 0)
                return c1 > c2
            }
        case .location:
            return plants.sorted { $0.location.localizedCompare($1.location) == .orderedAscending }
        case .wateringFrequency:
            return plants.sorted { $0.wateringFrequency < $1.wateringFrequency }
        }
    }

    private static func group(plants: [Plant], by option: GroupOption) -> [PlantGroup] {
        switch option {
        case .none:
            return [PlantGroup(title: nil, plants: plants)]
        case .healthStatus:
            let grouped = Dictionary(grouping: plants) { $0.healthStatus }
            return HealthStatus.allCases.compactMap { status in
                guard let items = grouped[status], !items.isEmpty else { return nil }
                return PlantGroup(title: status.displayText, plants: items)
            }
        case .location:
            let grouped = Dictionary(grouping: plants) { $0.location.isEmpty ? "Unspecified" : $0.location }
            return grouped.keys.sorted().map { loc in PlantGroup(title: loc, plants: grouped[loc] ?? []) }
        case .careNeeded:
            let urgent = plants.filter { $0.isWateringOverdue || $0.isFertilizingOverdue }
            let normal = plants.filter { !$0.isWateringOverdue && !$0.isFertilizingOverdue }
            var out: [PlantGroup] = []
            if !urgent.isEmpty { out.append(PlantGroup(title: "Needs Care (\(urgent.count))", plants: urgent)) }
            if !normal.isEmpty { out.append(PlantGroup(title: "Up to Date (\(normal.count))", plants: normal)) }
            return out
        case .lightLevel:
            let grouped = Dictionary(grouping: plants) { $0.lightLevel }
            return LightLevel.allCases.compactMap { level in
                guard let items = grouped[level], !items.isEmpty else { return nil }
                return PlantGroup(title: level.displayName, plants: items)
            }
        }
    }
}

// Types moved to Models/PlantListTypes.swift

// MARK: - View Mode Enum

enum ViewMode: String, CaseIterable {
    case grid = "Grid"
    case list = "List"
    
    var systemImage: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        }
    }
}

// MARK: - Supporting Components

struct QuickCareButton: View {
    let icon: String
    let color: Color
    let isOverdue: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isOverdue ? .white : color)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(isOverdue ? color : color.opacity(0.15))
                        .overlay {
                            Circle()
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        }
                )
                .scaleEffect(isOverdue ? 1.1 : 1.0)
                .shadow(
                    color: isOverdue ? color.opacity(0.3) : .clear,
                    radius: isOverdue ? 4 : 0
                )
        }
        .buttonStyle(PressedButtonStyle())
        .bounceByLayer(value: isOverdue)
    }
}

struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom Components

struct FloatingAddButton: View {
    let action: () -> Void
    @State private var isPressed = false
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Main button background
                Circle()
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
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(
                                .white.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: BotanicaTheme.Colors.primary.opacity(0.5),
                        radius: isPressed ? 8 : 16,
                        x: 0,
                        y: isPressed ? 2 : 6
                    )
                
                // Plus icon with enhanced styling
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .bounceByLayer(value: isPressed)
            }
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
            if pressing {
                HapticManager.shared.light()
            }
        }, perform: {})
        .accessibilityLabel("Add new plant")
        .accessibilityHint("Tap to add a new plant to your collection")
    }
}

// MARK: - Supporting Enums and Components

// CareNeededFilter moved to Models/PlantListTypes.swift

struct AdvancedFiltersView: View {
    @Binding var healthFilter: HealthStatus?
    @Binding var lightLevelFilter: LightLevel?
    @Binding var careNeededFilter: CareNeededFilter?
    let plantCount: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Health Status") {
                    Picker("Health Filter", selection: $healthFilter) {
                        Text("All (\(plantCount))").tag(HealthStatus?.none)
                        ForEach(HealthStatus.allCases, id: \.self) { status in
                            Text(status.rawValue.capitalized).tag(status as HealthStatus?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Light Requirements") {
                    Picker("Light Level", selection: $lightLevelFilter) {
                        Text("All Light Levels").tag(LightLevel?.none)
                        ForEach(LightLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level as LightLevel?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Care Status") {
                    Picker("Care Needed", selection: $careNeededFilter) {
                        Text("All Care Status").tag(CareNeededFilter?.none)
                        ForEach(CareNeededFilter.allCases, id: \.self) { filter in
                            Label(filter.rawValue, systemImage: filter.icon).tag(filter as CareNeededFilter?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section {
                    Button("Clear All Filters", role: .destructive) {
                        healthFilter = nil
                        lightLevelFilter = nil
                        careNeededFilter = nil
                        dismiss()
                    }
                }
            }
            .navigationTitle("Advanced Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Modern Design Components

struct ModernInsightCard: View {
    let insight: String
    let actionText: String?
    let action: (() -> Void)?
    
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                Text("Garden Insight")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(BotanicaTheme.Colors.primary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(insight)
                    .font(BotanicaTheme.Typography.callout)
                    .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            if let actionText = actionText, let action = action {
                Button(action: action) {
                    Text(actionText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BotanicaTheme.Colors.primary)
                        .padding(.horizontal, BotanicaTheme.Spacing.md)
                        .padding(.vertical, BotanicaTheme.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(BotanicaTheme.Colors.primary.opacity(0.1))
                        )
                }
            }
        }
        .padding(BotanicaTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                        .stroke(BotanicaTheme.Colors.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Safe Symbol Effects (iOS 18 guards)
extension View {
    @ViewBuilder func breatheRepeating() -> some View {
        if #available(iOS 18.0, *) {
            self.symbolEffect(.breathe.byLayer, options: .repeating)
        } else { self }
    }
    
    @ViewBuilder func pulseRepeatingByLayer() -> some View {
        if #available(iOS 18.0, *) {
            self.symbolEffect(.pulse.byLayer, options: .repeating)
        } else { self }
    }
    
    @ViewBuilder func bounceByLayerNonRepeating() -> some View {
        if #available(iOS 18.0, *) {
            self.symbolEffect(.bounce.byLayer, options: .nonRepeating)
        } else { self }
    }
    
    @ViewBuilder func bounceByLayer(value: Bool) -> some View {
        if #available(iOS 18.0, *) {
            self.symbolEffect(.bounce.byLayer, value: value)
        } else { self }
    }
    
    @ViewBuilder func bounceRepeating(if condition: Bool) -> some View {
        if #available(iOS 18.0, *) {
            self.symbolEffect(.bounce, options: condition ? .repeating : .nonRepeating)
        } else { self }
    }
}



// Removed synchronous PlantThumbnail in favor of AsyncPlantThumbnail

struct QuickFilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: BotanicaTheme.Spacing.xs) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isSelected ? .white : BotanicaTheme.Colors.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? .white.opacity(0.3) : BotanicaTheme.Colors.textSecondary.opacity(0.2))
                        )
                }
            }
            .foregroundStyle(isSelected ? .white : BotanicaTheme.Colors.textPrimary)
            .padding(.horizontal, BotanicaTheme.Spacing.md)
            .padding(.vertical, BotanicaTheme.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? BotanicaTheme.Colors.primary : Color(.secondarySystemGroupedBackground))
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.clear : BotanicaTheme.Colors.primary.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct ModernPlantSection: View {
    let group: PlantGroup
    let viewMode: ViewMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            // Section header
            if let title = group.title {
                HStack {
                    Text(title)
                        .font(BotanicaTheme.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(group.plants.count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                        .padding(.horizontal, BotanicaTheme.Spacing.sm)
                        .padding(.vertical, BotanicaTheme.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(BotanicaTheme.Colors.textSecondary.opacity(0.1))
                        )
                }
            }
            
            // Plants content with enhanced grid layout
            if viewMode == .grid {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: BotanicaTheme.Spacing.lg),
                    GridItem(.flexible(), spacing: BotanicaTheme.Spacing.lg)
                ], spacing: BotanicaTheme.Spacing.xl) {
                    ForEach(group.plants, id: \.id) { plant in
                        NavigationLink(destination: PlantDetailView(plant: plant)) {
                            ModernPlantCard(plant: plant)
                        }
                        .buttonStyle(ModernCardButtonStyle())
                    }
                }
            } else {
                LazyVStack(spacing: BotanicaTheme.Spacing.md) {
                    ForEach(group.plants, id: \.id) { plant in
                        NavigationLink(destination: PlantDetailView(plant: plant)) {
                            ModernPlantListRow(plant: plant)
                        }
                        .buttonStyle(ModernCardButtonStyle())
                    }
                }
            }
        }
    }
}

struct ModernPlantCard: View {
    let plant: Plant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Enhanced image section
            ZStack(alignment: .topTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                        .fill(BotanicaTheme.Colors.leafGreen.opacity(0.08))
                        .aspectRatio(1.3, contentMode: .fit)
                    
                    AsyncPlantImageFill(photo: plant.primaryPhoto, cornerRadius: BotanicaTheme.CornerRadius.large)
                }
                
                // Care status badge
                if plant.isWateringOverdue || plant.isFertilizingOverdue {
                    CareStatusBadge(plant: plant)
                        .offset(x: -8, y: 8)
                }
            }
            
            // Plant information
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                Text(plant.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                    .lineLimit(1)
                
                if !plant.scientificName.isEmpty {
                    Text(plant.scientificName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                        .italic()
                        .lineLimit(1)
                }
                
                // Health and care indicators
                HStack {
                    HealthStatusIndicator(status: plant.healthStatus)
                    
                    Spacer()
                    
                    if let lastCare = plant.careEvents.max(by: { $0.date < $1.date }) {
                        Text(lastCare.timeAgo)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(BotanicaTheme.Colors.textTertiary)
                    }
                }
            }
            .padding(BotanicaTheme.Spacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct ModernPlantListRow: View {
    let plant: Plant
    
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.md) {
            AsyncPlantThumbnail(photo: plant.primaryPhoto, plant: plant, size: 60)
            
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                Text(plant.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                    .lineLimit(1)
                
                if !plant.scientificName.isEmpty {
                    Text(plant.scientificName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                        .italic()
                        .lineLimit(1)
                }
                
                HStack(spacing: BotanicaTheme.Spacing.md) {
                    HealthStatusIndicator(status: plant.healthStatus)
                    
                    if plant.isWateringOverdue || plant.isFertilizingOverdue {
                        CareIndicators(plant: plant)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(BotanicaTheme.Colors.textTertiary)
        }
        .padding(BotanicaTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct CareStatusBadge: View {
    let plant: Plant
    
    var body: some View {
        HStack(spacing: 4) {
            if plant.isWateringOverdue {
                Image(systemName: "drop.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.white)
            }
            
            if plant.isFertilizingOverdue {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(BotanicaTheme.Colors.error)
        )
    }
}

struct HealthStatusIndicator: View {
    let status: HealthStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(healthStatusColor(for: status))
                .frame(width: 8, height: 8)
            
            Text(status.rawValue)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(BotanicaTheme.Colors.textSecondary)
        }
    }
    
    private func healthStatusColor(for status: HealthStatus) -> Color {
        switch status {
        case .excellent, .healthy: return BotanicaTheme.Colors.success
        case .fair: return BotanicaTheme.Colors.warning
        case .poor, .critical: return BotanicaTheme.Colors.error
        }
    }
}

struct CareIndicators: View {
    let plant: Plant
    
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.xs) {
            if plant.isWateringOverdue {
                Label("Water", systemImage: "drop.fill")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(BotanicaTheme.Colors.waterBlue)
            }
            
            if plant.isFertilizingOverdue {
                Label("Feed", systemImage: "leaf.fill")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(BotanicaTheme.Colors.leafGreen)
            }
        }
    }
}

struct ModernAdvancedFiltersView: View {
    @Binding var healthFilter: HealthStatus?
    @Binding var lightLevelFilter: LightLevel?
    @Binding var careNeededFilter: CareNeededFilter?
    @Binding var sortBy: SortOption
    @Binding var groupBy: GroupOption
    let plantCount: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Display") {
                    Picker("Sort By", selection: $sortBy) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Label(option.displayName, systemImage: option.icon).tag(option)
                        }
                    }
                    
                    Picker("Group By", selection: $groupBy) {
                        ForEach(GroupOption.allCases, id: \.self) { option in
                            Label(option.displayName, systemImage: option.icon).tag(option)
                        }
                    }
                }
                
                Section("Filters") {
                    Picker("Health Status", selection: $healthFilter) {
                        Text("All Plants").tag(HealthStatus?.none)
                        ForEach(HealthStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status as HealthStatus?)
                        }
                    }
                    
                    Picker("Light Level", selection: $lightLevelFilter) {
                        Text("All Light Levels").tag(LightLevel?.none)
                        ForEach(LightLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level as LightLevel?)
                        }
                    }
                    
                    Picker("Care Status", selection: $careNeededFilter) {
                        Text("All Care Status").tag(CareNeededFilter?.none)
                        ForEach(CareNeededFilter.allCases, id: \.self) { filter in
                            Label(filter.rawValue, systemImage: filter.icon).tag(filter as CareNeededFilter?)
                        }
                    }
                }
                
                Section {
                    Button("Clear All Filters", role: .destructive) {
                        healthFilter = nil
                        lightLevelFilter = nil
                        careNeededFilter = nil
                        groupBy = .none
                        dismiss()
                    }
                }
            }
            .navigationTitle("Organize & Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ModernCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.shared.light()
                }
            }
    }
}

// MARK: - Enhanced Components

struct EnhancedStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String?
    
    var body: some View {
        VStack(spacing: BotanicaTheme.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(color)
                    .bounceByLayerNonRepeating()
                
                Spacer()
                
                if let trend = trend {
                    Text(trend)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(BotanicaTheme.Colors.success)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(BotanicaTheme.Colors.success.opacity(0.15))
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(BotanicaTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
                .shadow(
                    color: color.opacity(0.1),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }
}

// MARK: - Custom Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview("With Plants") {
    MyPlantsView()
        .modelContainer(MockDataGenerator.previewContainer())
}

struct PlantCareReminderRow: View {
    let plant: Plant
    
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.md) {
            // Plant thumbnail
            AsyncPlantThumbnail(photo: plant.primaryPhoto, plant: plant, size: 40)
            
            // Plant info
            VStack(alignment: .leading, spacing: 2) {
                Text(plant.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: BotanicaTheme.Spacing.xs) {
                    if plant.isWateringOverdue {
                        Label("Water", systemImage: "drop.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(BotanicaTheme.Colors.waterBlue)
                    }
                    
                    if plant.isFertilizingOverdue {
                        Label("Feed", systemImage: "leaf.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(BotanicaTheme.Colors.leafGreen)
                    }
                }
            }
            
            Spacer()
            
            // Quick action button
            Button {
                // TODO: Quick care action
                HapticManager.shared.light()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(BotanicaTheme.Colors.success)
            }
        }
        .padding(.vertical, BotanicaTheme.Spacing.xs)
    }
}

// MARK: - Modern Stat Card Component

struct ModernStatCard: View {
    let title: String
    let value: String
    let icon: String
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
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
            }
        }
        .padding(BotanicaTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview("Empty State") {
    MyPlantsView()
        .modelContainer(for: [Plant.self, CareEvent.self, Reminder.self, Photo.self, CarePlan.self], inMemory: true)
}
