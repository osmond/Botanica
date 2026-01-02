import SwiftUI

/// Compact subviews extracted from MyPlantsView to simplify the main file.
struct CollectionInsightsHeaderView: View {
    let plantsCount: Int
    let insight: String
    let summary: String
    let onClearFilter: () -> Void
    let onFilterTap: () -> Void
    let activeFilterTitle: String?
    let activeFilterCount: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.section) {
            Text("Track care, health, and schedules for your plants.")
                .font(BotanicaTheme.Typography.callout)
                .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                .padding(.horizontal, BotanicaTheme.Spacing.screenPadding)
            
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                Text(summary)
                    .font(BotanicaTheme.Typography.bodyEmphasized)
                    .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                Text(insight)
                    .font(BotanicaTheme.Typography.subheadline)
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary)
            }
            .padding(BotanicaTheme.Spacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                    .fill(BotanicaTheme.Colors.surfaceAlt)
            )
            .padding(.horizontal, BotanicaTheme.Spacing.screenPadding)
            
            HStack(spacing: BotanicaTheme.Spacing.item) {
                Button(action: onFilterTap) {
                    HStack(spacing: BotanicaTheme.Spacing.xs) {
                        Image(systemName: "slider.horizontal.3")
                            .font(BotanicaTheme.Typography.captionEmphasized)
                        Text(filterLabel)
                            .font(BotanicaTheme.Typography.calloutEmphasized)
                    }
                    .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                    .padding(.horizontal, BotanicaTheme.Spacing.md)
                    .padding(.vertical, BotanicaTheme.Spacing.sm)
                    .background(
                        Capsule()
                            .fill(BotanicaTheme.Colors.surfaceAlt)
                            .overlay(
                                Capsule()
                                    .stroke(BotanicaTheme.Colors.primary.opacity(0.15), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                if activeFilterTitle != nil {
                    Button("Clear") { onClearFilter() }
                        .font(BotanicaTheme.Typography.captionEmphasized)
                        .foregroundStyle(BotanicaTheme.Colors.primary)
                }
            }
            .padding(.horizontal, BotanicaTheme.Spacing.screenPadding)
        }
    }
    
    private var filterLabel: String {
        if let activeFilterTitle {
            if let count = activeFilterCount {
                return "Filter: \(activeFilterTitle) (\(count))"
            }
            return "Filter: \(activeFilterTitle)"
        }
        return "Filter: All (\(plantsCount))"
    }
}

struct CollectionFilterChip {
    let id: String
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
}

struct CareRemindersSectionView: View {
    let urgentPlants: [Plant]
    let onViewAll: () -> Void
    
    var body: some View {
        EmptyView()
    }
}

struct QuickFiltersView: View {
    @Binding var filterBy: HealthStatus?
    @Binding var careNeededFilter: CareNeededFilter?
    @Binding var sortBy: SortOption
    let plantsCount: Int
    let needsWaterCount: Int
    let needsFertilizerCount: Int
    let dueTodayCount: Int
    let healthyPlantCount: Int
    let weeklyAddedCount: Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BotanicaTheme.Spacing.md) {
                QuickFilterPill(
                    title: "All Plants",
                    count: plantsCount,
                    isSelected: filterBy == nil && careNeededFilter == nil,
                    action: { filterBy = nil; careNeededFilter = nil }
                )
                
                QuickFilterPill(
                    title: "Need Water",
                    count: needsWaterCount,
                    isSelected: careNeededFilter == .needsWatering,
                    action: { careNeededFilter = careNeededFilter == .needsWatering ? nil : .needsWatering }
                )
                
                QuickFilterPill(
                    title: "Need Feed",
                    count: needsFertilizerCount,
                    isSelected: careNeededFilter == .needsFertilizing,
                    action: { careNeededFilter = careNeededFilter == .needsFertilizing ? nil : .needsFertilizing }
                )
                
                QuickFilterPill(
                    title: "Due Today",
                    count: dueTodayCount,
                    isSelected: careNeededFilter == .dueToday,
                    action: { careNeededFilter = careNeededFilter == .dueToday ? nil : .dueToday }
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
            .padding(.horizontal, BotanicaTheme.Spacing.screenPadding)
        }
    }
}

struct ModernEmptyStateView: View {
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: BotanicaTheme.Spacing.xxl) {
            Spacer()
            
            VStack(spacing: BotanicaTheme.Spacing.xl) {
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
                            .font(.system(size: BotanicaTheme.Sizing.iconXXXL, weight: .light))
                            .foregroundStyle(BotanicaTheme.Colors.primary)
                            .breatheRepeating()
                        
                        Text("🌱")
                            .font(BotanicaTheme.Typography.title1)
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
                    onAdd()
                } label: {
                    HStack(spacing: BotanicaTheme.Spacing.md) {
                        Image(systemName: "plus.circle.fill")
                            .font(BotanicaTheme.Typography.title3)
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
}

struct PlantsMainContentView: View {
    let groups: [PlantGroup]
    let viewMode: ViewMode
    
    var body: some View {
        VStack(spacing: BotanicaTheme.Spacing.xl) {
            ForEach(groups, id: \.id) { group in
                ModernPlantSection(
                    group: group,
                    viewMode: viewMode
                )
            }
        }
        .padding(.horizontal, BotanicaTheme.Spacing.screenPadding)
    }
}
